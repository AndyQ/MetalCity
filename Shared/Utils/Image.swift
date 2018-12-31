//
//  Image.swift
//  MetalCity
//
//  Created by Andy Qua on 19/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

#if os(OSX)

import AppKit
public typealias Image = NSImage

extension Image {
    public var cgImage: CGImage! {
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    public convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }

    public func pngData() -> Data? {
        let newRep = NSBitmapImageRep(cgImage: self.cgImage!)
        return newRep.representation(using: .png, properties: [:])
    }
}
#else
import UIKit
public typealias Image = UIImage
#endif


extension Image {
    class func createImageFromDrawing(size: CGSize, doDrawing : ((CGContext)->())) -> Image? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        context!.setFillColor(Color.black.cgColor)
        context!.fill(CGRect(size:size))

        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        context!.concatenate(flipVertical)

#if os(OSX)
        let gc = NSGraphicsContext(cgContext:context!, flipped:true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gc
#else
        UIGraphicsPushContext(context!)
#endif
        doDrawing(context!)

#if os(OSX)
        NSGraphicsContext.restoreGraphicsState()
#else
        UIGraphicsPopContext()
#endif

        let image = context!.makeImage()
        return Image(cgImage: image!)
    }


    class func createImageFromDrawing2(size: CGSize, doDrawing : ((CGContext)->())) -> Image? {
#if os(OSX)
        let im = NSImage(size: size)

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: Int(size.width),
                                   pixelsHigh: Int(size.height),
                                   bitsPerSample: 8,
                                   samplesPerPixel: 4,
                                   hasAlpha: true,
                                   isPlanar: false,
                                   colorSpaceName: .calibratedRGB,
                                   bytesPerRow: 0,
                                   bitsPerPixel: 0)


        im.addRepresentation(rep!)
        im.lockFocus()

        let ctx = NSGraphicsContext.current!.cgContext
#else
        UIGraphicsBeginImageContext(size)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
#endif

        doDrawing(ctx)

#if os(OSX)
        im.unlockFocus()
        let image = im
#else
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
#endif

        return image
    }

    @objc func debugQuickLookObject() -> AnyObject {
#if os(OSX)
        return self as NSImage
#else
        return self as UIImage
#endif
    }

}
