//
//  BLEManager.swift
//  BLE
//
//  Created by Marc Delling on 05.06.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BLEManagerDelegate: NSObjectProtocol {
    func didStartScanning(_ manager: BLEManager)
    func didStopScanning(_ manager: BLEManager)
    func didConnect(_ manager: BLEManager, peripheral: CBPeripheral)
    func didDisconnect(_ manager: BLEManager)
    func didDiscover(_ manager: BLEManager, peripheral: CBPeripheral)
    func didReceive(_ manager: BLEManager, message: String?)
}

class BLEManager: NSObject {
    
    let SerialServiceCBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9F")
    let TxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9F")
    let RxCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9F")
    let BaudCharacteristicUUID = CBUUID(string: "6E400004-B5A3-F393-E0A9-E50E24DCCA9F")
    let HWFCCharacteristicUUID = CBUUID(string: "6E400005-B5A3-F393-E0A9-E50E24DCCA9F")
    let NameCharacteristicUUID = CBUUID(string: "6E400006-B5A3-F393-E0A9-E50E24DCCA9F")
    let DirectionCharacteristicUUID = CBUUID(string: "6E400007-B5A3-F393-E0A9-E50E24DCCA9F")
    let RSSI_range = -40..<(-15)  // optimal -22dB -> reality -48dB
    let notifyMTU = 20  // Extended Data Length 244 for iPhone 7, 7 Plus
    
    static var sharedInstance = BLEManager()
    
    weak var stopScanTimer : Timer?
    weak var delegate : BLEManagerDelegate?
    
    fileprivate var centralManager: CBCentralManager!
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var uartTxCharacteristic: CBCharacteristic? {
        didSet {
            if let _ = self.uartTxCharacteristic, let peripheral = connectedPeripheral {
                delegate?.didConnect(self, peripheral: peripheral)
            }
        }
    }
    fileprivate var uartRxCharacteristic: CBCharacteristic? {
        didSet {
            if let characteristic = self.uartRxCharacteristic {
                connectedPeripheral?.setNotifyValue(true, for: characteristic)
            }
        }
    }
    fileprivate var baudCharacteristic: CBCharacteristic? {
        didSet {
            if let characteristic = self.baudCharacteristic {
                connectedPeripheral?.readValue(for: characteristic)
            }
        }
    }
    fileprivate var hwfcCharacteristic: CBCharacteristic? {
        didSet {
            if let characteristic = self.hwfcCharacteristic {
                connectedPeripheral?.readValue(for: characteristic)
            }
        }
    }
    
    fileprivate var receiveQueue = Data()
    fileprivate var sendQueue = [Data]()
    fileprivate var baud = UInt32(115200)
    fileprivate var hwfc = false
    fileprivate var shouldReconnect = false
    
    var baudRate: UInt32 {
        get { return baud }
        set {
            baud = newValue
            if let characteristic = self.baudCharacteristic {
                connectedPeripheral?.writeValue(baud.data, for: characteristic, type: .withResponse)
            }
        }
    }
    
    var hardwareFlowControl: Bool {
        get { return hwfc }
        set {
            hwfc = newValue
            if let characteristic = self.hwfcCharacteristic {
                connectedPeripheral?.writeValue(hwfc.data, for: characteristic, type: .withResponse)
            }
        }
    }
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        if let uuidString = UserDefaults.standard.value(forKey: "last_printer_uuid") as? String, let uuid = UUID(uuidString: uuidString) {
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if let peripheral = peripherals.first {
                print("restored printer from user defaults")
                centralManager.connect(peripheral, options: [:])
            }
        }
    }
    
    public func write(data: Data) {
        if let characteristic = uartTxCharacteristic {
            sendQueue = data.chunked(by: 20)
            connectedPeripheral?.writeValue(sendQueue.removeFirst(), for: characteristic, type: .withResponse)
        }
    }
    
    func applyKeepAliveTimer() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(60.0), repeats: false) { (_) in
            if let characteristic = self.hwfcCharacteristic {
                self.connectedPeripheral?.readValue(for: characteristic)
            }
        }
    }
    
    func applyStopScanTimer() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(9.0), repeats: false) { (_) in
            if self.centralManager.isScanning {
                self.centralManager.stopScan()
                self.delegate?.didStopScanning(self)
            }
        }
    }
    
    func killStopScanTimer() {
        stopScanTimer?.invalidate()
        stopScanTimer = nil
    }
    
    func scan() {
        killStopScanTimer()
        centralManager.scanForPeripherals(withServices: [SerialServiceCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true as Bool)])
        applyStopScanTimer()
        delegate?.didStartScanning(self)
    }
    
    func connect(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: [:])
    }
    
    func cleanup() {
        
        shouldReconnect = false
        killStopScanTimer()
        uartTxCharacteristic = nil
        sendQueue.removeAll()
        
        guard let connectedPeripheral = connectedPeripheral else {
            return
        }
        
        guard connectedPeripheral.state != .disconnected, let services = connectedPeripheral.services else {
            // FIXME: state connecting
            centralManager.cancelPeripheralConnection(connectedPeripheral)
            return
        }
        
        for service in services {
            if let characteristics = service.characteristics {
                for characteristic in characteristics {
                    if characteristic.uuid.isEqual(RxCharacteristicUUID) {
                        if characteristic.isNotifying {
                            connectedPeripheral.setNotifyValue(false, for: characteristic)
                            //return // ??? not cancelling if setNotify false succeeds ???
                        }
                    }
                }
            }
        }
        
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
}

