//
//  Postgres+String.swift
//  pretixios
//
//  Created by Marc Delling on 11.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation
import UIKit

public enum PrinterType : Int {
    case None
    case AirPrint
    case BLE
}

public extension String {
    
    func parsePSQLFractionedDate() -> Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ" // 2014-01-22T17:10:11.574
        
        // CONSIDER: since iOS11 ISO8601DateFormatter can do fractional seconds
        //let dateFormatter = ISO8601DateFormatter()
        //formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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

public extension Data {
    
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

public extension Date {
    
    func rfc1123String() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        
        return dateFormatter.string(from: self)
    }
    
    func iso8601String() -> String {
        let dateFormatter = ISO8601DateFormatter()
        //formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // since iOS11 ISO8601DateFormatter can do fractional seconds
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

public extension UIColor {
    
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

public extension Int {
    var nsNumber : NSNumber {
        return NSNumber(value: self)
    }
}

public extension UIDevice {
    var modelDescriptor: String {
#if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
#endif
        return identifier
    }
}

public extension URL {
    init?(optString: String?) {
        if let s = optString {
            self.init(string: s)
        } else {
            return nil
        }
    }
}
