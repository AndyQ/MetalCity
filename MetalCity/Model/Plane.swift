//
//  Plane.swift
//  MetalCity
//
//  Created by Andy Qua on 15/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

class Plane: NSObject {
    var hidden = false
    var position = vector_float4()
    var color = vector_float4()
    var scale = vector_float3()
    
    init( position: vector_float4, color: vector_float4, scale: vector_float3 = vector_float3(1) ) {
        self.position = position
        self.color = color
        self.scale = scale
    }

}
