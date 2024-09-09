//
//  User.swift
//
//
//  Created by Luiz Sena on 02/09/24.
//

import Vapor
import Foundation
import AMQPClient

class User {
    let id: String
    let ws: WebSocket
    var momClient: MOMClient = MOMClient()
    var isOnline: Bool = false
    init(id: String, ws: WebSocket) {
        self.id = id
        self.ws = ws
    }
}
