import FirebaseAuth

final class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
                return
            }
            completion(result?.user.uid)
        }
    }
    
    func register(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
                return
            }
            completion(result?.user.uid)
        }
    }
}
