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
    
    private let fontNames = ["Copperplate","KohinoorTelugu-Regular","Thonburi","GillSans","AppleSDGothicNeo-UltraLight","MarkerFelt-Thin","HelveticaNeue-Light","HelveticaNeue","ArialRoundedMTBold","ChalkboardSE-Regular","PingFangTC-Regular","Avenir-Medium","AcademyEngravedLetPlain","Futura-Medium","PartyLetPlain","Chalkduster","Helvetica","SnellRoundhand","AmericanTypewriter","Menlo-Bold"]
    
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
        let name_num = randomInt(logoName.count)
        let prefix_num = randomInt(logoPrefix.count)
        let suffix_num = randomInt(logoSuffix.count)
        
        let string : String
        if flipCoinIsHeads() {
            string = "\(logoPrefix[prefix_num])\(logoName[name_num])"
        } else {
            string = "\(logoName[name_num])\(logoSuffix[suffix_num])"
        }
        return string

    }
    
    // Now well :
    // Motors LLC using PartyLetPlain
    // Superior Med using DamascusLight
    // Unity Industrial using PingFangTC-Regular
    // Media.com using DamascusLight

    func buildAtlas() {
        let size = CGSize(width:512, height:512)
        let image = Image.createImageFromDrawing( size:size, doDrawing: { (ctx) in
            
//            var names = ["Medicalco", "Motors LLC", "Superior Med", "Unity Industrial", "Media.com", "END" ]
//            var fonts = ["PartyLetPlain", "PartyLetPlain", "PartyLetPlain", "PingFangTC-Regular", "PartyLetPlain", "Menlo-Bold"]
            // Motors LLC using PartyLetPlain
            // Superior Med using DamascusLight
            // Unity Industrial using PingFangTC-Regular
            // Media.com using DamascusLight
            
            ctx.setFillColor(red: 0.075, green: 0.075, blue: 0.075, alpha: 1)
            ctx.fill(CGRect(x:0, y:0, width:size.width, height:size.height))

            // Draw text
            var i : CGFloat = 0
            print( "Generating building names..." )
            while i < size.height {
                let string = generateName()
                let fontName = fontNames.randomElement()!
//            for j in 0 ..< names.count {
//                let string = names[j]
//                let fontName = fonts[j]

                print( "   \(string) using \(fontName)" )

                let attrs = [.font: Font(name:fontName, size: 24)!, .strokeColor: Color.white, .foregroundColor: Color.white]
                let textSize = string.size(withAttributes:attrs)
                
                if i + textSize.height > size.height {
                    break
                }

                
                let textRect = CGRect(x: 2, y: i, width: textSize.width, height: textSize.height)
                string.draw(with: textRect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                
                // Outline text - useful for debugging font drawing issues
//                ctx.setStrokeColor(Color.white.cgColor)
//                ctx.stroke(textRect)
                
                let ti = TextItem()
                ti.text = string
                ti.bl = float2(Float(2/size.width), Float(i/size.height))
                ti.br = float2(Float(2/size.width), Float((i + textSize.height)/size.height))
                ti.tl = float2(Float((2+textSize.width)/size.width), Float(i/size.height))
                ti.tr = float2(Float((2+textSize.width)/size.width), Float((i + textSize.height)/size.height))
                
                textItems.append(ti)
                
                i += textSize.height
                
            }
        })
        
        if let image = image {
            texture = TextureManager.instance.imageToTexture(image: image, named:"Logos", device: device, flip:false)
        }
    }
}
