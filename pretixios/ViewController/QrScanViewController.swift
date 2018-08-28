//
//  QrScanViewController.swift
//  pretixios
//
//  Created by Marc Delling on 03.04.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

protocol QrScanResultProtocolDelegate: AnyObject {
    func didScan(controller: QrScanViewController, result: String)
}

class AttentionView : UIView {
    
    let attentionLabel = UILabel()
    
    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        attentionLabel.numberOfLines = 0
        attentionLabel.textAlignment = .center
        attentionLabel.font = .preferredFont(forTextStyle: .headline)
        attentionLabel.adjustsFontForContentSizeCategory = true
        attentionLabel.textColor = .pretixWhiteColor
        attentionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(attentionLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            attentionLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            attentionLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            attentionLabel.topAnchor.constraint(equalTo: self.topAnchor),
            attentionLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

class InfoView: UIView {
    
    let resultLabel = UILabel()
    let ticketTypeLabel = UILabel()
    let orderCodeLabel = UILabel()
    let nameLabel = UILabel()
    let printButton = UIButton(type: UIButtonType.roundedRect)
    
    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .scanResultUnknown
        
        resultLabel.text = NSLocalizedString("Please scan a ticket", comment: "")
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        resultLabel.font = .preferredFont(forTextStyle: .title1)
        resultLabel.adjustsFontForContentSizeCategory = true
        resultLabel.textColor = .black
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        ticketTypeLabel.numberOfLines = 1
        ticketTypeLabel.textAlignment = .left
        ticketTypeLabel.font = .preferredFont(forTextStyle: .body)
        ticketTypeLabel.adjustsFontForContentSizeCategory = true
        ticketTypeLabel.textColor = .black
        ticketTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        orderCodeLabel.numberOfLines = 1
        orderCodeLabel.textAlignment = .left
        orderCodeLabel.font = .preferredFont(forTextStyle: .body)
        orderCodeLabel.adjustsFontForContentSizeCategory = true
        orderCodeLabel.textColor = .black
        orderCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.numberOfLines = 1
        nameLabel.textAlignment = .right
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        printButton.setTitle(NSLocalizedString("Print Badge", comment: ""), for: UIControlState.normal)
        printButton.translatesAutoresizingMaskIntoConstraints = false
        printButton.isHidden = true
        
        self.addSubview(resultLabel)
        self.addSubview(ticketTypeLabel)
        self.addSubview(orderCodeLabel)
        self.addSubview(nameLabel)
        self.addSubview(printButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            resultLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            resultLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            
            ticketTypeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            ticketTypeLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 8),
            ticketTypeLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            
            printButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            printButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            printButton.widthAnchor.constraint(equalToConstant: 100),
            printButton.heightAnchor.constraint(equalToConstant: 50),
            
            orderCodeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            orderCodeLabel.topAnchor.constraint(equalTo: ticketTypeLabel.bottomAnchor, constant: 6),
            
            nameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: orderCodeLabel.bottomAnchor, constant: 6)
        ])
    }
    
    public func setInfoView(order: Order?, result: PretixRedeemResponse?) {
        if let order = order, result?.reason == .already_redeemed {
            OperationQueue.main.addOperation {
                
                self.nameLabel.text = order.attendee_name
                self.orderCodeLabel.text = order.order
                self.ticketTypeLabel.text = order.item_name ?? "\(order.item)"
                self.printButton.isHidden = true // FIXME: enable when printing is implemented
                self.resultLabel.text = NSLocalizedString("Already redeemed", comment: "")
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = .pretixYellowColor
                    self.nameLabel.textColor = .black
                    self.orderCodeLabel.textColor = .black
                    self.ticketTypeLabel.textColor = .black
                    self.resultLabel.textColor = .black
                })
            }
        } else if let order = order, result?.status == .ok {
            OperationQueue.main.addOperation {
                
                self.nameLabel.text = order.attendee_name
                self.orderCodeLabel.text = order.order
                self.ticketTypeLabel.text = order.item_name ?? "\(order.item)"
                self.printButton.isHidden = true // FIXME: enable when printing is implemented
                self.resultLabel.text = NSLocalizedString("Valid Ticket", comment: "")
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = .pretixGreenColor
                    self.nameLabel.textColor = .pretixWhiteColor
                    self.orderCodeLabel.textColor = .pretixWhiteColor
                    self.ticketTypeLabel.textColor = .pretixWhiteColor
                    self.resultLabel.textColor = .pretixWhiteColor
                })
            }
        } else {
            OperationQueue.main.addOperation {
                
                self.nameLabel.text = nil
                self.orderCodeLabel.text = nil
                self.ticketTypeLabel.text = nil
                self.printButton.isHidden = true
                self.resultLabel.text = NSLocalizedString("Invalid Ticket", comment: "")
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = .pretixYellowColor
                    self.nameLabel.textColor = UIColor.black
                    self.orderCodeLabel.textColor = UIColor.black
                    self.ticketTypeLabel.textColor = UIColor.black
                    self.resultLabel.textColor = UIColor.black
                })
            }
        }
    }
    
    public func setConfigurationView(result: Bool) {
        if result {
            OperationQueue.main.addOperation {
                
                self.nameLabel.text = nil
                self.orderCodeLabel.text = nil
                self.ticketTypeLabel.text = nil
                self.printButton.isHidden = true
                self.resultLabel.text = NSLocalizedString("Configuration successful. You can now scan Tickets.", comment: "")
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = .pretixPurpleColor
                    self.resultLabel.textColor = .white
                })
            }
        } else {
            OperationQueue.main.addOperation {
                
                self.nameLabel.text = nil
                self.orderCodeLabel.text = nil
                self.ticketTypeLabel.text = nil
                self.printButton.isHidden = true
                self.resultLabel.text = NSLocalizedString("Invalid configuration code", comment: "")
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.backgroundColor = .pretixPurpleColor
                    self.resultLabel.textColor = .white
                })
            }
        }
    }
    
    public func resetInfoView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.nameLabel.text = nil
            self.orderCodeLabel.text = nil
            self.ticketTypeLabel.text = nil
            self.printButton.isHidden = true
            self.resultLabel.text = NSLocalizedString("Please scan a ticket", comment: "")
            self.backgroundColor = .pretixPurpleColor
            self.nameLabel.textColor = .pretixWhiteColor
            self.orderCodeLabel.textColor = .pretixWhiteColor
            self.ticketTypeLabel.textColor = .pretixWhiteColor
            self.resultLabel.textColor = .pretixWhiteColor
        })
    }
    
    public func resetConfigurationView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.nameLabel.text = nil
            self.orderCodeLabel.text = nil
            self.ticketTypeLabel.text = nil
            self.printButton.isHidden = true
            self.resultLabel.text = NSLocalizedString("Please scan a configuration code", comment: "")
            self.backgroundColor = .pretixPurpleColor
            self.resultLabel.textColor = .pretixWhiteColor
        })
    }
}

class QrScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let captureSession = AVCaptureSession()
    
    let laserView = UIView()
    let infoView = InfoView()
    let attentionView = AttentionView()
    let scannerView = UIView()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var currentOrder : Order?

    weak var delegate: QrScanResultProtocolDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Pretix"
        view.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(startRunning), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRunning), name: .UIApplicationWillResignActive, object: nil)
        
        //videoCaptureDevice?.addObserver(self, forKeyPath: "adjustingFocus", options: .new, context: nil)
        //videoCaptureDevice?.removeObserver(self, forKeyPath: "adjustingFocus")
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // info view
        infoView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(infoView)

        // camera preview
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        scannerView.backgroundColor = .black
        containerView.addSubview(scannerView)

        // laser view
        laserView.translatesAutoresizingMaskIntoConstraints = false
        laserView.backgroundColor = .red
        scannerView.addSubview(laserView)
        
        // attention view
        attentionView.translatesAutoresizingMaskIntoConstraints = false
        attentionView.backgroundColor = .yellow
        attentionView.alpha = 0.8
        attentionView.isHidden = true
        containerView.addSubview(attentionView)
        
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: containerView.topAnchor),
            infoView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            infoView.heightAnchor.constraint(equalToConstant: 140.0),
            infoView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            attentionView.topAnchor.constraint(equalTo: infoView.bottomAnchor),
            attentionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            attentionView.heightAnchor.constraint(equalToConstant: 30.0),
            attentionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            scannerView.topAnchor.constraint(equalTo: infoView.bottomAnchor),
            scannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            laserView.centerXAnchor.constraint(equalTo: scannerView.centerXAnchor),
            laserView.centerYAnchor.constraint(equalTo: scannerView.centerYAnchor),
            laserView.widthAnchor.constraint(equalTo: scannerView.widthAnchor, multiplier: 0.85),
            laserView.heightAnchor.constraint(equalToConstant: 2.0)
        ])
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }
        
        infoView.printButton.addTarget(self, action: #selector(printBadge), for: .touchUpInside)
    }
    
    internal func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer?.frame = self.view.bounds
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let previewLayerConnection = self.previewLayer?.connection as AVCaptureConnection? {
            let orientation: UIDeviceOrientation = UIDevice.current.orientation
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break

                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break

                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break

                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break

                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: "app_configured") == true {
            self.infoView.resetInfoView()
        } else {
            self.infoView.resetConfigurationView()
        }
        checkCaptureSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.1, delay: 0.2, options:[.repeat, .autoreverse], animations: {
            self.laserView.backgroundColor = .red
            self.laserView.backgroundColor = .orange
        }, completion:nil)
        startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopRunning()
        laserView.layer.removeAllAnimations()
        super.viewWillDisappear(animated)
    }

    // MARK: - KeyValueCoding

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "adjustingFocus" {
            if let adjustingFocus = change?[NSKeyValueChangeKey.newKey] as? NSNumber, adjustingFocus.isEqual(to: NSNumber(value: 1)) {
                print("adjustingFocus")
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func startRunning() {
        if !captureSession.isRunning {
            //DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            //}
        }
    }

    @objc private func stopRunning() {
        if captureSession.isRunning {
            //DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            //}
        }
    }
    
    @objc private func printBadge() {
        if let order = self.currentOrder, let name = order.attendee_name, let company = order.company {
            let data = SLCSPrintFormatter.buildUartPrinterData(lines: [name, company], barcode: order.pseudonymization_id, speaker: order.checkin_attention)
            BLEManager.sharedInstance.write(data: data)
        }
    }
    
    // MARK: - Alerts
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showAttentionView(comment: String? = nil) {
        self.attentionView.isHidden = false
        if let comment = comment {
             self.attentionView.attentionLabel.text = comment
        } else {
            self.attentionView.attentionLabel.text = NSLocalizedString("Special Ticket", comment: "")
        }
        UIView.animate(withDuration: 0.2, delay: 0, options:[.repeat, .autoreverse], animations: {
            self.attentionView.backgroundColor = UIColor.scanResultAttention
            self.attentionView.backgroundColor = UIColor.scanResultAttentionAlternate
        }, completion:nil )
    }
    
    private func hideAttentionView() {
        self.attentionView.layer.removeAllAnimations()
        self.attentionView.isHidden = true
    }
    
    // MARK: - Setup
    
    private func setupCaptureSession() {

        if let videoCaptureDevice = AVCaptureDevice.default(for: .video) {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    print("canAddInput failed")
                    return;
                }
            } catch {
                print("videoInput failed")
                return
            }
        }
        
        OperationQueue.main.addOperation {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer!.frame = self.scannerView.bounds
            self.previewLayer!.videoGravity = .resizeAspectFill
            self.scannerView.layer.addSublayer(self.previewLayer!)
            self.scannerView.bringSubview(toFront: self.laserView)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            let dispatchQueue = DispatchQueue(label: "CaptureQueue")
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatchQueue)
            if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                metadataOutput.metadataObjectTypes = [.qr]
            }
        } else {
            print("canAddOutput failed")
            return
        }
    }
    
    private func checkCaptureSession() {
#if targetEnvironment(simulator)
        print("No camera on simulator")
        return
#else
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch(authStatus) {
        case .authorized:
            setupCaptureSession()
            break
        case .denied:
            showAlert(title: NSLocalizedString("No camera access", comment: ""),
                      message: NSLocalizedString("Please allow camera access in the app settings.", comment: ""))
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    self.setupCaptureSession()
                } else {
                    self.showAlert(title: NSLocalizedString("No camera access", comment: ""),
                                   message: NSLocalizedString("This feature is only available with camera access.", comment: ""))
                }
            }
            break
        case .restricted:
            print("restricted")
            showAlert(title: NSLocalizedString("No camera access", comment: ""),
                      message: NSLocalizedString("Camera access has been denied in restrictions.", comment: ""))
            break
        }
