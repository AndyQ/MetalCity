//
//  City.swift
//  MetalCity
//
//  Created by Andy Qua on 13/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class Plot {
    var x : Int = 0
    var z : Int = 0
    var width : Int = 0
    var depth : Int = 0

    init(x:Int, z:Int, width:Int, depth:Int) {
        self.x = x
        self.z = z
        self.width = width
        self.depth = depth
    }
}


class City {
    var sky : Sky
    var floor : PlaneModel
    var buildings = [Building]()
    var cars : Cars
    var texture : Int = 0

    var vlist : [Int]
    var nrVertices : Int = 0

    var device: MTLDevice

    var modern_count = 0
    var tower_count = 0
    var blocky_count = 0
    var reset_needed = false
    var skyscrapers = 0


    init(device: MTLDevice) {
        self.device = device

        vlist = [Int]()

        print("Creating sky")
        sky = Sky(device: device)
        print("Creating floor")
        floor = PlaneModel(device: device)

        cars = Cars(device:device)

        print("Building city")
        buildCity()

        // Add in 100 cars
        print("Creating cars")
        for _ in 0 ..< 100 {
            cars.addCar()
        }
        print("City Built")
    }

    func update()
    {
        WorldMap.instance.updateVisibilityGrid()


        sky.update()
        floor.update()
        cars.update()
        DecorationManager.instance.update()
    }

    func prepareToDraw() {
        sky.prepareToDraw()
        floor.prepareToDraw()
    }

    func finishDrawing() {
        sky.finishDrawing()
        floor.finishDrawing()
    }

    func draw(commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer) {
        sky.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)

        floor.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
        for b in buildings {
            b.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
        }

