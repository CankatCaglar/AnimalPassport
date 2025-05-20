import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let animalsCollection = "animals"
    
    private init() {}
    
    // MARK: - Error Types
    enum FirebaseError: LocalizedError {
        case notLoggedIn
        case noPermission
        case invalidData
        case networkError
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "Please log in."
            case .noPermission:
                return "You do not have permission for this operation."
            case .invalidData:
                return "Invalid data format."
            case .networkError:
                return "Network connection error."
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }
    
    // MARK: - Save Animal Data
    func saveAnimalData(_ animalData: NFCAnimalData, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.notLoggedIn))
            return
        }
        
        do {
            // First convert to JSON string to handle dates properly
            let jsonString = try animalData.toJSON()
            guard let jsonData = jsonString.data(using: .utf8),
                  var dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                completion(.failure(FirebaseError.invalidData))
                return
            }
            
            // Add user and timestamp info
            dictionary["userId"] = currentUser.uid
            dictionary["createdAt"] = FieldValue.serverTimestamp()
            dictionary["updatedAt"] = FieldValue.serverTimestamp()
            
            // deathDate nil ise dictionary'den çıkar
            if animalData.deathDate == nil {
                dictionary.removeValue(forKey: "deathDate")
            }
            
            // Save to Firestore
            db.collection(animalsCollection).document(animalData.id).setData(dictionary) { error in
                if let error = error {
                    print("Error saving animal data: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Animal data saved successfully: \(animalData.id)")
                    completion(.success(animalData.id))
                }
            }
        } catch {
            print("Data conversion error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Get Animal Data
    func getAnimalData(by id: String, completion: @escaping (Result<NFCAnimalData, Error>) -> Void) {
        db.collection(animalsCollection).document(id).getDocument { document, error in
            if let error = error {
                print("Error fetching animal data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  var data = document.data() else {
                completion(.failure(FirebaseError.invalidData))
                return
            }
            
            // Convert Firestore Timestamps to ISO8601 strings
            let dateFields = ["birthDate", "transferDate", "exportDate", "deathDate", "createdAt", "updatedAt"]
            for field in dateFields {
                if let timestamp = data[field] as? Timestamp {
                    let dateFormatter = ISO8601DateFormatter()
                    data[field] = dateFormatter.string(from: timestamp.dateValue())
                }
            }
            
            // Handle vaccination dates
            if var vaccinations = data["vaccinations"] as? [String: Any] {
                let vaccinationFields = ["sapVaccine", "brucellaVaccine", "pasteurellaVaccine", "otherVaccine"]
                for field in vaccinationFields {
                    if let timestamp = vaccinations[field] as? Timestamp {
                        let dateFormatter = ISO8601DateFormatter()
                        vaccinations[field] = dateFormatter.string(from: timestamp.dateValue())
                    }
                }
                data["vaccinations"] = vaccinations
            }
            
            // Handle slaughterhouse dates
            if var slaughterhouse = data["slaughterhouse"] as? [String: Any] {
                if let timestamp = slaughterhouse["slaughterDate"] as? Timestamp {
                    let dateFormatter = ISO8601DateFormatter()
                    slaughterhouse["slaughterDate"] = dateFormatter.string(from: timestamp.dateValue())
                }
                data["slaughterhouse"] = slaughterhouse
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let animalData = try decoder.decode(NFCAnimalData.self, from: jsonData)
                completion(.success(animalData))
            } catch {
                print("Data parsing error: \(error)")
                completion(.failure(FirebaseError.invalidData))
            }
        }
    }
    
    // MARK: - Get User Animals
    func getUserAnimals(completion: @escaping (Result<[NFCAnimalData], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.notLoggedIn))
            return
        }
        
        db.collection(animalsCollection)
            .whereField("userId", isEqualTo: currentUser.uid)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching user animals: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                var animals: [NFCAnimalData] = []
                
                for document in querySnapshot?.documents ?? [] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                        let decoder = JSONDecoder()
                        let animalData = try decoder.decode(NFCAnimalData.self, from: jsonData)
                        animals.append(animalData)
                    } catch {
                        print("Data parsing error: \(error.localizedDescription)")
                        // Continue with the next document even if one fails
                        continue
                    }
                }
                
                completion(.success(animals))
            }
    }
    
    // MARK: - Update Animal Data
    func updateAnimalData(_ animalData: NFCAnimalData, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.notLoggedIn))
            return
        }
        
        // First check if the user has permission to update this animal
        db.collection(animalsCollection).document(animalData.id).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document,
                  let data = document.data(),
                  let userId = data["userId"] as? String,
                  userId == currentUser.uid else {
                completion(.failure(FirebaseError.noPermission))
                return
            }
            
            // User has permission, proceed with update
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(animalData)
                guard var dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion(.failure(FirebaseError.invalidData))
                    return
                }
                
                dictionary["updatedAt"] = FieldValue.serverTimestamp()
                
                self.db.collection(self.animalsCollection).document(animalData.id).updateData(dictionary) { error in
                    if let error = error {
                        print("Error updating animal data: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Animal data updated successfully: \(animalData.id)")
                        completion(.success(()))
                    }
                }
            } catch {
                print("Data conversion error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Animal Data
    func deleteAnimalData(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(FirebaseError.notLoggedIn))
            return
        }
        
        // First check if the user has permission to delete this animal
        db.collection(animalsCollection).document(id).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document,
                  let data = document.data(),
                  let userId = data["userId"] as? String,
                  userId == currentUser.uid else {
                completion(.failure(FirebaseError.noPermission))
                return
            }
            
            // User has permission, proceed with deletion
            self.db.collection(self.animalsCollection).document(id).delete { error in
                if let error = error {
                    print("Error deleting animal data: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Animal data deleted successfully: \(id)")
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Statistics
    func fetchAnimalStatistics(completion: @escaping (Int, Int, Int) -> Void) {
        let animalsRef = db.collection(animalsCollection)
        // 1. Total Tags
        animalsRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(0, 0, 0)
                return
            }
            let total = documents.count
            // 2. Active Tags (deathDate alanı olmayanlar veya boş olanlar)
            let active = documents.filter { doc in
                let deathDate = doc.data()["deathDate"]
                return deathDate == nil || (deathDate is NSNull) || (deathDate as? String == "") || (deathDate as? String == "null")
            }.count
            // 3. This Month (createdAt bu ay olanlar)
            let calendar = Calendar.current
            let now = Date()
            let thisMonth = documents.filter { doc in
                if let ts = doc.data()["createdAt"] as? Timestamp {
                    let date = ts.dateValue()
                    return calendar.isDate(date, equalTo: now, toGranularity: .month) && calendar.isDate(date, equalTo: now, toGranularity: .year)
                }
                return false
            }.count
            completion(total, active, thisMonth)
        }
    }
} 