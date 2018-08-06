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
        self.tableView.rowHeight = 44;
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
            return 3
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchTableViewCell
            cell.label.text = NSLocalizedString("Enable NFC", comment: "")
            return cell
            
        case(0, 1):
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! LabelTableViewCell
            cell.label.text = NSLocalizedString("Badge print", comment: "")
            return cell
        // FIXME: off, ble serial, airprint (if off, hide button in scanner)
        case(0, 2):
            let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as! LabelTableViewCell
            cell.label.text = NSLocalizedString("Checkin list", comment: "")
            return cell
        // FIXME: display name of list and display chooser
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
        //case 2:
        //    return NSLocalizedString("Additional Info", comment: "")
        default: return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(indexPath.section, indexPath.row) {
        case(0,1):
            let printTableViewController = PrintTableViewController()
            self.navigationController?.pushViewController(printTableViewController, animated: true)
        case(0,2):
            let checkinListTableViewController = CheckinListTableViewController()
            self.navigationController?.pushViewController(checkinListTableViewController, animated: true)
        default: ()
        }
    }
    
    // MARK : - ButtonCellDelegate
    
    func buttonTableViewCell(_ cell: ButtonTableViewCell, action: UIButton) {
        let context = LAContext()
        let localizedReasonString = NSLocalizedString("You are about to delete all pretix data on this device", comment: "")
        var authError: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString) { success, evaluateError in
                if success {
                    // User authenticated successfully, take appropriate action
                    KeychainService.deletePassword(key: "pretix_api_token")
                    UserDefaults.standard.removeObject(forKey: "pretix_api_base")
                    UserDefaults.standard.removeObject(forKey: "pretix_checkin_list")
                    UserDefaults.standard.set(false, forKey: "reset_preference")
                    UserDefaults.standard.set(false, forKey: "app_configured")
                    UserDefaults.standard.synchronize()
                    SyncManager.sharedInstance.deleteDatabase()
                } else {
                    // User did not authenticate successfully, look at error and take appropriate action
                    print("fail: \(evaluateError!)")
                }
            }
        } else {
            // Could not evaluate policy; look at authError and present an appropriate message to user
            print("error: \(authError!)")
        }
    }
    
}
