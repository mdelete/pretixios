//
//  AppDelegate.swift
//  pretixios
//
//  Created by Marc Delling on 10.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = TabBarController()
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if UserDefaults.standard.bool(forKey: "reset_preference") == true {
            KeychainService.deletePassword(key: "pretix_api_token")
            UserDefaults.standard.removeObject(forKey: "pretix_api_base_url")
            UserDefaults.standard.removeObject(forKey: "pretix_event_slug")
            UserDefaults.standard.removeObject(forKey: "pretix_checkin_list")
            UserDefaults.standard.set(false, forKey: "reset_preference")
            UserDefaults.standard.set(false, forKey: "app_configured")
            UserDefaults.standard.synchronize()
            SyncManager.sharedInstance.deleteDatabase()
            print("Preferences resetted...")
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        //self.saveContext()
    }

}

