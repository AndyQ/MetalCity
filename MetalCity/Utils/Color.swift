//
//  Color.swift
//  MetalCity
//
//  Created by Andy Qua on 19/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//


#if os(OSX)
import AppKit
public typealias Color = NSColor

extension NSColor {
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
#else
import UIKit
public typealias Color = UIColor
#endif

extension Color {
#if !os(OSX)
    
    public var alphaComponent: CGFloat {
        var value: CGFloat = 0.0
        getRed(nil, green: nil, blue: nil, alpha: &value)
        return value
    }
    func rgba() -> float4? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha : CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            
            return float4(Float(fRed), Float(fGreen), Float(fBlue), 1.0)
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
#else
    func rgba() -> float4? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha : CGFloat = 0
        self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        return float4(Float(fRed), Float(fGreen), Float(fBlue), 1.0)
    }

#endif
}
