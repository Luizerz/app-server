//
//  Message.swift
//
//
//  Created by Luiz Sena on 02/09/24.
//

import Foundation

struct Message: Codable {
    let from: String
    let to: String
    let content: String

    func toData() -> Data {
        return try! JSONEncoder().encode(self)
    }
}

struct VerifyMessage: Codable {
    let from: String
    let content: [Message]
    func toData() -> Data {
        return try! JSONEncoder().encode(self)
    }
}
