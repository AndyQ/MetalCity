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
    
    static let unclaimed      = MapItem(rawValue: 0 << 0)
    static let claimRoad      = MapItem(rawValue: 1 << 0)
    static let claimWalk    = MapItem(rawValue: 1 << 1)
    static let claimBuilding     = MapItem(rawValue: 1 << 2)
    static let roadNorth       = MapItem(rawValue: 1 << 3)
    static let roadSouth     = MapItem(rawValue: 1 << 4)
    static let roadEast       = MapItem(rawValue: 1 << 5)
    static let roadWest       = MapItem(rawValue: 1 << 6)
}

enum Direction {
    case north
    case south
    case east
    case west
}

enum TextureType
{
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
        let array : [TextureType] = [.building1,building2,building3,building4,building5,building6,building7,building8,building9]
        return array.randomElement()!
    }
}

var textureCount = 1
var textureSizes = [Int]()

struct CameraState {
    
    var angle : float3 = float3(0,0,0)
    var position : float3 = float3(0,0,0)
    var target : float3 = float3(0,0,0)
    var auto_angle : float3 = float3(0,0,0)
    var auto_position : float3 = float3(0,0,0)
    var movement : Float = 0
    var moving : Bool = false
    var cam_auto : Bool = false
    var tracker : Float = 0
    var Int = 0
    var camera_behavior : CameraBehaviour = .manual
    var last_update : UInt64 = 0
}


struct AppState {
    var cameraState = CameraState()
    var hot_zone = BoundingBox()

    var bloom_color : float4 = float4(0,0,0,1)
    var last_update : Int = 0
    
    init() {
        let index = randomValue(light_colors.count)
        let hue = light_colors[index].hueComponent
        
        bloom_color = Color(hue: hue, saturation: 0.5 + CGFloat(randomValue(10)) / 20, brightness: 0.75, alpha: 1.0).rgba()!
    }
}

/*
typedef struct
{
    GLKVector2      angles[5][360]
    bool           angles_done
    int            count
} light_state


typedef struct {
    int              k
    unsigned long    mag01[2]
    unsigned long    ptgfsr[N]
} random_state

typedef struct {
    GLKVector3     angle
    GLKVector3     position
    GLKVector3     target
    GLKVector3     auto_angle
    GLKVector3     auto_position
    float        movement
    bool         moving
    bool         cam_auto
    float        tracker
    uint64_t     last_update
    int          camera_behavior
} camera_state

typedef struct {
    GLKVector2         angles[360]
    bool               angles_done
    unsigned char      carmap[WORLD_SIZE][WORLD_SIZE]
    uint64_t           next_update
    int                count
} car_state


typedef struct {
    bool          vis_grid[GRID_SIZE][GRID_SIZE]
} visible_state

typedef struct {
    float            fog_distance
    uint64_t         next_fps
    unsigned         current_fps
    unsigned         frames
    bool             show_wireframe
    bool             flat
    bool             show_fps
    bool             show_fog
    bool             show_help
} render_state

typedef struct
{
    app_state app
    camera_state camera
    random_state random
    light_state light
    visible_state visible
    render_state render
    car_state car
    __unsafe_unretained City *city
    __unsafe_unretained NSMutableArray *cars
    __unsafe_unretained NSMutableArray *lights
    __unsafe_unretained NSMutableArray *decorations
    __strong GLKTextureInfo **textures
    //  entity_state_t entity
    //  sky_state_t sky
    //  texture_state_t texture
    //  building_state_t building
} State


bool VisibleVect(GLKVector3 pos)
bool Visible( NSInteger x, NSInteger y )
void updateVisibilityGrid( void )
char WorldCell(NSInteger x, NSInteger y)
void removeAllCars( void )

extern State state
*/
