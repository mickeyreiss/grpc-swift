/// {{ method.name }} (Server Streaming)
public class {{ .|call:protoFile.package,service.name,method.name}} {
  private var call : Call

  /// Create a call.
  fileprivate init(_ channel: Channel) {
    self.call = channel.makeCall("{{ .|path:protoFile.package,service.name,method.name }}")
  }

  /// Call this once with the message to send. Nonblocking.
  fileprivate func start(request: {{ method.input|protoMessageType }},
                         metadata: Metadata,
                         completion: @escaping (CallResult) -> ())
    throws -> {{ .|call:protoFile.package,service.name,method.name}} {
      let requestData = try request.serializedData()
      try call.start(.serverStreaming,
                     metadata:metadata,
                     message:requestData,
                     completion:completion)
      return self
  }

  /// Call this to wait for a result. Blocking.
  public func receive() throws -> {{ method.output|protoMessageType }} {
    var returnError : {{ .|clienterror:protoFile.package,service.name }}?
    var returnResponse : {{ method.output|protoMessageType }}!
    let sem = DispatchSemaphore(value: 0)
    do {
      try receive() {response, error in
        returnResponse = response
        returnError = error
        sem.signal()
      }
      _ = sem.wait(timeout: DispatchTime.distantFuture)
    }
    if let returnError = returnError {
      throw returnError
    }
    return returnResponse
  }

  /// Call this to wait for a result. Nonblocking.
  public func receive(completion:@escaping ({{ method.output|protoMessageType }}?, {{ .|clienterror:protoFile.package,service.name }}?)->()) throws {
    do {
      try call.receiveMessage() {(responseData) in
        if let responseData = responseData {
          if let response = try? {{ method.output|protoMessageType }}(serializedData:responseData) {
            completion(response, nil)
          } else {
            completion(nil, {{ .|clienterror:protoFile.package,service.name }}.invalidMessageReceived)
          }
        } else {
          completion(nil, {{ .|clienterror:protoFile.package,service.name }}.endOfStream)
        }
      }
    }
  }
}
