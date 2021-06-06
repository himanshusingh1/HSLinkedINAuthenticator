//
//  Errors.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import Foundation
public enum LinkedINAuthenticatorError: Error {
    case authenticationTokenDecodeFailed
    case authenticationTokenUnableToReceive
    case userCanceled(reason: String)
    case linkedINLoginError(domain: String, reason: String)
}
