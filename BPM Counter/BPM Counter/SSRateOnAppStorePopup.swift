//
//  SSRateOnAppStorePopup.swift
//  SwiftShizzle
//
//  Created by Benjamin Ludwig on 18.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import StoreKit

let SSRateOnAppStorePopupUseCountIdentifier = "SSRateOnAppStorePopupUseCountIdentifier"
let SSRateOnAppStorePopupDontShowAgainIdentifier = "SSRateOnAppStorePopupDontShowAgainIdentifier"
let SSRateOnAppStorePopupAlreadyRatedIdentifier = "SSRateOnAppStorePopupAlreadyRatedIdentifier"

public class SSRateOnAppStorePopup: NSObject, SKStoreProductViewControllerDelegate {
    
    private var viewController: UIViewController!
    
    public class var shared: SSRateOnAppStorePopup {
        struct Singleton {
            static let instance = SSRateOnAppStorePopup()
        }
        return Singleton.instance
    }
    
    func present(fromViewController viewController: UIViewController) {
        
        self.viewController = viewController
        
        if UserDefaults.standard.bool(forKey: SSRateOnAppStorePopupDontShowAgainIdentifier) || UserDefaults.standard.bool(forKey: SSRateOnAppStorePopupAlreadyRatedIdentifier) {
            return
        }
        
        let usageCount = UserDefaults.standard.integer(forKey: SSRateOnAppStorePopupUseCountIdentifier)
        debugPrint("usageCount: \(usageCount)")
        if usageCount >= 6 {
            UserDefaults.standard.set(0, forKey: SSRateOnAppStorePopupUseCountIdentifier)
            UserDefaults.standard.synchronize()
        } else {
            let newCount = usageCount + 1
            UserDefaults.standard.set(newCount, forKey: SSRateOnAppStorePopupUseCountIdentifier)
            if !UserDefaults.standard.synchronize() {
                debugPrint("Cloudn't sync UserDefaults")
            }
            return
        }
    
    
        let alert = UIAlertController(title: "Please rate this app", message: "If you like this app, please rate it on the App Store.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Take me to the store", style: .default) { action in
            
            self.openStoreProductWithiTunesItemIdentifier(identifier: "1195925283")
            
            UserDefaults.standard.set(true, forKey: SSRateOnAppStorePopupAlreadyRatedIdentifier)
            UserDefaults.standard.synchronize()
        }
        alert.addAction(okAction)
        
        let laterAction = UIAlertAction(title: "Maybe later", style: .default) { action in
            
        }
        alert.addAction(laterAction)
        
        let neverAction = UIAlertAction(title: "Never ask me again", style: .default) { action in
            UserDefaults.standard.set(true, forKey: SSRateOnAppStorePopupDontShowAgainIdentifier)
            UserDefaults.standard.synchronize()
        }
        alert.addAction(neverAction)
        
        viewController.present(alert, animated: true, completion: nil)
        
    }
    
    func openStoreProductWithiTunesItemIdentifier(identifier: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        let parameters = [ SKStoreProductParameterITunesItemIdentifier : identifier]
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) -> Void in
            if loaded {
                // Parent class of self is UIViewContorller
                self?.viewController.present(storeViewController, animated: true, completion: nil)
            }
        }
    }
    
    
    //MARK: - SKStoreProductViewControllerDelegate
    
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
}
