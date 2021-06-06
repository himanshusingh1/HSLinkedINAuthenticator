//
//  GetProfilePictureOperation.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 06/06/21.
//

import Foundation
class GetProfilePictureOperation : AsyncOperation {
    var response: ( (LinkedINAuthenticatorProfileResponse) -> Void )?
    let expiryCheck:CheckExpiryOfToken
    
    var apiCallTask: URLSessionDataTask?
    init(expiryOperation: CheckExpiryOfToken) {
        expiryCheck = expiryOperation
        super.init()
        self.addDependency(expiryCheck)
    }
    override func main() {
        guard let result = expiryCheck.result else {
            self.response?(.failure(NSError(domain: "API FAIL", code: 2, userInfo: nil)))
            self.finish()
            return
        }
        let accessToken: String
        switch result {
        case .success(let token):
            accessToken = token.accessToken
        case .failure(let error):
            self.response?(.failure(error))
            self.finish()
            return
        }
        
        
        let getMeApiUrl = URL(string: "https://api.linkedin.com/v2/me?projection=(id,profilePicture(displayImage~:playableStreams))&oauth2_access_token=" + accessToken )!
        apiCallTask = URLSession.shared.dataTask(with: getMeApiUrl) { data, response, error in
            
            if let responseError = error {
                self.response?(.failure(responseError))
                self.finish()
                return
            }
            
            guard let responseData = data else {
                self.response?(.failure(NSError(domain: "NO DATA", code: 1, userInfo: nil)))
                self.finish()
                return
            }
            guard let responseString = String(data: responseData, encoding: .utf8) else {
                self.response?(.failure(NSError(domain: "NO DATA", code: 2, userInfo: nil)))
                self.finish()
                return
            }
            guard let dictonary = convertToDictionary(text: responseString) else {
                self.response?(.failure(NSError(domain: "NO DATA", code: 3, userInfo: nil)))
                self.finish()
                return
            }
            self.response?(.success(dictonary))
            self.finish()
        }
        apiCallTask?.resume()
    }
    override func cancel() {
        apiCallTask?.cancel()
        self.cancel()
    }
}

