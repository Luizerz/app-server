//
//  MessageSystem.swift
//
//
//  Created by Luiz Sena on 02/09/24.
//

import Vapor
import Foundation
import AMQPClient

final class ServerSystem: @unchecked Sendable  {

    private var clients: [User] = []


    func connect(_ req: Request, _ ws: WebSocket) {

        let id = req.parameters.get("id")!
        if (findUser(id: id) == nil) {
            let user = User(id: id, ws: ws)
            user.isOnline = true
            self.clients.append(user)
        } else {
            let user = findUser(id: id)
            user?.isOnline = true
        }

        ws.onText { ws, msg in
            print(msg)
        }

        ws.onBinary { ws, buffer in
            let wrappedData = try! buffer.decodedToDataContainer()

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

                do {
                    let user = self.findUser(id: id)!
                    let messages = try await user.momClient.recive(id: user.id)
                    let verifiedDTO = VerifyMessage(from: "", content: messages).toData()
                    let dataContainer = DataContainer(contentType: .verifyMessages, content: verifiedDTO).toData()
                    try await ws.send(raw: dataContainer, opcode: .binary)

                } catch {
                    print(error)
                }

            }
        }

        ws.onClose.whenSuccess {
            self.disconnect(id: id)
        }
    }

    private func isUserOnline(id: String) -> Bool {
        let index = self.clients.firstIndex { $0.id == id && $0.isOnline }
        return (index != nil)
    }

    private func messageTo(message: Message) async throws {

        if isUserOnline(id: message.to) {
            let client = self.clients.first { $0.id == message.to }
            try await client?.ws.send(raw: DataContainer(contentType: .message, content: message.toData()).toData(), opcode: .binary)
        } else {
            if let user = findUser(id: message.from) {
                try await user.momClient.send(to: message.to, msg: ByteBuffer(data: message.toData()))
            }
        }
    }
    
    private func disconnect(id: String){
        let findedUser = findUser(id: id)!
        findedUser.isOnline = false
    }

    private func findUser(id: String) -> User? {
        return self.clients.first{ $0.id == id }
    }
}