// MARK: - Central Manager delegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: ()
        case .poweredOff, .resetting: cleanup()
        default: return
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //guard RSSI_range.contains(RSSI.intValue) && discoveredPeripheral != peripheral else { return }
        print("didDiscover \(peripheral) with RSSI \(RSSI.intValue)")
        delegate?.didDiscover(self, peripheral: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error { print(error.localizedDescription) }
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        shouldReconnect = true
        connectedPeripheral = peripheral
        centralManager.stopScan()
        delegate?.didStopScanning(self)
        receiveQueue.removeAll()
        
        UserDefaults.standard.set("\(peripheral.identifier)", forKey: "last_printer_uuid")
        UserDefaults.standard.synchronize()
        print("stored to defaults")
        
        peripheral.delegate = self
        peripheral.discoverServices([SerialServiceCBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if shouldReconnect {
            centralManager.connect(peripheral, options: [:])
        } else {
            cleanup()
            delegate?.didDisconnect(self)
        }
    }
    
}

// MARK: - Peripheral Delegate
extension BLEManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            cleanup()
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([TxCharacteristicUUID, RxCharacteristicUUID, BaudCharacteristicUUID, HWFCCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == RxCharacteristicUUID {
                uartRxCharacteristic = characteristic
            } else if characteristic.uuid == TxCharacteristicUUID {
                uartTxCharacteristic = characteristic
            } else if characteristic.uuid == BaudCharacteristicUUID {
                baudCharacteristic = characteristic
            } else if characteristic.uuid == HWFCCharacteristicUUID {
                hwfcCharacteristic = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else if characteristic == uartRxCharacteristic {
            guard let newData = characteristic.value else { return }
            receiveQueue.append(newData)
            if newData[newData.count-1] == 0x0a {
                delegate?.didReceive(self, message: String(data: receiveQueue, encoding: .utf8))
                receiveQueue.removeAll()
            }
        } else if characteristic == baudCharacteristic {
            if let value = UInt32(data: characteristic.value) {
                baud = value
                print("Baud: \(baud)")
            }
        } else if characteristic == hwfcCharacteristic {
            hwfc = Bool(data: characteristic.value)
            print("HWFC: \(hwfc)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { print(error.localizedDescription) }
        guard characteristic.uuid == RxCharacteristicUUID else { return }
        if characteristic.isNotifying {
            print("Notification began on \(characteristic)")
        } else {
            print("Notification stopped on \(characteristic). Disconnecting...")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("write: \(error.localizedDescription)")
        } else {
            print("write successful")
            if sendQueue.count > 0, characteristic == self.uartTxCharacteristic {
                peripheral.writeValue(sendQueue.removeFirst(), for: characteristic, type: .withResponse)
            }
        }
    }
}

extension Data {
    var hexString : String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    func chunked(by chunkSize: Int) -> [Data] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Data(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Bool {
    init(data: Data?) {
        if let data = data, data.count == 1 {
            self = (data[0] == 255)
        } else {
            self = false
        }
    }
    var data: Data {
        return Data(bytes: [self ? 255 : 0])
    }
}

extension UInt32 {
    init?(data: Data?) {
        guard let data = data, data.count == MemoryLayout<UInt32>.size else {
            return nil
        }
        self = data.withUnsafeBytes { $0.pointee }
    }
    var data: Data {
        var value = self // CFSwapInt32HostToBig(self)
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}
