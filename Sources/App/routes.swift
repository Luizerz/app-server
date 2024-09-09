import Vapor
import AMQPClient

func routes(_ app: Application) throws {
    let system = ServerSystem()


    app.webSocket(":id") { req, ws in
        system.connect(req, ws)
    }
}



