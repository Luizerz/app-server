//
//  MessageSystem.swift
//
//
//  Created by Luiz Sena on 02/09/24.
//

import Vapor
import Foundation

final class MessageSystem: @unchecked Sendable  {

    private var clients: [User] = []


    func connect(_ req: Request, _ ws: WebSocket) {
        let id = req.parameters.get("id")!
        let user = User(id: id, ws: ws)
        self.clients.append(user)

        ws.onText { ws, msg in
            print(msg)
        }

        ws.onBinary { ws, buffer in
            let wrappedData = try! buffer.decodedToDataWrapper()

            switch wrappedData.contentType {
            case .message:
                let message = try! JSONDecoder().decode(Message.self, from: wrappedData.content)
                do {
                    try await self.messageTo(message: message)
                } catch {
                    print(error)
                }
            case .verifyMessages:
                let message = try! JSONDecoder().decode(VerifyMessage.self, from: wrappedData.content)
                if let user = self.findUser(id: id) {
                    do {
                        let messages = try await user.mqttClient.recive(user: user)
                        let mappedMessages = messages.map { return Message(from: message.from, to: user.id, content: $0)}
                        let verifiedMessages = VerifyMessage(from: message.from, content: mappedMessages.reversed())
                        let dataWrapper = DataWrapper(contentType: .verifyMessages, content: verifiedMessages.toData()).toData()
                        try await user.ws.send(raw: dataWrapper, opcode: .binary)
                    } catch {
                        print(error)
                    }
                }
            }
        }

        ws.onClose.whenSuccess {
            self.disconnect(id: id)
        }
    }

    private func isUserOnline(id: String) -> Bool {
        let index = self.clients.firstIndex { $0.id == id }
        return (index != nil)
    }

    private func messageTo(message: Message) async throws {
        if isUserOnline(id: message.to) {
            let client = self.clients.first { $0.id == message.to }
            try await client?.ws.send(raw: DataWrapper(contentType: .message, content: message.toData()).toData(), opcode: .binary)
        } else {
            if let user = findUser(id: message.from) {
                try await user.mqttClient.send(to: message.to, msg: ByteBuffer(data: message.toData()))
            }
        }
    }

    private func disconnect(id: String){
        let index = self.clients.firstIndex{$0.id == id}!
        self.clients.remove(at: index)
    }

    private func findUser(id: String) -> User? {
        return self.clients.first{ $0.id == id }
    }
}
