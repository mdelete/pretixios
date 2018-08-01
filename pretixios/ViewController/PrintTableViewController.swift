//
//  PrintTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 02.05.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class PrintTableViewController: UITableViewController, UIPrintInteractionControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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

    class Badge : UIPrintPaper {
        
        let ppmm : CGFloat = 2.835 // 72 ppi -> 2,835 ppmm
        
        var printSize = CGSize()
        var cutOnWidth = true
        
        override init() {
            super.init()
            printSize = CGSize(width: 10 * ppmm, height: 6.2 * ppmm) // default badge is 100mm wide and 62mm high
        }
        
        convenience init(mmSize: CGSize) {
            self.init()
            printSize = CGSize(width: mmSize.width * ppmm, height: mmSize.height * ppmm)
        }
        
        override var printableRect: CGRect {
            return CGRect(origin: CGPoint.zero, size: printSize)
        }
        
        func cut() -> CGFloat {
            return cutOnWidth ? printSize.width : printSize.height
        }
    }
    
    var savedPrinter : UIPrinter?
    let modelName = "Prof. Dr. Karl-Wilhelm-Ignatius von Weissviel zu Hirnknick"
    let modelCompany = "Bigdata Very Longname GmbH & Co. KGaA"
    let modelSpecial = "Speaker"
    
    func printBadgeAirPrint() {
        if let printer = savedPrinter {
            self.printBadgeWithPrinter(printer)
        } else {
            let printerPicker = UIPrinterPickerController(initiallySelectedPrinter: nil)
            if UIUserInterfaceIdiom.pad == UIDevice.current.userInterfaceIdiom {
                printerPicker.present(from: self.navigationItem.rightBarButtonItem!, animated: true) { (picker, userDidSelect, error) in
                    if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                        self.printBadgeWithPrinter(selectedPrinter)
                    }
                }
            } else {
                printerPicker.present(animated: true) { (picker, userDidSelect, error) in
                    if userDidSelect, let selectedPrinter = picker.selectedPrinter {
                        self.printBadgeWithPrinter(selectedPrinter)
                    }
                }
            }
        }
    }
    
    func printBadgeWithPrinter(_ printer: UIPrinter) {
        
        let pc = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        
        printInfo.jobName = "AirPrint"
        printInfo.orientation = .landscape
        printInfo.outputType = .general // .grayscale should be better for text only output
        if let printerID = UserDefaults.standard.string(forKey: "last_used_printer") {
            printInfo.printerID = printerID
        }
        pc.showsNumberOfCopies = false
        pc.printInfo = printInfo
        pc.delegate = self
        
        let attributeName = [ NSAttributedStringKey.font: UIFont(name: "Helvetica-Bold", size: 25.0)! ]
        let attributedStringName = NSMutableAttributedString(string: modelName, attributes: attributeName)
        
        let attributeOther = [ NSAttributedStringKey.font: UIFont(name: "Helvetica", size: 20.0)! ]
        let attributedStringCompany = NSAttributedString(string: "\n\n" + modelCompany, attributes: attributeOther)
        
        let attributedStringSpecial = NSAttributedString(string: "\n\n" + modelSpecial, attributes: attributeOther)
    
        attributedStringName.append(attributedStringCompany)
        attributedStringName.append(attributedStringSpecial)
        
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedStringName)
        formatter.textAlignment = .center
        pc.printFormatter = formatter
        
        pc.print(to: printer) { (printInteractionController, completed, error) in
            if !completed, let error = error {
                print("Print failed: \(error)")
                self.savedPrinter = nil
            } else {
                print("Printer used: \(pc.printInfo?.printerID ?? "unknown")")
                if self.savedPrinter != printer {
                    self.savedPrinter = printer
                    UserDefaults.standard.set(pc.printInfo?.printerID, forKey: "last_used_printer")
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    // MARK: - UIPrintInteractionControllerDelegate
    
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        return Badge()
    }
    
    func printInteractionController(_ printInteractionController: UIPrintInteractionController, cutLengthFor paper: UIPrintPaper) -> CGFloat {
        return Badge().cut()
    }
}
