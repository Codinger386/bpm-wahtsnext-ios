//
//  AppDelegate.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 14.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if UserDefaults.standard.bool(forKey: "subscribedToChanges") == false {
            TrackDatabase.shared.subscribeToChanges()
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("Error: \(error)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        debugPrint("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        debugPrint("Received remote notification")
        
        let dict = userInfo as! [String: NSObject]
        let notification = CKNotification(fromRemoteNotificationDictionary: dict)!
        if (notification.subscriptionID == "track-changes") {
            TrackDatabase.shared.fetchSharedChanges {
                completionHandler(UIBackgroundFetchResult.newData)
            }
        }
    }
}

