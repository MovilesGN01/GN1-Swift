//
//  User.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 3/04/26.
//

import Foundation

enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}

struct User {
    var userId: String
    var name: String
    var email: String
    var role: String
    var gender: Gender?

    var carModel: String?
    var plate: String?
    var seats: Int?

    var reputationScore: Double = 5.0
    var punctualityRate: Double = 5.0
    var ridesPerMonth: Int = 0
    var driverRating: Double = 5.0
    var verified: Bool = false
}
