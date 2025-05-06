import Foundation
import FirebaseFirestore

class OfflineManager {
    static let shared = OfflineManager()
    private let userDefaults = UserDefaults.standard
    private let offlineQueueKey = "offlineQueue"
    
    private init() {}
    
    // MARK: - Save Offline Data
    func saveOfflineData(_ animalData: NFCAnimalData) {
        var queue = getOfflineQueue()
        queue.append(animalData)
        saveOfflineQueue(queue)
    }
    
    // MARK: - Get Offline Queue
    func getOfflineQueue() -> [NFCAnimalData] {
        guard let data = userDefaults.data(forKey: offlineQueueKey),
              let queue = try? JSONDecoder().decode([NFCAnimalData].self, from: data) else {
            return []
        }
        return queue
    }
    
    // MARK: - Save Offline Queue
    private func saveOfflineQueue(_ queue: [NFCAnimalData]) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        userDefaults.set(data, forKey: offlineQueueKey)
    }
    
    // MARK: - Sync Offline Data
    func syncOfflineData(completion: @escaping (Result<Void, Error>) -> Void) {
        let queue = getOfflineQueue()
        guard !queue.isEmpty else {
            completion(.success(()))
            return
        }
        
        let group = DispatchGroup()
        var errors: [Error] = []
        
        for animalData in queue {
            group.enter()
            FirebaseManager.shared.saveAnimalData(animalData) { result in
                switch result {
                case .success:
                    // Remove from queue on success
                    var updatedQueue = self.getOfflineQueue()
                    if let index = updatedQueue.firstIndex(where: { $0.id == animalData.id }) {
                        updatedQueue.remove(at: index)
                        self.saveOfflineQueue(updatedQueue)
                    }
                case .failure(let error):
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(()))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }
    
    // MARK: - Check Internet Connection
    func isInternetAvailable() -> Bool {
        return NetworkMonitor.shared.isInternetAvailable()
    }
} 