//
//  AppDelegate.swift
//  Panic Attack
//
//  Created by Adrian Martushev on 5/18/24.
//

import Foundation
import UIKit
import CoreLocation
import Firebase
import FirebaseCore

let base_url = "https://panicattack-2e382c02613e.herokuapp.com"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var deviceToken = String()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        FirebaseApp.configure()
        
        // Check notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)

        
        return true
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    //Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        self.deviceToken = deviceTokenString
        saveDeviceTokenToFirestore(token: deviceTokenString)

        print("Device Token: " + self.deviceToken)
    }
    

    
    func saveDeviceTokenToFirestore(token: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        if !userID.isEmpty {
            
        }
        let usersRef = Firestore.firestore().collection("users")
        usersRef.document(userID).setData(["isPushOn" : true, "pushToken": token], merge: true)
    }
    
    

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
        print("Not available on simulator")
   }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }

}


