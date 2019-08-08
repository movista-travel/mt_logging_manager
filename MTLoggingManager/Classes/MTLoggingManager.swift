//
//  MTLoggingManager.swift
//  MTLoggingManager
//
//  Created by Alex Khodko on 08.08.2019.
//

import Foundation
import Crashlytics
import SwiftyBeaver

//5065
public final class MTLoggingManager {
    
    private let crashlytics: Crashlytics
    private let beaver: SwiftyBeaver.Type
    private let fileManager: FileManager
    private let kLogsFolderName = "Logs"
    private lazy var folder = fileManager.containerURL(forSecurityApplicationGroupIdentifier: kApplicationGroupID)?.appendingPathComponent(kLogsFolderName)
    
    private var fileNameFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd_MM_yyyy"
        return  dateFormatter
    }
    
    private var timeStampFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
    
   public enum Environment {
        case production
        case stage
        case test
    }
    
    private let environment: Environment
    private let kApplicationGroupID: String
    
    public static func create(environment: Environment, kApplicationGroupID: String) {
        MTLoggingManager.shared = MTLoggingManager(environment: environment, kApplicationGroupID: kApplicationGroupID)
    }
    
    init(beaver: SwiftyBeaver.Type = SwiftyBeaver.self,
         crashlytics: Crashlytics = Crashlytics.sharedInstance(),
         fileManager: FileManager = FileManager.default,
         environment: Environment,
         kApplicationGroupID: String) {
        self.environment = environment
        self.kApplicationGroupID = kApplicationGroupID
        self.beaver = beaver
        self.crashlytics = crashlytics
        self.fileManager = fileManager
        if environment == .test || environment == .stage {
            let console = ConsoleDestination()
            console.format = "$DHH:mm:ss$d $C$L$c - $M"
            self.beaver.addDestination(console)
        }
        DispatchQueue.global().async {
            if let folder = self.folder {
                do {
                    try fileManager.createDirectory(atPath: folder.path, withIntermediateDirectories: true, attributes: nil)
                    let fileList = try fileManager.contentsOfDirectory(atPath: folder.path).compactMap {
                        $0.split(separator: ".").first
                        }.map {
                            String($0)
                    }
                    let dateFormatter = self.fileNameFormatter
                    let now = Date()
                    for filename in fileList {
                        if let date = dateFormatter.date(from: filename) {
                            if now.timeIntervalSince(date) > 60 * 60 * 24 * 4 {
                                let fileURL = folder.appendingPathComponent(filename + ".txt")
                                try fileManager.removeItem(atPath: fileURL.path)
                            }
                        } else {
                            let fileURL = folder.appendingPathComponent(filename + ".txt")
                            try fileManager.removeItem(atPath: fileURL.path)
                        }
                    }
                } catch let error {
                    let loggableError = MTLoggableError(error: error, errorCode: 5002)
                    self.log(error: loggableError)
                }
            } else {
                let error = MTLoggerError.unhandledState(description: "missing logs folder")
                let loggableError = MTLoggableError(error: error, errorCode: 5003)
                self.log(error: loggableError)
            }
            
            if environment == .test {
                self.healthCheckLogs()
            }
        }
    }
    
    public static var shared: MTLoggingManager!

    private func healthCheckLogs() {
        print("health check logs:", logs)
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
            self.healthCheckLogs()
        }
    }
    
    private func writeToLog(message: inout String) {
        message = timeStampFormatter.string(from: Date()) + " " + message
        DispatchQueue.global().async { [message] in
            do {
                if let folder = self.folder {
                    let dateFormatter = self.fileNameFormatter
                    let now = Date()
                    let fileName = dateFormatter.string(from: now) + ".txt"
                    let fileURL = folder.appendingPathComponent(fileName)
                    
                    if !self.fileManager.fileExists(atPath: fileURL.path) {
                        try "".write(to: fileURL, atomically: false, encoding: .utf8)
                    }
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    if let utf8 = message.data(using: .utf8) {
                        fileHandle.write(utf8)
                    }
                    fileHandle.closeFile()
                } else {
                    let error = MTLoggerError.unhandledState(description: "missing logs folder")
                    let loggableError = MTLoggableError(error: error, errorCode: 5000)
                    self.crashlytics.recordError(error, withAdditionalUserInfo: ["message": loggableError.errorDescription ?? loggableError])
                    if self.environment == .test || self.environment == .stage {
                        self.beaver.error(loggableError.errorDescription ?? loggableError)
                    }
                }
            } catch let error {
                let loggableError = MTLoggableError(error: error, errorCode: 5001)
                self.crashlytics.recordError(error, withAdditionalUserInfo: ["message": loggableError.errorDescription ?? loggableError])
                if self.environment == .test || self.environment == .stage {
                    self.beaver.error(loggableError.errorDescription ?? loggableError)
                }
            }
        }
    }
}

extension MTLoggingManager: IMTLogsProvider {
    public var logs: [String : Data] {
        var currentLogs: [String: Data] = [:]
        do {
            if let folder = folder {
                let fileList = try fileManager.contentsOfDirectory(atPath: folder.path)
                for fileName in fileList {
                    let fileURL = folder.appendingPathComponent(fileName)
                    let data = try Data(contentsOf: fileURL)
                    currentLogs[fileName] = data
                }
            } else {
                let error = MTLoggerError.unhandledState(description: "missing logs folder")
                let loggableError = MTLoggableError(error: error, errorCode: 5004)
                log(error: loggableError)
            }
        } catch let error {
            let loggableError = MTLoggableError(error: error, errorCode: 5005)
            log(error: loggableError)
        }
        return currentLogs
    }
}

extension MTLoggingManager: IMTLoggingManager {
    public func log(error: MTLoggableError) {
        DispatchQueue.global().async {
            let nError = error as NSError
            let e = NSError(domain: nError.domain, code: error.errorCode, userInfo: [
                NSLocalizedDescriptionKey: error.message,
                ])
            var message = error.errorDescription ?? "\(error)"
            self.crashlytics.recordError(e, withAdditionalUserInfo: ["message": message])
            self.writeToLog(message: &message)
            if self.environment == .test || self.environment == .stage {
                self.beaver.error(error.errorDescription ?? error)
            }
        }
    }
    
    public func log(message: MTLoggableMessage) {
        DispatchQueue.global().async {
            if self.environment == .test || self.environment == .stage {
                var message = message.message
                self.writeToLog(message: &message)
                self.beaver.info(message)
            }
        }
    }
}

public protocol IMTLoggingManager: class {
    func log(error: MTLoggableError)
    func log(message: MTLoggableMessage)
}

public protocol IMTLogsProvider: class {
    var logs: [String : Data] { get }
}

public struct MTLoggableError: Error {
    let message: String
    let errorCode: Int
    
    public init(error: Error, file: String = #file, function: String = #function, line: Int = #line, errorCode: Int) {
        let fileName: String
        if let name = file.split(separator: "/").last {
            fileName = String(name)
        } else {
            fileName = file
        }
        
        self.message = "\(function) \(fileName):\(line)\n\(error.localizedDescription)\n----------------\n"
        self.errorCode = errorCode
    }
}

extension MTLoggableError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(message, comment: "")
    }
}

public enum MTLoggerError: Error {
    case unhandledState(description: String)
}

extension MTLoggerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unhandledState(let description):
            return description
        }
    }
}

