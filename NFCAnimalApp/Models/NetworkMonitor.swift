import Foundation
import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Internet connection is available, sync offline data
                self?.syncOfflineData()
            }
        }
        monitor.start(queue: queue)
    }
    
    private func syncOfflineData() {
        OfflineManager.shared.syncOfflineData { result in
            switch result {
            case .success:
                print("Successfully synced offline data")
            case .failure(let error):
                print("Failed to sync offline data: \(error.localizedDescription)")
            }
        }
    }
    
    func isInternetAvailable() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
} 