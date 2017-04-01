/// {{ method.name }} (Client Streaming)
public class {{ .|call:protoFile.package,service.name,method.name}} {
  private var call : Call

  /// Create a call.
  fileprivate init(_ channel: Channel) {
    self.call = channel.makeCall("{{ .|path:protoFile.package,service.name,method.name }}")
  }

  /// Call this to start a call. Nonblocking.
  fileprivate func start(metadata:Metadata, completion:@escaping (CallResult)->())
    throws -> {{ .|call:protoFile.package,service.name,method.name}} {
      try self.call.start(.clientStreaming, metadata:metadata, completion:completion)
      return self
  }

  /// Call this to send each message in the request stream. Nonblocking.
  public func send(_ message:Echo_EchoRequest, errorHandler:@escaping (Error)->()) throws {
    let messageData = try message.serializedData()
    try call.sendMessage(data:messageData, errorHandler:errorHandler)
  }

  /// Call this to close the connection and wait for a response. Blocking.
  public func closeAndReceive() throws -> {{ method.output|protoMessageType }} {
    var returnError : {{ .|clienterror:protoFile.package,service.name }}?
    var returnResponse : {{ method.output|protoMessageType }}!
    let sem = DispatchSemaphore(value: 0)
    do {
      try closeAndReceive() {response, error in
        returnResponse = response
        returnError = error
        sem.signal()
      }
      _ = sem.wait(timeout: DispatchTime.distantFuture)
    } catch (let error) {
      throw error
    }
    if let returnError = returnError {
      throw returnError
    }
    return returnResponse
  }

  /// Call this to close the connection and wait for a response. Nonblocking.
  public func closeAndReceive(completion:@escaping ({{ method.output|protoMessageType }}?, {{ .|clienterror:protoFile.package,service.name }}?)->())
    throws {
      do {
        try call.receiveMessage() {(responseData) in
          if let responseData = responseData,
            let response = try? {{ method.output|protoMessageType }}(serializedData:responseData) {
            completion(response, nil)
          } else {
            completion(nil, {{ .|clienterror:protoFile.package,service.name }}.invalidMessageReceived)
          }
        }
        try call.close(completion:{})
      } catch (let error) {
        throw error
      }
  }
}
