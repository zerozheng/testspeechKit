//
//  File.swift
//  testspeechKit
//
//  Created by zero on 16/10/18.
//  Copyright © 2016年 zero. All rights reserved.
//

import Foundation

protocol Then {}

extension Then where Self: Any {
    func then(block:(inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}

extension Then where Self: AnyObject {
    func then(block:(Self) -> Void) -> Self {
        block(self)
        return self
    }
}

extension NSObject: Then {}
