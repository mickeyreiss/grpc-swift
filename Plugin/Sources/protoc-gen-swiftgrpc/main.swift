/*
 *
 * Copyright 2017, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import Foundation
import SwiftProtobuf
import PluginLibrary
import Stencil
import PathKit

extension String {
  var undotted : String {
    return self.replacingOccurrences(of:".", with:"_")
  }

  var lowercaseFirst : String {
    let first = String(self.characters.prefix(1)).lowercased()
    let other = String(self.characters.dropFirst())
    return first + other
  }

  var uppercasedFirst : String {
    var out = self.characters
    if let first = out.popFirst() {
      return String(first).uppercased() + String(out)
    } else {
      return self
    }
  }
}

// Transforms .some.package_name.FooBarRequest -> Some_PackageName_FooBarRequest
func protoMessageName(_ name :String?) -> String {
  guard let name = name else {
    return ""
  }

  var parts : [String] = []
  for dotComponent in name.components(separatedBy:".") {
    var part = ""
    if dotComponent == "" {
      continue
    }
    for underscoreComponent in dotComponent.components(separatedBy:"_") {
      part.append(underscoreComponent.uppercasedFirst)
    }
    parts.append(part)
  }

  return parts.joined(separator:"_")
}

func pathName(forPackage packageName: String, service serviceName: String, method methodName: String) throws -> String {
  return "/" + packageName + "." + serviceName + "/" + methodName
}

func serviceMethodName(forPackage packageName: String, service serviceName: String, method methodName: String) throws -> String {
  return packageName.capitalized.undotted + "_" + serviceName + methodName
}

func serviceName(forPackage packageName: String, service serviceName: String) throws -> String {
  return packageName.capitalized.undotted + "_" + serviceName
}

// Code templates use "//-" prefixes to comment-out template operators
// to keep them from interfering with Swift code formatting tools.
// Use this to remove them after templates have been expanded.
func stripMarkers(_ code:String) -> String {
  let inputLines = code.components(separatedBy:"\n")

  var outputLines : [String] = []
  for line in inputLines {
    if line.contains("//-") {
      let removed = line.replacingOccurrences(of:"//-", with:"")
      if (removed.trimmingCharacters(in:CharacterSet.whitespaces) != "") {
        outputLines.append(removed)
      }
    } else {
      outputLines.append(line)
    }
  }
  return outputLines.joined(separator:"\n")
}

func Log(_ message : String) {
  FileHandle.standardError.write((message + "\n").data(using:.utf8)!)
}

func main() throws {

  // initialize template engine and add custom filters
  let ext = Extension()
  ext.registerFilter("call") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 3,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String,
      let method = arguments[2] as? String else {
        throw TemplateSyntaxError("call filter received invalid arguments, expected (package, service, method), got: \(arguments)")
    }
    return try serviceMethodName(forPackage: package, service: service, method: method) + "Call"
  }
  ext.registerFilter("session") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 3,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String,
      let method = arguments[2] as? String else {
        throw TemplateSyntaxError("session filter received invalid arguments, expected (package, service, method), got: \(arguments)")
    }
    return try serviceMethodName(forPackage: package, service: service, method: method) + "Session"
  }
  ext.registerFilter("path") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 3,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String,
      let method = arguments[2] as? String else {
        throw TemplateSyntaxError("path filter received invalid arguments, expected (package, service, method), got: \(arguments)")
    }
    return try pathName(forPackage: package, service: service, method: method)
  }
  ext.registerFilter("provider") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("provider filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service) + "Provider"
  }
  ext.registerFilter("clienterror") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("clienterror filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service) + "ClientError"
  }
  ext.registerFilter("serviceclass") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("serviceclass filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service) + "Service"
  }
  ext.registerFilter("servererror") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("servererror filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service) + "ServerError"
  }
  ext.registerFilter("server") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("server filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service) + "Server"
  }
  ext.registerFilter("service") { (value: Any?, arguments: [Any?]) in
    guard
      arguments.count == 2,
      let package = arguments[0] as? String,
      let service = arguments[1] as? String
      else {
        throw TemplateSyntaxError("service filter received invalid arguments, expected (package, service), got: \(arguments)")
    }
    return try serviceName(forPackage: package, service: service)
  }
  ext.registerFilter("protoMessageType") { (value: Any?) in
    guard
      let typeName = value as? String
      else {
        throw TemplateSyntaxError("protoMessageType filter received invalid value, expected type name string, got: \(value.debugDescription)")
    }
    return protoMessageName(typeName)
  }
  ext.registerFilter("lowercaseFirst") { (value: Any?) in
    guard let string = value as? String else {
      return value
    }
    return string.lowercaseFirst
  }
  let templateEnvironment = Environment(loader: InternalLoader(),
                                        extensions:[ext])

  // initialize responses
  var response = Google_Protobuf_Compiler_CodeGeneratorResponse()
  var log = ""

  // read plugin input
  let rawRequest = try Stdin.readall()
  let request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: rawRequest)

  var generatedFileNames = Set<String>()
  
  // process each .proto file separately
  for protoFile in request.protoFile {

    let package = protoFile.package

    // log info about the service
    log += "File \(protoFile.name)\n"
    for service in protoFile.service {
      log += "Service \(service.name)\n"
      for method in service.method {
        log += " Method \(method.name)\n"
        log += "  input \(method.inputType)\n"
        log += "  output \(method.outputType)\n"
        log += "  client_streaming \(method.clientStreaming)\n"
        log += "  server_streaming \(method.serverStreaming)\n"
      }
      log += " Options \(service.options)\n"
    }

    // generate separate implementation files for client and server
    if protoFile.service.count > 0 {
      let context = [
        "protoFile": [
          "name": protoFile.name,
          "package": protoFile.package,
          "service": protoFile.service.map { 
            [
              "name": $0.name,
              "method": $0.method.map { [
                "name": $0.name,
                "input": $0.inputType,
                "output": $0.outputType,
                "clientStreaming": $0.clientStreaming,
                "serverStreaming": $0.serverStreaming
              ] },
            ] 
          },
        ]
      ]

      do {
        let clientFileName = package + ".client.pb.swift"
        if !generatedFileNames.contains(clientFileName) {
          generatedFileNames.insert(clientFileName)
          let clientcode = try templateEnvironment.renderTemplate(name:"client.pb.swift",
            context: context)
          var clientfile = Google_Protobuf_Compiler_CodeGeneratorResponse.File()
          clientfile.name = clientFileName
          clientfile.content = stripMarkers(clientcode)
          response.file.append(clientfile)
        }

        let serverFileName = package + ".server.pb.swift"
        if !generatedFileNames.contains(serverFileName) {
          generatedFileNames.insert(serverFileName)
          let servercode = try templateEnvironment.renderTemplate(name:"server.pb.swift",
            context: context)
          var serverfile = Google_Protobuf_Compiler_CodeGeneratorResponse.File()
          serverfile.name = serverFileName
          serverfile.content = stripMarkers(servercode)
          response.file.append(serverfile)
        }
      } catch (let error) {
        NSLog("Error: \(error)")
        log += "ERROR: \(error)\n"
      }
    }
  }

  log += "\(request)"

  // add the logfile to the code generation response
  var logfile = Google_Protobuf_Compiler_CodeGeneratorResponse.File()
  logfile.name = "swiftgrpc.log"
  logfile.content = log
  response.file.append(logfile)

  // return everything to the caller
  let serializedResponse = try response.serializedData()
  Stdout.write(bytes: serializedResponse)
}

do {
	try main()	
} catch (let error) {
	Log("ERROR: \(error)")	
}
