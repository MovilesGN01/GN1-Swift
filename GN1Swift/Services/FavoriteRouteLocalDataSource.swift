import CoreData

struct FavoriteRoute: Identifiable {
    let id: String
    let origin: String
    let destination: String
    let zone: String
    let useCount: Int
    let savedAt: Date
}

final class FavoriteRouteLocalDataSource {
    private let store = FavoritePersistenceController.shared

    // MARK: - Read (view context — main thread safe)

    func fetchAll() -> [FavoriteRoute] {
        let ctx = store.viewContext
        let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteRouteEntity")
        req.sortDescriptors = [NSSortDescriptor(key: "useCount", ascending: false)]
        return ((try? ctx.fetch(req)) ?? []).compactMap { obj in
            guard let id = obj.value(forKey: "id") as? String,
                  let origin = obj.value(forKey: "origin") as? String,
                  let destination = obj.value(forKey: "destination") as? String else { return nil }
            return FavoriteRoute(
                id: id,
                origin: origin,
                destination: destination,
                zone: obj.value(forKey: "zone") as? String ?? "",
                useCount: obj.value(forKey: "useCount") as? Int ?? 0,
                savedAt: obj.value(forKey: "savedAt") as? Date ?? Date()
            )
        }
    }

    // MARK: - Write (background context)

    func save(origin: String, destination: String, zone: String,
              completion: @escaping () -> Void = {}) {
        let ctx = store.backgroundContext()
        ctx.perform {
            let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteRouteEntity")
            req.predicate = NSPredicate(format: "origin == %@ AND destination == %@", origin, destination)
            req.fetchLimit = 1
            if let existing = (try? ctx.fetch(req))?.first {
                let count = existing.value(forKey: "useCount") as? Int32 ?? 0
                existing.setValue(count + 1, forKey: "useCount")
                existing.setValue(zone, forKey: "zone")
            } else {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "FavoriteRouteEntity", into: ctx)
                obj.setValue(UUID().uuidString, forKey: "id")
                obj.setValue(origin,            forKey: "origin")
                obj.setValue(destination,       forKey: "destination")
                obj.setValue(zone,              forKey: "zone")
                obj.setValue(Int32(1),          forKey: "useCount")
                obj.setValue(Date(),            forKey: "savedAt")
            }
            try? ctx.save()
            DispatchQueue.main.async { completion() }
        }
    }

    func incrementUseCount(id: String, completion: @escaping () -> Void = {}) {
        let ctx = store.backgroundContext()
        ctx.perform {
            let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteRouteEntity")
            req.predicate = NSPredicate(format: "id == %@", id)
            req.fetchLimit = 1
            if let obj = (try? ctx.fetch(req))?.first {
                let count = obj.value(forKey: "useCount") as? Int32 ?? 0
                obj.setValue(count + 1, forKey: "useCount")
                try? ctx.save()
            }
            DispatchQueue.main.async { completion() }
        }
    }

    func delete(id: String, completion: @escaping () -> Void = {}) {
        let ctx = store.backgroundContext()
        ctx.perform {
            let req = NSFetchRequest<NSManagedObject>(entityName: "FavoriteRouteEntity")
            req.predicate = NSPredicate(format: "id == %@", id)
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
            try? ctx.save()
            DispatchQueue.main.async { completion() }
        }
    }
}
