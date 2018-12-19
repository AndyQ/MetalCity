//
//  TextureManager.swift
//  MetalCity
//
//  Created by Andy Qua on 17/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation
import MetalKit

class TextureManager {
    public static let instance = TextureManager()
    
    var textures = [TextureType:MTLTexture]()
    
    private init() {
        
    }
    
    func createTextures( device:MTLDevice ) {
        createStreetlightTexture(device:device)
        createBuildingTextures(device:device)
    }
    
    func createStreetlightTexture(device:MTLDevice) {
        let t = imageToTexture(imageNamed: "light", device: device)
        textures[.light] = t
    }
    
    func imageToTexture(imageNamed: String, device: MTLDevice) -> MTLTexture {
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        
        let image = Image(named: imageNamed)!
        
        let width = image.size.width
        let height = image.size.height
        let bounds = CGRect(x:0, y:0, width:width, height:height)
        
        let rowBytes = Int(width) * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: rowBytes, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.clear( bounds)
        context.translateBy(x: width, y: height)
        context.scaleBy(x: -1, y: -1)
        context.draw(image.cgImage!, in: bounds)
        
        let texDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(width), height: Int(height), mipmapped: false)
        
        let texture = device.makeTexture(descriptor: texDescriptor)!
        texture.label = imageNamed
        
        let pixelsData = context.data!
        
