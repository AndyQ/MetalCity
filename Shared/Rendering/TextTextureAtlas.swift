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
    private let logoPrefix = ["i", "Green ", "Mega", "Super ","Omni", "e", "Hyper", "Global ", "Vital", "Next ", "Pacific ", "Metro", "Unity ", "G-", "Trans", "Infinity ", "Superior ", "Monolith ", "Best ", "Atlantic ", "First ", "Union ", "National "]
    
    
    private let logoName = ["Biotic", "Info", "Data", "Solar", "Aerospace", "Motors", "Nano", "Online", "Circuits", "Energy", "Med", "Robotic", "Exports", "Security", "Systems", "Financial", "Industrial", "Media", "Materials", "Foods", "Networks", "Shipping", "Tools", "Medical", "Publishing", "Enterprises", "Audio", "Health", "Bank", "Imports", "Apparel", "Petroleum", "Studios"]
    
    private let logoSuffix  = ["Corp", " Inc.", "co", "World", ".com", " USA", " Ltd.", "Net", " Tech", " Labs", " Mfg", " UK", " Unlimited", " One", " LLC"]
    
    private let fontNames = ["Copperplate","KohinoorTelugu-Regular","Thonburi","GillSans","AppleSDGothicNeo-UltraLight","MarkerFelt-Thin","HelveticaNeue-Light","HelveticaNeue","ArialRoundedMTBold","ChalkboardSE-Regular","PingFangTC-Regular","DamascusLight","Avenir-Medium","AcademyEngravedLetPlain","Futura-Medium","PartyLetPlain","Chalkduster","Helvetica","SnellRoundhand","AmericanTypewriter","Menlo-Bold"]
    
    var textItems = [TextItem]()
    var device:MTLDevice
    
    var texture : MTLTexture!
    var nrItems : Int {
        get { return textItems.count }
    }
    
    
    init(device:MTLDevice) {
        self.device = device
    }
    
    func generateName() -> String {
        let name_num = randomValue(logoName.count)
        let prefix_num = randomValue(logoPrefix.count)
        let suffix_num = randomValue(logoSuffix.count)
        
        let string : String
        if flipCoinIsHeads() {
            string = "\(logoPrefix[prefix_num])\(logoName[name_num])"
        } else {
            string = "\(logoName[name_num])\(logoSuffix[suffix_num])"
        }
        return string

    }
    
    func buildAtlas() {
        let size = CGSize(width:512, height:512)
        let image = Image.createImageFromDrawing( size:size, doDrawing: { (ctx) in
            
            // Draw text
            var i : CGFloat = 0
            let nrRows : CGFloat = 16
            let logoHeight : CGFloat = size.height/nrRows
            while i < size.height {
                let string = generateName()
                let fontName = fontNames.randomElement()!
                let attrs = [NSAttributedString.Key.font: Font(name:fontName, size: 24)!, NSAttributedString.Key.strokeColor: Color.white, NSAttributedString.Key.foregroundColor: Color.white]
                let textSize = string.size(withAttributes:attrs)
                string.draw(with: CGRect(x: 2, y: i, width: textSize.width, height: textSize.height), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                
                let ti = TextItem()
                ti.text = string
                ti.bl = float2(Float(2/size.width), Float(i/size.height))
                ti.br = float2(Float(2/size.width), Float((i + textSize.height)/size.height))
                ti.tl = float2(Float((2+textSize.width)/size.width), Float(i/size.height))
                ti.tr = float2(Float((2+textSize.width)/size.width), Float((i + textSize.height)/size.height))
                
                textItems.append(ti)
                
                i += textSize.height
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
            texture = TextureManager.instance.imageToTexture(image: image, named:"Logos", device: device, flip:false)
        }
    }
}
