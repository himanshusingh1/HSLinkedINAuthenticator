
//
//  LinkedINAuthenticator.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import Foundation
import UIKit
public enum LinkedINGrantScope: String, CaseIterable {
    case r_liteprofile = "r_liteprofile"
    case r_emailaddress = "r_emailaddress"
    case w_share = "w_share"
    case r_contactinfo = "r_contactinfo"
    case rw_company_admin = "rw_company_admin"
}
public protocol LinkedINAuthenticatorDataSource: AnyObject {
    var appOAuthUrl: String { get }
    var scope: LinkedINGrantScope { get }
    var clientId: String { get }
    var clientSecret: String { get }
    var viewControllerToPresentLogin: UIViewController { get }
}
extension LinkedINAuthenticatorDataSource {
    var scope: LinkedINGrantScope {
        return LinkedINGrantScope.r_liteprofile
    }
}
public typealias LinkedINAuthenticatorProfileResponse = Result<[String: Any], Error>
@objc public final class LinkedINAuthenticator : NSObject {
    static public var sharedDataSource: LinkedINAuthenticatorDataSource?
}
extension LinkedINAuthenticator {
    public func fetchLinkedINAccessToken(handler: ((Result<LinkedINAuthTokenResponse, LinkedINAuthenticatorError>) -> Void)? ){
        let workQueue = OperationQueue()
        let expiryOperation = CheckExpiryOfToken()
        expiryOperation.authenticatorRespose = { response in
            handler?(response)
        }
        workQueue.addOperation(expiryOperation)
    }
}
extension LinkedINAuthenticator {
    public func fetchLinkedINProfilePictureURL(handler: ((LinkedINAuthenticatorProfileResponse) -> Void)? ){
        let workQueue = OperationQueue()
        let expiryOperation = CheckExpiryOfToken()
        let getProfilePictureOperation = GetProfilePictureOperation(expiryOperation: expiryOperation)
        
        getProfilePictureOperation.response = { response in
            print(response)
            handler?(response)
        }
        workQueue.addOperation(expiryOperation)
        workQueue.addOperation(getProfilePictureOperation)
        
    }
}
extension LinkedINAuthenticator {
    public func fetchLinkedInData(handler: ((LinkedINAuthenticatorProfileResponse) -> Void)? ) {
        let workQueue = OperationQueue()
        let expiryOperation = CheckExpiryOfToken()
        let getProfile = GetProfileOperation(expiryOperation: expiryOperation)
        
        getProfile.response = { response in
            print(response)
            handler?(response)
        }
        workQueue.addOperation(expiryOperation)
        workQueue.addOperation(getProfile)
        
    }
}
