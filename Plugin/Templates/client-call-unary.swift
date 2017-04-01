/// {{ method.name }} (Unary)
public class {{ .|call:protoFile.package,service.name,method.name}} {
  private var call : Call

  /// Create a call.
  fileprivate init(_ channel: Channel) {
    self.call = channel.makeCall("{{ .|path:protoFile.package,service.name,method.name }}")
  }

  /// Run the call. Blocks until the reply is received.
  fileprivate func run(request: {{ method.input|protoMessageType }},
                       metadata: Metadata) throws -> {{ method.output|protoMessageType }} {
    let sem = DispatchSemaphore(value: 0)
    var returnCallResult : CallResult!
    var returnResponse : {{ method.output|protoMessageType }}?
    _ = try start(request:request, metadata:metadata) {response, callResult in
      returnResponse = response
      returnCallResult = callResult
      sem.signal()
    }
    _ = sem.wait(timeout: DispatchTime.distantFuture)
    if let returnResponse = returnResponse {
      return returnResponse
    } else {
      throw {{ .|clienterror:protoFile.package,service.name }}.error(c: returnCallResult)
    }
  }

  /// Start the call. Nonblocking.
  fileprivate func start(request: {{ method.input|protoMessageType }},
                         metadata: Metadata,
                         completion: @escaping ({{ method.output|protoMessageType }}?, CallResult)->())
    throws -> {{ .|call:protoFile.package,service.name,method.name}} {

      let requestData = try request.serializedData()
      try call.start(.unary,
                     metadata:metadata,
                     message:requestData)
      {(callResult) in
        if let responseData = callResult.resultData,
          let response = try? {{ method.output|protoMessageType}}(serializedData:responseData) {
          completion(response, callResult)
        } else {
          completion(nil, callResult)
        }
      }
      return self
  }
}
