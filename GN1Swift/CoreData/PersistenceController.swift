import CoreData

/// Owns the CoreData stack for the app.
/// The model is built programmatically so no .xcdatamodeld file is needed —
/// Xcode just has to compile this file.
final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // MARK: - Init

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: "GN1Swift",
            managedObjectModel: Self.makeModel()
        )
        if inMemory {
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                // Acceptable to crash here in development; in production you
                // would log the error and degrade gracefully.
                fatalError("CoreData failed to load store: \(error.localizedDescription)")
            }
        }
        // viewContext automatically picks up saves made on background contexts.
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Contexts

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// Returns a new background context for safe off-main-thread writes.
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    // MARK: - Programmatic Model

    /// Builds the NSManagedObjectModel entirely in code.
    /// Every attribute here must match a @NSManaged property in RideEntity.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "RideEntity"
        entity.managedObjectClassName = NSStringFromClass(RideEntity.self)

        // Helper to reduce repetition
        func attribute(
            _ name: String,
            _ type: NSAttributeType,
            optional: Bool = false,
            defaultValue: Any? = nil
        ) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            if let defaultValue { attr.defaultValue = defaultValue }
            return attr
        }

        entity.properties = [
            attribute("id",             .stringAttributeType,   defaultValue: ""),
            attribute("driverId",       .stringAttributeType,   defaultValue: ""),
            attribute("driverName",     .stringAttributeType,   defaultValue: ""),
            attribute("driverRating",   .doubleAttributeType,   defaultValue: 0.0),
            attribute("driverGender",   .stringAttributeType,   optional: true),
            attribute("origin",         .stringAttributeType,   defaultValue: ""),
            attribute("destination",    .stringAttributeType,   defaultValue: ""),
            attribute("zone",           .stringAttributeType,   defaultValue: ""),
            attribute("departureTime",  .dateAttributeType,     defaultValue: Date()),
            attribute("seatsAvailable", .integer32AttributeType, defaultValue: 0),
            attribute("status",         .stringAttributeType,   defaultValue: ""),
            attribute("price",          .doubleAttributeType,   defaultValue: 0.0),
            // Coordinates: 0 is used as "not set" sentinel
            attribute("originLat",      .doubleAttributeType,   defaultValue: 0.0),
            attribute("originLng",      .doubleAttributeType,   defaultValue: 0.0),
            attribute("destinationLat", .doubleAttributeType,   defaultValue: 0.0),
            attribute("destinationLng", .doubleAttributeType,   defaultValue: 0.0),
            // Local-only: timestamp of when the ride entity was saved to CoreData
            attribute("createdAt",      .dateAttributeType,     defaultValue: Date()),
        ]

        // MARK: RideRequestEntity
        let requestEntity = NSEntityDescription()
        requestEntity.name = "RideRequestEntity"
        requestEntity.managedObjectClassName = NSStringFromClass(RideRequestEntity.self)
        requestEntity.properties = [
            attribute("id",            .stringAttributeType, defaultValue: ""),
            attribute("rideId",        .stringAttributeType, defaultValue: ""),
            attribute("passengerId",   .stringAttributeType, defaultValue: ""),
            attribute("passengerName", .stringAttributeType, defaultValue: ""),
            attribute("driverId",      .stringAttributeType, defaultValue: ""),
            attribute("status",        .stringAttributeType, defaultValue: ""),
            attribute("requestTime",   .dateAttributeType,   defaultValue: Date()),
        ]

        // MARK: RideHistoryEntity
        let historyEntity = NSEntityDescription()
        historyEntity.name = "RideHistoryEntity"
        historyEntity.managedObjectClassName = NSStringFromClass(RideHistoryEntity.self)
        historyEntity.properties = [
            attribute("id",              .stringAttributeType, defaultValue: ""),
            attribute("rideId",          .stringAttributeType, defaultValue: ""),
            attribute("passengerId",     .stringAttributeType, defaultValue: ""),
            attribute("driverId",        .stringAttributeType, defaultValue: ""),
            attribute("origin",          .stringAttributeType, defaultValue: ""),
            attribute("destination",     .stringAttributeType, defaultValue: ""),
            attribute("zone",            .stringAttributeType, defaultValue: ""),
            attribute("completedAt",     .dateAttributeType,   defaultValue: Date()),
            attribute("passengerRating", .doubleAttributeType, defaultValue: 0.0),
            attribute("driverRating",    .doubleAttributeType, defaultValue: 0.0),
        ]

        model.entities = [entity, requestEntity, historyEntity]
        return model
    }
}
