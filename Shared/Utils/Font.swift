//
//  Font.swift
//  MetalCity
//
//  Created by Andy Qua on 21/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

#if os(OSX)

import AppKit
public typealias Font = NSFont
#else
import UIKit
public typealias Font = UIFont
#endif
