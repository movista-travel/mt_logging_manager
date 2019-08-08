//
//  MTLoggableMessage.swift
//  MTLoggingManager
//
//  Created by Alex Khodko on 08.08.2019.
//

import Foundation

public struct MTLoggableMessage {
    let message: String
    
    public init(message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName: String
        if let name = file.split(separator: "/").last {
            fileName = String(name)
        } else {
            fileName = file
        }
        
        self.message = "\(function) \(fileName):\(line)\n\(message)\n----------------\n"
    }
}
