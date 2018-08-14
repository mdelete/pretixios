//
//  PrintTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 02.05.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData

class PrintTableViewController: UITableViewController, UIPrintInteractionControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Testbadge", comment: ""),
                                                                 style: UIBarButtonItemStyle.done,
                                                                 target: self,
                                                                 action: #selector(printBadgeAirPrint))
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
    
    var maxName = ""
    var maxCompany = ""
    
    @objc func printBadgeAirPrint() {
       
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
        } else {
            print("Nothing found")
        }
        
        
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
        printInfo.outputType = .general // .grayscale should be better for text only output
        
        pc.showsNumberOfCopies = false
        pc.printInfo = printInfo
        pc.delegate = self
        
        let attributeName = [ NSAttributedStringKey.font: UIFont(name: "Helvetica-Bold", size: 24.0)! ]
        let attributeOther = [ NSAttributedStringKey.font: UIFont(name: "Helvetica", size: 20.0)! ]
        
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
