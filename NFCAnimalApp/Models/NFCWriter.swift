import CoreNFC
import Foundation
import FirebaseAuth

class NFCWriter: NSObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    private var completion: ((Bool, String) -> Void)?
    private var jsonToWrite: String?
    private var messageToWrite: NFCNDEFMessage?
    private var maxRetries = 3
    private var currentRetry = 0
    private var animalDataToWrite: NFCAnimalData?
    private var currentTag: NFCNDEFTag?
    
    /// Write animal data to an NFC tag
    func writeToTag(animalData: NFCAnimalData, completion: @escaping (Bool, String) -> Void) {
        // Check if user is authenticated only when internet is available
        if OfflineManager.shared.isInternetAvailable() {
            guard Auth.auth().currentUser != nil else {
                completion(false, "Please sign in to write data")
                return
            }
        }
        
        do {
            let jsonString = try animalData.toJSON()
            print("Attempting to write JSON: \(jsonString)")
            self.jsonToWrite = jsonString
            self.animalDataToWrite = animalData
            
            // Create the NDEF message once
            let payload = NFCNDEFPayload(
                format: .nfcWellKnown,
                type: "T".data(using: .utf8)!,
                identifier: Data(),
                payload: jsonString.data(using: .utf8)!
            )
            self.messageToWrite = NFCNDEFMessage(records: [payload])
            
            self.completion = completion
            self.currentRetry = 0
            
            guard NFCNDEFReaderSession.readingAvailable else {
                print("NFC writing not available on this device")
                completion(false, "NFC feature is not available on this device")
                return
            }
            
            session = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
            session?.alertMessage = "Hold your device near the NFC tag to write"
            session?.begin()
        } catch {
            print("Failed to encode data: \(error)")
            completion(false, "Failed to encode data: \(error.localizedDescription)")
        }
    }
    
    private func formatTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession, completion: @escaping (Bool) -> Void) {
        tag.queryNDEFStatus { ndefStatus, capacity, error in
            if let error = error {
                print("Failed to query tag: \(error)")
                session.invalidate(errorMessage: "Failed to read tag information")
                completion(false)
                return
            }
            
            print("Tag status before formatting: \(ndefStatus), capacity: \(capacity) bytes")
            
            // If the tag is already in readWrite state, we don't need to format it
            if ndefStatus == .readWrite {
                print("Tag is already in readWrite state, no formatting needed")
                completion(true)
                return
            }
            
            // For tags that need formatting, we'll try to write a simple text record
            let textPayload = NFCNDEFPayload(
                format: .nfcWellKnown,
                type: "T".data(using: .utf8)!,
                identifier: Data(),
                payload: "Initialized".data(using: .utf8)!
            )
            let message = NFCNDEFMessage(records: [textPayload])
            
            // Format the tag
            tag.writeNDEF(message) { error in
                if let error = error {
                    print("Failed to format tag: \(error)")
                    
                    // If we get a specific error about the tag being read-only, handle it
                    if (error as NSError).domain == NFCReaderError.errorDomain && 
                       (error as NSError).code == NFCReaderError.ndefReaderSessionErrorTagNotWritable.rawValue {
                        print("Tag is read-only, cannot format")
                        session.invalidate(errorMessage: "This tag is read-only and cannot be formatted")
                        completion(false)
                        return
                    }
                    
                    // For other errors, try to proceed anyway
                    print("Formatting failed but will try to write anyway")
                    completion(true)
                    return
                }
                
                print("Successfully formatted tag")
                completion(true)
            }
        }
    }
    
    private func writeDataToTag(_ tag: NFCNDEFTag, message: NFCNDEFMessage, session: NFCNDEFReaderSession, completion: @escaping (Bool, String) -> Void) {
        // Write the data
        tag.writeNDEF(message) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Write failed: \(error)")
                
                // If we get a connection error, try to reconnect
                if (error as NSError).domain == NFCReaderError.errorDomain && 
                   (error as NSError).code == NFCReaderError.readerTransceiveErrorTagConnectionLost.rawValue {
                    print("Connection error detected, attempting to retry...")
                    
                    // Check if we've exceeded max retries
                    if self.currentRetry >= self.maxRetries {
                        print("Max retries reached, giving up")
                        session.invalidate(errorMessage: "Connection failed. Please try again")
                        completion(false, "Connection failed. Please try again")
                        return
                    }
                    
                    // Increment retry counter
                    self.currentRetry += 1
                    print("Retry attempt \(self.currentRetry) of \(self.maxRetries)")
                    
                    // Wait a moment before reconnecting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        session.connect(to: tag) { error in
                            if let error = error {
                                print("Reconnection failed: \(error)")
                                session.invalidate(errorMessage: "Connection lost: \(error.localizedDescription)")
                                completion(false, "Connection lost: \(error.localizedDescription)")
                                return
                            }
                            print("Reconnected successfully, retrying write...")
                            // Retry the write operation
                            self.writeDataToTag(tag, message: message, session: session, completion: completion)
                        }
                    }
                } else {
                    session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                    completion(false, "Write failed: \(error.localizedDescription)")
                }
            } else {
                print("Successfully wrote data to tag")
                
                // After successful NFC write, handle Firebase save based on internet availability
                if let animalData = self.animalDataToWrite {
                    if OfflineManager.shared.isInternetAvailable() {
                        // Internet is available, save directly to Firebase
                        FirebaseManager.shared.saveAnimalData(animalData) { result in
                            switch result {
                            case .success(let id):
                                session.alertMessage = "Successfully saved to tag and database!"
                                session.invalidate()
                                completion(true, "Data successfully saved! ID: \(id)")
                            case .failure(let error):
                                session.alertMessage = "Written to tag but failed to save to database: \(error.localizedDescription)"
                                session.invalidate()
                                completion(false, "Written to tag but failed to save to database: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        // No internet, save to offline queue
                        OfflineManager.shared.saveOfflineData(animalData)
                        session.alertMessage = "Successfully written to tag! Data will be synced when internet is available."
                        session.invalidate()
                        completion(true, "Successfully written to tag! Data will be synced when internet is available.")
                    }
                } else {
                    session.alertMessage = "Successfully written to tag!"
                    session.invalidate()
                    completion(true, "Successfully written to tag!")
                }
            }
        }
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("NFC session invalidated with error: \(error)")
        
        let nfcError = error as NSError
        
        // Handle specific NFCReaderError cases
        if nfcError.domain == NFCReaderError.errorDomain {
            switch nfcError.code {
            case NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue:
                // User canceled NFC screen - silently end
                self.session = nil
                return
                
            case NFCReaderError.readerSessionInvalidationErrorSessionTimeout.rawValue:
                completion?(false, "NFC reading timed out. Please try again")
                
            case NFCReaderError.readerSessionInvalidationErrorSystemIsBusy.rawValue:
                completion?(false, "NFC system is busy. Please wait and try again")
                
            case NFCReaderError.readerSessionInvalidationErrorFirstNDEFTagRead.rawValue:
                // Normal termination - silently end
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
                    completion?(false, "Failed to establish NFC connection. Please try again")
                }
            }
        }
        
        self.session = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            print("No tag found")
            session.invalidate(errorMessage: "No NFC tag found")
            completion?(false, "No NFC tag found")
            return
        }
        
        // Store the tag for potential retries
        self.currentTag = tag
        
        // Connect to the tag
        connectToTag(tag, session: session)
    }
    
    private func connectToTag(_ tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Connection failed: \(error)")
                session.invalidate(errorMessage: "Connection failed: Please hold your phone closer to the tag")
                self.completion?(false, "Connection failed: Please hold your phone closer to the tag")
                return
            }
            
            print("Successfully connected to tag")
            
            // Use the pre-created message
            guard let message = self.messageToWrite else {
                print("No data to write")
                session.invalidate(errorMessage: "No data to write")
                self.completion?(false, "No data to write")
                return
            }
            
            // Write to tag
            tag.queryNDEFStatus { ndefStatus, capacity, error in
                if let error = error {
                    print("Failed to query tag: \(error)")
                    session.invalidate(errorMessage: "Failed to read tag information")
                    self.completion?(false, "Failed to read tag information")
                    return
                }
                
                print("Tag status: \(ndefStatus), capacity: \(capacity) bytes")
                
                switch ndefStatus {
                case .notSupported:
                    print("Tag is not supported")
                    session.invalidate(errorMessage: "This NFC tag is not supported")
                    self.completion?(false, "This NFC tag is not supported")
                case .readOnly:
                    print("Tag is read-only")
                    session.invalidate(errorMessage: "This tag is read-only")
                    self.completion?(false, "This tag is read-only")
                case .readWrite:
                    // Format the tag first if needed
                    self.formatTag(tag, session: session) { success in
                        if success {
                            print("Tag formatted successfully, attempting to write data...")
                            // Now write the data with retry logic
                            self.writeDataToTag(tag, message: message, session: session, completion: self.completion ?? { _, _ in })
                        } else {
                            print("Failed to format tag")
                            self.completion?(false, "Failed to format tag")
                        }
                    }
                @unknown default:
                    print("Unknown tag status")
                    session.invalidate(errorMessage: "Unknown tag status")
                    self.completion?(false, "Unknown tag status")
                }
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