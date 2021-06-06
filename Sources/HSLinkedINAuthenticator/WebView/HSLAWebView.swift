//
//  HSLAWebView.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import UIKit
import WebKit
typealias HSLAWebResult = Result<LinkedINAuthTokenResponse, LinkedINAuthenticatorError>

class HSLAWebView: UIViewController {
    private var webView: WKWebView = WKWebView()
    var authenticatorRespose: ( (HSLAWebResult) -> Void)?
    private enum Constants: String {
        case authorizationEndPoint = "https://www.linkedin.com/uas/oauth2/authorization"
        case accessTokenEndPoint = "https://www.linkedin.com/uas/oauth2/accessToken"
    }
    private var result:HSLAWebResult? {
        didSet{
            guard let newValue = result else { return }
            
            switch newValue {
            case .success(let authresponse):
                let expiry = Date().addingTimeInterval(TimeInterval(authresponse.expiresIn)).timeIntervalSince1970
                let newToken = LinkedINAuthTokenResponse(accessToken: authresponse.accessToken, expiresIn: Int(expiry))
                savedAuthResponse = newToken
            default:
                break
            }
            authenticatorRespose?(newValue)
            DispatchQueue.main.async {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel", style: .plain, target: self, action: #selector(cancelLogin))
        webView.navigationDelegate = self
        webView.frame = self.view.frame
        self.view.addSubview(webView)
        startAuthorization()
    }
    
    private func startAuthorization() {
        let responseType = "code"
        guard let dataSource = LinkedINAuthenticator.sharedDataSource else {
            assert(false, "LinkedINAuthenticator.sharedDataSource needs to be set before trying to signin.")
            return
        }
        let appOAuthUrl = dataSource.appOAuthUrl
        let redirectURL = appOAuthUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let state = "linkedin_\(UUID.init().uuidString)"
        let scope = dataSource.scope.rawValue
        
        var authorizationURL = "\(Constants.authorizationEndPoint.rawValue)?"
        authorizationURL += "response_type=\(responseType)&"
        authorizationURL += "client_id=\(dataSource.clientId)&"
        authorizationURL += "redirect_uri=\(redirectURL)&"
        authorizationURL += "state=\(state)&"
        authorizationURL += "scope=\(scope)"
   
        let request = URLRequest(url: URL(string: authorizationURL)! )
        webView.load(request)
    }
    
     @objc private func cancelLogin(){
        self.result = .failure(.userCanceled(reason: "user manually cancelled the login"))
    }
    
    private func requestForAccessToken(authorizationCode: String) {
        let grantType = "authorization_code"
        guard let dataSource = LinkedINAuthenticator.sharedDataSource else {
            assert(false, "LinkedINAuthenticator.sharedDataSource needs to be set before trying to signin.")
            return
        }
        
        let redirectURL = dataSource.appOAuthUrl.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
        var postParams = "grant_type=\(grantType)&"
        postParams += "code=\(authorizationCode)&"
        postParams += "redirect_uri=\(redirectURL)&"
        postParams += "client_id=\(dataSource.clientId)&"
        postParams += "client_secret=\(dataSource.clientSecret)"
        
        let postData = postParams.data(using: .utf8)
        var request = URLRequest(url: URL(string: Constants.accessTokenEndPoint.rawValue)! )
        request.httpMethod = "POST"
        request.httpBody = postData
        request.addValue("application/x-www-form-urlencoded;", forHTTPHeaderField: "Content-Type")
        
        
        let accessTokenTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , let responseData = data else {
                self.result = .failure(.authenticationTokenUnableToReceive)
                return
            }
            if statusCode == 200 {
                do {
                    let authToken = try JSONDecoder().decode(LinkedINAuthTokenResponse.self, from: responseData)
                    self.result = .success(authToken)
                }catch {
                    self.result = .failure(.authenticationTokenDecodeFailed)
                }
            }else{
                self.result = .failure(.authenticationTokenUnableToReceive)
            }
        }
        accessTokenTask.resume()
    }
    
    
}
extension HSLAWebView :WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        guard let dataSource = LinkedINAuthenticator.sharedDataSource else {
            assert(false, "DataSource is required for the full functionality")
            return }
        guard let myAppHost = URL(string: dataSource.appOAuthUrl)?.host else {
            assert(false, "Terminating because host from url cannot be derived")
            return }
        
        if url.host == myAppHost {
            if let queries = url.queryDictionary {
                if let error = queries["error"], let errorDescription = queries["error_description"]{
                    self.result = .failure(.linkedINLoginError(domain: error, reason: errorDescription))
                }else if let code = queries["code"] {
                    requestForAccessToken(authorizationCode: code)
                }else{
                    self.result = .failure(.linkedINLoginError(domain: "UNKNOWN", reason: "neither code nor error was received"))
                }
            }
        }
        decisionHandler(.allow)
    }
}

fileprivate extension URL {
    var queryDictionary: [String: String]? {
        guard let query = self.query else { return nil}
        
        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {
            
            let key = pair.components(separatedBy: "=")[0]
            
            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""
            
            queryStrings[key] = value
        }
        return queryStrings
    }
}
