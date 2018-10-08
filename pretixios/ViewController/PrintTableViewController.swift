//
//  PrintTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 02.05.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData
import CoreBluetooth

class PrintTableViewController: UITableViewController, BLEManagerDelegate {
    
    var selectedSetting : Int = 0
    var selectedPeripheral : CBPeripheral?
    var discoveredPeripherals = [CBPeripheral]()
    
    private let airPrintService = AirPrintService()
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Testbadge", comment: ""),
                                                                 style: UIBarButtonItem.Style.done,
                                                                 target: self,
                                                                 action: #selector(printTestBadge))
        BLEManager.sharedInstance.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedSetting = UserDefaults.standard.integer(forKey: "printer_type")
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section) {
        case 0:
            return NSLocalizedString("Printing method", comment: "")
        default: return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            return discoveredPeripherals.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = NSLocalizedString("None", comment: "")
                cell.textLabel?.textColor = UIColor.black
            case 1:
                cell.textLabel?.text = NSLocalizedString("AirPrint", comment: "AirPrint is a brand name")
                cell.textLabel?.textColor = UIColor.black
            case 2:
                cell.textLabel?.text = NSLocalizedString("Bluetooth Serial", comment: "")
                cell.textLabel?.textColor = UIColor.black
            default: ()
            }
            if selectedSetting == indexPath.row {
                cell.accessoryType = .checkmark
                cell.selectionStyle = .none
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        } else {
            let peripheral = discoveredPeripherals[indexPath.row]
            cell.textLabel?.text = peripheral.name
            
            if peripheral.name == selectedPeripheral?.name {
                cell.accessoryType = .checkmark
                cell.selectionStyle = .none
            } else {
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            selectedSetting = indexPath.row
            UserDefaults.standard.set(selectedSetting, forKey: "printer_type")
            UserDefaults.standard.synchronize()
            
            if indexPath.row == 2 {
                BLEManager.sharedInstance.scan()
            }
        } else {
            selectedPeripheral = discoveredPeripherals[indexPath.row]
            if let peripheral = selectedPeripheral {
                BLEManager.sharedInstance.connect(peripheral: peripheral)
            }
        }
        self.tableView.reloadData()
    }
    
    // MARK: - BLEManagerDelegate
    
    func didStartScanning(_ manager: BLEManager) {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView(style: .gray)
            spinner.startAnimating()
            self.tableView.tableFooterView = spinner
        }
    }
    
    func didStopScanning(_ manager: BLEManager) {
        DispatchQueue.main.async {
            print("didStopScanning")
            let spinner = self.tableView.tableFooterView as? UIActivityIndicatorView
            spinner?.stopAnimating()
            self.tableView.tableFooterView = nil
        }
    }
    
    func didDiscover(_ manager: BLEManager, peripheral: CBPeripheral) {
        if let _ = discoveredPeripherals.index(of: peripheral) {
            // nix
        } else {
            discoveredPeripherals.append(peripheral)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func didConnect(_ manager: BLEManager, peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            print("didConnect")
            self.selectedPeripheral = peripheral
            self.tableView.reloadData()
        }
    }
    
    func didDisconnect(_ manager: BLEManager) {
        DispatchQueue.main.async {
            self.selectedPeripheral = nil
            self.tableView.reloadData()
        }
    }
    
    func didReceive(_ manager: BLEManager, message: String?) {
        print("didReceive")
    }
    
    // MARK: - CoreData Helper
    
    func maxBadge() -> (String, String) {
        var maxName = ""
        var maxCompany = ""
        
        let fetchRequest : NSFetchRequest<Order> = Order.fetchRequest()
        
        if let results = try? SyncManager.sharedInstance.backgroundContext.fetch(fetchRequest) {
            results.forEach { (order) in
                if let n = order.attendee_name, n.count > maxName.count {
                    maxName = n
                }
                if let c = order.company, c.count > maxCompany.count {
                    maxCompany = c
                }
            }
        }
        
        return (maxName, maxCompany)
    }
    
    // MARK: - Print action
    
    @objc func printTestBadge() {
        
        let (maxName, maxCompany) = maxBadge()
        
        switch selectedSetting {
        case 1:
            let printerPicker = UIPrinterPickerController(initiallySelectedPrinter: nil)
            if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom {
                printerPicker.present(from: self.navigationItem.rightBarButtonItem!, animated: true) { (picker, userDidSelect, error) in
                    if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                        self.airPrintService.printTestBadgeWithPrinter(selectedPrinter, firstLine: maxName, secondLine: maxCompany)
                        print("printer url: \(selectedPrinter.url)")
                        UserDefaults.standard.set(selectedPrinter.url, forKey: "last_used_printer")
                        UserDefaults.standard.synchronize()
                    }
                }
            } else {
                printerPicker.present(animated: true) { (picker, userDidSelect, error) in
                    if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                        self.airPrintService.printTestBadgeWithPrinter(selectedPrinter, firstLine: maxName, secondLine: maxCompany)
                        print("printer url: \(selectedPrinter.url)")
                        UserDefaults.standard.set(selectedPrinter.url, forKey: "last_used_printer")
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        case 2:
            let data = SLCSPrintFormatter.buildUartPrinterData(lines: [maxName, maxCompany], auxiliary: "TESTBADGE")
            BLEManager.sharedInstance.write(data: data)
        default:
            ()
        }
    }
}
