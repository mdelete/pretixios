//
//  PretixModel+Codable.swift
//  pretixios
//
//  Created by Marc Delling on 04.04.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import Foundation

struct PretixConfig : Codable {
    let version : Int
    let allow_search : Bool
    let show_info : Bool
    let apikey : String
    let apiurl : String
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
            let variation : String?
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

struct PretixVoucherResponse : Codable {
    
    struct Result : Codable {
        
        enum PriceMode : String, Codable {
            case none
            case set
            case subtract
            case percent
        }
        
        let id : Int
        let code : String
        let max_usages : Int
        let redeemed : Int
        let valid_until : Date?
        let block_quota : Bool
        let allow_ignore_quota : Bool
        let price_mode : PriceMode
        let value : String
        let item : Int?
        let variation : Int?
        let quota : Int?
        let tag : String
        let comment : String
        let subevent : Int?
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



