import CoreData

/// Responsible for all CoreData read and write operations related to Ride.
/// All writes happen on a background context; reads happen on the view context.
final class RideLocalDataSource {

    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Read

    /// Fetches all locally cached rides, sorted by departure time.
    /// Runs on the view context — safe to call from any thread (result returned on caller's thread).
    func fetchRides() async -> [Ride] {
        let context = persistence.viewContext
        return await context.perform {
            let request = RideEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "departureTime", ascending: true)
            ]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { Ride(entity: $0) }
        }
    }

    // MARK: - Write

    /// Replaces the Firebase ride cache with the supplied rides.
    /// Rides with status "pending" (locally created while offline) are preserved.
    /// Uses a background context so the main thread is never blocked.
    func saveRides(_ rides: [Ride]) async {
        guard !rides.isEmpty else { return }
        let context = persistence.newBackgroundContext()

        await context.perform {
            // 1. Delete only non-pending cached rides (preserve offline-created rides)
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RideEntity")
            deleteRequest.predicate = NSPredicate(format: "status != %@", "pending")
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(batchDelete) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [self.persistence.viewContext]
                )
            }

            // 2. Insert fresh Firebase data
            for ride in rides {
                let entity = RideEntity(context: context)
                entity.populate(from: ride)
            }

            // 3. Persist
            try? context.save()
        }
    }

    // MARK: - Offline / Pending Rides

    /// All locally created rides that are waiting to be synced to Firebase.
    func fetchPendingRides() async -> [Ride] {
        let context = persistence.viewContext
        return await context.perform {
            let request = RideEntity.fetchRequest()
            request.predicate = NSPredicate(format: "status == %@", "pending")
            request.sortDescriptors = [NSSortDescriptor(key: "departureTime", ascending: true)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { Ride(entity: $0) }
        }
    }

    /// Persists a single locally created ride (status must be "pending").
    func savePendingRide(_ ride: Ride) async {
        let context = persistence.newBackgroundContext()
        await context.perform {
            let entity = RideEntity(context: context)
            entity.populate(from: ride)
            entity.createdAt = Date()
            try? context.save()
        }
    }

    /// Removes a single ride by its local id.
    func deleteRide(id: String) async {
        let context = persistence.newBackgroundContext()
        await context.perform {
            let request = RideEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            let entities = (try? context.fetch(request)) ?? []
            entities.forEach { context.delete($0) }
            try? context.save()
        }
    }

    // MARK: - Passenger Requests Cache

    /// Replaces cached requests for a passenger and inserts fresh ones.
    func savePassengerRequests(_ requests: [RideRequest], for passengerId: String) async {
        let context = persistence.newBackgroundContext()
        await context.perform {
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RideRequestEntity")
            deleteRequest.predicate = NSPredicate(format: "passengerId == %@", passengerId)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(batchDelete) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [self.persistence.viewContext]
                )
            }
            for request in requests {
                let entity = RideRequestEntity(context: context)
                entity.populate(from: request)
            }
            try? context.save()
        }
    }

    /// Returns all cached requests for a given passenger.
    func fetchPassengerRequests(for passengerId: String) async -> [RideRequest] {
        let context = persistence.viewContext
        return await context.perform {
            let request = RideRequestEntity.fetchRequest()
            request.predicate = NSPredicate(format: "passengerId == %@", passengerId)
            request.sortDescriptors = [NSSortDescriptor(key: "requestTime", ascending: false)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { RideRequest(entity: $0) }
        }
    }

    // MARK: - Ride History Cache

    /// Replaces cached history for a passenger and inserts fresh records.
    func saveRideHistory(_ history: [RideHistory], for passengerId: String) async {
        let context = persistence.newBackgroundContext()
        await context.perform {
            let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RideHistoryEntity")
            deleteRequest.predicate = NSPredicate(format: "passengerId == %@", passengerId)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
            batchDelete.resultType = .resultTypeObjectIDs
            if let result = try? context.execute(batchDelete) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                    into: [self.persistence.viewContext]
                )
            }
            for record in history {
                let entity = RideHistoryEntity(context: context)
                entity.populate(from: record)
            }
            try? context.save()
        }
    }

    /// Returns all cached history entries for a given passenger.
    func fetchRideHistory(for passengerId: String) async -> [RideHistory] {
        let context = persistence.viewContext
        return await context.perform {
            let request = RideHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "passengerId == %@", passengerId)
            request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { RideHistory(entity: $0) }
        }
    }
}
