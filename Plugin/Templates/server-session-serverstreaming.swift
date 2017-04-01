// {{ method.name }} (Server Streaming)
class {{ .|session:protoFile.package,service.name,method.name }} : {{ .|service:protoFile.package,service.name }}Session {
  private var provider : {{ .|provider:protoFile.package,service.name }}

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: {{ .|provider:protoFile.package,service.name }}) {
    self.provider = provider
    super.init(handler:handler)
  }

  /// Send a message. Nonblocking.
  func send(_ response: {{ method.output|protoMessageType }}) throws {
    try handler.sendResponse(message:response.serializedData()) {}
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) throws {
    try self.handler.receiveMessage(initialMetadata:initialMetadata) {(requestData) in
      if let requestData = requestData {
        do {
          let requestMessage = try {{ method.input|protoMessageType }}(serializedData:requestData)
          // to keep providers from blocking the server thread,
          // we dispatch them to another queue.
          queue.async {
            do {
              try self.provider.{{ method.name|lowercase }}(request:requestMessage, session: self)
              try self.handler.sendStatus(statusCode:self.statusCode,
                                          statusMessage:self.statusMessage,
                                          trailingMetadata:self.trailingMetadata,
                                          completion:{})
            } catch (let error) {
              print("error: \(error)")
            }
          }
        } catch (let error) {
          print("error: \(error)")
        }
      }
    }
  }
}
