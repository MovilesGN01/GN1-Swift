import Foundation

protocol AppFacadeType {
    func signIn(email: String, password: String, completion: @escaping (AuthFlowResult) -> Void)
    func registerUser(
        name: String,
        email: String,
        password: String,
        role: String,
        carModel: String,
        plate: String,
        seats: Int?,
        completion: @escaping (AuthFlowResult) -> Void
    )
}
