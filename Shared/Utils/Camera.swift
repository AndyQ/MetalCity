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
    var m_vPosition = float3(0)
    var m_vView = float3([0,1,0.5])
    var m_vUpVector = float3([0,1,0])

    init() {
    }

    init( pos:float3, lookAt:float3, up:float3=[0,1,0] ) {
        m_vPosition = pos
        m_vView = lookAt
        m_vUpVector = up
    }

    func getPosition() -> float3 {
        return m_vPosition
    }

    func getView() -> float3 {
        return m_vView
    }

    func setPosition(pos:float3) {
        m_vPosition = pos
    }

    func setView( view:float3) {
        m_vView = view
    }

    func look()  -> float4x4
    {
        // Calculate angle
        let dist = distance(m_vPosition.x, m_vPosition.z, m_vView.x, m_vView.z)
        appState.cameraState.angle.y = clampAngle(-angleBetweenPoints(m_vPosition.x, m_vPosition.z, m_vView.x, m_vView.z))
        appState.cameraState.angle.x = 90.0 + angleBetweenPoints (0, m_vPosition.y, dist, m_vView.y)

        appState.cameraState.position = m_vPosition
        let lookAt = float4x4.makeLookAt(eye: m_vPosition, lookAt: m_vView, up:m_vUpVector)

        return lookAt
    }


    ///////////////////////////////// POSITION CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This function sets the camera's position and view and up point.
    /////
    ///////////////////////////////// POSITION CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func positionCamera(x:Float, y:Float, z:Float, vx:Float, vy:Float, vz:Float, upX:Float, upY:Float, upZ:Float ) {
        m_vPosition    = [x,y,z]
        m_vView    = [vx, vy, vz]
        m_vUpVector    = [upX, upY, upZ]
    }


    ///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This rotates the view around the position
    /////
    ///////////////////////////////// ROTATE VIEW \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func rotateViewRound(x:Float, y:Float, z:Float ) {
        var point = float3()

        // Get our view GLKVector3 (The direction we are facing)
        point.x = m_vView.x - m_vPosition.x        // This gets the direction of the X
        point.y = m_vView.y - m_vPosition.y        // This gets the direction of the Y
        point.z = m_vView.z - m_vPosition.z        // This gets the direction of the Z

        // If we pass in a negative X Y or Z, it will rotate the opposite way,
        // so we only need one function for a left and right , up or down rotation.
        // I suppose we could have one move function too, but I decided not too.

        if x != 0.0 {
            m_vView.z = Float(m_vPosition.z + sin(x)*point.y + cos(x)*point.z)
            m_vView.y = Float(m_vPosition.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            m_vView.z = Float(m_vPosition.z + sin(y) * point.x + cos(y) * point.z)
            m_vView.x = Float(m_vPosition.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            m_vView.x = Float(m_vPosition.x + sin(z)*point.y + cos(z)*point.x)
            m_vView.y = Float(m_vPosition.y + cos(z)*point.y - sin(z)*point.x)
        }
    }




    ///////////////////////////////// MOVE CAMERA BY MOUSE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This allows us to look around uSing the mouse, like in most first person games.
    /////
    /////
    ///////////////////////////////// MOVE CAMERA BY MOUSE \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func moveCameraByMouse( prevPoint:CGPoint, newPoint:CGPoint) {
        var deltaY : Float  = 0.0                            // This is the direction for looking up or down
        var rotateY : Float = 0.0                            // This will be the value we need to rotate around the Y axis (Left and Right)

        // If our cursor is still in the middle, we never moved... so don't update the screen
        guard prevPoint != newPoint else { return }

        // Get the direction the mouse moved in, but bring the number down to a reasonable amount
        rotateY = Float( (prevPoint.x - newPoint.x) ) / 100
        deltaY  = Float( (prevPoint.y - newPoint.y) ) / 100

        // Multiply the direction GLKVector3 for Y by an acceleration (The higher the faster is goes).
        m_vView.y += deltaY * 15

        // Note, this is a bad way of doing this (Ideal would be spherical coordinates)

        // Check if the distance of our view exceeds 60 from our position, if so, stop it. (UP)
        //    if( ( m_vView.y - m_vPosition.y ) >  10)  m_vView.y = m_vPosition.y + 10

        // Check if the distance of our view exceeds -60 from our position, if so, stop it. (DOWN)
        //    if( ( m_vView.y - m_vPosition.y ) < -10)  m_vView.y = m_vPosition.y - 10

        // Here we rotate the view along the X avis depending on the direction (Left of Right)
        self.rotateViewRound(x: 0, y: -rotateY, z: 0)
    }


    ///////////////////////////////// ROTATE AROUND POINT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This rotates the camera position around a given point
    /////
    ///////////////////////////////// ROTATE AROUND POINT \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func rotateAroundPoint(x:Float, y:Float, z:Float ) {
        var point = float3()

        // Get the GLKVector3 from our position to the center we are rotating around
        point.x = m_vPosition.x - m_vView.x        // This gets the direction of the X
        point.y = m_vPosition.y - m_vView.y        // This gets the direction of the Y
        point.z = m_vPosition.z - m_vView.z        // This gets the direction of the Z

        // Rotate the position along the desired axis around the desired point vCenter
        if x != 0.0 {
            m_vView.z = Float(m_vView.z + sin(x)*point.y + cos(x)*point.z)
            m_vView.y = Float(m_vView.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            m_vView.z = Float(m_vView.z + sin(y) * point.x + cos(y) * point.z)
            m_vView.x = Float(m_vView.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            m_vView.x = Float(m_vView.x + sin(z)*point.y + cos(z)*point.x)
            m_vView.y = Float(m_vView.y + cos(z)*point.y - sin(z)*point.x)
        }
    }


    func rotateAroundPoint(atCenter vCenter:float3, x:Float, y:Float, z:Float ) {
        var point = float3()

        // Get the GLKVector3 from our position to the center we are rotating around
        point.x = m_vPosition.x - vCenter.x        // This gets the direction of the X
        point.y = m_vPosition.y - vCenter.y        // This gets the direction of the Y
        point.z = m_vPosition.z - vCenter.z        // This gets the direction of the Z

        // Rotate the position along the desired axis around the desired point vCenter
        if x != 0.0 {
            m_vView.z = Float(vCenter.z + sin(x)*point.y + cos(x)*point.z)
            m_vView.y = Float(vCenter.y + cos(x)*point.y - sin(x)*point.z)
        }
        if y != 0.0 {
            m_vView.z = Float(vCenter.z + sin(y) * point.x + cos(y) * point.z)
            m_vView.x = Float(vCenter.x + cos(y)*point.x - sin(y)*point.z)
        }
        if z != 0.0 {
            m_vView.x = Float(vCenter.x + sin(z)*point.y + cos(z)*point.x)
            m_vView.y = Float(vCenter.y + cos(z)*point.y - sin(z)*point.x)
        }
    }



    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *

    ///////////////////////////////// STRAFE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This strafes the camera left and right depending on the speed (-/+)
    /////
    ///////////////////////////////// STRAFE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func getVectorRightAnglesAwayFromCamera() -> float3 {
        var vCross = float3()

        // Get the view GLKVector3 of our camera and store it in a local variable
        var vViewPoint :float3 = [m_vView.x - m_vPosition.x, m_vView.y - m_vPosition.y, m_vView.z - m_vPosition.z]                            // GLKVector3 for the position/view.

        // Here we calculate the cross product of our up GLKVector3 and view GLKVector3

        // The X value for the GLKVector3 is:  (V1.y * V2.z) - (V1.z * V2.y)
        vCross.x = ((m_vUpVector.y * vViewPoint.z) - (m_vUpVector.z * vViewPoint.y))

        // The Y value for the GLKVector3 is:  (V1.z * V2.x) - (V1.x * V2.z)
        vCross.y = ((m_vUpVector.z * vViewPoint.x) - (m_vUpVector.x * vViewPoint.z))

        // The Z value for the GLKVector3 is:  (V1.x * V2.y) - (V1.y * V2.x)
        vCross.z = ((m_vUpVector.x * vViewPoint.y) - (m_vUpVector.y * vViewPoint.x))

        return vCross
    }

    func strafeCamera( speed:Float) {
        // Strafing is quite simple if you understand what the cross product is.
        // If you have 2 GLKVector3s (say the up GLKVector3 and the view GLKVector3) you can
        // use the cross product formula to get a GLKVector3 that is 90 degrees from the 2 GLKVector3s.
        // For a better explanation on how this works, check out the OpenGL "Normals" tutorial at our site.

        // Initialize a variable for the cross product result
        var vCross = float3()

        // Get the view GLKVector3 of our camera and store it in a local variable
        var vViewPoint : float3 = [m_vView.x - m_vPosition.x, m_vView.y - m_vPosition.y, m_vView.z - m_vPosition.z]                            // GLKVector3 for the position/view.

        // Here we calculate the cross product of our up GLKVector3 and view GLKVector3

        // The X value for the GLKVector3 is:  (V1.y * V2.z) - (V1.z * V2.y)
        vCross.x = ((m_vUpVector.y * vViewPoint.z) - (m_vUpVector.z * vViewPoint.y))

        // The Y value for the GLKVector3 is:  (V1.z * V2.x) - (V1.x * V2.z)
        vCross.y = ((m_vUpVector.z * vViewPoint.x) - (m_vUpVector.x * vViewPoint.z))

        // The Z value for the GLKVector3 is:  (V1.x * V2.y) - (V1.y * V2.x)
        vCross.z = ((m_vUpVector.x * vViewPoint.y) - (m_vUpVector.y * vViewPoint.x))

        // Now we want to just add this new GLKVector3 to our position and view, as well as
        // multiply it by our speed factor.  If the speed is negative it will strafe the
        // opposite way.

        // Add the resultant GLKVector3 to our position
        m_vPosition.x += vCross.x * speed
        m_vPosition.z += vCross.z * speed

        // Add the resultant GLKVector3 to our view
        m_vView.x += vCross.x * speed
        m_vView.z += vCross.z * speed
    }

    // Raises or lowers the camera
    func raiseCamera(amount:Float ) {
        m_vPosition.y += amount
        m_vView.y += amount
    }

    /////// * /////////// * /////////// * NEW * /////// * /////////// * /////////// *


    ///////////////////////////////// MOVE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*
    /////
    /////    This will move the camera forward or backward depending on the speed
    /////
    ///////////////////////////////// MOVE CAMERA \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

    func moveCamera(speed:Float) {

        var point = float3()

        // Get our view GLKVector3 (The direciton we are facing)
        point.x = m_vView.x - m_vPosition.x        // This gets the direction of the X
        point.y = m_vView.y - m_vPosition.y        // This gets the direction of the Y
        point.z = m_vView.z - m_vPosition.z        // This gets the direction of the Z

        m_vPosition.x += point.x * speed        // Add our acceleration to our position's X
        //    m_vPosition.y += point.y * speed        // Add our acceleration to our position's Y
        m_vPosition.z += point.z * speed        // Add our acceleration to our position's Z
        m_vView.x += point.x * speed            // Add our acceleration to our view's X
        //    m_vView.y += point.y * speed            // Add our acceleration to our view's Y
        m_vView.z += point.z * speed            // Add our acceleration to our view's Z
    }
}
