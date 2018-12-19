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
    
    public convenience init?(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
    
    public func pngData() -> Data? {
        let cgRef = self.cgImage!
        let newRep = NSBitmapImageRep(cgImage: cgRef)
        let data = newRep.representation(using: .png, properties: [:])

        return data
    }
}
#else
import UIKit
public typealias Image = UIImage
#endif


extension Image {
    class func createImageFromDrawing( size: CGSize, doDrawing : ((CGContext)->()) ) -> Image? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        doDrawing(context!)
        
        let image = context!.makeImage()
        return Image(cgImage: image!)
    }

    
    class func createImageFromDrawing2( size: CGSize, doDrawing : ((CGContext)->()) ) -> Image? {
#if os(OSX)
        let im = NSImage.init(size: size)
        
        let rep = NSBitmapImageRep.init(bitmapDataPlanes: nil,
                                        pixelsWide: Int(size.width),
                                        pixelsHigh: Int(size.height),
                                        bitsPerSample: 8,
                                        samplesPerPixel: 4,
                                        hasAlpha: true,
                                        isPlanar: false,
                                        colorSpaceName: NSColorSpaceName.calibratedRGB,
                                        bytesPerRow: 0,
                                        bitsPerPixel: 0)
        
        
        im.addRepresentation(rep!)
        im.lockFocus()
        
        let ctx = NSGraphicsContext.current!.cgContext
#else
        UIGraphicsBeginImageContext(size)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
#endif
        
        doDrawing( ctx )
        
#if os(OSX)
        im.unlockFocus()
        let image = im
#else
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
#endif
        
        return image
    }
}
