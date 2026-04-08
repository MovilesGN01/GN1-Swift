import Foundation

final class AppFacade: AppFacadeType {
    static let shared = AppFacade()

    private let authService: AuthService
    private let firestoreService: FirestoreService
    private let cloudFunctionsService: CloudFunctionsService
    private let session: UserSession

    init(
        authService: AuthService = .shared,
        firestoreService: FirestoreService = .shared,
        cloudFunctionsService: CloudFunctionsService = .shared,
        session: UserSession = .shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.cloudFunctionsService = cloudFunctionsService
        self.session = session
    }

    func signIn(email: String, password: String, completion: @escaping (AuthFlowResult) -> Void) {
        authService.login(email: email, password: password) { [weak self] userId in
            guard let self = self, let userId = userId else {
                completion(.failure(message: "Login failed"))
                return
            }

            self.session.userId = userId
            self.session.email = email

            self.firestoreService.loadUser(userId: userId) { success in
                if success {
                    completion(.success)
                } else {
                    completion(.failure(message: "Could not load user profile"))
                }
            }
        }
    }

    func registerUser(
        name: String,
        email: String,
        password: String,
        role: String,
        carModel: String,
        plate: String,
        seats: Int?,
        completion: @escaping (AuthFlowResult) -> Void
    ) {
        authService.register(email: email, password: password) { [weak self] userId in
            guard let self = self, let userId = userId else {
                completion(.failure(message: "Error creating account"))
                return
            }

            self.session.userId = userId
            self.session.email = email
            self.session.name = name
            self.session.role = role
            self.session.carModel = carModel
            self.session.plate = plate
            self.session.seats = seats

            self.cloudFunctionsService.createUserDocument { success in
                if success {
                    completion(.success)
                } else {
                    completion(.failure(message: "Error creating user profile"))
                }
            }
        }
    }
}
