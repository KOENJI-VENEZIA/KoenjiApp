//
//  NormalizedTimeCache.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//
import SwiftUI

class NormalizedTimeCache {
    private var cache: [String: (startTime: Date, endTime: Date)] = [:]
    private let queue = DispatchQueue(label: "com.app.NormalizedTimeCache", attributes: .concurrent)

    func get(key: String) -> (startTime: Date, endTime: Date)? {
        var result: (startTime: Date, endTime: Date)?
        queue.sync {
            result = cache[key]
        }
        return result
    }

    func set(key: String, value: (startTime: Date, endTime: Date)) {
        queue.async(flags: .barrier) {
            self.cache[key] = value
        }
    }
}
