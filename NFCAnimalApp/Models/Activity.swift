import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Activity: Identifiable, Codable {
    let id: String
    let type: ActivityType
    let animalId: String
    let timestamp: Date
    let userId: String
    let userName: String
    
    enum ActivityType: String, Codable {
        case readTag = "Read Tag"
        case writeTag = "Write Tag"
        case addAnimal = "Add Animal"
        case updateAnimal = "Update Animal"
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

extension Activity {
    static func fetchRecentActivities(limit: Int = 5, completion: @escaping ([Activity]) -> Void) {
        let db = Firestore.firestore()
        db.collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching activities: \(error)")
                    completion([])
                    return
                }
                
                let activities = snapshot?.documents.compactMap { document -> Activity? in
                    try? document.data(as: Activity.self)
                } ?? []
                
                completion(activities)
            }
    }
    
    static func logActivity(type: ActivityType, animalId: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let activity = Activity(
            id: UUID().uuidString,
            type: type,
            animalId: animalId,
            timestamp: Date(),
            userId: user.uid,
            userName: user.displayName ?? "Unknown User"
        )
        
        do {
            // Create activities collection if it doesn't exist
            let activitiesRef = db.collection("activities")
            
            // Convert activity to dictionary
            let activityData: [String: Any] = [
                "id": activity.id,
                "type": activity.type.rawValue,
                "animalId": activity.animalId,
                "timestamp": Timestamp(date: activity.timestamp),
                "userId": activity.userId,
                "userName": activity.userName
            ]
            
            // Save to Firebase
            try activitiesRef.document(activity.id).setData(activityData)
            print("Activity logged successfully: \(activity.id)")
        } catch {
            print("Error logging activity: \(error)")
        }
    }
} 