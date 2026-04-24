import CoreData

// MARK: - RideRequestEntity

@objc(RideRequestEntity)
final class RideRequestEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var rideId: String
    @NSManaged var passengerId: String
    @NSManaged var passengerName: String
    @NSManaged var driverId: String
    @NSManaged var status: String
    @NSManaged var requestTime: Date

    @nonobjc static func fetchRequest() -> NSFetchRequest<RideRequestEntity> {
        NSFetchRequest<RideRequestEntity>(entityName: "RideRequestEntity")
    }

    func populate(from request: RideRequest) {
        id            = request.id
        rideId        = request.rideId
        passengerId   = request.passengerId
        passengerName = request.passengerName
        driverId      = request.driverId
        status        = request.status
        requestTime   = request.requestTime
    }
}

extension RideRequest {
    init(entity: RideRequestEntity) {
        self.init(id: entity.id, from: [
            "rideId":        entity.rideId,
            "passengerId":   entity.passengerId,
            "passengerName": entity.passengerName,
            "driverId":      entity.driverId,
            "status":        entity.status,
        ])
    }
}

// MARK: - RideHistoryEntity

@objc(RideHistoryEntity)
final class RideHistoryEntity: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var rideId: String
    @NSManaged var passengerId: String
    @NSManaged var driverId: String
    @NSManaged var origin: String
    @NSManaged var destination: String
    @NSManaged var zone: String
    @NSManaged var completedAt: Date
    @NSManaged var passengerRating: Double
    @NSManaged var driverRating: Double

    @nonobjc static func fetchRequest() -> NSFetchRequest<RideHistoryEntity> {
        NSFetchRequest<RideHistoryEntity>(entityName: "RideHistoryEntity")
    }

    func populate(from history: RideHistory) {
        id              = history.id
        rideId          = history.rideId
        passengerId     = history.passengerId
        driverId        = history.driverId
        origin          = history.origin
        destination     = history.destination
        zone            = history.zone
        completedAt     = history.completedAt
        passengerRating = history.passengerRating
        driverRating    = history.driverRating
    }
}

extension RideHistory {
    init(entity: RideHistoryEntity) {
        self.init(id: entity.id, from: [
            "rideId":          entity.rideId,
            "passengerId":     entity.passengerId,
            "driverId":        entity.driverId,
            "origin":          entity.origin,
            "destination":     entity.destination,
            "zone":            entity.zone,
            "passengerRating": entity.passengerRating,
            "driverRating":    entity.driverRating,
        ])
    }
}
