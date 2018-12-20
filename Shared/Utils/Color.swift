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
    public convenience init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.init(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
#else
import UIKit
public typealias Color = UIColor
#endif

extension Color {
    
    public convenience init(rgba:float4) {
        self.init(red:CGFloat(rgba.x), green:CGFloat(rgba.y), blue:CGFloat(rgba.z), alpha:CGFloat(rgba.w))
    }
    
#if !os(OSX)
    
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

    public var hueComponent: CGFloat {
        var value: CGFloat = 0.0
        getHue(&value, saturation: nil, brightness: nil, alpha: nil)
        return value
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
    
    @objc func debugQuickLookObject() -> AnyObject {
#if os(OSX)
        return self as NSColor
#else
        return self as UIColor
#endif
    }

}
