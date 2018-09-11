//
//  SLCSPrintFormatter.swift
//  pretixios
//
//  Created by Marc Delling on 28.08.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class SLCSPrintFormatter: NSObject {
    
    static let maxPrintLineLength = 20
    
    class func splitLongLines(_ longLine: String) -> [String] {
        if longLine.count >= (SLCSPrintFormatter.maxPrintLineLength * 2) {
            let lines = longLine.chunked(by: SLCSPrintFormatter.maxPrintLineLength)
            return Array(lines.prefix(2))
        } else {
            let start = longLine.startIndex
            let mid = longLine.index(start, offsetBy: 20)
            if let pos = longLine.range(of: " ", options: String.CompareOptions.backwards, range: start..<mid, locale: nil) {
                return [String(longLine[start..<pos.lowerBound]), String(longLine[pos.upperBound..<longLine.endIndex])]
            } else if let pos = longLine.range(of: "-", options: String.CompareOptions.backwards, range: start..<mid, locale: nil) {
                return [String(longLine[start...pos.lowerBound]), String(longLine[pos.upperBound..<longLine.endIndex])]
            } else {
                return [longLine]
            }
        }
    }
    
    class func buildUartPrinterData(lines: [String], auxiliary: String, auxIsBarcode: Bool = false) -> Data {
        
        // Printer setup commands
        let prnInitCmd        = "@\r\n"     // Set speed to 5 ips
        let prnSpeedCmd       = "SS3\r\n"   // Set speed to 5 ips
        let prnDensityCmd     = "SD20\r\n"  // Set density to 20
        let prnLabelWidthCmd  = "SW800\r\n" // Set label width to 800
        let prnOriCmd         = "SOT\r\n"   // Set printing direction from top to bottom
        let prnCharSet        = "CS2,6\r\n" // Set german charset (2) and Latin1+Euro code page (22)
        
        // Print command - this has to be the last command, on its own on a single line!
        let prnPrintCmd = "P1\r\n" // 1 = Print *one* label
        
        // Origin of the printer is the upper left corner
        let prnXpos        = 400  // P1: X position (center of the ticket)
        var prnYpos        = 50   // P2: Y position (initial)
        let prnFontSel     = "U"  // P3: Font Selection ("U" = ASCII, all other options are for asian character sets)
        let prnFontWidth   = 65   // P4: Font Width (dot)
        let prnFontHeight  = 65   // P5: Font Height (dot)
        let prnRCSpacing   = "+1" // P6: Right-side Character Spacing (dot), +/- can be used
        var prnBold        = "B"  // P7: Bold Printing: valid values are "N" (normal) and "B" (bold)
        let prnReverse     = "N"  // P8: Reverse Printing: valid values are "N" (normal) and "R" (reversed)
        let prnStyle       = "N"  // P9: Text Style: valid values are "N" (normal) and "I" (italic)
        let prnRotate      = 0    // P10: Rotation: valid values are 0-3 (0, 90, 180, 270 degrees)
        let prnAlignment   = "C"  // P11: Text Alignment: valid values are "L" (left), "R" (right) and "C" (center)
        let prnDirection   = 0    // P12: Text Direction: valid values are 0 (left to right) and 1 (right to left)
        
        // Assemble the printer configuration commands
        
        var printString = String(format: "%@%@%@%@%@%@", prnInitCmd, prnSpeedCmd, prnDensityCmd, prnLabelWidthCmd, prnOriCmd, prnCharSet)
        
        for (index, element) in lines.enumerated() {
            
            //print("Item \(index): \(element)")
            
            if index != 0 {
                prnBold = "N" // Print only first line in bold font
            }
            
            var currentLine = ""
            
            if (element.count >= SLCSPrintFormatter.maxPrintLineLength) {
                print("BLE PRINT $k length: \(element.count)")
                // FIXME: Add code to break up that line at white spaces of hyphens
                splitLongLines(element).forEach { line in
                    // Print parameters            1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,'data'
                    currentLine = String(format:"V%d,%d,%@,%d,%d,%@,%@,%@,%@,%d,%@,%d,'%@'\r\n",
                                         prnXpos, prnYpos, prnFontSel, prnFontWidth, prnFontHeight,
                                         prnRCSpacing, prnBold, prnReverse, prnStyle, prnRotate,
                                         prnAlignment, prnDirection, line)
                    prnYpos += prnFontHeight // Line feed
                    printString += currentLine
                }
                prnYpos += prnFontHeight // Line feed
                
            } else {
                // Print parameters          1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,'data'
                currentLine = String(format: "V%d,%d,%@,%d,%d,%@,%@,%@,%@,%d,%@,%d,'%@'\r\n",
                                     prnXpos, prnYpos, prnFontSel, prnFontWidth, prnFontHeight,
                                     prnRCSpacing, prnBold, prnReverse, prnStyle, prnRotate,
                                     prnAlignment, prnDirection, element)
                prnYpos += prnFontHeight * 2 // Line feed
                printString += currentLine
            }
            
        }
        
        // Add "Speaker" or Barcode
        if !auxIsBarcode {
            prnYpos = 420
            printString += String(format: "V%d,%d,%@,%d,%d,%@,%@,%@,%@,%d,%@,%d,'%@'\r\n",
                                  prnXpos, prnYpos, prnFontSel, prnFontWidth, prnFontHeight,
                                  prnRCSpacing, prnBold, prnReverse, prnStyle, prnRotate,
                                  prnAlignment, prnDirection, auxiliary)
        } else {
            prnYpos = 450
            
            let xPos = 200 // X Position of barcode
            let bcType = 0 // Barcode Type: 0-16
            let nbWidth = 2 // narrow Bar width
            let wbWidth = 6 // wide Bar width
            let bcHeight = 50 // Barcode height
            let bcRot = 0 // Barcode rotation: 0-3
            let hri = 0 // Human readable interpretation: 0-8
            let qzWidth = 0 // Quiet zone width: 0-20
            
            printString += String(format: "B1%d,%d,%d,%d,%d,%d,%d,%d,%d,'%@'\r\n",
                                  xPos, prnYpos, bcType, nbWidth, wbWidth, bcHeight, bcRot, hri, qzWidth, auxiliary)
        }
        
        printString += prnPrintCmd
        //print(printString)
        return printString.data(using: .ascii)!
    }
}

extension String {
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    func chunked(by chunkSize: Int) -> [String] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            String(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

