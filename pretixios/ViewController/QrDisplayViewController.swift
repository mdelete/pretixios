//
//  QRDisplayViewController.swift
//  pretixios
//
//  Created by Marc Delling on 20.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class CICode39 : CIFilter
{
    private let cp : [UInt8] = [0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,
                                0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x5A,
                                0x2D,0x2E,0x20,0x24,0x2F,0x2B,0x25]
    
    var inputMessage : Data?
    
    override var inputKeys: [String] {
        return ["inputMessage"]
    }
    
    override var outputImage: CIImage? {
        print("CICode39.outputImage")
        if var data = inputMessage {
            var checksum = 0
            data.forEach { (byte) in
                if let i = cp.index(of: byte) {
                    checksum += i
                } else {
                    checksum = -1
                    return
                }
            }
            if checksum == -1 {
                print("inputMessage: \(String(bytes: data, encoding: .utf8)!) is invalid")
            } else {
                data.append(cp[checksum % 43])
                print("inputMessage: \(String(bytes: data, encoding: .utf8)!) valid")
                // image width in pixels: data.count * 18 + 15 -> each symbol is 15 pixels wide with 3 pixels space between symbols
                // narrow stripe is 1 pixel, wide stripe is 3 pixels, each symbol is 9 stripes, stripes can be black or white/space
                // return image CIImage *input = [CIImage imageWithCGImage: CGImage]
            }
        }
        return nil
    }
}

class Badge {
    
    static func createQR(_ content: String?, scale: CGFloat = 9) -> CIImage? {
        if let data = content?.data(using: String.Encoding.isoLatin1) {
            let qrFilter = CIFilter(name: "CIQRCodeGenerator")
            qrFilter?.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            return qrFilter?.outputImage?.transformed(by: transform)
        }
        return nil
    }
    
    static func createCode128(_ content: String?, scale: CGFloat = 9) -> CIImage? {
        if let data = content?.data(using: String.Encoding.ascii) {
            let qrFilter = CIFilter(name: "CICode128BarcodeGenerator")
            qrFilter?.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            return qrFilter?.outputImage?.transformed(by: transform)
        }
        return nil
    }
    
}

class QrDisplayViewController: UIViewController {

    private let imageView = UIImageView(frame: .zero)
    
    var content : String?
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.white
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.imageView.contentMode = .center
        self.view.addSubview(self.imageView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let image = Badge.createQR(content) {
            self.imageView.image = UIImage(ciImage: image)
        }
    }

}
