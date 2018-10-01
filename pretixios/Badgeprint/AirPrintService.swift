//
//  AirPrintService.swift
//  pretixios
//
//  Created by Marc Delling on 01.10.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData

class AirPrintService: NSObject, UIPrintInteractionControllerDelegate {
    
    // MARK: - A standard badge
    
    class Badge: UIPrintPaper {
        
        private let size = CGSize(width: 283, height: 176) // 100mm x 62mm
        
        override var paperSize: CGSize {
            return size
        }
        
        override var printableRect: CGRect {
            return CGRect(origin: CGPoint(x: 0, y: 10), size: size)
        }
        
        var cut: CGFloat {
            return size.width
        }
    }
    
    func printTestBadgeWithPrinter(_ printer: UIPrinter, firstLine: String, secondLine: String) {
        
        let pc = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo.printInfo()
        
        printInfo.jobName = "Badge"
        printInfo.orientation = .landscape
        printInfo.outputType = .general
        
        pc.showsNumberOfCopies = false
        pc.printInfo = printInfo
        pc.delegate = self
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 15
        
        let attributeFirst = [ NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: 24.0)!, NSAttributedString.Key.paragraphStyle: paragraphStyle ]
        let attributeOther = [ NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 20.0)!, NSAttributedString.Key.paragraphStyle: paragraphStyle ]
        
        let attributedStringFirst = NSMutableAttributedString(string: firstLine, attributes: attributeFirst)
        let attributedStringSecond = NSAttributedString(string: "\n" + secondLine, attributes: attributeOther)
        let attributedStringTest = NSAttributedString(string: "\nTESTBADGE", attributes: attributeOther)
        
        attributedStringFirst.append(attributedStringSecond)
        attributedStringFirst.append(attributedStringTest)
        
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedStringFirst)
        formatter.textAlignment = .center
        
        pc.printFormatter = formatter
        pc.present(animated: true, completionHandler: nil)
    }
    
    func printBadgeWithConfiguredPrinter(firstLine: String, secondLine: String, thirdLine: String? = nil) {
        
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
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 15
        
        let attributeFirst = [ NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: 24.0)!, NSAttributedString.Key.paragraphStyle: paragraphStyle ]
        let attributeOther = [ NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 20.0)!, NSAttributedString.Key.paragraphStyle: paragraphStyle ]
        
        let attributedStringFirst = NSMutableAttributedString(string: firstLine, attributes: attributeFirst)
        let attributedStringSecond = NSAttributedString(string: "\n" + secondLine, attributes: attributeOther)
        
        attributedStringFirst.append(attributedStringSecond)
        
        if let third = thirdLine {
            let attributedStringSpecial = NSAttributedString(string: "\n" + third, attributes: attributeOther)
            attributedStringFirst.append(attributedStringSpecial)
        }
        
        let formatter = UISimpleTextPrintFormatter(attributedText: attributedStringFirst)
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
