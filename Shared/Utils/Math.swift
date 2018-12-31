//
//  Math.swift
//  MetalSample
//
//  Created by Andy Qua on 29/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import simd
import CoreGraphics

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}


func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

func calculateTriangleSurfaceNormal(v1 : Vertex, v2 : Vertex, v3 : Vertex ) -> float4 {
    let vector1 = (v2.position - v1.position).xyz
    let vector2 = (v3.position - v1.position).xyz
    let crossProduct = cross(vector1, vector2)
    let normal = normalize(crossProduct)

    return [normal.x, normal.y, normal.z, 1]
}

func distance(_ x1 : Float, _ y1: Float, _ x2: Float, _ y2: Float) -> Float {

    let dx = x1 - x2
    let dy = y1 - y2
    return sqrtf(dx * dx + dy * dy)
}

/*-----------------------------------------------------------------------------
 Keep an angle between 0 and 360
 -----------------------------------------------------------------------------*/

func clampAngle( _ angle : Float ) -> Float {
    let newAngle : Float
    if angle < 0.0 {
        newAngle = 360.0 - fmodf(abs(angle), 360.0)
    } else {
        newAngle = fmodf(angle, 360.0)
    }
    return newAngle

}


func angleBetweenPoints ( _ x1 : Float, _ y1 : Float, _ x2 : Float, _ y2 : Float) -> Float
{
    let  z_delta = (y1 - y2)
    let x_delta = (x1 - x2)
    if x_delta == 0 {
        if (z_delta > 0) {
            return 0.0
        } else {
            return 180.0
        }
    }

    var angle : Float
    if abs(x_delta) < abs(z_delta) {
        angle = 90 - atanf(z_delta / x_delta) * RADIANS_TO_DEGREES
        if x_delta < 0 {
            angle -= 180.0
        }
    } else {
        angle = atanf(x_delta / z_delta) * RADIANS_TO_DEGREES
        if z_delta < 0.0 {
            angle += 180.0
        }
    }
    if angle < 0.0 {
        angle += 360.0
    }
    return angle
}

func mathAngleDifference( _ a1: Float, _ a2: Float ) -> Float {
    let result = fmodf(a1 - a2, 360.0)
    if result > 180.0 {
        return result - 360.0
    }
    if result < -180.0 {
        return result + 360.0
    }
    return result

}

extension Double {
    /// Number of radians in *half a turn*.
    public static let pi_2: Double = Double.pi * 2
}

extension Float {
    /// Number of radians in *half a turn*.
    public static let pi_2: Float = Float.pi * 2
}

extension CGSize {
    /// Transforms a `CGSize` into a vector with two numbers
    var float2: simd.float2 {
        return simd.float2(Float(self.width), Float(self.height))
    }

    var aspectRatio: CGFloat {
        return width / height
    }
}

extension float3 {
    static func lerp( vectorStart : float3,  vectorEnd: float3, t : Float ) -> float3 {
        let v : float3 = float3(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t),
            vectorStart.y + ((vectorEnd.y - vectorStart.y) * t),
            vectorStart.z + ((vectorEnd.z - vectorStart.z) * t) )
        return v
    }

}

extension float4 {
    var xy: float2 {
        return float2([self.x, self.y])
    }

    var xyz: float3 {
        return float3([self.x, self.y, self.z])
    }
}

extension float4x4 {
    /// Creates a 4x4 matrix representing a translation given by the provided vector.
    /// - parameter vector: Vector giving the direction and magnitude of the translation.
    init(translate vector: float3) {
        // List of the matrix' columns
        let baseX: float4 = [1, 0, 0, 0]
        let baseY: float4 = [0, 1, 0, 0]
        let baseZ: float4 = [0, 0, 1, 0]
        let baseW: float4 = [vector.x, vector.y, vector.z, 1]
        self.init(baseX, baseY, baseZ, baseW)
    }

    /// Creates a 4x4 matrix representing a uniform scale given by the provided scalar.
    /// - parameter s: Scalar giving the uniform magnitude of the scale.
    init(scale s: Float) {
        self.init(diagonal: [s, s, s, 1])
    }

    /// Creates a 4x4 matrix that will rotate through the given vector and given angle.
    /// - parameter angle: The amount of radians to rotate from the given vector center.
    init(rotate vector: float3, angle: Float) {
        let c: Float = cos(angle)
        let s: Float = sin(angle)
        let cm = 1 - c

        let x0 = vector.x*vector.x + (1-vector.x*vector.x)*c
        let x1 = vector.x*vector.y*cm - vector.z*s
        let x2 = vector.x*vector.z*cm + vector.y*s

        let y0 = vector.x*vector.y*cm + vector.z*s
        let y1 = vector.y*vector.y + (1-vector.y*vector.y)*c
        let y2 = vector.y*vector.z*cm - vector.x*s

        let z0 = vector.x*vector.z*cm - vector.y*s
        let z1 = vector.y*vector.z*cm + vector.x*s
        let z2 = vector.z*vector.z + (1-vector.z*vector.z)*c

        // List of the matrix' columns
        let baseX: float4 = [x0, x1, x2, 0]
        let baseY: float4 = [y0, y1, y2, 0]
        let baseZ: float4 = [z0, z1, z2, 0]
        let baseW: float4 = [ 0,  0,  0, 1]
        self.init(baseX, baseY, baseZ, baseW)
    }

    /// Creates a perspective matrix from an aspect ratio, field of view, and near/far Z planes.
    init(perspectiveWithAspect aspect: Float, fovy: Float, near: Float, far: Float) {
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange

        // List of the matrix' columns
        let vectorP: float4 = [xScale,      0,       0,  0]
        let vectorQ: float4 = [     0, yScale,       0,  0]
        let vectorR: float4 = [     0,      0,  zScale, -1]
        let vectorS: float4 = [     0,      0, wzScale,  0]
        self.init(vectorP, vectorQ, vectorR, vectorS)
    }

    func upper_left3x3( ) -> matrix_float3x3
    {
        let c1 = vector_float3(self.columns.0.x, self.columns.0.y, self.columns.0.z)
        let c2 = vector_float3(self.columns.1.x, self.columns.1.y, self.columns.1.z)
        let c3 = vector_float3(self.columns.2.x, self.columns.2.y, self.columns.2.z)

        let mat3x3 = matrix_float3x3(columns:(c1, c2, c3))
        return mat3x3
    }


    static func makeLookAt(eye: float3, lookAt: float3, up:float3) -> float4x4 {
        let n = normalize(eye + (-lookAt))
        let u = normalize(cross(up, n))
        let v = cross(n, u)

        let m : float4x4 = float4x4([ u.x, v.x, n.x, 0.0],
                                    [u.y, v.y, n.y, 0.0],
                                    [u.z, v.z, n.z, 0.0],
                                    [dot(-u, eye), dot(-v, eye), dot(-n, eye), 1.0] )

        return m
    }

    static func makeLookAt( eyeX : Float, eyeY : Float, eyeZ : Float,
                     lookAtX : Float, lookAtY : Float, lookAtZ : Float,
                     upX : Float, upY : Float, upZ : Float) -> float4x4 {

        let ev : float3 = [ eyeX, eyeY, eyeZ ]
        let cv : float3 = [ lookAtX, lookAtY, lookAtZ ]
        let uv: float3 = [ upX, upY, upZ ]

        return makeLookAt(eye:ev, lookAt:cv, up:uv )
    }


}
