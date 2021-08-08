//
//  BoundingBox.swift
//  MetalCity
//
//  Created by Andy Qua on 16/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

class BoundingBox {
    private let maxVal: Float = 999999999999999.9

    var minPoint: SIMD3<Float> = .zero
    var maxPoint: SIMD3<Float> = .zero

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
    func include(point: SIMD3<Float>) {
        minPoint.x = min(minPoint.x, point.x)
        minPoint.y = min(minPoint.y, point.y)
        minPoint.z = min(minPoint.z, point.z)
        maxPoint.x = max(maxPoint.x, point.x)
        maxPoint.y = max(maxPoint.y, point.y)
        maxPoint.z = max(maxPoint.z, point.z)
    }
}
