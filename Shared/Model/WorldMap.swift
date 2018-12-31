//
//  WorldMap.swift
//  MetalCity
//
//  Created by Andy Qua on 20/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import Foundation

let WORLD_SIZE : Int = 512
let WORLD_HALF = WORLD_SIZE / 2
let WORLD_EDGE = 100
let GRID_RESOLUTION = 32
let GRID_CELL = GRID_RESOLUTION / 2
let GRID_SIZE = WORLD_SIZE / GRID_RESOLUTION

class WorldMap {
    static let instance : WorldMap = WorldMap()

    var world = [[MapItem]]()
    var visGrid = [[Bool]]()

    static func worldToGrid( _ x : Int, _ y : Int ) -> (Int,Int) {
        return (worldToGrid(x), worldToGrid(y))
    }

    static func worldToGrid( _ x : Int ) -> Int {
        return (x/GRID_RESOLUTION).clamped(to: 0 ... GRID_SIZE-1)
    }

    static func gridToWorld( _ x : Int, _ y : Int ) -> (Int,Int) {
        return (gridToWorld(x), gridToWorld(y))
    }

    static func gridToWorld( _ x: Int ) -> Int {
        return x * GRID_RESOLUTION
    }



    private init() {
    }

    func reset() {
        world = Array(repeating: Array(repeating: .unclaimed, count: WORLD_SIZE), count: WORLD_SIZE)
        visGrid = Array(repeating: Array(repeating: false, count: GRID_SIZE), count: GRID_SIZE)
    }

    func cellAt( _ x : Int, _ y : Int) -> MapItem {

        let cx = x.clamped(to: 0...WORLD_SIZE-1)
        let cy = y.clamped(to: 0...WORLD_SIZE-1)
        return self.world[cx][cy]
    }

    func addValue( _ x : Int, _ y : Int, val : MapItem ) {
        let cx = x.clamped(to: 0...WORLD_SIZE-1)
        let cy = y.clamped(to: 0...WORLD_SIZE-1)
        self.world[cx][cy].insert(val)
    }

    func isVisible(pos : float3) -> Bool {
        return isVisible(x:Int(pos.x), y:Int(pos.z))

    }

    func isVisible( x : Int, y : Int ) -> Bool {
        let (x,y) = WorldMap.worldToGrid(x, y)
        return visGrid[x][y]
    }


    func updateVisibilityGrid( ) {
        //Clear the visibility table
        visGrid = Array(repeating: Array(repeating: false, count: GRID_SIZE), count: GRID_SIZE)

        //Calculate which cell the camera is in
        let angle = appState.cameraState.angle
        let position = appState.cameraState.position
        let (grid_x, grid_z) = WorldMap.worldToGrid(Int(position.x), Int(position.z))

        //Cells directly adjactent to the camera might technically fall out of the fov,
        //but still have a few objects poking into screenspace when looking up or down.
        //Rather than obsess over sorting those objects properly, it's more efficient to
        //just mark them visible.
        var left = 3, right = 3, front = 3, back = 3

        //Looking north, can't see south.
        if angle.y < 60.0 || angle.y > 300.0 {
            front = 2
        }
        //Looking south, can't see north
        if angle.y > 120.0 && angle.y < 245.0 {
            back = 2
        }
        //Looking east, can't see west
        if angle.y > 30.0 && angle.y < 150.0 {
            left = 2
        }
        //Looking west, can't see east
        if angle.y > 210.0 && angle.y < 330.0 {
            right = 2
        }
        //Now mark the block around us the might be visible
        for x in grid_x - left ... grid_x + right {
            if x < 0 || x >= GRID_SIZE { //just in case the camera leaves the world map
                continue
            }
            for y in grid_z - back ... grid_z + front {
                if y < 0 || y >= GRID_SIZE { //just in case the camera leaves the world map
                    continue
                }
                visGrid[x][y] = true
            }
        }

        //Doesn't matter where we are facing, objects in current cell are always visible
        visGrid[grid_x][grid_z] = true

        //Here, we look at the angle from the current camera position to the cell
        //on the grid, and how much that angle deviates from the current view angle.
        for x in 0 ..< GRID_SIZE {
            for y in 0 ..< GRID_SIZE {
                //if we marked it visible earlier, skip all this math
                if visGrid[x][y] {
                    continue
                }
                //if the camera is to the left of this cell, use the left edge
                let target_x : Float
                let target_z : Float
                if grid_x < x {
                    target_x = Float(x * GRID_RESOLUTION)
                } else {
                    target_x = Float((x + 1) * GRID_RESOLUTION)
                }
                if grid_z < y {
                    target_z = Float(y * GRID_RESOLUTION)
                } else {
                    target_z = Float((y + 1) * GRID_RESOLUTION)
                }

                let angle_to = 180 - angleBetweenPoints(target_x, target_z, position.x, position.z)

                //Store how many degrees the cell is to the
                let angle_diff = fabsf(mathAngleDifference(angle.y, angle_to))
                visGrid[x][y] = angle_diff < 60
            }
        }
    }

}
