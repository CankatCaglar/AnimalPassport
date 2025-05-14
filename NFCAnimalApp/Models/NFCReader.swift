import CoreNFC
import Foundation

class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    private var completion: ((Result<NFCAnimalData, Error>) -> Void)?
    private var maxRetries = 3
    private var currentRetry = 0
    private var currentTag: NFCNDEFTag?
    
    /// Start an NFC session to read animal data
    func readFromTag(completion: @escaping (Result<NFCAnimalData, Error>) -> Void) {
        self.completion = completion
        self.currentRetry = 0
        
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NSError(domain: "NFCReadError", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "NFC özelliği bu cihazda kullanılamıyor."])))
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
        session?.alertMessage = "NFC tag'i okumak için telefonunuzu yaklaştırın."
        session?.begin()
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC session invalidated with error: \(error)")
        
        let nfcError = error as NSError
        
        // Handle specific NFCReaderError cases
        if nfcError.domain == NFCReaderError.errorDomain {
            switch nfcError.code {
            case NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue:
                // Kullanıcı NFC ekranını kapattı - sessizce işlemi sonlandır
                self.session = nil
                return
                
            case NFCReaderError.readerSessionInvalidationErrorSessionTimeout.rawValue:
                completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "NFC okuma süresi doldu. Lütfen tekrar deneyin."])))
                
            case NFCReaderError.readerSessionInvalidationErrorSystemIsBusy.rawValue:
                completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "NFC sistemi şu anda meşgul. Lütfen biraz bekleyip tekrar deneyin."])))
                
            case NFCReaderError.readerSessionInvalidationErrorFirstNDEFTagRead.rawValue:
                // Normal sonlandırma - sessizce işlemi bitir
                self.session = nil
                return
                
            default:
                // Handle connection errors with retry logic
                if currentRetry < maxRetries {
                    print("Connection error detected, attempting to retry...")
                    currentRetry += 1
                    print("Retry attempt \(currentRetry) of \(maxRetries)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let tag = self.currentTag {
                            self.connectToTag(tag, session: session)
                        }
                    }
                    return
                } else {
                    completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "NFC bağlantısı kurulamadı. Lütfen tekrar deneyin."])))
                }
            }
        }
        
        self.session = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            print("No tag found")
            session.invalidate(errorMessage: "NFC tag bulunamadı.")
            completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "NFC tag bulunamadı."])))
            return
        }
        
        // Store the tag for potential retries
        self.currentTag = tag
        
        // Connect to the tag
        connectToTag(tag, session: session)
    }
    
    private func connectToTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        session.connect(to: tag) { error in
            if let error = error {
                print("Connection failed: \(error)")
                session.invalidate(errorMessage: "Bağlantı başarısız: Lütfen telefonu tag'e yakın tutun.")
                self.completion?(.failure(error))
                return
            }
            
            print("Successfully connected to tag")
            
            tag.queryNDEFStatus { ndefStatus, capacity, error in
                if let error = error {
                    print("Failed to query tag: \(error)")
                    session.invalidate(errorMessage: "Tag bilgisi okunamadı.")
                    self.completion?(.failure(error))
                    return
                }
                
                print("Tag status: \(ndefStatus), capacity: \(capacity) bytes")
                
                switch ndefStatus {
                case .notSupported:
                    print("Tag is not supported")
                    session.invalidate(errorMessage: "Bu NFC tag desteklenmiyor.")
                    self.completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Bu NFC tag desteklenmiyor."])))
                    return
                case .readOnly:
                    // Read-only tag'ler için okumaya devam et
                    self.readNDEFFromTag(tag, session: session)
                case .readWrite:
                    self.readNDEFFromTag(tag, session: session)
                @unknown default:
                    print("Unknown tag status")
                    session.invalidate(errorMessage: "Bilinmeyen tag durumu.")
                    self.completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Bilinmeyen tag durumu."])))
                    return
                }
            }
        }
    }
    
    private func readNDEFFromTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF { message, error in
            if let error = error {
                print("Read failed: \(error)")
                
                // Handle specific error cases
                if (error as NSError).domain == NFCReaderError.errorDomain {
                    switch (error as NSError).code {
                    case NFCReaderError.ndefReaderSessionErrorTagNotWritable.rawValue:
                        print("Tag is not formatted with NDEF data")
                        session.alertMessage = "Tag is not formatted. Please write data to the tag first."
                        session.invalidate()
                        self.completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Tag is not formatted. Please write data to the tag first."])))
                        return
                    case NFCReaderError.readerTransceiveErrorTagConnectionLost.rawValue:
                        // Connection error, will be handled by didInvalidateWithError
                        print("Connection error during read")
                        session.invalidate(errorMessage: "Connection lost. Please keep your phone close to the tag.")
                        return
                    default:
                        print("Unknown NFC error: \(error)")
                        session.invalidate(errorMessage: "Reading failed. Please try again.")
                        self.completion?(.failure(error))
                        return
                    }
                }
                
                session.invalidate(errorMessage: "Reading failed. Please try again.")
                self.completion?(.failure(error))
                return
            }
            
            guard let message = message,
                  let record = message.records.first,
                  let payloadString = String(data: record.payload, encoding: .utf8) else {
                print("Failed to decode payload")
                session.invalidate(errorMessage: "Could not read tag data.")
                self.completion?(.failure(NSError(domain: "NFCReadError", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Could not read tag data."])))
                return
            }
            
            print("Successfully read payload: \(payloadString)")
            
            do {
                if let animalData = try NFCAnimalData.fromJSON(payloadString) {
                    print("Successfully parsed animal data")
                    self.completion?(.success(animalData))
                    session.alertMessage = "Tag read successfully!"
                    session.invalidate()
                } else {
                    throw NSError(domain: "NFCReadError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Could not parse data."])
                }
            } catch {
                print("Failed to parse data: \(error)")
                session.invalidate(errorMessage: "Could not parse data.")
                self.completion?(.failure(error))
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session became active")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // This method is required by the protocol but we're using the newer API
        // that handles tag detection directly in didDetect
    }
} 