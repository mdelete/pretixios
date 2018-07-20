//
//  QRDisplayViewController.swift
//  pretixios
//
//  Created by Marc Delling on 20.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class QrDisplayViewController: UIViewController {

    private let imageView = UIImageView(frame: .zero)
    
    var scale = CGFloat(9)
    var qrdata : Data?
    var qrstring : String? {
        get {
            if let data = qrdata {
                return String(bytes: data, encoding: .utf8)
            } else {
                return nil
            }
        }
        set {
            qrdata = newValue?.data(using: String.Encoding.ascii)
        }
    }
    
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
        if let image = createQR(qrdata) {
            self.imageView.image = UIImage(ciImage: image)
        }
    }
    
    private func createQR(_ data: Data?) -> CIImage? {
        if let data = data {
            let qrFilter = CIFilter(name: "CIQRCodeGenerator")
            qrFilter?.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            return qrFilter?.outputImage?.transformed(by: transform)
        }
        return nil
    }

}
