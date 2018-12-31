//
//  AutoCamera.swift
//  MetalCity
//
//  Created by Andy Qua on 19/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

enum CameraBehaviour: Int, CaseIterable {
    case flycam1
    case orbitInward
    case orbitOutward
    case orbitElliptical
    case flycam2
    case speed
    case spin
    case flycam3

    static func random() -> CameraBehaviour {
        return CameraBehaviour.allCases.randomElement()!
    }
}


let MAX_PITCH = 85
let FLYCAM_CIRCUT = 60000
let FLYCAM_CIRCUT_HALF = (FLYCAM_CIRCUT / 2)
let FLYCAM_LEG = (FLYCAM_CIRCUT / 4)
let ONE_SECOND = 1000
let CAMERA_CHANGE_INTERVAL :UInt64 = 15 * 1000
let CAMERA_CYCLE_LENGTH = (10 * CAMERA_CHANGE_INTERVAL)

class AutoCamera {
    var camera: Camera
    var isEnabled: Bool = false
    var behaviour: CameraBehaviour = .flycam1
    var timeUntilNextChange :UInt64 = 0
    var randomBehaviour = true {
        didSet {
            timeUntilNextChange = getTickCount() + CAMERA_CHANGE_INTERVAL
        }
    }

    init(camera:Camera) {
        self.camera = camera
        behaviour = .speed
    }


    func setCameraBehaviour(behaviour:CameraBehaviour) {
        self.behaviour = behaviour
        timeUntilNextChange = getTickCount() + CAMERA_CHANGE_INTERVAL
        randomBehaviour = false
    }

    func update() {
        if isEnabled {
            doAutoCam()
        }

        if appState.cameraState.moving {
            appState.cameraState.movement *= 1.1
        } else {
            appState.cameraState.movement = 0.0
        }
        appState.cameraState.movement = appState.cameraState.movement.clamped(to:0.01 ... 1.0)

        if appState.cameraState.angle.y < 0.0 {
            appState.cameraState.angle.y = 360.0 - Float(fmod(abs(appState.cameraState.angle.y), 360.0))
        }

        appState.cameraState.angle.y = Float(fmod(appState.cameraState.angle.y, 360.0))
        appState.cameraState.angle.x = appState.cameraState.angle.x.clamped(to: Float(-MAX_PITCH) ... Float(MAX_PITCH))
        appState.cameraState.moving = false

    }


    func position(for t: UInt64) -> float3 {
        var start: float3 = .zero
        var end: float3 = .zero

        let hot_zone = appState.hot_zone
        let timeInCircuit = t % UInt64(FLYCAM_CIRCUT)
        let leg = timeInCircuit / UInt64(FLYCAM_LEG)
        var delta = Float(timeInCircuit % UInt64(FLYCAM_LEG)) / Float(FLYCAM_LEG)
        switch leg {
        case 0:
            start = float3(hot_zone.minPoint.x, 25.0, hot_zone.minPoint.z)
            end = float3(hot_zone.minPoint.x, 60.0, hot_zone.maxPoint.z)
        case 1:
            start = float3(hot_zone.minPoint.x, 60.0, hot_zone.maxPoint.z)
            end = float3(hot_zone.maxPoint.x, 25.0, hot_zone.maxPoint.z)
        case 2:
            start = float3(hot_zone.maxPoint.x, 25.0, hot_zone.maxPoint.z)
            end = float3(hot_zone.maxPoint.x, 60.0, hot_zone.minPoint.z)
        case 3:
            start = float3(hot_zone.maxPoint.x, 60.0, hot_zone.minPoint.z)
            end = float3(hot_zone.minPoint.x, 25.0, hot_zone.minPoint.z)
        default:
            break
        }
        delta = mathScalarCurve(delta)
        return float3.lerp(vectorStart: start, vectorEnd: end, t: delta)
    }

    func nextBehaviour(manuallyChanged:Bool = false) {
        let behaviours = CameraBehaviour.allCases
        if let i = behaviours.firstIndex(of: behaviour) {
            if i+1 >= behaviours.count {
                behaviour = behaviours[1]
            } else {
                behaviour = behaviours[i+1]
            }
        } else {
            behaviour = behaviours[1]
        }

        if manuallyChanged {
            timeUntilNextChange = 0
        }
    }

    func doAutoCam() {

        let now = getTickCount()

        var elapsed = now - appState.cameraState.last_update
        elapsed = min(elapsed, 50) //limit to 1/20th second worth of time
        if elapsed == 0 {
            return
        }

        appState.cameraState.last_update = now
        if timeUntilNextChange != 0 && now > timeUntilNextChange {
            nextBehaviour()
            timeUntilNextChange = now + CAMERA_CHANGE_INTERVAL
        }

        appState.cameraState.tracker += Float(elapsed) / 300.0

        let worldHalf = Float(WORLD_HALF)
        var target: float3
        switch behaviour {
        case .orbitInward:
            appState.cameraState.auto_position.x = worldHalf + sinf(appState.cameraState.tracker * DEGREES_TO_RADIANS) * 150.0
            appState.cameraState.auto_position.y = 60.0
            appState.cameraState.auto_position.z = worldHalf + cosf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 150.0
            target = float3(worldHalf, 40.0, worldHalf)
        case .orbitOutward:
            appState.cameraState.auto_position.x = worldHalf + sinf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 250.0
            appState.cameraState.auto_position.y = 60.0
            appState.cameraState.auto_position.z = worldHalf + cosf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 250.0
            target = float3 (worldHalf, 30.0, worldHalf)
        case .orbitElliptical:
            let dist = 150.0 + sinf (appState.cameraState.tracker * DEGREES_TO_RADIANS / 1.1) * 50
            appState.cameraState.auto_position.x = worldHalf + sinf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * dist
            appState.cameraState.auto_position.y = 60.0
            appState.cameraState.auto_position.z = worldHalf + cosf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * dist
            target = float3 (worldHalf, 50.0, worldHalf)
        case .flycam1, .flycam2, .flycam3:
            appState.cameraState.auto_position = (position(for: now) + position(for: now + 4000)) / 2.0
            target = position(for: now + UInt64(FLYCAM_CIRCUT_HALF - ONE_SECOND) * 3)
        case .speed:
            appState.cameraState.auto_position = (position(for: now) + position(for: now + 500)) / 2.0
            target = position(for: now + UInt64(ONE_SECOND) * 5)
            appState.cameraState.auto_position.y /= 2
            target.y /= 2
        default:
            target = float3(worldHalf + sinf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 300.0,
                30.0,
                worldHalf + cosf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 300.0)
            appState.cameraState.auto_position.x = worldHalf + sinf(appState.cameraState.tracker * DEGREES_TO_RADIANS) * 50.0
            appState.cameraState.auto_position.y = 60.0
            appState.cameraState.auto_position.z = worldHalf + cosf (appState.cameraState.tracker * DEGREES_TO_RADIANS) * 50.0
        }

        camera.position = appState.cameraState.auto_position
        camera.lookAt = target
    }


    /*-----------------------------------------------------------------------------
     This will take linear input values from 0.0 to 1.0 and convert them to
     values along a curve.  This could also be acomplished with sin (), but this
     way avoids converting to radians and back.
     -----------------------------------------------------------------------------*/

    func mathScalarCurve(_ origVal:Float) -> Float {

        var val = (origVal - 0.5) * 2.0
        let sign: Float = val < 0 ? -1: 1
        if val < 0.0 {
            val = -val
        }
        val = 1.0 - val
        val *= val
        val = 1.0 - val
        val *= sign
        val = (val + 1.0) / 2.0
        return val

    }
}

