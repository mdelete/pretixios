//
//  StatusViewController.swift
//  pretixios
//
//  Created by Marc Delling on 06.04.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import LocalAuthentication

class SettingsViewController: UITableViewController, ButtonCellDelegate {

    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Settings", comment: "")
        self.tableView.estimatedRowHeight = 44.5
        self.tableView.register(LabelTableViewCell.self, forCellReuseIdentifier: "labelCell")
        self.tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: "buttonCell")
        self.tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "switchCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch(indexPath.section, indexPath.row) {
        case(0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! LabelTableViewCell
            cell.label.text = NSLocalizedString("Badge print", comment: "")
            cell.valueLabel.text = NSLocalizedString("AirPrint", comment: "AirPrint is a brand name")
            return cell
        case(0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! LabelTableViewCell
            cell.label.text = NSLocalizedString("Event", comment: "")
            return cell
        case(1, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as! ButtonTableViewCell
            cell.title = NSLocalizedString("Delete configuration & data", comment: "")
            cell.delegate = self
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case 0:
            return NSLocalizedString("Settings", comment: "")
        case 1:
            return NSLocalizedString("Reset Configuration", comment: "")
        default: return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.section, indexPath.row) {
        case(0,0):
            let printTableViewController = PrintTableViewController()
            self.navigationController?.pushViewController(printTableViewController, animated: true)
        case(0,1):
            let eventListTableViewController = EventListTableViewController()
            self.navigationController?.pushViewController(eventListTableViewController, animated: true)
        default: ()
        }
    }
    
    // MARK : - ButtonCellDelegate
    
    func buttonTableViewCell(_ cell: ButtonTableViewCell, action: UIButton) {
        
        let alert = UIAlertController(title: NSLocalizedString("Reset Configuration", comment: ""), message: NSLocalizedString("You are about to delete all pretix data on this device", comment: ""), preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { _ in
            KeychainService.deletePassword(key: "pretix_api_token")
            UserDefaults.standard.removeObject(forKey: "pretix_api_base_url")
            UserDefaults.standard.removeObject(forKey: "pretix_event_slug")
            UserDefaults.standard.removeObject(forKey: "pretix_checkin_list")
            UserDefaults.standard.set(false, forKey: "reset_preference")
            UserDefaults.standard.set(false, forKey: "app_configured")
            UserDefaults.standard.synchronize()
            SyncManager.sharedInstance.deleteDatabase()
        })
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in
            print("Cancelled")
        })
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}
