//
//  Camera.swift
//  MetalCity
//
//  Created by Andy Qua on 13/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit
import CoreGraphics


class Camera {
    var position = SIMD3<Float>(0,0,0)
    var lookAt = SIMD3<Float>([0,1,0.5])
    var up = SIMD3<Float>([0,1,0])

    init() {
    }

    init(pos:SIMD3<Float>, lookAt:SIMD3<Float>, up:SIMD3<Float>=[0,1,0]) {
        self.position = pos
        self.lookAt = lookAt
        self.up = up
    }

    func look()  -> float4x4 {
        // Calculate angle
        let dist = distance(position.x, position.z, lookAt.x, lookAt.z)
        appState.cameraState.angle.y = clampAngle(-angleBetweenPoints(position.x, position.z, lookAt.x, lookAt.z))
        appState.cameraState.angle.x = 90.0 + angleBetweenPoints (0, position.y, dist, lookAt.y)

        appState.cameraState.position = position
        return float4x4.makeLookAt(eye: position, lookAt: lookAt, up:up)
    }

    ///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This rotates the view around the position
    /////
    ///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func rotateViewRound(x:Float, y:Float, z:Float) {
        let point = lookAt - position

        // If we pass in a negative X Y or Z, it will rotate the opposite way,
        // so we only need one function for a left and right , up or down rotation.
        // I suppose we could have one move function too, but I decided not too.

        if x != 0.0 {
            lookAt.z = Float(position.z + sin(x)*point.y + cos(x)*point.z)
            lookAt.y = Float(position.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            lookAt.z = Float(position.z + sin(y) * point.x + cos(y) * point.z)
            lookAt.x = Float(position.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            lookAt.x = Float(position.x + sin(z)*point.y + cos(z)*point.x)
            lookAt.y = Float(position.y + cos(z)*point.y - sin(z)*point.x)
        }
    }

    ///////////////////////////////// MOVE CAMERA BY MOUSE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This allows us to look around uSing the mouse, like in most first person games.
    /////
    /////
    ///////////////////////////////// MOVE CAMERA BY MOUSE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func moveCameraByMouse(prevPoint:CGPoint, newPoint:CGPoint) {
        // If our cursor is still in the middle, we never moved... so don't update the screen
        guard prevPoint != newPoint else { return }

        // Get the direction the mouse moved in, but bring the number down to a reasonable amount
        let rotateY = Float((prevPoint.x - newPoint.x)) / 100
        let deltaY  = Float((prevPoint.y - newPoint.y)) / 100

        // Multiply the direction GLKVector3 for Y by an acceleration (The higher the faster is goes).
        lookAt.y += deltaY * 15

        // Note, this is a bad way of doing this (Ideal would be spherical coordinates)

        // Check if the distance of our view exceeds 60 from our position, if so, stop it. (UP)
        //    if((m_vView.y - m_vPosition.y) >  10)  m_vView.y = m_vPosition.y + 10

        // Check if the distance of our view exceeds -60 from our position, if so, stop it. (DOWN)
        //    if((m_vView.y - m_vPosition.y) < -10)  m_vView.y = m_vPosition.y - 10

        // Here we rotate the view along the X avis depending on the direction (Left of Right)
        self.rotateViewRound(x: 0, y: -rotateY, z: 0)
    }


    ///////////////////////////////// ROTATE AROUND POINT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This rotates the camera position around a given point
    /////
    ///////////////////////////////// ROTATE AROUND POINT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func rotateAroundPoint(x:Float, y:Float, z:Float) {
        let point = position - lookAt

