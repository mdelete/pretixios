//
//  Postgres+String.swift
//  guests2
//
//  Created by Marc Delling on 11.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation
import UIKit

extension String {
    
    func parsePSQLFractionedDate() -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ" // 2014-01-22T17:10:11.574
        
        return dateFormatter.date(from: self)
    }
    
    func rfc1123Date() -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        
        return dateFormatter.date(from: self)
    }
    
    static func randomUUID() -> String {
        return UUID().uuidString.lowercased()
    }
    
}

extension Data {
    
    func sha256() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(self.count), &hash)
        }
        let hexBytes = hash.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
    
    func sha256Base64() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(self.count), &hash)
        }
        return Data(bytes: hash).base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
    }
    
}

extension Date {
    
    func rfc1123String() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        
        return dateFormatter.string(from: self)
    }
    
    func longTimeString() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "dd MMM yyyy HH':'mm':'ss z"
        
        return dateFormatter.string(from: self)
    }
    
    func shortTimeString() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "EEE' 'HH':'mm'"
        
        return dateFormatter.string(from: self)
    }
    
}

extension UIColor {
    
    public convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 24) & mask
        let g = Int(color >> 16) & mask
        let b = Int(color >> 8) & mask
        let a = Int(color) & mask
        
        let red    = CGFloat(r) / 255.0
        let green  = CGFloat(g) / 255.0
        let blue   = CGFloat(b) / 255.0
        let alpha  = CGFloat(a) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    
    static let scanResultUnknown = UIColor(hexString: "#dddddddd")
    static let scanResultOk = UIColor(hexString: "#5cb85cdd")
    static let scanResultWarn = UIColor(hexString: "#F0AD4Edd")
    static let scanResultErr = UIColor(hexString: "#D9534Fdd")
    static let scanResultAttention = UIColor(hexString: "#3B1C4Add")
    static let scanResultAttentionAlternate = UIColor(hexString: "#ffee58dd")

    static let lightBlue = UIColor(red: 0.169, green: 0.490, blue: 0.965, alpha: 1.0)
    
    static let pretixPurpleColor = UIColor(red: 59.0/255.0, green: 28.0/255.0, blue: 74.0/255.0, alpha: 1.0) //#3B1C4A
    static let pretixWhiteColor = UIColor.white
    static let pretixGreenColor = UIColor(red: 43.0/255.0, green: 74.0/255.0, blue: 28.0/255.0, alpha: 1.0) //#2B4A1C
    static let pretixYellowColor = UIColor(red: 238.0/255.0, green: 162.0/255.0, blue: 21.0/255.0, alpha: 1.0) //#EEA215 in sRGB
    
}

extension UIFont {

    static let defaultFontRegular = UIFont.systemFont(ofSize: 16.0, weight: .regular)
    static let defaultFontBold = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    static let largeFontRegular = UIFont.systemFont(ofSize: 24.0, weight: .regular)
    static let largeFontBold = UIFont.systemFont(ofSize: 24.0, weight: .bold)
}

extension CAShapeLayer {
    func drawCircleAtLocation(location: CGPoint, withSize size: CGSize, andColor color: UIColor, filled: Bool) {
        fillColor = filled ? color.cgColor : UIColor.white.cgColor
        strokeColor = color.cgColor
        let origin = CGPoint(x: location.x - size.height, y: location.y - size.height)
        path = UIBezierPath(roundedRect:  CGRect(origin: origin, size: CGSize(width: size.width, height: size.height * 2)), cornerRadius: size.height).cgPath
    }
}

private var handle: UInt8 = 0

extension UIBarButtonItem {
    private var badgeLayer: CAShapeLayer? {
        if let b: AnyObject = objc_getAssociatedObject(self, &handle) as AnyObject? {
            return b as? CAShapeLayer
        } else {
            return nil
        }
    }
    
    func addBadge(number: Int, withOffset offset: CGPoint = CGPoint.zero, andColor color: UIColor = UIColor.red, andFilled filled: Bool = true) {
        guard let view = self.value(forKey: "view") as? UIView else { return }
        
        badgeLayer?.removeFromSuperlayer()
        
        let fontSize: CGFloat = 11
        let string = NSString(format: "%d", number)
        let realStringWidth = string.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize)]).width
        let stringWidth = (realStringWidth < 10) ? 10 : realStringWidth

        // Initialize Badge
        let badge = CAShapeLayer()
        let size = CGSize(width: stringWidth + 7, height: 7)
        let location = CGPoint(x: view.frame.width - (size.height + offset.x), y: (size.height + offset.y))
        badge.drawCircleAtLocation(location: location, withSize: size, andColor: color, filled: filled)
        view.layer.addSublayer(badge)
        
        // Initialiaze Badge's label
        let label = CATextLayer()
        label.string = "\(number)"
        label.alignmentMode = kCAAlignmentCenter
        label.fontSize = fontSize
        label.frame = CGRect(origin: CGPoint(x: location.x - 4, y: offset.y), size: CGSize(width: stringWidth, height: 16))
        label.foregroundColor = filled ? UIColor.white.cgColor : color.cgColor
        label.backgroundColor = UIColor.clear.cgColor
        label.contentsScale = UIScreen.main.scale
        badge.addSublayer(label)
        
        // Save Badge as UIBarButtonItem property
        objc_setAssociatedObject(self, &handle, badge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func updateBadge(number: Int) {
        if let text = badgeLayer?.sublayers?.filter({ $0 is CATextLayer }).first as? CATextLayer {
            text.string = "\(number)"
        }
    }
    
    func removeBadge() {
        badgeLayer?.removeFromSuperlayer()
    }
}

extension Int {
    var nsNumber : NSNumber {
        return NSNumber(value: self)
    }
}
