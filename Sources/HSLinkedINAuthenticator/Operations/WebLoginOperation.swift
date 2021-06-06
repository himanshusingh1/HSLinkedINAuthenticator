//
//  WebLoginOperation.swift
//  LinkedINAuthenticator
//
//  Created by Himanshu Singh on 05/06/21.
//

import Foundation
import UIKit
class WebLoginOperation: LinkedINAuthOperation {
    override func main() {
        DispatchQueue.main.async {
        let webView = HSLAWebView()
        webView.authenticatorRespose = { response in
            self.authenticatorRespose?(response)
            self.finish()
        }
        let navigationController = UINavigationController(rootViewController: webView)
        navigationController.modalPresentationStyle = .fullScreen
        LinkedINAuthenticator.sharedDataSource?.viewControllerToPresentLogin.present(navigationController, animated: true, completion: nil)
        }
    }
}
