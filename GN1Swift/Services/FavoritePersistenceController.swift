import CoreData

final class FavoritePersistenceController {
    static let shared = FavoritePersistenceController()

    private let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }
    func backgroundContext() -> NSManagedObjectContext { container.newBackgroundContext() }

    private init() {
        let entity = NSEntityDescription()
        entity.name = "FavoriteRouteEntity"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            favAttr("id",          .stringAttributeType),
            favAttr("origin",      .stringAttributeType),
            favAttr("destination", .stringAttributeType),
            favAttr("zone",        .stringAttributeType),
            favAttr("useCount",    .integer32AttributeType),
            favAttr("savedAt",     .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]

        container = NSPersistentContainer(name: "FavoritesModel", managedObjectModel: model)
        container.loadPersistentStores { desc, error in
            if let error = error {
                print("[FavoritesDB] Load error:", error.localizedDescription)
                if let url = desc.url { try? FileManager.default.removeItem(at: url) }
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

private func favAttr(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
    let a = NSAttributeDescription()
    a.name = name
    a.attributeType = type
    a.isOptional = true
    return a
}
