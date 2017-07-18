//
//  OpenWeatherNetworkOperation.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - OpenWeatherOperationRequestor Protocol
protocol OpenWeatherOperationRequestor
{
    var request: URLRequest { get }
}

// MARK: - OpenWeatherNetworkOperationProcessor Protocol
protocol OpenWeatherOperationProcessor
{
    func handle(error: NSError)
    func process(data: Data)
}

// MARK: - OpenWeatherOperationError Enum
enum OpenWeatherOperationError: Int
{
    case invalidStatus = 900
    case response
    case jsonParse
}

// MARK: - OpenWeatherNetworkOperation
class OpenWeatherOperation: Operation
{
    fileprivate let incomingData = NSMutableData()
    fileprivate var sessionTask: URLSessionTask?
    fileprivate lazy var session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }()
    fileprivate var processor: OpenWeatherOperationProcessor
    fileprivate let requestor: OpenWeatherOperationRequestor
    
    var _finished: Bool = false
    override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    init(processor: OpenWeatherOperationProcessor, requestor: OpenWeatherOperationRequestor)
    {
        self.processor = processor
        self.requestor = requestor
        super.init()
    }
    
    override func start()
    {
        if isCancelled {
            isFinished = true
            return
        }
        sessionTask = session.dataTask(with: requestor.request)
        sessionTask!.resume()
    }
}

// MARK: - NSURLSessionDataDelegate Implementation
extension OpenWeatherOperation: URLSessionDataDelegate
{
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        if isCancelled {
            sessionTask?.cancel()
            isFinished = true
            completionHandler(.cancel)
            return
        }
        if let response = response as? HTTPURLResponse {
            if !(response.statusCode ~= 200 ..< 300) {
                let invalidStatusProcessor = InvalidStatusProcessor(processor: processor)
                processor = invalidStatusProcessor
            }
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        if isCancelled {
            sessionTask?.cancel()
            isFinished = true
            return
        }
        incomingData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        defer { isFinished = true }
        if isCancelled {
            sessionTask?.cancel()
            return
        }
        guard error == nil else {
            processor.handle(error: error! as NSError)
            return
        }
        processor.process(data: NSData(data: incomingData as Data) as Data)
    }
}

// MARK: - InvalidStatusProcessor
private class InvalidStatusProcessor: OpenWeatherOperationProcessor
{
    let processor: OpenWeatherOperationProcessor
    init(processor: OpenWeatherOperationProcessor)
    {
        self.processor = processor
        NSLog("Invalid status detected")
    }
    
    func handle(error: NSError)
    {
        processor.handle(error: error)
    }
    
    func process(data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: OpenWeatherOperationError.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
            return
        }
        if let message = json["message"] as? String {
            let userInfo = [NSLocalizedDescriptionKey: message]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: OpenWeatherOperationError.invalidStatus.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        else {
            let userInfo = [NSLocalizedDescriptionKey: "Invalid status received."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: OpenWeatherOperationError.invalidStatus.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object",
                NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "InvalidStatusProcessor.parseJson",
                code: OpenWeatherOperationError.response.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
}