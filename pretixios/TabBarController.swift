//
//  TabBarController.swift
//  pretixios
//
//  Created by Marc Delling on 22.01.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

enum TabBarIndex: NSInteger {
    case List
    case Scanner
    case Status
}

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let listTableViewController = UINavigationController(rootViewController: ListTableViewController())
        listTableViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("List", comment: ""), image: UIImage(named: "List"), tag: TabBarIndex.List.rawValue)
        
        let scanViewController = UINavigationController(rootViewController: QrScanViewController())
        scanViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Scan", comment: ""), image: UIImage(named: "Scan"), tag: TabBarIndex.Scanner.rawValue)
        
        let statusViewController = UINavigationController(rootViewController: SettingsViewController())
        statusViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Settings", comment: ""), image: UIImage(named: "Status"), tag: TabBarIndex.Status.rawValue)
        
        viewControllers =  [listTableViewController, scanViewController, statusViewController]
        selectedIndex = TabBarIndex.Scanner.rawValue
        tabBar.isTranslucent = false
    }
    
}
