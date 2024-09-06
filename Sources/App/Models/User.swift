//
//  User.swift
//
//
//  Created by Luiz Sena on 02/09/24.
//

import Vapor
import Foundation

struct User {
    let id: String
    let ws: WebSocket
    var mqttClient: MQTTClient = MQTTClient()
}
