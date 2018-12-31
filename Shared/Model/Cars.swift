//
//  Car.swift
//  MetalCity
//
//  Created by Andy Qua on 20/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit






class Car {
    var m_position : float3 = float3(0,0,0)
    var m_drive_position : float3 = float3(0,0,0)
    var m_frontColor : float4 = float4(0,0,0,0)
    var m_backColor : float4 = float4(0,0,0,0)
    var m_ready : Bool = false
    var m_front : Bool = false
    var m_drive_angle : Int = 0
    var m_row : Int = 0
    var m_col : Int = 0
    var m_direction : Int = 0
    var m_stuck : Int = 0
    var m_speed : Float = 0
    var m_max_speed : Float = 0
}

class Cars: Model {
    let direction : [float3] = [
        float3(0.0, 0.0, -1.0),
        float3(1.0, 0.0,  0.0),
        float3(0.0, 0.0,  1.0),
        float3(-1.0, 0.0,  0.0)]

    let dangles : [Int] = [ 0, 90, 180, 270]

    let CAR_SIZE : Float = 0.5
    let DEAD_ZONE = 25
    let STUCK_TIME = 230
    let MOVEMENT_SPEED : Float = 0.61

    let NORTH = 0
    let EAST = 1
    let SOUTH = 2
    let WEST = 3


    let frontColor = float4( 1, 1, 0.8, 1.0 )
    let backColor = float4( 1, 0.2, 0, 1.0 )

    var device : MTLDevice

    var vertices = [Vertex]()
    var indices = [UInt32]()


    var carAngles = [float2]()
    var carMap : [[UInt8]]

    var cars = [Car]()

    init( device: MTLDevice ) {
        self.device = device

        let vertexShader : String = "carVertexShader"
        let fragmentShader : String = "carFragmentShader"

        carMap = Array(repeating: Array(repeating: 0, count: WORLD_SIZE), count: WORLD_SIZE)

        for i in 0 ..< 360 {
            var v = float2(0, 0)
            v.x = cosf(Float(i) * DEGREES_TO_RADIANS) * CAR_SIZE
            v.y = sinf(Float(i) * DEGREES_TO_RADIANS) * CAR_SIZE
            carAngles.append(v)
        }

        super.init()

        self.renderPipelineState = createLibraryAndRenderPipeline( device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader  )
    }

    func addCar( ) {

        cars.append( Car() )

        let newVertices : [Vertex] = [
            Vertex(position:vector_float4(0,  0,  0, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 0.0)),
            Vertex(position:vector_float4(0,  0,  0, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 0.0)),
            Vertex(position:vector_float4(0,  0,  0, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 1.0)),
            Vertex(position:vector_float4(0,  0,  0, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 1.0)),
            ]

        let start = UInt32(vertices.count)
        indices.append(contentsOf: [ 0 + start, 1 + start, 2 + start, 0 + start, 2 + start, 3 + start ])
        vertices.append(contentsOf: newVertices)
    }

    func createBuffers() {
        guard vertices.count > 0 else { return }

        vertexBuffer = device.makeBuffer(bytes:vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices plane"

        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: MemoryLayout<UInt32>.stride * indices.count,
                                        options: [])
        indexBuffer.label = "indices plane"
    }

