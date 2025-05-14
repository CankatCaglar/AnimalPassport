import Foundation
import FirebaseFirestore
import Combine

class ActivitiesViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = true
    private var listener: ListenerRegistration?
    
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    func startListening() {
        isLoading = true
        let db = Firestore.firestore()
        listener = db.collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: 5)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    print("Error listening for activities: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No activities found")
                    return
                }
                
                // Convert documents to activities
                let newActivities = documents.compactMap { document -> Activity? in
                    let data = document.data()
                    
                    guard let id = data["id"] as? String,
                          let typeString = data["type"] as? String,
                          let type = Activity.ActivityType(rawValue: typeString),
                          let animalId = data["animalId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let userId = data["userId"] as? String,
                          let userName = data["userName"] as? String else {
                        return nil
                    }
                    
                    return Activity(
                        id: id,
                        type: type,
                        animalId: animalId,
                        timestamp: timestamp.dateValue(),
                        userId: userId,
                        userName: userName
                    )
                }
                
                // Update on main thread
                DispatchQueue.main.async {
                    self.activities = newActivities
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func refresh() {
        stopListening()
        startListening()
    }
} 