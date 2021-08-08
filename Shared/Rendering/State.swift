//
//  State.swift
//  MetalCity
//
//  Created by Andy Qua on 16/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation
import CoreGraphics


var appState = AppState()

struct MapItem: OptionSet {

    let rawValue: Int

    static let unclaimed = MapItem(rawValue: 0 << 0)
    static let claimRoad = MapItem(rawValue: 1 << 0)
    static let claimWalk = MapItem(rawValue: 1 << 1)
    static let claimBuilding = MapItem(rawValue: 1 << 2)
    static let roadNorth = MapItem(rawValue: 1 << 3)
    static let roadSouth = MapItem(rawValue: 1 << 4)
    static let roadEast = MapItem(rawValue: 1 << 5)
    static let roadWest = MapItem(rawValue: 1 << 6)
}

enum Direction {
    case north
    case south
    case east
    case west
}

enum TextureType: Int {
    case sky
    case lattice
    case headlight
    case count
    case light
    case clouds
    case city
    case logos
    case building1
    case building2
    case building3
    case building4
    case building5
    case building6
    case building7
    case building8
    case building9

    static func randomBuildingTexture() -> TextureType {
        let array: [TextureType] = [.building1,building2,building3,building4,building5,building6,building7,building8,building9]
        return array.randomElement()!
    }
}

var textureCount = 1
var textureSizes = [Int]()

struct CameraState {

    var angle: SIMD3<Float> = .zero
    var position: SIMD3<Float> = .zero
    var target: SIMD3<Float> = .zero
    var auto_angle: SIMD3<Float> = .zero
    var auto_position: SIMD3<Float> = .zero
    var movement: Float = 0
    var moving: Bool = false
    var cam_auto: Bool = false
    var tracker: Float = 0
    var Int = 0
    var last_update: UInt64 = 0
}


struct AppState {
    var cameraState = CameraState()
    var hot_zone = BoundingBox()

    var bloom_color: SIMD4<Float> = SIMD4<Float>(0,0,0,1)
    var last_update: Int = 0

    init() {
        let index = randomInt(light_colors.count)
        let hue = light_colors[index].hueComponent

        bloom_color = Color(hue: hue, saturation: 0.5 + CGFloat(randomInt(10)) / 20, brightness: 0.75, alpha: 1.0).rgba()
    }
}
