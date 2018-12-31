//
//  BoundingBox.swift
//  MetalCity
//
//  Created by Andy Qua on 16/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

class BoundingBox {
    private let maxVal : Float = 999999999999999.9

    var minPoint : float3 = [0, 0, 0]
    var maxPoint : float3 = [0, 0, 0]

    init() {
        clear()

    }
    /*-----------------------------------------------------------------------------
     This will invalidate the bbox.
     -----------------------------------------------------------------------------*/
    func clear() {
        maxPoint = [-maxVal, -maxVal, -maxVal]
        minPoint = [maxVal, maxVal, maxVal]
    }

    /*-----------------------------------------------------------------------------
     Expand Bbox (if needed) to contain given point
     -----------------------------------------------------------------------------*/
    func include(point : float3) {
        minPoint.x = min(minPoint.x, point.x)
        minPoint.y = min(minPoint.y, point.y)
        minPoint.z = min(minPoint.z, point.z)
        maxPoint.x = max(maxPoint.x, point.x)
        maxPoint.y = max(maxPoint.y, point.y)
        maxPoint.z = max(maxPoint.z, point.z)
    }
}
