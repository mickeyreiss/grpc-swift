// {{ method.name }} (Unary)
public class {{ .|session:protoFile.package,service.name,method.name }} : {{ .|service:protoFile.package,service.name }}Session {
  private var provider : {{ .|provider:protoFile.package,service.name }}

  /// Create a session.
  fileprivate init(handler:gRPC.Handler, provider: {{ .|provider:protoFile.package,service.name }}) {
    self.provider = provider
    super.init(handler:handler)
  }

  /// Run the session. Internal.
  fileprivate func run(queue:DispatchQueue) throws {
    try handler.receiveMessage(initialMetadata:initialMetadata) {(requestData) in
      if let requestData = requestData {
        let requestMessage = try {{ method.input|protoMessageType }}(protobuf:requestData)
        let replyMessage = try self.provider.{{ method.name|lowercase }}(request:requestMessage, session: self)
        try self.handler.sendResponse(message:replyMessage.serializeProtobuf(),
                                      statusCode:self.statusCode,
                                      statusMessage:self.statusMessage,
                                      trailingMetadata:self.trailingMetadata)
      }
    }
  }
}