#endif
    }
    
    private func resumeScanning() {
        
        let delayInSeconds : UInt64 = 3
        let delay = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + delayInSeconds * NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: delay) {
            if UserDefaults.standard.bool(forKey: "app_configured") == true {
                self.infoView.resetInfoView()
                self.hideAttentionView()
                self.currentOrder = nil
            } else {
                self.infoView.resetConfigurationView()
            }
            self.startRunning()
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            if let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject, readableObject.type == .qr {
                if let qrstring = readableObject.stringValue {
                    
                    self.captureSession.stopRunning()
                    
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    } else {
                        AudioServicesPlaySystemSound(SystemSoundID(1328))
                    }
                    
                    print("QR: \(qrstring)")
                    
                    if UserDefaults.standard.bool(forKey: "app_configured") == true {
                        let fetchOrder: NSFetchRequest<Order> = Order.fetchRequest()
                        fetchOrder.predicate = NSPredicate(format: "secret == %@", qrstring)
                        do {
                            let orders = try SyncManager.sharedInstance.viewContext.fetch(fetchOrder)
                            if let order = orders.first {
                                
                                let fetchItem: NSFetchRequest<Item> = Item.fetchRequest()
                                fetchItem.predicate = NSPredicate(format: "id == %d", order.item)
                                order.item_name = try SyncManager.sharedInstance.viewContext.fetch(fetchItem).first?.name
                                
                                self.currentOrder = order
                                
                                if let _ = order.checkin {
                                    self.infoView.setInfoView(order: order, result: PretixRedeemResponse(status: .ok, reason: .already_redeemed))
                                    if order.checkin_attention {
                                        OperationQueue.main.addOperation {
                                            self.showAttentionView(comment: order.comment)
                                        }
                                    }
                                } else {
                                    order.checkin = Date()
                                    order.synced = -1
                                    SyncManager.sharedInstance.save()
                                    NetworkManager.sharedInstance.postPretixRedeem(order: order) { (response, error) in
                                        self.infoView.setInfoView(order: order, result: response)
                                        if order.checkin_attention {
                                            OperationQueue.main.addOperation {
                                                self.showAttentionView(comment: order.comment)
                                            }
                                        }
                                    }
                                }
                            } else {
                                self.infoView.setInfoView(order: nil, result: nil)
                            }
                        } catch {
                            print("Fetch error: \(error.localizedDescription)")
                        }
                    } else {
                        if let config = try? JSONDecoder().decode(PretixConfig.self, from: qrstring.data(using: .utf8)!) {
                            print("\(config)")
                            infoView.setConfigurationView(result: true)

                            UserDefaults.standard.set(true, forKey: "app_configured")
                            UserDefaults.standard.set(false, forKey: "reset_preference")
                            
                            KeychainService.savePassword(token: config.apikey, key: "pretix_api_token")
                            UserDefaults.standard.setValue(config.apiurl, forKey: "pretix_api_base")
                            UserDefaults.standard.synchronize()
                            
                            NetworkManager.sharedInstance.getPretixItems()
                            NetworkManager.sharedInstance.getPretixCheckinlist()
                            NetworkManager.sharedInstance.getPretixOrders()
                            
                        } else {
                            infoView.setConfigurationView(result: false)
                        }
                    }
                    
                    resumeScanning()
                    
                    // Inform delegate
                    DispatchQueue.main.async {
                        self.delegate?.didScan(controller: self, result: qrstring)
                    }
                }
            }
        }
    }
}
