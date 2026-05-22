import CoreData

// Standalone CoreData stack for Profile — does not touch the existing Rides stack.
final class ProfilePersistenceController {
    static let shared = ProfilePersistenceController()

    private let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }
    func backgroundContext() -> NSManagedObjectContext { container.newBackgroundContext() }

    private init() {
        // Build the entity entirely in code — no .xcdatamodeld file needed.
        let entity = NSEntityDescription()
        entity.name = "CachedProfile"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attr("userId",    .stringAttributeType),
            attr("name",      .stringAttributeType),
            attr("email",     .stringAttributeType),
            attr("role",      .stringAttributeType),
            attr("rating",    .doubleAttributeType),
            attr("updatedAt", .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]

        container = NSPersistentContainer(name: "ProfileModel", managedObjectModel: model)
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("[ProfileDB] Load error:", error.localizedDescription)
                // Remove a corrupted store so the next launch recovers cleanly.
                if let url = desc.url { try? FileManager.default.removeItem(at: url) }
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

private func attr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
    let a = NSAttributeDescription()
    a.name = name
    a.attributeType = type
    a.isOptional = true
    return a
}
