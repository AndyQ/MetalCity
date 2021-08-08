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

    public convenience init(rgba:SIMD4<Float>) {
        self.init(red:CGFloat(rgba.x), green:CGFloat(rgba.y), blue:CGFloat(rgba.z), alpha:CGFloat(rgba.w))
    }

#if !os(OSX)

    func rgba() -> SIMD4<Float> {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0
        self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        return SIMD4<Float>(Float(fRed), Float(fGreen), Float(fBlue), 1.0)
    }

    public var hueComponent: CGFloat {
        var value: CGFloat = 0.0
        getHue(&value, saturation: nil, brightness: nil, alpha: nil)
        return value
    }


#else

    func rgba() -> SIMD4<Float> {
        var fRed: CGFloat = 0
        var fGreen: CGFloat = 0
        var fBlue: CGFloat = 0
        var fAlpha: CGFloat = 0

        self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha)
        return SIMD4<Float>(Float(fRed), Float(fGreen), Float(fBlue), 1.0)
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
