//
//  Utils.swift
//  MetalCity
//
//  Created by Andy Qua on 16/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation
import GameKit

let TEXTURE_SIZE = 512
let SEGMENTS_PER_TEXTURE = 64
let ONE_SEGMENT : Float = 0.015625 //1.0 / Float(SEGMENTS_PER_TEXTURE)
let DEGREES_TO_RADIANS : Float = 0.017453292
let RADIANS_TO_DEGREES : Float = 57.29577951

let RANDOM_COLOR_SHIFT = Float(randomValue(10)) / 50.0
let RANDOM_COLOR_VAL = Float(randomValue(256)) / 256.0

func randomValue( ) -> Int{
    let i = abs(GKRandomSource.sharedRandom().nextInt())
    return i
}


var vals = [1,18,1,11,0,24,1,12,2,2,9,5,1,0,1,4,11,1,7]
func randomValue( _ range : Int) -> Int {
    //let i = vals.removeFirst()

    let i = GKRandomSource.sharedRandom().nextInt(upperBound: range)
    //print( i )
    return i
}

func getTickCount() -> UInt64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info);
        
    var ticks = mach_absolute_time()
    
    /* Convert to nanoseconds */
    ticks *= UInt64(info.numer)
    ticks /= UInt64(info.denom)
    
    return ticks/1000000
}

func flipCoinIsHeads() -> Bool {
    return GKRandomSource.sharedRandom().nextBool()
}

var light_colors : [Color] = [
    Color( hue:0.04, saturation:0.9,  brightness:0.93, alpha:1 ),   //Amber / pink
    Color( hue:0.055, saturation:0.95, brightness:0.93, alpha:1 ),  //Slightly brighter amber
    Color( hue:0.08, saturation:0.7,  brightness:0.93, alpha:1 ),   //Very pale amber
    Color( hue:0.07, saturation:0.9,  brightness:0.93, alpha:1 ),   //Very pale orange
    Color( hue:0.1, saturation: 0.9,  brightness:0.85, alpha:1 ),   //Peach
    Color( hue:0.13, saturation:0.9,  brightness:0.93, alpha:1 ),   //Pale Yellow
    Color( hue:0.15, saturation:0.9,  brightness:0.93, alpha:1 ),   //Yellow
    Color( hue:0.17, saturation:1.0,  brightness:0.85, alpha:1 ),   //Saturated Yellow
    Color( hue:0.55, saturation:0.9,  brightness:0.93, alpha:1 ),   //Cyan
    Color( hue:0.55, saturation:0.9,  brightness:0.93, alpha:1 ),   //Cyan - pale, almost white
    Color( hue:0.6, saturation: 0.9,  brightness:0.93, alpha:1 ),   //Pale blue
    Color( hue:0.65, saturation:0.9,  brightness:0.93, alpha:1 ),   //Pale Blue II, The Palening
    Color( hue:0.65, saturation:0.4,  brightness:0.99, alpha:1 ),   //Pure white. Bo-ring.
    Color( hue:0.65, saturation:0.0,  brightness:0.8, alpha:1 ),    //Dimmer white.
    Color( hue:0.65, saturation:0.0,  brightness:0.6, alpha:1 )    //Dimmest white.
]

func worldLightColor( _ index : Int ) -> float4 {
    let ci = index % light_colors.count
    return light_colors[ci].rgba()!
}
