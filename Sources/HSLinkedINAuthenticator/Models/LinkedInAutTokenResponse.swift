//
//  LinkedInAutTokenResponse.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import Foundation
public struct LinkedINAuthTokenResponse: Codable {
    public let accessToken: String
    public let expiresIn: Int
    public var expired: Bool {
        let date = Date(timeIntervalSince1970: TimeInterval(expiresIn))
        print(expiresIn)
        print(date.timeIntervalSinceNow <= 0)
        return date.timeIntervalSinceNow <= 0
    }
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}