        // Rotate the position along the desired axis around the desired point vCenter
        if x != 0.0 {
            lookAt.z = Float(lookAt.z + sin(x)*point.y + cos(x)*point.z)
            lookAt.y = Float(lookAt.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            lookAt.z = Float(lookAt.z + sin(y) * point.x + cos(y) * point.z)
            lookAt.x = Float(lookAt.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            lookAt.x = Float(lookAt.x + sin(z)*point.y + cos(z)*point.x)
            lookAt.y = Float(lookAt.y + cos(z)*point.y - sin(z)*point.x)
        }
    }


    func rotateAroundPoint(atCenter vCenter:SIMD3<Float>, x:Float, y:Float, z:Float) {
        let point = position - vCenter

        // Rotate the position along the desired axis around the desired point vCenter
        if x != 0.0 {
            lookAt.z = Float(vCenter.z + sin(x)*point.y + cos(x)*point.z)
            lookAt.y = Float(vCenter.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            lookAt.z = Float(vCenter.z + sin(y) * point.x + cos(y) * point.z)
            lookAt.x = Float(vCenter.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            lookAt.x = Float(vCenter.x + sin(z)*point.y + cos(z)*point.x)
            lookAt.y = Float(vCenter.y + cos(z)*point.y - sin(z)*point.x)
        }
    }



    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *

    ///////////////////////////////// STRAFE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This strafes the camera left and right depending on the speed (-/+)
    /////
    ///////////////////////////////// STRAFE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func getVectorRightAnglesAwayFromCamera() -> SIMD3<Float> {
        var vCross = SIMD3<Float>()

        // Get the view GLKVector3 of our camera and store it in a local variable
        let vViewPoint :SIMD3<Float> = lookAt - position
        // GLKVector3 for the position/view.

        // Here we calculate the cross product of our up GLKVector3 and view GLKVector3

        // The X value for the GLKVector3 is:  (V1.y * V2.z) - (V1.z * V2.y)
        vCross.x = ((up.y * vViewPoint.z) - (up.z * vViewPoint.y))

        // The Y value for the GLKVector3 is:  (V1.z * V2.x) - (V1.x * V2.z)
        vCross.y = ((up.z * vViewPoint.x) - (up.x * vViewPoint.z))

        // The Z value for the GLKVector3 is:  (V1.x * V2.y) - (V1.y * V2.x)
        vCross.z = ((up.x * vViewPoint.y) - (up.y * vViewPoint.x))

        return vCross
    }

    func strafeCamera(speed:Float) {
        // Strafing is quite simple if you understand what the cross product is.
        // If you have 2 GLKVector3s (say the up GLKVector3 and the view GLKVector3) you can
        // use the cross product formula to get a GLKVector3 that is 90 degrees from the 2 GLKVector3s.
        // For a better explanation on how this works, check out the OpenGL "Normals" tutorial at our site.

        // Initialize a variable for the cross product result
        var vCross = SIMD3<Float>()

        // Get the view GLKVector3 of our camera and store it in a local variable
        let vViewPoint: SIMD3<Float> = lookAt - position                            // GLKVector3 for the position/view.

        // Here we calculate the cross product of our up GLKVector3 and view GLKVector3

        // The X value for the GLKVector3 is:  (V1.y * V2.z) - (V1.z * V2.y)
        vCross.x = ((up.y * vViewPoint.z) - (up.z * vViewPoint.y))

        // The Y value for the GLKVector3 is:  (V1.z * V2.x) - (V1.x * V2.z)
        vCross.y = ((up.z * vViewPoint.x) - (up.x * vViewPoint.z))

        // The Z value for the GLKVector3 is:  (V1.x * V2.y) - (V1.y * V2.x)
        vCross.z = ((up.x * vViewPoint.y) - (up.y * vViewPoint.x))

        // Now we want to just add this new GLKVector3 to our position and view, as well as
        // multiply it by our speed factor.  If the speed is negative it will strafe the
        // opposite way.

        // Add the resultant GLKVector3 to our position
        position.x += vCross.x * speed
        position.z += vCross.z * speed

        // Add the resultant GLKVector3 to our view
        lookAt.x += vCross.x * speed
        lookAt.z += vCross.z * speed
    }

    // Raises or lowers the camera
    func raiseCamera(amount:Float) {
        position.y += amount
        lookAt.y += amount
    }

    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *


    ///////////////////////////////// MOVE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This will move the camera forward or backward depending on the speed
    /////
    ///////////////////////////////// MOVE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func moveCamera(speed:Float) {
        let point = lookAt - position

        position.x += point.x * speed        // Add our acceleration to our position's X
        //    m_vPosition.y += point.y * speed        // Add our acceleration to our position's Y
        position.z += point.z * speed        // Add our acceleration to our position's Z
        lookAt.x += point.x * speed            // Add our acceleration to our view's X
        //    m_vView.y += point.y * speed            // Add our acceleration to our view's Y
        lookAt.z += point.z * speed            // Add our acceleration to our view's Z
    }
}