        DecorationManager.instance.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)

        cars.draw(commandEncoder: commandEncoder, sharedUniformsBuffer: sharedUniformsBuffer)
    }

    func  buildCity() {
        WorldMap.instance.reset()
        buildRoads()

        if let image = genTextureImage() {
            floor.setTexture(image: image)
        }

    }

    func genTextureImage() -> Image? {

        // Create our image
        let len = WORLD_SIZE*WORLD_SIZE*4
        var bytes : [UInt8] = [UInt8](repeating:0, count:len)

        // Take away the red pixel, assuming 32-bit RGBA
        for i in stride(from:0, to:len, by:4) {
            let x = (i/4) % WORLD_SIZE
            let y = (i/4) / WORLD_SIZE
/*
            bytes[i] = 0 // red
            bytes[i+1] = 0 // green
            bytes[i+2] = 0 // blue
            bytes[i+3] = 255 // alpha
*/
            let cell = WorldMap.instance.cellAt(x, y)
            if cell.contains(.claimRoad) {
                bytes[i] = 75 // red
                bytes[i+1] = 75 // green
                bytes[i+2] = 75 // blue
                bytes[i+3] = 255 // alpha
            } else if cell.contains(.claimBuilding) {
                bytes[i] = 0 // red
                bytes[i+1] = 0 // green
                bytes[i+2] = 0 // blue
                bytes[i+3] = 255 // alpha
            } else if cell.contains(.claimWalk) {
                bytes[i] = 50 // red
                bytes[i+1] = 50 // green
                bytes[i+2] = 50 // blue
                bytes[i+3] = 255 // alpha
            } else {
                bytes[i] = 0 // red
                bytes[i+1] = 0 // green
                bytes[i+2] = 0 // blue
                bytes[i+3] = 255 // alpha
            }
        }
        let ptr = UnsafeMutableRawPointer(mutating: &bytes)
        let ctx = CGContext(data: ptr,
                            width: WORLD_SIZE,
                            height: WORLD_SIZE,
                            bitsPerComponent: 8,
                            bytesPerRow: WORLD_SIZE*4, //imageRef.bytesPerRow,
                            space: CGColorSpaceCreateDeviceRGB(), //imageRef.colorSpace!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let newImageRef = ctx!.makeImage() else { return nil }
        let newImage = Image(cgImage:newImageRef)

        return newImage
    }

    func buildRoads() {

        var width = 0
        var depth = 0
        var height = 0
        var attempts = 0
        var broadway_done = false
        var road_left = false
        var road_right = false
        var west_street : Float = 0
        var north_street : Float = 0
        var east_street : Float = 0
        var south_street : Float = 0

        // Generate East/west roads
        print("   generating east/west roads")
        var y = WORLD_EDGE
        while y < WORLD_SIZE - WORLD_EDGE {

            if !broadway_done && y > WORLD_HALF - 20 {
                self.buildRoad(fromX1: 0, y1: y, width: WORLD_SIZE, depth: 19)
                y += 20
                broadway_done = true
            }
            else
            {
                depth = 6 + randomInt(6)
                if y < WORLD_HALF / 2 {
                    north_street = Float(y + depth / 2)
                }
                if y < (WORLD_SIZE - WORLD_HALF / 2) {
                    south_street = Float(y + depth / 2)
                }

                self.buildRoad(fromX1: 0, y1: y, width: WORLD_SIZE, depth: depth)
            }
            y += randomInt(25) + 25
        }

        // Generate North/south roads
        print("   generating north/south roads")
        broadway_done = false
        var x = WORLD_EDGE
        while x < WORLD_SIZE - WORLD_EDGE {
            if !broadway_done && x > WORLD_HALF - 20 {
                self.buildRoad(fromX1:x, y1: 0, width: 19, depth: WORLD_SIZE)
                x += 20
                broadway_done = true
            } else {
                width = 6 + randomInt(6)
                if x <= WORLD_HALF / 2 {
                    west_street = Float(x + width / 2)
                }

                if x <= WORLD_HALF + WORLD_HALF / 2 {
                    east_street = Float(x + width / 2)
                }
                self.buildRoad(fromX1:x, y1: 0, width: width, depth: WORLD_SIZE)
            }
            x += randomInt(25) + 25
        }

        //Scan for places to put runs of streetlights on the east & west side of the road
        print("   generating east/west streetlights")
        for x in 1 ..< WORLD_SIZE - 1 {
            var y = 0
            while y < WORLD_SIZE {
                //if this isn't a bit of sidewalk, then keep looking
                //If it's used as a road, skip it.
                if WorldMap.instance.cellAt(x, y).contains(.claimWalk) && !WorldMap.instance.cellAt(x, y).contains(.claimRoad) {
                    road_left = WorldMap.instance.cellAt(x+1, y).contains(.claimRoad)
                    road_right = WorldMap.instance.cellAt(x-1, y).contains(.claimRoad)

                    //if the cells to our east and west are not road, then we're not on a corner.
                    //if the cell to our east AND west is road, then we're on a median. skip it
                    if road_left != road_right {
                        y += self.buildLightStrip(atX: x, z: y, direction: road_right ? .south : .north, height:0)
                    }
                }

                y += 1
            }
        }

        //Scan for places to put runs of streetlights on the north & south side of the road
        print("   generating north/south streetlights")
        for y in 1 ..< WORLD_SIZE - 1 {
            var x = 0
            while x < WORLD_SIZE {
                //if this isn't a bit of sidewalk, then keep looking
                //If it's used as a road, skip it.
                if WorldMap.instance.cellAt(x, y).contains(.claimWalk) && !WorldMap.instance.cellAt(x, y).contains(.claimRoad) {

                    road_left = WorldMap.instance.cellAt(x, y+1).contains(.claimRoad)
                    road_right = WorldMap.instance.cellAt(x, y-1).contains(.claimRoad)

                    //if the cells to our east and west are not road, then we're not on a corner.
                    //if the cell to our east AND west is road, then we're on a median. skip it
                    if road_left != road_right {
                       x += self.buildLightStrip(atX: x, z: y, direction: road_right ? .east : .west, height:0.01)
                    }
                }

                x += 1
            }
        }


        //We kept track of the positions of streets that will outline the high-detail hot zone
        //in the middle of the world.  Save this in a bounding box so that later we can
        //have the camera fly around without clipping through buildings.
        appState.hot_zone.clear()
        appState.hot_zone.include(point: float3(west_street, 0.0, north_street))
        appState.hot_zone.include(point: float3(east_street, 0.0, south_street))


        print("   Placing large buildings in center of map")
        //Scan over the center area of the map and place the big buildings
        attempts = 0
        while self.skyscrapers < 50 && attempts < 350 {
            let x = (WORLD_HALF / 2) + (randomInt() % WORLD_HALF)
            let y = (WORLD_HALF / 2) + (randomInt() % WORLD_HALF)
            if !self.claimed(atX:x, y:y, width:1, depth:1) {
                self.doBuilding(atPlot:self.findPlot(atX:x, andY:y))
                self.skyscrapers += 1
            }
            attempts += 1
        }

        //now blanket the rest of the world with lesser buildings
        print("   Placing smaller buildings around outside")
        x = 0
        while x < WORLD_SIZE {
            var y = 0
            while y < WORLD_SIZE {
                if WorldMap.instance.cellAt(x, y).rawValue != 0 {
                    y += 1
                    continue
                }
                width = 12 + randomInt(20)
                depth = 12 + randomInt(20)
                height = min(width, depth)

                if x < 30 || y < 30 || x > WORLD_SIZE - 30 || y > WORLD_SIZE - 30 {
                    height = randomInt(15) + 20
                } else if x < WORLD_HALF / 2 {
                    height /= 2
                }

                while width > 8 && depth > 8 {
                    if !self.claimed(atX:x, y:y, width:width, depth:depth) {
                        self.claimPatch(atX:x, y:y, width:width, depth:depth, value:.claimBuilding)

                        let color = worldLightColor(randomInt())

                        //if we're out of the hot zone, use simple buildings
                        var building : Building?
                        if x < Int(appState.hot_zone.minPoint.x) || x > Int(appState.hot_zone.maxPoint.x) || y < Int(appState.hot_zone.minPoint.z) || y > Int(appState.hot_zone.maxPoint.z) {

                            height = 5 + randomInt(height) + randomInt(height)
                            building = Building(device:device, type:.simple, x:x + 1, y:y + 1, height:height, width:width - 2, depth:depth - 2, seed:randomInt(), color:color)
                        }
                        else
                        {
                            //use fancy buildings.
                            height = 15 + randomInt(15)
                            width -= 2
                            depth -= 2

                            if flipCoinIsHeads() {
                                building = Building(device:device, type:.tower, x:x + 1, y:y + 1, height:height, width:width, depth:depth, seed:randomInt(), color:color)
                            } else {
                                building = Building(device:device, type:.blocky, x:x + 1, y:y + 1, height:height, width:width, depth:depth, seed:randomInt(), color:color)
                            }
                        }

                        if let building = building {
                            self.buildings.append(building)
                        }
                        break
                    }
                    width -= 1
                    depth -= 1
                }

                //leave big gaps near the edge of the map, no need to pack detail there.
                if y < WORLD_EDGE || y > WORLD_SIZE - WORLD_EDGE {
                    y += 32
                }

                y += 1
            }
            //leave big gaps near the edge of the map
            if x < WORLD_EDGE || x > WORLD_SIZE - WORLD_EDGE {
                x += 28
            }
            x += 1
        }

        // Finally, sort the buildings by texture type
        buildings.sort { $0.textureType.rawValue <= $1.textureType.rawValue }
    }

    func buildRoad(fromX1 x1: Int, y1:Int, width : Int, depth:Int) {
        var lanes = 0
        var divider = 0
        var sidewalk = 0

        // the given rectangle defines a street and its sidewalk. See which way it goes.
        lanes = width > depth ? depth : width

        // if we dont have room for both lanes and sidewalk, abort
        if lanes < 4 {
            return
        }

        //if we have an odd number of lanes, give the extra to a divider.
        if lanes % 2 != 0 {
            lanes -= 1
            divider = 1
        } else {
            divider = 0
        }

        //no more than 10 traffic lanes, give the rest to sidewalks
        sidewalk = max(2, (lanes - 10))
        lanes -= sidewalk
        sidewalk /= 2

        //take the remaining space and give half to each direction
        lanes /= 2

        //Mark the entire rectangle as used
        claimPatch(atX:x1, y:y1, width:width, depth:depth, value:.claimWalk)

        //now place the directional roads
        if (width > depth)
        {
            claimPatch(atX:x1, y:y1 + sidewalk, width:width, depth:lanes, value:[.claimRoad, .roadWest])
            claimPatch(atX:x1, y:y1 + sidewalk + lanes + divider, width:width, depth:lanes, value:[.claimRoad, .roadEast])
        }
        else
        {
            claimPatch(atX:x1 + sidewalk, y:y1, width:lanes, depth:depth, value:[.claimRoad, .roadSouth])
            claimPatch(atX:x1 + sidewalk + lanes + divider, y:y1, width:lanes, depth:depth, value:[.claimRoad, .roadNorth])
        }
    }

    func claimPatch(atX x: Int, y:Int, width:Int, depth:Int, value:MapItem) {

        for xx in x ..< x + width {
            let x = xx.clamped(to:0...WORLD_SIZE-1)
            for yy in y ..< y + depth {
                let y = yy.clamped(to:0...WORLD_SIZE-1)
                WorldMap.instance.addValue(x, y, val:value)
            }
        }
    }

    func buildLightStrip(atX x1:Int, z z1:Int, direction:Direction, height: Float = 0) -> Int {
        var  color : float4 = [0,0,0,1]
        var dir_x = 0
        var dir_z = 0
        let size_adjust : Float = 2.5//.5

        //We adjust the size of the lights with this.
        color = Color(hue: 0.09, saturation: 0.99, brightness: 0.85, alpha: 1.0).rgba()

        switch direction {
        case .north:
            dir_z = 1
            dir_x = 0
        case .south:
            dir_z = 1
            dir_x = 0
        case .east:
            dir_z = 0
            dir_x = 1
        case .west:
            dir_z = 0
            dir_x = 1
        }

        //So we know we're on the corner of an intersection
        //look in the given  until we reach the end of the sidewalk
        var x2 = x1
        var z2 = z1
        var length = 0
        while x2 > 0 && x2 < WORLD_SIZE && z2 > 0 && z2 < WORLD_SIZE {
            if WorldMap.instance.cellAt(x2, z2).contains(.claimRoad) {
                break
            }
            length += 1
            x2 += dir_x
            z2 += dir_z
        }
        if length < 10 {
            return length
        }
        let width = max(abs(x2 - x1), 1)
        let depth = max(abs(z2 - z1), 1)

        let fx1 = Float(x1)
        let fz1 = Float(z1)
        let fwidth = Float(width)
        let fdepth = Float(depth)
        switch direction {
        case .east:
            DecorationManager.instance.addStreetLightStrip(atX:fx1,
                                                           z:fz1 - size_adjust + 1,
                                                           width:fwidth,
                                                           depth:fdepth + size_adjust,
                                                           height:height,
                                                           color:color)
        case .west:
            DecorationManager.instance.addStreetLightStrip(atX:fx1,
                                                           z:fz1 - 1,
                                                           width:fwidth,
                                                           depth:fdepth + size_adjust,
                                                           height:height,
                                                           color:color)
        case .north:
            DecorationManager.instance.addStreetLightStrip(atX:fx1 - 1,
                                                           z:fz1,
                                                           width:fwidth + size_adjust,
                                                           depth:fdepth,
                                                           height:height,
                                                           color:color)
        case .south:
            DecorationManager.instance.addStreetLightStrip(atX:fx1 - size_adjust + 1,
                                                           z:fz1,
                                                           width:fwidth + size_adjust,
                                                           depth:fdepth,
                                                           height:height,
                                                           color:color)
        }

        return length
    }


    func doBuilding(atPlot p:Plot) {

        //now we know how big the rectangle plot is.
        let area = p.width * p.depth
        let color = worldLightColor(randomInt())

        //Make sure the plot is big enough for a building
        if p.width < 10 || p.depth < 10 {
            return
        }

        //If the area is too big for one building, sub-divide it.
        if area > 800 {
            if flipCoinIsHeads() {
                p.width /= 2
                if flipCoinIsHeads() {
                    self.doBuilding(atPlot: Plot(x: p.x, z: p.z, width: p.width, depth: p.depth))
                } else {
                    self.doBuilding(atPlot: Plot(x: p.x + p.width, z: p.z, width: p.width, depth: p.depth))
                }
                return
            }
            else {
                p.depth /= 2
                if flipCoinIsHeads() {
                    self.doBuilding(atPlot: Plot(x: p.x, z: p.z, width: p.width, depth: p.depth))
                } else {
                    self.doBuilding(atPlot: Plot(x: p.x, z: p.z + p.depth, width: p.width, depth: p.depth))
                }
                return
            }
        }

        if area < 100 {
            return
        }

        //The plot is "square" if width & depth are close
        let square = abs(p.width - p.depth) < 10

        //mark the land as used so other buildings don't appear here, even if we don't use it all.
        self.claimPatch(atX: p.x, y: p.z, width: p.width, depth: p.depth, value: .claimBuilding)

        let seed : Int = randomInt()
        let height : Int = 45 + randomInt(10)
        var type : BuildingType = .modern

        //The roundy mod buildings look best on square plots.
        if square && p.width > 20 {
            self.modern_count += 1
            self.skyscrapers += 1

            let building = Building(device:device, type:type, x:p.x, y:p.z, height:height, width:p.width, depth:p.depth, seed:seed, color:color)
            self.buildings.append(building)
            return
        }

        //This spot isn't ideal for any particular building, but try to keep a good mix
        if self.tower_count < self.modern_count && self.tower_count < self.blocky_count {
            type = .tower
            self.tower_count += 1
        }
        else if self.blocky_count < self.modern_count {
            type = .blocky
            self.blocky_count += 1
        } else {
            type = .modern
            self.modern_count += 1
        }


         let building = Building(device:device, type:type, x:p.x, y:p.z, height:height, width:p.width, depth:p.depth, seed:seed, color:color)
        self.buildings.append(building)

        self.skyscrapers += 1
    }

    func findPlot(atX x : Int, andY z:Int) -> Plot {
        var x1 = x
        var x2 = x
        var z1 = z
        var z2 = z

        //We've been given the location of an open bit of land, but we have no
        //idea how big it is. Find the boundary.
        while !self.claimed(atX: x1 - 1, y: z, width: 1, depth: 1) && x1 > 0 {
            x1 -= 1
        }
        while self.claimed(atX: x2 + 1, y: z, width: 1, depth: 1) && x2 < WORLD_SIZE {
            x2 += 1
        }

        while !self.claimed(atX: x, y: z1 - 1, width: 1, depth: 1) && z1 > 0 {
            z1 -= 1
        }
        while !self.claimed(atX: x, y: z2 + 1, width: 1, depth: 1) && z2 < WORLD_SIZE {
            z2 += 1
        }

        let p = Plot(x: x1, z: z1, width: (x2 - x1), depth: (z2 - z1))
        return p
    }

    func claimed(atX x: Int, y:Int, width:Int, depth:Int) -> Bool {
        for xx in x ..< x + width {
            for yy in y ..< y + depth {
                if WorldMap.instance.cellAt(xx, yy).rawValue != 0 {
                    return true
                }
            }
        }
        return false
    }
}