        let region = MTLRegionMake2D(0, 0, Int(width), Int(height))
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: rowBytes)
        
        return texture
    }

    
    func createBuildingTextures(device:MTLDevice) {
        let buildingTextures : [TextureType] = [.building1, .building2, .building3, .building4, .building5, .building6, .building7, .building8, .building9]
        
        for t in buildingTextures {
            guard let image = createBuildingTexture(textureType: t) else { print( "Invalid image created for t" ); continue }
            
            guard let data = image.pngData() else { return }
            let loader = MTKTextureLoader(device: device)
            do {
                let texture = try loader.newTexture(data: data, options: nil)
                textures[t] = texture
            }
            catch let error {
                fatalError("\(error)")
            }
        }
    }
    
    func createBuildingTexture( textureType: TextureType ) -> Image? {
        
        let size = CGSize(width:256, height:256);

        let image = Image.createImageFromDrawing( size:size, doDrawing: { [unowned self] (ctx) in
            ctx.setFillColor( Color.black.cgColor )
            ctx.fill(CGRect( x:0, y:0, width:size.width, height:size.height ) )
            
            self.drawBuildingTexture( context: ctx, size:Int(size.width), textureType: textureType )

        })

        return image
    }

    func drawBuildingTexture( context ctx : CGContext, size:Int, textureType: TextureType ) {
        var run = 0
        var run_length = 0
        var lit_density = 0
        var color = float4(0,0,0,1)
        var lit = true
        let segment_size = (size*2) / SEGMENTS_PER_TEXTURE
        
        for y in 0 ..< SEGMENTS_PER_TEXTURE {
            //Every few floors we change the behavior
            if (y % 8) != 0 {
                run = 0
                run_length = randomValue( 9) + 2
                lit_density = 2 + randomValue( 2) + randomValue( 2)
                lit = false
            }
            for x in 0 ..< SEGMENTS_PER_TEXTURE {
                //if this run is over reroll lit and start a new one
                if run < 1 {
                    run = randomValue( run_length)
                    lit = randomValue( lit_density) == 0
                }
                
                if lit {
                    let luminance : Float = 0.5 + Float(randomValue() % 128) / 256.0
                    color = float4( RANDOM_COLOR_SHIFT+luminance, RANDOM_COLOR_SHIFT+luminance, RANDOM_COLOR_SHIFT+luminance, 1.0)
                } else {
                    let v = Float(randomValue() % 40) / 256.0
                    color = float4( v, v, v, 1 )
                }
                
                self.drawWindow( context: ctx, x:x * segment_size, y:y * segment_size, size:segment_size, color:color, textureId:textureType)
                run -= 1
            }
        }
    }
    
    func drawWindow( context ctx:CGContext, x:Int, y:Int, size:Int, color:float4, textureId: TextureType  ) {
        
        let margin = size / 3;
        let half = size / 2;

        switch (textureId)
        {
        case .building1: //filled, 1-pixel frame
            drawRect( context:ctx, left:x+1, top:y+1, right:x+size-1, bottom:y+size-1, color:color)
            break;
        case .building2: //vertical
            drawRect( context:ctx, left:x+margin, top:y+1, right:x+size-margin, bottom:y+size-1, color:color)
            break;
        case .building3: //side-by-side pair
            drawRect( context:ctx, left:x+1, top:y+1, right:x+half-1, bottom:y+size-margin, color:color)
            drawRect( context:ctx, left:x+half+1, top:y+1, right:x+size-1, bottom:y+size-margin, color:color)
            break;
        case .building4: //windows with blinds
            drawRect( context:ctx, left:x+1, top:y+1, right:x+size-1, bottom:y+size-1, color:color)
            let i = randomValue( size - 2);
            
            drawRect( context:ctx, left:x+1, top:y+1, right:x+size-1, bottom:y+i+1, color:color * 0.3)
            
            break;
        case .building5: //vert stripes
            drawRect( context:ctx, left:x+1, top:y+1, right:x+size-1, bottom:y+size-1, color:color)
            drawRect( context:ctx, left:x+margin, top:y+1, right:x+margin, bottom:y+size-1, color:color*0.7)
            drawRect( context:ctx, left:x+size-margin-1, top:y+1, right:x+size-margin-1, bottom:y+size-1, color:color*0.3)
            break;
        case .building6: //wide horz line
            drawRect( context:ctx, left:x+1, top:y+1, right:x+size-1, bottom:y+size-1, color:color)
            break;
        case .building7: //4-pane
            drawRect( context:ctx, left:x+2, top:y+1, right:x+size-1, bottom:y+size-margin, color:color)
            drawRect( context:ctx, left:x+2, top:y+half, right:x+size-1, bottom:y+half, color:color*0.2)
            drawRect( context:ctx, left:x+half, top:y+1, right:x+half, bottom:y+size-1, color:color*0.2)
            break;
        case .building8: // Single narrow window
            drawRect( context:ctx, left:x+half-1, top:y+1, right:x+half+1, bottom:y+size-margin, color:color)
            break;
        case .building9: //horizontal
            drawRect( context:ctx, left:x+1, top:y+margin, right:x+size-1, bottom:y+size-margin-1, color:color)
            break;
        default:
            return
        }

    }
    
    func drawRect( context ctx:CGContext, left:Int, top:Int, right:Int, bottom:Int, color:float4 ) {
        
        // lighten up the color a bit
        let c = Color(red: CGFloat(color.x+0.1), green: CGFloat(color.y+0.1), blue: CGFloat(color.z+0.1), alpha: 1)
        ctx.setFillColor(c.cgColor)
        ctx.setAlpha(1)
        
        if left == right {
            //in low resolution, a "rect" might be 1 pixel wide
            ctx.fill( CGRect( x:left, y:top, width:1, height:bottom-top) )
        } else if top == bottom {
            //in low resolution, a "rect" might be 1 pixel wide
            ctx.fill( CGRect( x:left, y:top, width:right-left, height:1) )
        } else {
            let average = (color.x + color.y + color.z) / 3.0
            let bright = average > 0.5
            let potential = Int(average * 255.0)
            
            // draw one of those fancy 2-dimensional rectangles
            ctx.fill( CGRect( x:left, y:top, width:right-left, height:bottom-top) )
            
            
            if bright {
                for i in left+1 ..< right-1 {
                    for j in top+1 ..< bottom {
                        let hue = 0.2 + CGFloat(randomValue(100)) / 300.0 + CGFloat(randomValue(100)) / 300.0 + CGFloat(randomValue(100)) / 300.0
                        var color_noise = Color( hue:hue, saturation:0.4, brightness:0.5, alpha:1).rgba()!
                        color_noise.w = Float(randomValue(potential)) / 144.0
                        
                        let c = Color(red: CGFloat(color_noise.x), green: CGFloat(color_noise.y), blue: CGFloat(color_noise.z), alpha: CGFloat(color_noise.w))
                        
                        ctx.setFillColor(c.cgColor)
                        ctx.setAlpha(CGFloat(color_noise.w))
                        ctx.fill(CGRect( x:i, y:j, width:1, height:1 ) );
                    }
                }
            }
            
            var height = (bottom - top) + (randomValue(3) - 1) + (randomValue(3) - 1);
            for i in left ..< right {
                if randomValue(6) == 0 {
                    height = bottom - top;
                    height = randomValue( height)
                    height = randomValue( height)
                    height = randomValue( height)
                    height = ((bottom - top) + height) / 2;
                }
                for _ in 0 ..< 1 {
                    let a = CGFloat(randomValue(256)) / 256.0
                    let c = Color(red: 0, green: 0, blue: 0, alpha: a)
                    ctx.setFillColor(c.cgColor)
                    ctx.setAlpha(CGFloat(a))
                    ctx.fill(CGRect( x:i, y:bottom - height, width:1, height:height ) );
                }
            }
        }
    }
}
