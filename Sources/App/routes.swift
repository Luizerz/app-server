import Vapor
import AMQPClient

func routes(_ app: Application) throws {
    let system = MessageSystem()


    app.webSocket(":id") { req, ws in
        system.connect(req, ws)
    }
}


class MQTTClient {

    func send(to id: String, msg: ByteBuffer) async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        var connection: AMQPConnection
        var channel: AMQPChannel


        connection = try await AMQPConnection.connect(use: eventLoopGroup.next(), from: .init(connection: .plain, server: .init()))

        //            print("Succesfully connected")
        channel = try await connection.openChannel()
        //            print("Succesfully opened a channel")
        try await channel.queueDeclare(name: id, durable: false)
        //            print("Succesfully created queue")
        try await channel.basicPublish(from: msg, exchange: "", routingKey: id)
        try await connection.close()

    }

    func recive(user: User) async throws -> [String] {
        let id = user.id
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 10)
        var connection: AMQPConnection
        var channel: AMQPChannel

        connection = try await AMQPConnection.connect(use: eventLoopGroup.next(), from: .init(connection: .plain, server: .init()))

        //            print("Succesfully connected")
        channel = try await connection.openChannel()
        //            print("Succesfully opened a channel")
        try await channel.queueDeclare(name: id, durable: false)
        let consumer = try await channel.basicConsume(queue: id, noAck:true)

        for try await msg in consumer {
            print("Succesfully consumed a message", String(buffer: msg.body))
            let decoded = try! JSONDecoder().decode(Message.self, from: msg.body)
            print(decoded)
            print(id)
            let verifiedMessage = VerifyMessage(from: decoded.from, content: [decoded]).toData()
            let wrapper = DataWrapper(contentType: .verifyMessages, content: verifiedMessage).toData()
            try await user.ws.send(raw: wrapper, opcode: .binary)
        }
        try await connection.close()
        return msgArr
    }

}
