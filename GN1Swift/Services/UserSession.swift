//
//  UserSession.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 3/04/26.
//

class UserSession {
    static let shared = UserSession()
    
    var userId: String?
    var email: String?
    var name: String?
    var role: String?
    
    var carModel: String?
    var plate: String?
    var seats: Int?
}
