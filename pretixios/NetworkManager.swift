//
//  NetworkManager.swift
//  pretixios
//
//  Created by Marc Delling on 19.07.15.
//  Copyright © 2015 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation
import Security
import UIKit
import CoreData

class NetworkManager : NSObject, URLSessionDelegate {
    
    static let sharedInstance = NetworkManager()
    
    fileprivate let operationQueue = OperationQueue()
    fileprivate let sessionConfiguration = URLSessionConfiguration.default
    
    fileprivate let encoder : JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    fileprivate let decoder : JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            var optionalDate : Date?
 
            switch(dateString.count) {
            case 32:
                fallthrough
            case 27:
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ"
                optionalDate = formatter.date(from: dateString)
            default:
                let formatter = ISO8601DateFormatter()
                // since iOS11 ISO8601DateFormatter can do fractional seconds but it seems to be broken
                // formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                optionalDate = formatter.date(from: dateString)
            }

            guard let date = optionalDate else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString) for \(decoder.codingPath)")
            }

            return date
        })
        return decoder
    }()

    fileprivate lazy var session: URLSession = {
        self.operationQueue.maxConcurrentOperationCount = 1
        self.sessionConfiguration.httpAdditionalHeaders = ["Content-Type":"application/json","Accept":"application/json"]
        return URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
    }()
    
    // MARK: - Errors
    
    struct HttpError: LocalizedError {
        
        var code: Int
        var errorDescription: String? { return "Http-Status: \(code)" }
        var failureReason: String? { return "Http-Status: \(code)" }
        
        init(code: Int) {
            self.code = code
        }
    }
    
    struct ConfigError: LocalizedError {
        let code : Int = 42
        let errorDescription = "Event not configured"
        let failureReason = "Event not configured"
    }
    
    // MARK: - URLSessionDelegate
    
    private func publicKeyRefToHash(publicKeyRef: SecKey) -> String {
        
        if let data = publicKeyRefToData(publicKeyRef: publicKeyRef) {
            var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA256($0, CC_LONG(data.count), &hash)
            }
            return Data(bytes: hash).base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        }
        
        return ""
    }
    
    private func publicKeyRefToData(publicKeyRef: SecKey) -> Data? {
        
        let keychainTag = "X509_KEY"
        var publicKeyData : AnyObject?
        var putResult : OSStatus = noErr
        var delResult : OSStatus = noErr
        
        let putKeyParams : NSMutableDictionary = [
            kSecClass as String : kSecClassKey,
            kSecAttrApplicationTag as String : keychainTag,
            kSecValueRef as String : publicKeyRef,
            kSecReturnData as String : kCFBooleanTrue
        ]
        
        let delKeyParams : NSMutableDictionary = [
            kSecClass as String : kSecClassKey,
            kSecAttrApplicationTag as String : keychainTag,
            kSecReturnData as String : kCFBooleanTrue
        ]
        
        putResult = SecItemAdd(putKeyParams as CFDictionary, &publicKeyData)
        delResult = SecItemDelete(delKeyParams as CFDictionary)
        
        if putResult != errSecSuccess || delResult != errSecSuccess {
            return nil
        }
        
        return publicKeyData as? Data
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let serverTrust = challenge.protectionSpace.serverTrust
        
        let policies = NSMutableArray();
        policies.add(SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString?)))
        SecTrustSetPolicies(serverTrust!, policies);
        
        var result = SecTrustResultType.deny
        SecTrustEvaluate(serverTrust!, &result)
        let certificate = SecTrustGetCertificateAtIndex(serverTrust!, 1) // check leaf of ca, not our cert, because letencrypt renews after 90 days
        let isServerTrusted = (result == SecTrustResultType.unspecified || result == SecTrustResultType.proceed)
        var isPublicKeyTrusted = false
        
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate!, policy, &trust)
        
        if let trust = trust, trustCreationStatus == errSecSuccess {
            let publicKey = SecTrustCopyPublicKey(trust)
            let hash = publicKeyRefToHash(publicKeyRef: publicKey!)
            isPublicKeyTrusted = ("q7W2d0B0dmT/C8X82CAnMJ5Drj4giWg+8Ozc5CxjpzE=" == hash)
            print("PUBKEY_SHA256_BASE64: \(hash) [\(isPublicKeyTrusted)]")
        }
         
        if (isServerTrusted && isPublicKeyTrusted) {
            let credential:URLCredential = URLCredential(trust: serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    // MARK: - Rest API Calls

    func postPretixRedeem(order: Order, completion: @escaping (PretixRedeemResponse?, Error?) -> Void) {
        
        guard let token = KeychainService.loadPassword(key: "pretix_api_token") else {
            print("pretix_api_token not configured")
            return completion(nil, ConfigError())
        }
        
        guard let base = UserDefaults.standard.string(forKey: "pretix_api_base")  else {
            print("pretix_api_base not configured")
            return completion(nil, ConfigError())
        }
        
        guard let list = UserDefaults.standard.string(forKey: "pretix_checkin_list")  else {
            print("pretix_checkin_list not configured")
            return completion(nil, ConfigError())
        }
        
        var request = URLRequest(url: URL(string: base + "/checkinlists/\(list)/positions/\(order.position)/redeem/")!)
        request.httpMethod = "POST"
        request.setValue("Token " + token, forHTTPHeaderField: "Authorization")
        request.httpBody = try? self.encoder.encode(PretixRedeemRequestBody(force: false, ignore_unpaid: true, nonce: "", datetime: order.checkin, questions_supported: false, answers: nil))
        // FIXME: include nonce in sync process
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, neterror) -> Void in
            if neterror == nil {
                let status = (response as! HTTPURLResponse).statusCode
                if (status == 200 || status == 201 || status == 400), let data = data { // FIXME: document why 400 might be ok
                    do {
                        let response = try self.decoder.decode(PretixRedeemResponse.self, from: data)
                        order.synced = 1
                        SyncManager.sharedInstance.save()
                        completion(response, nil)
                    } catch let jsonerror {
                        completion(nil, jsonerror)
                    }
                } else {
                    print("Error: \(status) \(#file):\(#line) Url: \(request.url!)")
                    completion(nil, HttpError(code: status))
                }
            } else {
                completion(nil, neterror)
            }
        })
        
        dataTask.resume()
    }
    
    func getPretixCheckinlist() {
        if let base = UserDefaults.standard.string(forKey: "pretix_api_base") {
            NetworkManager.sharedInstance.getPretixCheckinlist(path: base + "/checkinlists/", progress: 0, status: 0)
        } else {
            SyncManager.sharedInstance.failure("getPretixCheckinlist", code: -1)
        }
    }
    
    func getPretixCheckinlist(path: String?, progress: Int, status: Int) {
        
        let syncManager = SyncManager.sharedInstance
        let syncPath = "getPretixCheckinlist"
        
        guard let path = path, let url = URL(string: path) else {
            if status == 200 {
                syncManager.success(syncPath, code: status)
                syncManager.checkDefaultCheckinList()
                print("last chunk success")
            } else {
                syncManager.failure(syncPath, code: status)
            }
            return
        }
        
        guard let token = KeychainService.loadPassword(key: "pretix_api_token") else {
            print("pretix_api_token not configured")
            return
        }
        
        guard let context = syncManager.backgroundContext else {
            print("No Background context")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token " + token, forHTTPHeaderField: "Authorization")
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                let status = (response as! HTTPURLResponse).statusCode
                if status == 200, let data = data {
                    do {
                        let response = try self.decoder.decode(PretixCheckinListsResponse.self, from: data)
                        let fetchRequest: NSFetchRequest<Checkinlist> = Checkinlist.fetchRequest()
                        for result in response.results {
                            
                            fetchRequest.predicate = NSPredicate(format: "id == %u", result.id)
                            
                            do {
                                let results = try context.fetch(fetchRequest)
                                if results.count == 1 {
                                    results.first?.name = result.name
                                    results.first?.checkin_count = Int32(result.checkin_count)
                                    results.first?.position_count = Int32(result.position_count)
                                    print("Remote update \(result.id)")
                                } else if (results.count == 0) {
                                    let checkinlist = Checkinlist(context: context)
                                    checkinlist.id = Int32(result.id)
                                    checkinlist.name = result.name
                                    checkinlist.checkin_count = Int32(result.checkin_count)
                                    checkinlist.position_count = Int32(result.position_count)
                                    print("Remote new \(result.id)")
                                } else {
                                    print("HORROR! \(results.count)")
                                }
                            } catch {
                                print("Fetch error: \(error.localizedDescription)")
                            }
                            
                        }
                        
                        syncManager.saveBackgroundPartial(state: (response.results.count + progress, response.count))
                        self.getPretixCheckinlist(path: response.next, progress: response.results.count, status: status)
                        
                    } catch let error {
                        print(error)
                        syncManager.failure(syncPath, code: -2)
                    }
                } else if status == 401 {
                    print("\(error!.localizedDescription)")
                    syncManager.failure(syncPath, code: status)
                } else if status == 304 {
                    syncManager.success(syncPath, code: status)
                } else {
                    syncManager.failure(syncPath, code: status)
                }
            } else {
                print("\(error!.localizedDescription)")
                syncManager.failure(syncPath, code: -1)
            }
        })
        dataTask.resume()
    }
    
    func getPretixVouchers() {
        if let base = UserDefaults.standard.string(forKey: "pretix_api_base") {
            NetworkManager.sharedInstance.getPretixVouchers(path: base + "/vouchers/", progress: 0, status: 0)
        } else {
            SyncManager.sharedInstance.failure("getPretixVoucher", code: -1)
        }
    }
    
    func getPretixVouchers(path: String?, progress: Int, status: Int) {
        
        let syncManager = SyncManager.sharedInstance
        let syncPath = "getPretixVoucher"
        
        guard let path = path, let url = URL(string: path) else {
            if status == 200 {
                syncManager.success(syncPath, code: status)
                print("last chunk success")
            } else {
                syncManager.failure(syncPath, code: status)
            }
            return
        }
        
        guard let token = KeychainService.loadPassword(key: "pretix_api_token") else {
            print("pretix_api_token not configured")
            return
        }
        
        guard let context = syncManager.backgroundContext else {
            print("No Background context")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token " + token, forHTTPHeaderField: "Authorization")
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                let status = (response as! HTTPURLResponse).statusCode
                if status == 200, let data = data {
                    do {
                        let response = try self.decoder.decode(PretixVoucherResponse.self, from: data)
                        let fetchRequest: NSFetchRequest<Voucher> = Voucher.fetchRequest()
                        for result in response.results {
                            
                            fetchRequest.predicate = NSPredicate(format: "id == %@", result.id)
                            
                            do {
                                let results = try context.fetch(fetchRequest)
                                if results.count == 1 {
                                    print("Remote update \(result.id)")
                                } else if (results.count == 0) {
                                    let voucher = Voucher(context: context)
                                    voucher.id = Int32(result.id)
                                    // FIXME: implement
                                    print("Remote new \(result.id)")
                                } else {
                                    print("HORROR! \(results.count)")
                                }
                            } catch {
                                print("Fetch error: \(error) description: \(error.localizedDescription)")
                            }

                        }
                        
                        syncManager.saveBackgroundPartial(state: (response.results.count + progress, response.count))
                        self.getPretixVouchers(path: response.next, progress: response.results.count, status: status)
                        
                    } catch let error {
                        print(error)
                        syncManager.failure(syncPath, code: -2)
                    }
                } else if status == 401 {
                    print("\(error!.localizedDescription)")
                    syncManager.failure(syncPath, code: status)
                } else if status == 304 {
                    syncManager.success(syncPath, code: status)
                } else {
                    syncManager.failure(syncPath, code: status)
                }
            } else {
                print("\(error!.localizedDescription)")
                syncManager.failure(syncPath, code: -1)
            }
        })
        dataTask.resume()
    }
    
    func getPretixOrders() {
        if let base = UserDefaults.standard.string(forKey: "pretix_api_base") {
            NetworkManager.sharedInstance.getPretixOrders(path: base + "/orders/", progress: 0, status: 0)
        } else {
            SyncManager.sharedInstance.failure("getPretixOrders", code: -1)
        }
    }
    
    func getPretixOrders(path: String?, progress: Int, status: Int) {
        
        let syncManager = SyncManager.sharedInstance
        let syncPath = "getPretixOrders"
        
        guard let path = path, var url = URL(string: path) else {
            if status == 200 {
                syncManager.success(syncPath, code: status)
                print("last chunk success")
            } else {
                syncManager.failure(syncPath, code: status)
            }
            return
        }
        
        guard let token = KeychainService.loadPassword(key: "pretix_api_token") else {
            print("pretix_api_token not configured")
            syncManager.failure(syncPath, code: -1)
            return
        }
        
        guard let context = syncManager.backgroundContext else {
            print("No Background context")
            return
        }
        
        if let modified = SyncManager.sharedInstance.lastSync(syncPath) {
            print("Last sync \(modified.rfc1123String())")
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                urlComponents.queryItems = [URLQueryItem(name: "modified_since", value: modified.iso8601String())]
                url = urlComponents.url!
                print(url)
            }
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token " + token, forHTTPHeaderField: "Authorization")
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                let status = (response as! HTTPURLResponse).statusCode
                if status == 200, let data = data {
                    do {
                        let response = try self.decoder.decode(PretixOrderResponse.self, from: data)
                        let fetchRequest: NSFetchRequest<Order> = Order.fetchRequest()
                        
                        for result in response.results {
                            for position in result.positions {
                                
                                let checkin = position.checkins.last?.datetime
                                let guid = "\(result.code)-\(position.id)"
                                
                                fetchRequest.predicate = NSPredicate(format: "guid == %@", guid)
                                
                                do {
                                    let results = try context.fetch(fetchRequest)
                                    if results.count == 1 {
                                        results.first?.order = position.order
                                        results.first?.attendee_name = position.attendee_name
                                        results.first?.attendee_email = position.attendee_email
                                        results.first?.status = result.status
                                        results.first?.item = Int32(position.item)
                                        results.first?.voucher =  position.voucher?.nsNumber
                                        results.first?.position = Int32(position.id)
                                        results.first?.company = result.invoice_address?.company
                                        results.first?.secret = position.secret
                                        results.first?.checkin = checkin
                                        results.first?.pseudonymization_id = position.pseudonymization_id
                                        results.first?.datetime = result.datetime
                                        results.first?.checkin_attention = result.checkin_attention
                                        results.first?.comment = result.comment
                                        print("Remote update \(guid)")
                                    } else if (results.count == 0) {
                                        let order = Order(context: context)
                                        order.guid = guid
                                        order.order = position.order
                                        order.attendee_name = position.attendee_name
                                        order.attendee_email = position.attendee_email
                                        order.status = result.status
                                        order.item = Int32(position.item)
                                        order.voucher = position.voucher?.nsNumber
                                        order.position = Int32(position.id)
                                        order.company = result.invoice_address?.company
                                        order.secret = position.secret
                                        order.checkin = checkin
                                        order.pseudonymization_id = position.pseudonymization_id
                                        order.datetime = result.datetime
                                        order.checkin_attention = result.checkin_attention
                                        order.comment = result.comment
                                        print("Remote new \(guid)")
                                    } else {
                                        print("HORROR! \(results.count)")
                                    }
                                } catch {
                                    print("Fetch error: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                        syncManager.saveBackgroundPartial(state: (response.results.count + progress, response.count))
                        self.getPretixOrders(path: response.next, progress: response.results.count, status: status)
                        
                    } catch let error {
                        print(error)
                        syncManager.failure(syncPath, code: -2)
                    }
                } else if status == 401 {
                    syncManager.failure(syncPath, code: status)
                } else if status == 304 {
                    syncManager.success(syncPath, code: status)
                } else {
                    syncManager.failure(syncPath, code: status)
                }
            } else {
                print("\(error!.localizedDescription)")
                syncManager.failure(syncPath, code: -1)
            }
        })
        dataTask.resume()
    }
    
    func getPretixItems() {
        if let base = UserDefaults.standard.string(forKey: "pretix_api_base") {
            NetworkManager.sharedInstance.getPretixItems(path: base + "/orders/", progress: 0, status: 0)
        } else {
            SyncManager.sharedInstance.failure("getPretixItems", code: -1)
        }
    }
    
    func getPretixItems(path: String?, progress: Int, status: Int) {
        
        let syncManager = SyncManager.sharedInstance
        let syncPath = "getPretixItems"
        
        guard let path = path, var url = URL(string: path) else {
            if status == 200 {
                syncManager.success(syncPath, code: status)
                print("last chunk success")
            } else {
                syncManager.failure(syncPath, code: status)
            }
            return
        }
        
        guard let token = KeychainService.loadPassword(key: "pretix_api_token") else {
            print("pretix_api_token not configured")
            syncManager.failure(syncPath, code: -1)
            return
        }
        
        guard let context = syncManager.backgroundContext else {
            print("No Background context")
            return
        }
        
        if let modified = SyncManager.sharedInstance.lastSync(syncPath) {
            print("Last sync \(modified.rfc1123String())")
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                urlComponents.queryItems = [URLQueryItem(name: "modified_since", value: modified.iso8601String())]
                url = urlComponents.url!
                print(url)
            }
        }
        
        var request = URLRequest(url: url)
        request.setValue("Token " + token, forHTTPHeaderField: "Authorization")
        
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if error == nil {
                let status = (response as! HTTPURLResponse).statusCode
                if status == 200, let data = data {
                    do {
                        let response = try self.decoder.decode(PretixItemResponse.self, from: data)
                        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                        
                        for result in response.results {
                            
                            fetchRequest.predicate = NSPredicate(format: "id == %@", result.id)
                            
                            do {
                                let results = try context.fetch(fetchRequest)
                                if results.count == 1 {
                                    results.first?.id = Int32(result.id)
                                    results.first?.name = result.name
                                    print("Remote update \(result.id)")
                                } else if (results.count == 0) {
                                    let item = Item(context: context)
                                    item.id = Int32(result.id)
                                    item.name = result.name
                                    print("Remote new \(result.id)")
                                } else {
                                    print("HORROR! \(results.count)")
                                }
                            } catch {
                                print("Fetch error: \(error.localizedDescription)")
                            }
                        }
                        
                        syncManager.saveBackgroundPartial(state: (response.results.count + progress, response.count))
                        self.getPretixItems(path: response.next, progress: response.results.count, status: status)
                        
                    } catch let error {
                        print(error)
                        syncManager.failure(syncPath, code: -2)
                    }
                } else if status == 401 {
                    syncManager.failure(syncPath, code: status)
                } else if status == 304 {
                    syncManager.success(syncPath, code: status)
                } else {
                    syncManager.failure(syncPath, code: status)
                }
            } else {
                print("\(error!.localizedDescription)")
                syncManager.failure(syncPath, code: -1)
            }
        })
        dataTask.resume()
    }
}
