import CoreData

/// NSManagedObject that mirrors the Ride value type for local persistence.
/// Properties must exactly match the attributes declared in PersistenceController.makeModel().
@objc(RideEntity)
final class RideEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var driverId: String
    @NSManaged var driverName: String
    @NSManaged var driverRating: Double
    @NSManaged var driverGender: String?
    @NSManaged var origin: String
    @NSManaged var destination: String
    @NSManaged var zone: String
    @NSManaged var departureTime: Date
    @NSManaged var seatsAvailable: Int32
    @NSManaged var status: String
    @NSManaged var price: Double
    @NSManaged var originLat: Double     // 0 == not set
    @NSManaged var originLng: Double
    @NSManaged var destinationLat: Double
    @NSManaged var destinationLng: Double
    // Local-only — timestamp of when this entity was written to CoreData.
    // Meaningful only for locally created ("pending") rides.
    @NSManaged var createdAt: Date

    @nonobjc static func fetchRequest() -> NSFetchRequest<RideEntity> {
        NSFetchRequest<RideEntity>(entityName: "RideEntity")
    }

    // MARK: - Populate from Ride (Ride → CoreData)

    func populate(from ride: Ride) {
        id             = ride.id
        driverId       = ride.driverId
        driverName     = ride.driverName
        driverRating   = ride.driverRating
        driverGender   = ride.driverGender
        origin         = ride.origin
        destination    = ride.destination
        zone           = ride.zone
        departureTime  = ride.departureTime
        seatsAvailable = Int32(ride.seatsAvailable)
        status         = ride.status
        price          = ride.price
        // Optional coordinates: store 0 when absent
        originLat      = ride.originLat ?? 0
        originLng      = ride.originLng ?? 0
        destinationLat = ride.destinationLat ?? 0
        destinationLng = ride.destinationLng ?? 0
    }
}

// MARK: - Ride ← RideEntity (CoreData → Ride)

extension Ride {
    /// Reconstructs a Ride value from a persisted RideEntity.
    /// Uses the memberwise init so there is no dependency on FirebaseFirestore.Timestamp.
    init(entity: RideEntity) {
        self.init(
            id:             entity.id,
            driverId:       entity.driverId,
            driverName:     entity.driverName,
            driverRating:   entity.driverRating,
            driverGender:   entity.driverGender,
            origin:         entity.origin,
            destination:    entity.destination,
            zone:           entity.zone,
            departureTime:  entity.departureTime,
            seatsAvailable: Int(entity.seatsAvailable),
            status:         entity.status,
            price:          entity.price,
            // Convert sentinel 0 back to nil
            originLat:      entity.originLat      == 0 ? nil : entity.originLat,
            originLng:      entity.originLng      == 0 ? nil : entity.originLng,
            destinationLat: entity.destinationLat == 0 ? nil : entity.destinationLat,
            destinationLng: entity.destinationLng == 0 ? nil : entity.destinationLng
        )
    }
}
