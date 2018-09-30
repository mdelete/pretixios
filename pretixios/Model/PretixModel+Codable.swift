//
//  PretixModel+Codable.swift
//  pretixios
//
//  Created by Marc Delling on 04.04.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation

struct PretixConfigHandshake : Codable {
    let handshake_version : Int
    let url : URL
    let token : String
}

struct PretixInitializeRequest : Codable {
    let token : String
    let hardware_brand = "Apple"
    let hardware_model : String
    let software_brand = "Silpion-Prextios"
    let software_version : String
}

struct PretixInitializeResponse : Codable {
    let organizer : String
    let device_id : Int
    let unique_serial : String
    let api_token : String
    let name : String
}

struct PretixRedeemResponse : Codable {
    
    enum Status : String, Codable {
        case ok
        case incomplete
        case error
    }
    
    enum Reason : String, Codable {
        case unpaid
        case already_redeemed
        case product
    }
    
    let status : Status
    let reason : Reason?
}

struct PretixRedeemRequestBody : Codable {
    
    let force : Bool
    let ignore_unpaid : Bool
    let nonce : String
    let datetime : Date?
    let questions_supported : Bool
    let answers : [String:String]?

}

struct PretixOrderResponse : Codable {
    
    struct Result : Codable {
        
        enum Status : String, Codable {
            case n // pending
            case p // paid
            case e // expired
            case c // canceled
            case r // refunded
        }
        
        struct Address : Codable {
            let company : String
            let street : String
            let zipcode : String
            let city : String
        }
        
        struct Position : Codable {
            
            struct Checkin : Codable {
                let datetime : Date
            }
            
            let id : Int
            let item : Int
            let order : String
            let variation : Int?
            let attendee_name : String?
            let attendee_email : String?
            let voucher : Int?
            let pseudonymization_id : String
            let secret : String
            let checkins : [Result.Position.Checkin]
        }
        
        let code : String
        let checkin_attention : Bool
        let comment : String?
        let status : Result.Status
        let datetime : Date?
        let invoice_address : Result.Address?
        let positions : [Result.Position]
    }
    
    let count : Int
    let next : String?
    let results : [Result]
}

struct PretixCheckinListsResponse : Codable {

    struct Result : Codable {
        let id : Int
        let name : String
        let checkin_count : Int
        let position_count : Int
    }
    
    let count : Int
    let next : String?
    let results : [Result]
}

struct PretixItemResponse : Codable {
    
    struct Result : Codable {
        let id : Int
        let name : [String:String]?
        let internal_name : String?
    }
    
    let count : Int
    let next : String?
    let results : [Result]
}
