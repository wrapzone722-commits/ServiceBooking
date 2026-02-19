//
//  CompanyInfo.swift
//  ServiceBooking
//

import Foundation

struct CompanyInfo: Decodable, Equatable {
    let name: String
    let phone: String?
    let phoneExtra: String?
    let email: String?
    let website: String?
    let address: String?
    let legalAddress: String?
    let inn: String?
    let ogrn: String?
    let kpp: String?
    let directorName: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case phone
        case phoneExtra = "phone_extra"
        case email
        case website
        case address
        case legalAddress = "legal_address"
        case inn
        case ogrn
        case kpp
        case directorName = "director_name"
    }
}