    func update(  )
    {
        guard vertexBuffer != nil else { return }
        var pointer = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: vertices.count)
        for car in cars {
            // 4 vertices per car
            updateCar( car:car, vertexPtr:pointer )

            pointer = pointer.advanced(by: 4)
        }
    }



    func updateCar( car: Car, vertexPtr: UnsafeMutablePointer<Vertex> ) {
        var camera : float3

        //If the car isn't ready, place it on the map and get it moving
        camera = appState.cameraState.position
        if (!car.m_ready)
        {
            car.m_row = DEAD_ZONE + randomInt(WORLD_SIZE - DEAD_ZONE * 2)
            car.m_col = DEAD_ZONE + randomInt(WORLD_SIZE - DEAD_ZONE * 2)
            //if there is already a car here, forget it.
            if carMap[car.m_row][car.m_col] > 0 {
                return
            }

            //if there is already a car here, forget it.
            if !testPosition(atRow: car.m_row, col: car.m_col, forCar:car) {
                return
            }

            if !WorldMap.instance.isVisible(x:car.m_row, y:car.m_col) {
                return
            }

            //good spot. place the car
            var l : Int = 0
            var r : Int = 0
            if WorldMap.instance.cellAt(car.m_row, car.m_col).contains(.roadNorth) {
                car.m_direction = NORTH

                // Move car to middle of road
                l = car.m_row
                while WorldMap.instance.cellAt(l, car.m_col).contains(.roadNorth) {
                    l -= 1
                }
                r = car.m_row
                while WorldMap.instance.cellAt(r, car.m_col).contains(.roadNorth) {
                    r += 1
                }
                car.m_row = l+2 //r-l > 4 ? l+2 : l+1
            }
            if WorldMap.instance.cellAt(car.m_row, car.m_col).contains(.roadEast) {
                car.m_direction = EAST

                // Move car to middle of road
                var l = car.m_col
                while WorldMap.instance.cellAt(car.m_row, l).contains(.roadEast) {
                    l -= 1
                }
                r = car.m_col
                while ( WorldMap.instance.cellAt(car.m_row, r).contains(.roadEast) ) {
                    r += 1
                }
                car.m_col = l+2// r-l > 4 ?l+2 : l+1
            }
            if WorldMap.instance.cellAt(car.m_row, car.m_col).contains(.roadSouth) {
                car.m_direction = SOUTH
                // Move car to middle of road
                l = car.m_row
                while WorldMap.instance.cellAt(l, car.m_col).contains(.roadSouth) {
                    l -= 1
                }
                r = car.m_row
                while WorldMap.instance.cellAt(r, car.m_col).contains(.roadSouth) {
                    r += 1
                }
                car.m_row = r-2//r-l > 4 ? r-2 : r-1
            }
            if (WorldMap.instance.cellAt(car.m_row, car.m_col).contains(.roadWest))
            {
                car.m_direction = WEST
                // Move car to middle of road
                l = car.m_col
                while WorldMap.instance.cellAt(car.m_row, l).contains(.roadWest) {
                    l -= 1
                }
                r = car.m_col
                while WorldMap.instance.cellAt(car.m_row, r).contains(.roadWest) {
                    r += 1
                }
                car.m_col = r-2//r-l > 4 ? r-2 : r-1
            }

            car.m_position = float3(Float(car.m_row), 0.1, Float(car.m_col))
            car.m_drive_position = car.m_position
            car.m_ready = true

            car.m_drive_angle = dangles[car.m_direction]
            car.m_max_speed = Float(4 + randomInt(6)) / 10.0
            car.m_speed = 0.0
            car.m_stuck = 0
            carMap[car.m_row][car.m_col] += 1
        }
        //take the car off the map and move it
        carMap[car.m_row][car.m_col] -= 1
        let old_pos = car.m_position
        car.m_speed += car.m_max_speed * 0.05
        car.m_speed = min(car.m_speed, car.m_max_speed)
        car.m_position = car.m_position + ( direction[car.m_direction] * MOVEMENT_SPEED * car.m_speed )
        let futurePos = car.m_position + ( direction[car.m_direction] * MOVEMENT_SPEED * car.m_speed * 5 )

        //If the car has moved out of view, there's no need to keep simulating it.
        if !WorldMap.instance.isVisible( x:car.m_row,y: car.m_col) {
            car.m_ready = false
        }

        //if the car is far away, remove it.  We use manhattan units because buildings almost always
        //block views of cars on the diagonal.
//        if fabs(camera.x - m_position.x) + fabs(camera.z - m_position.z) > state.render.fog_distance {
//            m_ready = false
//        }
        //if the car gets too close to the edge of the map, take it out of play
        if Int(car.m_position.x) < DEAD_ZONE || Int(car.m_position.x) > (WORLD_SIZE - DEAD_ZONE) {
            car.m_ready = false
        }
        if Int(car.m_position.z) < DEAD_ZONE || Int(car.m_position.z) > (WORLD_SIZE - DEAD_ZONE) {
            car.m_ready = false
        }
        if car.m_stuck >= STUCK_TIME {
            car.m_ready = false
        }
        if !car.m_ready {
            return
        }

        if carMap[Int(futurePos.x)][Int(futurePos.z)] > 0 {
            // Slow down
            if car.m_max_speed > 0.3 {
                car.m_max_speed -= 0.1
            }
        }

        //Check the new position and make sure its not in another car
        let new_row = Int(car.m_position.x)
        let new_col = Int(car.m_position.z)
        if new_row != car.m_row || new_col != car.m_col {
            //see if the new position places us on top of another car
            if carMap[new_row][new_col] > 0 {
                car.m_position = old_pos
                car.m_speed = 0.0
                car.m_stuck += 1
                if car.m_max_speed > 0.3 {
                    car.m_max_speed -= 0.1
                }
            } else {
                //look at the new position and decide if we're heading towards or away from the camera
                car.m_row = new_row
                car.m_col = new_col
                car.m_stuck = 0
                if car.m_direction == NORTH {
                    car.m_front = camera.z < car.m_position.z
                } else if car.m_direction == SOUTH {
                    car.m_front = camera.z > car.m_position.z
                } else if car.m_direction == EAST {
                    car.m_front = camera.x > car.m_position.x
                } else {
                    car.m_front = camera.x < car.m_position.x
                }
            }
        }
        car.m_drive_position = (car.m_drive_position + car.m_position) / 2.0
        //place the car back on the map
        carMap[car.m_row][car.m_col] += 1



        if !car.m_ready {
            return
        }

        if !WorldMap.instance.isVisible( pos: car.m_drive_position ) {
            return
        }

        let top = CAR_SIZE * 2

        var pos = car.m_drive_position
        let angle = (360 - Int(angleBetweenPoints(car.m_position.x, car.m_position.z, pos.x, pos.z))) % 360
        let turn = Int(mathAngleDifference(Float(car.m_drive_angle), Float(angle)))

        car.m_drive_angle += (turn > 0 ? 1 : turn < 0 ? -1 : 0)
        pos = pos + float3(0.5, 0.0, 0.5)

        let c : float4
        if car.m_front {
            c = frontColor
        } else {
            c = backColor
        }
        let xAngle = carAngles[angle].x
        let zAngle = carAngles[angle].y

        var ptr = vertexPtr
        ptr.pointee.position = float4(pos.x + xAngle, 0, pos.z + zAngle, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(pos.x - xAngle, 0, pos.z - zAngle, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(pos.x - xAngle,  top, pos.z - zAngle, 1)
        ptr.pointee.color = c
        ptr = ptr.advanced(by: 1)
        ptr.pointee.position = float4(pos.x + xAngle,  top, pos.z + zAngle, 1)
        ptr.pointee.color = c
    }


    func testPosition( atRow row: Int, col: Int, forCar car:Car ) -> Bool {
        //test the given position and see if it's already occupied
        if carMap[row][col] != 0 {
            return false
        }
        //now make sure that the lane is going the right direction
        if !WorldMap.instance.cellAt( row, col).contains( .claimRoad ) {
            return false
        }
        if WorldMap.instance.cellAt( row, col).rawValue != WorldMap.instance.cellAt( car.m_row, car.m_col).rawValue {
            return false
        }
        return true
    }

    override func draw( commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer ) {
        guard indices.count > 0 else { return }
        if vertexBuffer == nil {
            self.createBuffers()
        }

        commandEncoder.setRenderPipelineState(self.renderPipelineState)

        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)


        if let texture = TextureManager.instance.textures[.headlight] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        } else {
            print( "ARRGH!")
        }

        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint32,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }
}
