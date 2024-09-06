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

    func recive(id:String) async throws -> [String] {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        var connection: AMQPConnection
        var channel: AMQPChannel

        connection = try await AMQPConnection.connect(use: eventLoopGroup.next(), from: .init(connection: .plain, server: .init()))

        //            print("Succesfully connected")
        channel = try await connection.openChannel()
        //            print("Succesfully opened a channel")
        try await channel.queueDeclare(name: id, durable: false)
        let consumer = try await channel.basicConsume(queue: "test", noAck:true)
        var msgArr: [String] = []
        for try await msg in consumer {
            print("Succesfully consumed a message", String(buffer: msg.body))
            msgArr.append(String(buffer: msg.body))
        }
        return msgArr
    }

}
