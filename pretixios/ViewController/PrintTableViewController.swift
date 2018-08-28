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

class PrintTableViewController: UITableViewController, UIPrintInteractionControllerDelegate, BLEManagerDelegate {
    
    var selectedSetting : Int = 1
    var selectedPeripheral : CBPeripheral?
    var discoveredPeripherals = [CBPeripheral]()
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Testbadge", comment: ""),
                                                                 style: UIBarButtonItemStyle.done,
                                                                 target: self,
                                                                 action: #selector(printBadgeAirPrint))
        BLEManager.sharedInstance.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // read printer setting
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
            return 4
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
                cell.textLabel?.textColor = UIColor.gray
            case 1:
                cell.textLabel?.text = NSLocalizedString("AirPrint", comment: "AirPrint is a brand name")
            case 2:
                cell.textLabel?.text = NSLocalizedString("MQTT", comment: "")
                cell.textLabel?.textColor = UIColor.gray
            case 3:
                cell.textLabel?.text = NSLocalizedString("Bluetooth Serial", comment: "")
                //cell.textLabel?.textColor = UIColor.gray
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
            if indexPath.row == 3 {
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
    
    // MARK: - BLEManagerDelegate
    
    func didStartScanning(_ manager: BLEManager) {
        DispatchQueue.main.async {
            let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
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
        // nix
    }
    
    // MARK: - BLE Print
    
    @objc func printBadgeBLE() {
        let (maxName, maxCompany) = maxBadge()
        let data = SLCSPrintFormatter.buildUartPrinterData(lines: [maxName, maxCompany], barcode: "DONOTTRACK", speaker: false)
        BLEManager.sharedInstance.write(data: data)
    }
    
    // MARK: - AirPrint

    class Badge: UIPrintPaper {
        
        private let size = CGSize(width: 283, height: 176) // 100mm x 62mm
        
        override var paperSize: CGSize {
            return size
        }
        
        override var printableRect: CGRect {
            return CGRect(origin: CGPoint(x: 0, y: 6), size: size)
        }
        
        var cut: CGFloat {
            return size.width
        }
    }
    
    @objc func printBadgeAirPrint() {
        let printerPicker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom {
            printerPicker.present(from: self.navigationItem.rightBarButtonItem!, animated: true) { (picker, userDidSelect, error) in
                if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                    self.printBadgeWithPrinter(selectedPrinter)
                    print("printer url: \(selectedPrinter.url)")
                    UserDefaults.standard.set(selectedPrinter.url, forKey: "last_used_printer")
                    UserDefaults.standard.synchronize()
                }
            }
        } else {
            printerPicker.present(animated: true) { (picker, userDidSelect, error) in
                if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                    self.printBadgeWithPrinter(selectedPrinter)
                    print("printer url: \(selectedPrinter.url)")
                    UserDefaults.standard.set(selectedPrinter.url, forKey: "last_used_printer")
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    func printBadgeWithPrinter(_ printer: UIPrinter) {
        
        let pc = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        
        printInfo.jobName = "Badge"
        printInfo.orientation = .landscape
        printInfo.outputType = .general
        
        pc.showsNumberOfCopies = false
        pc.printInfo = printInfo
        pc.delegate = self
        
        let attributeName = [ NSAttributedStringKey.font: UIFont(name: "Helvetica-Bold", size: 24.0)! ]
        let attributeOther = [ NSAttributedStringKey.font: UIFont(name: "Helvetica", size: 20.0)! ]
        
        let (maxName, maxCompany) = maxBadge()
        
        let attributedStringName = NSMutableAttributedString(string: maxName, attributes: attributeName)
        let attributedStringCompany = NSAttributedString(string: "\n\n" + maxCompany, attributes: attributeOther)
        // FIXME: print barcode
        //let attributedStringSpecial = NSAttributedString(string: "\n\n" + maxSpecial, attributes: attributeOther)
        
        attributedStringName.append(attributedStringCompany)
        //attributedStringName.append(attributedStringSpecial)
        
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedStringName)
        formatter.textAlignment = .center
        
        pc.printFormatter = formatter
        pc.present(animated: true, completionHandler: nil)
    }
    
    func printBadgeWithConfiguredPrinter(first: String, second: String, third: String? = nil) {
        
        guard let printerURL = UserDefaults.standard.url(forKey: "last_used_printer") else {
            print("No last used printer")
            return
        }
        
        let p = UIPrinter(url: printerURL)
        let pc = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        
        //printInfo.printerID = printerID
        printInfo.jobName = "Badge"
        printInfo.orientation = .landscape
        printInfo.outputType = .general // .grayscale should be better for text only output
        
        pc.showsNumberOfCopies = false
        pc.printInfo = printInfo
        pc.delegate = self
        
        let attributeName = [ NSAttributedStringKey.font: UIFont(name: "Helvetica-Bold", size: 24.0)! ]
        let attributeOther = [ NSAttributedStringKey.font: UIFont(name: "Helvetica", size: 20.0)! ]
        
        let attributedStringName = NSMutableAttributedString(string: first, attributes: attributeName)
        let attributedStringCompany = NSAttributedString(string: "\n\n" + second, attributes: attributeOther)
        
        attributedStringName.append(attributedStringCompany)
        
        if let third = third {
            let attributedStringSpecial = NSAttributedString(string: "\n\n" + third, attributes: attributeOther)
            attributedStringName.append(attributedStringSpecial)
        }
        
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedStringName)
        formatter.textAlignment = .center
        pc.printFormatter = formatter
        pc.print(to: p) { (printInteractionController, completed, error) in
            if !completed, let error = error {
                print("Print failed: \(error)")
                UserDefaults.standard.removeObject(forKey: "last_used_printer")
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    // MARK: - UIPrintInteractionControllerDelegate
    
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        return Badge()
    }
    
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, cutLengthFor paper: UIPrintPaper) -> CGFloat {
        return Badge().cut
    }
}
