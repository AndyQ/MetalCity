//
//  Cube
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

class Cube {
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
