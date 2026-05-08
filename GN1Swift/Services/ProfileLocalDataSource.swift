import CoreData

// Relational local DB operations for the Profile feature.
// Uses a background NSManagedObjectContext so writes never block the main thread.
final class ProfileLocalDataSource {
    private let store = ProfilePersistenceController.shared

    // MARK: - Write (background context)

    func saveProfile(userId: String, name: String, email: String,
                     rating: Double, role: String) {
        let ctx = store.backgroundContext()
        ctx.perform {
            // Delete stale record for this user first
            let req = NSFetchRequest<NSManagedObject>(entityName: "CachedProfile")
            req.predicate = NSPredicate(format: "userId == %@", userId)
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }

            // Insert fresh record
            let obj = NSEntityDescription.insertNewObject(forEntityName: "CachedProfile",
                                                          into: ctx)
            obj.setValue(userId,  forKey: "userId")
            obj.setValue(name,    forKey: "name")
            obj.setValue(email,   forKey: "email")
            obj.setValue(rating,  forKey: "rating")
            obj.setValue(role,    forKey: "role")
            obj.setValue(Date(),  forKey: "updatedAt")
            try? ctx.save()
        }
    }

    // MARK: - Read (view context — main thread safe)

    func loadProfile(userId: String) -> (name: String, email: String,
                                         rating: Double, role: String)? {
        let ctx = store.viewContext
        let req = NSFetchRequest<NSManagedObject>(entityName: "CachedProfile")
        req.predicate = NSPredicate(format: "userId == %@", userId)
        req.fetchLimit = 1

        guard let obj   = try? ctx.fetch(req).first,
              let name  = obj.value(forKey: "name")  as? String,
              !name.isEmpty else { return nil }

        return (
            name:   name,
            email:  obj.value(forKey: "email")  as? String ?? "",
            rating: obj.value(forKey: "rating") as? Double ?? 0.0,
            role:   obj.value(forKey: "role")   as? String ?? ""
        )
    }
}
