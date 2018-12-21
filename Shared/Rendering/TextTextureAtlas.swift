//
//  FontTextureAtlas.swift
//  MetalCity
//
//  Created by Andy Qua on 21/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit
import CoreGraphics

class TextItem {
    var text : String = ""
    var bl = float2(0, 0)
    var br = float2(1, 0)
    var tl = float2(0, 1)
    var tr = float2(1, 1)
}

class TextTextureAtlas {
    
    var textItems = [TextItem]()
    var device:MTLDevice
    
    var texture : MTLTexture!
    init(device:MTLDevice) {
        self.device = device
    }
    
    func buildAtlas() {
        let size = CGSize(width:512, height:512)
        let image = Image.createImageFromDrawing( size:size, doDrawing: { (ctx) in
            
            // Draw text
            var i : CGFloat = 0
            let nrRows : CGFloat = 12
            let logoHeight : CGFloat = size.height/nrRows
            while i < size.height {
                let string = "MyLogo\(i)"
                let attrs = [NSAttributedString.Key.font: Font(name: "HelveticaNeue", size: 36)!, NSAttributedString.Key.strokeColor: Color.white, NSAttributedString.Key.foregroundColor: Color.white]
                string.draw(with: CGRect(x: 2, y: i, width: 448, height: logoHeight), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                let textSize = string.size(withAttributes:attrs)
                
                let ti = TextItem()
                ti.text = string
                ti.bl = float2(Float(2/size.width), Float(i/size.height))
                ti.br = float2(Float(2/size.width), Float((i + textSize.width)/size.height))
                ti.tl = float2(Float((2+textSize.height)/size.width), Float(i/size.height))
                ti.tr = float2(Float((2+textSize.height)/size.width), Float((i + textSize.width)/size.height))
                
                textItems.append(ti)
                
                i += logoHeight
            }
            /*
             #define LOGO_RESOLUTION       512
             #define LOGO_ROWS             16
             #define LOGO_SIZE             (1.0f / LOGO_ROWS)
             #define LOGO_PIXELS           (LOGO_RESOLUTION / LOGO_ROWS)
             #define FONT_SIZE           (LOGO_PIXELS - LOGO_PIXELS / 8)
             RenderPrint (render_width / 2 - LOGO_PIXELS, render_height / 2 + LOGO_PIXELS, 0, glRgba (0.5f), "%1.2f%%", EntityProgress () * 100.0f);
             */
        })
        
        if let image = image {
            texture = TextureManager.instance.imageToTexture(image: image, named:"Logos", device: device)
        }
    }
}
