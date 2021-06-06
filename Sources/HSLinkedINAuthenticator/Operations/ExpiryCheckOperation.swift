//
//  ExpiryCheckOperation.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import Foundation
import UIKit
let authTokenUserDefaultsKey = "LinkedINAuthenticator.authToken"
var savedAuthResponse: LinkedINAuthTokenResponse? {
    get{
        guard let data = UserDefaults.standard.data(forKey: authTokenUserDefaultsKey) else { return nil }
        do {
            let token = try JSONDecoder().decode(LinkedINAuthTokenResponse.self, from: data)
            return token
        }catch {
            return nil
        }
    }
    set{
        guard let encodable = newValue else {
            UserDefaults.standard.set(nil, forKey: authTokenUserDefaultsKey)
            return }
        guard let data = try? JSONEncoder().encode(encodable) else { return }
        UserDefaults.standard.set(data, forKey: authTokenUserDefaultsKey)
        UserDefaults.standard.synchronize()
    }
}
class CheckExpiryOfToken: LinkedINAuthOperation {
    var result: HSLAWebResult? {
        didSet{
            guard let newValue = result else { return }
            self.authenticatorRespose?(newValue)
        }
    }
    override func main() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        if let token = savedAuthResponse, !token.expired {
            result = .success(token)
            super.authenticatorRespose?(.success(token))
            self.finish()
        }else{
            let webLoginOperation = WebLoginOperation()
            webLoginOperation.authenticatorRespose = {[weak self] response in
                self?.result = response
                self?.finish()
            }
            OperationQueue().addOperation(webLoginOperation)
        }
    }
    override func finish() {
        super.finish()
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}
