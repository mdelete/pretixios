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
        
        let scanViewController = UINavigationController(rootViewController: QrScanViewController())
        scanViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Scan", comment: ""), image: UIImage(named: "Scan"), tag: TabBarIndex.Scanner.rawValue)
        
        let statusTableViewController = UINavigationController(rootViewController: SettingsViewController())
        statusTableViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("Settings", comment: ""), image: UIImage(named: "Status"), tag: TabBarIndex.Status.rawValue)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let listTableViewController = ListTableViewController()
            let detailTableViewController = DetailTableViewController()
            let splitViewController = UISplitViewController()
            
            listTableViewController.detailTableViewController = detailTableViewController
            
            detailTableViewController.navigationItem.leftItemsSupplementBackButton = true
            detailTableViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            
            splitViewController.viewControllers = [UINavigationController(rootViewController: listTableViewController),
                                                   UINavigationController(rootViewController: detailTableViewController)]
            splitViewController.delegate = detailTableViewController;
            splitViewController.preferredPrimaryColumnWidthFraction = 0.4;
            splitViewController.preferredDisplayMode = .allVisible
            
            splitViewController.extendedLayoutIncludesOpaqueBars = true
            splitViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("List", comment: ""), image: UIImage(named: "List"), tag: TabBarIndex.List.rawValue)
            viewControllers = [splitViewController, scanViewController, statusTableViewController]
        } else {
            let listTableViewController = UINavigationController(rootViewController: ListTableViewController())
            listTableViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("List", comment: ""), image: UIImage(named: "List"), tag: TabBarIndex.List.rawValue)
            viewControllers =  [listTableViewController, scanViewController, statusTableViewController]
        }
        
        selectedIndex = TabBarIndex.Scanner.rawValue
        tabBar.isTranslucent = false
    }
    
}
