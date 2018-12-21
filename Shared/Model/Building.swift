//
//  Building.swift
//  MetalCity
//
//  Created by Andy Qua on 16/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

enum BuildingType {
    case tower
    case blocky
    case modern
    case simple
}

enum BuildingAddOns : CaseIterable
{
    case none
    case logo
    case trim
    case lights
    
    static func random() -> BuildingAddOns {
        return BuildingAddOns.allCases.randomElement()!
    }
}



class Building : Model {
    
    var bufferProvider : BufferProvider!
    var device : MTLDevice

    var x : Int
    var y : Int
    var width : Int
    var height : Int
    var depth : Int

    var gridX : Int
    var gridY : Int

    var textureType : TextureType
    var type : BuildingType
    
    var seed : Int
    var roof_tiers : Int = 0
    var color : float4
    var trim_color : float4
    
    var haveLights = false
    var have_trim = false
    var have_logo = false
    
    var vertexCount : Int = 0
    
    init( device: MTLDevice, type:BuildingType, x:Int, y:Int, height:Int, width:Int, depth:Int, seed:Int, color:float4) {
        self.device = device

        self.x = x
        self.y = y
        
        self.width = width
        self.height = height
        self.depth = depth
        
        self.type = type
        
        self.seed = seed
        self.color = color

        self.trim_color = worldLightColor(seed)
        
        self.gridX = WorldMap.worldToGrid( x + width/2 )
        self.gridY = WorldMap.worldToGrid( y + depth / 2)
        
        
        // Generate a random texture
        self.textureType = TextureType.randomBuildingTexture()

        super.init()
        
        let vertexShader : String = "indexedVertexShader"
        let fragmentShader : String = "indexedFragmentShader"
//        let vertexShader : String = "objectVertexShader"
//        let fragmentShader : String = "objectFragmentShader"
        createLibraryAndRenderPipeline( device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader  )


        switch type {
        case .modern:
            createModern()
            break
        case .simple:
            createSimple()
            break
        case .blocky:
            createBlocky()
            break
        case .tower:
            createTower()
            break
        }
        
    }
    
    func update( )
    {
        self.uniformsBuffer = bufferProvider.nextBuffer()
        
        let translation = float4x4(translate: [0,0,0])
        
        // copy matrices into uniform buffers
        var uniform = PerInstanceUniforms()
        uniform.modelMatrix = translation
        uniform.normalMatrix = uniform.modelMatrix.upper_left3x3()
        
        uniform.r = 1
        uniform.g = 1
        uniform.b = 1
        uniform.a = 1.0
        
        memcpy(self.uniformsBuffer.contents() + MemoryLayout<PerInstanceUniforms>.stride*0, &uniform, MemoryLayout<PerInstanceUniforms>.stride)
    }
    
    func prepareToDraw() {
//        _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    func finishDrawing() {
//        self.bufferProvider.avaliableResourcesSemaphore.signal()
    }
    
    override func draw( commandEncoder : MTLRenderCommandEncoder, sharedUniformsBuffer : MTLBuffer ) {
        if vertexCount == 0 {
            return
        }
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        
        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(sharedUniformsBuffer, offset: 0, index: 1)
//        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 2)

        if let texture = TextureManager.instance.textures[textureType] {
            commandEncoder.setFragmentTexture(texture, index: 0)
        }
        
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount )
    }
    
    func createSimple() {

        //How tall the flat-color roof is
        let cap_height = Float(1 + randomValue(4))
        
        //how much the ledge sticks out
        let ledge = Float(randomValue(10)) / 30.0
        
        let x1 = Float(x)
        let x2 = Float(x + width)
        let y1 = Float(0.0)
        let y2 = Float(height)
        let z2 = Float(y)
        let z1 = Float(y + depth)
        
        var u = Float(randomValue(SEGMENTS_PER_TEXTURE)) / Float(SEGMENTS_PER_TEXTURE)
        
        let v1 = Float(randomValue(SEGMENTS_PER_TEXTURE)) / Float(SEGMENTS_PER_TEXTURE)
        let v2 = v1 + Float(height) * ONE_SEGMENT
        
        var verticesArray = [Vertex]()

        verticesArray.append( Vertex(position:vector_float4(x1,  y1,  z1, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u, v1)) )
        verticesArray.append( Vertex(position:vector_float4(x1,  y2,  z1, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u, v2)) )

        u += Float(depth) / Float(SEGMENTS_PER_TEXTURE)
        verticesArray.append( Vertex(position:vector_float4(x1, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x1, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )
        
        verticesArray.append( Vertex(position:vector_float4(x1, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x1, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )

        u += Float(depth) / Float(SEGMENTS_PER_TEXTURE)
        verticesArray.append( Vertex(position:vector_float4(x2, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x2, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )
        
        verticesArray.append( Vertex(position:vector_float4(x2, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x2, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )

        u += Float(depth) / Float(SEGMENTS_PER_TEXTURE)
        verticesArray.append( Vertex(position:vector_float4(x2, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x2, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )
        
        verticesArray.append( Vertex(position:vector_float4(x2, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x2, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)) )

        u += Float(depth) / Float(SEGMENTS_PER_TEXTURE)
        verticesArray.append( Vertex(position:vector_float4(x1, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)) )
        verticesArray.append( Vertex(position:vector_float4(x1, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u, v2)) )
        
        let cubeVertices = self.constructCube(left: x1 - ledge, right: x2 + ledge, front: z2 - ledge, back: z1 + ledge, bottom: Float(height), top: Float(height) + cap_height, textured: false)

        verticesArray.append(contentsOf: cubeVertices)
        
        self.convertQuadsToTriangles( verticesArray )
        //[self convertQuadsToLinesForMesh]
    }
    
    func createModern() {
        //How many 10-degree segments to build before the next skip.
        let skip_interval = 1 + randomValue(8)
        //When a skip happens, how many degrees should be skipped
        let skip_delta = (1 + randomValue(2)) * 30 //30 60 or 90
        
        //See if this is eligible for fancy lighting trim on top
        
        //Get the center and radius of the circle
        let half_depth = depth / 2
        let half_width = width / 2
        var center = float3(Float(x + half_width), 0.0, Float(y + half_depth) )
        var radius = float2(Float(half_width), Float(half_depth))
        var windows = 0
        
        var points = 0
        var skip_counter = 0
        var v = Vertex()
        var verticesArray = [Vertex]()

        var pos = float4(0, 0, 0, 1)
        var angle = 0
        while angle <= 360 {
            if (skip_counter >= skip_interval && (angle + skip_delta < 360))
            {
                angle += skip_delta
                skip_counter = 0
            }
            
            var p = pos
            pos.x = center.x - sin(Float(angle) * DEGREES_TO_RADIANS) * radius.x
            pos.z = center.z + cos(Float(angle) * DEGREES_TO_RADIANS) * radius.y
            
            var length = 0
            if (angle > 0 && skip_counter == 0)
            {
                length = Int(distance(p, pos))
                windows += length
            } else if (skip_counter != 1) {
                windows += 1
            }
            
            p = pos
            pos.y = 0
            v.position = pos
            v.texCoords = float2(Float(windows) / Float(SEGMENTS_PER_TEXTURE), 0.0)
            verticesArray.append(v)
            
            pos.y = Float(height)
            v.position = pos
            v.texCoords = float2(Float(windows) / Float(SEGMENTS_PER_TEXTURE), Float(height) / Float(SEGMENTS_PER_TEXTURE))
            verticesArray.append(v)
 
            points += 2
            skip_counter += 1
        
            angle += 10
        }
        
        var vlist = [Vertex]()
        for i in stride( from:0, to:points, by:2 ) {
            var v1 = verticesArray[i]
            var v2 = verticesArray[i+1]
            var v3 : Vertex
            var v4 : Vertex
            if ( i < (points-2) )
            {
                v3 = verticesArray[i+2]
                v4 = verticesArray[i+3]
            }
            else
            {
                v3 = verticesArray[i-(points-2)]
                v4 = verticesArray[i-(points-2)+1]
            }
            
            // Triangle1 = v1, v2, v3
            // Triangle2 = v2, v4, v3
            
            let n1 = calculateTriangleSurfaceNormal(v1:v1, v2:v2, v3:v3 )
            let n2 = calculateTriangleSurfaceNormal(v1:v2, v2:v4, v3:v3 )
            
            v1.normal = n1
            v2.normal = n1
            v3.normal = n1
            vlist.append( contentsOf:[v1, v2, v3] )
            
            v2.normal = n2
            v4.normal = n2
            v3.normal = n2
            vlist.append( contentsOf:[v2, v4, v3] )
        }
        
        // Now add the roof
        // v is now the centre point of the roof
        pos.x = center.x
        pos.y += 1
        pos.z = center.z

        v.position = pos
        
        for i in 0 ..< points / 2 {
            if points - (1 + (i+1) * 2) < 0 {
                break
            }
            
            var v1 = verticesArray[points - (1 + i * 2)]
            var v2 = verticesArray[points - (1 + (i+1) * 2)]
            
            let n1 = calculateTriangleSurfaceNormal(v1:v, v2:v1, v3:v2 )
            v.normal = n1
            v1.normal = n1
            v2.normal = n1
            v.texCoords = float2(0, 0)
            v1.texCoords = float2(0, 0)
            v2.texCoords = float2(0, 0)
            vlist.append( contentsOf:[v, v1, v2] )
        }
        createVertexBufforFromVertexArray( array:vlist )
    }
    
    func createBlocky() {
        //Choose if the corners of the building are to be windowless.
        let blank_corners = flipCoinIsHeads()
        
        //Choose a random column on our texture
        var uv_start = Float(randomValue(SEGMENTS_PER_TEXTURE)) / Float(SEGMENTS_PER_TEXTURE)
            
        //Choose how the windows are grouped
        let grouping = 2 + randomValue(4)
        
        //Choose how tall the lid should be on top of each section
        let lid_height = Float(randomValue(3) + 1)
        
        //find the center of the building.
        let mid_x = x + width / 2
        let mid_z = y + depth / 2
        var max_left = 1
        var max_right = 1
        var max_front = 1
        var max_back = 1
        var h = height

        
        let min_height = 3
        let half_depth = depth / 2
        let half_width = width / 2
        var tiers = 0
        var max_tiers = 0
        if height > 40 {
            max_tiers = 15
        } else if height > 30 {
            max_tiers = 10
        } else if height > 20 {
            max_tiers = 5
        } else if height > 10 {
            max_tiers = 2
        } else {
            max_tiers = 1
        }
        //We begin at the top of the building, and work our way down.
        //Viewed from above, the sections of the building are randomly sized
        //rectangles that ALWAYS include the center of the building somewhere within
        //their area.
        
        var  walls : [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: max_tiers)
        var vertices = [Vertex]()
        var tmpV : [Vertex]
        while ( true ) {
            if h < min_height || tiers >= max_tiers {
                break
            }

            //pick new locationsfor our four outer walls
            let left = (randomValue() % half_width) + 1
            let right = (randomValue() % half_width) + 1
            let front = (randomValue() % half_depth) + 1
            let back = (randomValue() % half_depth) + 1
            var skip = false
            
            //At least ONE of the walls must reach out beyond a previous maximum.
            //Otherwise, this tier would be completely hidden within a previous one.
            if left <= max_left && right <= max_right && front <= max_front && back <= max_back {
                skip = true
            }
            
            //If any of the four walls is in the same position as the previous max,then
            //skip this tier, or else the two walls will end up z-fightng.
            if left == max_left || right == max_right || front == max_front || back == max_back {
                skip = true
            }
            
            for j in 0 ..< tiers {
                if skip {
                    break
                }
                
                if left == walls[j][0] || right == walls[j][1] || front == walls[j][2] || back == walls[j][3] {
                    skip = true
                }
            }
                
            if !skip {
                // Store walls
                walls[tiers][0] = left
                walls[tiers][1] = right
                walls[tiers][2] = front
                walls[tiers][3] = back
                
                //if this is the top, then put some lights up here
                max_left = max(left, max_left)
                max_right = max(right, max_right)
                max_front = max(front, max_front)
                max_back = max(back, max_back)
                
                //Now build the four walls of this part
                (uv_start, tmpV) = constructWall( atX:mid_x - left, y:2, z:mid_z + back, dir:.south, length:front + back,
                    height:h-2, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
                uv_start -= ONE_SEGMENT
                vertices.append(contentsOf: tmpV)
                
                (uv_start, tmpV) = constructWall( atX:mid_x - left, y:2, z:mid_z - front, dir:.east, length:right + left,
                    height:h-2, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
                uv_start -= ONE_SEGMENT
                vertices.append(contentsOf: tmpV)

                (uv_start, tmpV) = constructWall( atX:mid_x + right, y:2, z:mid_z - front, dir:.north, length:front + back,
                    height:h-2, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
                uv_start -= ONE_SEGMENT
                vertices.append(contentsOf: tmpV)

                (uv_start, tmpV) = constructWall( atX:mid_x + right, y:2, z:mid_z + back, dir:.west, length:right + left,
                    height:h-2, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
                uv_start -= ONE_SEGMENT
                vertices.append(contentsOf: tmpV)


                if tiers == 0 {
                    tmpV = constructRoof(left: Float(mid_x - left), right: Float(mid_x + right), front: Float(mid_z - front), back: Float(mid_z + back), bottom: Float(h), roofTiers: 0)
                } else {
                    //add a flat-color lid onto this section
                    tmpV = constructCube(left: Float(mid_x - left), right: Float(mid_x + right), front: Float(mid_z - front), back: Float(mid_z + back), bottom: Float(h), top: Float(h) + lid_height, textured: false)
                }
                vertices.append(contentsOf: tmpV)

                height -= (randomValue() % 10) + 1
                tiers += 1
            }
            h -= 1
        }
        
        tmpV = constructCube(left: Float(mid_x - half_width), right: Float(mid_x + half_width), front: Float(mid_z - half_depth), back: Float(mid_z + half_depth), bottom: 0, top: 2, textured: false)
        vertices.append(contentsOf: tmpV)
        
        convertQuadsToTriangles(vertices)
    }
    
    func createTower() {
        
        var vertices = [Vertex]()
        var tmpV : [Vertex]

        
        //How much ledges protrude from the building
        let ledge = Float(randomValue(3)) * 0.25
        //How tall the ledges are, in stories
        let ledge_height = randomValue(4) + 1
        //How the windows are grouped
        let grouping = randomValue(3) + 2
        //if the corners of the building have no windows
        let blank_corners = randomValue(4) > 0
        
        //if the roof is pointed or has infrastructure on it
        //    roof_spike = randomValue(3) == 0
        
        //What fraction of the remaining height should be given to each tier
        let tier_fraction = 2 + randomValue(4)
        //How often (in tiers) does the building get narrorwer?
        let narrowing_interval = 1 + randomValue(10)
        //The height of the windowsless slab at the bottom
        let foundation = 2 + randomValue(3)
        
        //The odds that we'll have a big fancy spikey top
        //    tower = randomValue(5) != 0 && _height > 40
        
        //set our initial parameters
        var left = x
        var right = x + width
        var front = y
        var back = y + depth
        var bottom = 0
        var tiers = 0
        
        
        //build the foundations.
        tmpV = constructCube(left: Float(left) - ledge, right: Float(right) + ledge, front: Float(front) - ledge, back: Float(back) + ledge, bottom: Float(bottom), top: Float(foundation), textured: true)
        vertices.append(contentsOf: tmpV)

        bottom += foundation
        
        //now add tiers until we reach the top
        while ( true )
        {
            let remaining_height = height - bottom
            let section_depth = back - front
            let section_width = right - left
            var section_height = max(remaining_height / tier_fraction, 2)
            if remaining_height < 10 {
                section_height = remaining_height
            }
            //Build the four walls
            var uv_start = Float(randomValue(SEGMENTS_PER_TEXTURE)) / Float(SEGMENTS_PER_TEXTURE)

            (uv_start, tmpV) = constructWall( atX:left, y:bottom, z:back, dir:.south, length:section_depth,
                                              height:section_height, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
            uv_start -= ONE_SEGMENT
            vertices.append(contentsOf: tmpV)

            (uv_start, tmpV) = constructWall( atX:left, y:bottom, z:front, dir:.east, length:section_width,
                                              height:section_height, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
            uv_start -= ONE_SEGMENT
            vertices.append(contentsOf: tmpV)

            (uv_start, tmpV) = constructWall( atX:right, y:bottom, z:front, dir:.north, length:section_depth,
                                              height:section_height, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
            uv_start -= ONE_SEGMENT
            vertices.append(contentsOf: tmpV)

            (uv_start, tmpV) = constructWall( atX:right, y:bottom, z:back, dir:.west, length:section_width,
                                              height:section_height, windowGroups:grouping, uvStart:uv_start, blankCorners:blank_corners)
            uv_start -= ONE_SEGMENT
            vertices.append(contentsOf: tmpV)

            bottom += section_height
            
            //Build the slab / ledges to cap this section.
            if bottom + ledge_height > height {
                break
            }
            tmpV = constructCube(left: Float(left) - ledge, right: Float(right) + ledge, front: Float(front) - ledge, back: Float(back) + ledge, bottom: Float(bottom), top: Float(bottom + ledge_height), textured: false)
            vertices.append(contentsOf: tmpV)
            
            bottom += ledge_height
            if bottom > height {
                break
            }
            tiers += 1
            if tiers % narrowing_interval == 0 {
                if section_width > 7 {
                    left += 1
                    right -= 1
                }
                if section_depth > 7 {
                    front += 1
                    back -= 1
                }
            }
        }
        tmpV = constructRoof(left: Float(left), right:Float(right), front:Float(front), back:Float(back), bottom:Float(bottom), roofTiers: 0)
        vertices.append(contentsOf: tmpV)
        
        convertQuadsToTriangles(vertices)

    }
    
    func constructWall( atX startX:Int, y startY:Int, z startZ:Int, dir:Direction, length:Int, height:Int, windowGroups:Int, uvStart: Float, blankCorners:Bool) -> (Float, [Vertex]) {

        
        var x = 0
        var z = 0
        var step_x = 0
        var step_z = 0
        
        switch (dir)
        {
        case .north:
            step_z = 1
            step_x = 0
        case .west:
            step_z = 0
            step_x = -1
        case .south:
            step_z = -1
            step_x = 0
        case .east:
            step_z = 0
            step_x = 1
        }
        
        x = startX
        z = startZ
        
        var mid = (length / 2) - 1
        let odd = 1 - (length % 2)
        if length % 2 != 0 {
            mid += 1
        }
        
        var blank = false
        var textureS = uvStart
        var vertices = [Vertex]()
        for i in 0 ... length {
            //column counts up to the mid point, then back down, to make it symetrical
            var column : Int
            if i <= mid {
                column = i - odd
            } else {
                column = (mid) - (i - (mid))
            }
            
            let last_blank = blank
            blank = (column % windowGroups) > windowGroups / 2
            if blankCorners && i == 0 {
                blank = true
            }
            if blankCorners && i == (length - 1) {
                blank = true
            }
            
            if last_blank != blank || i == 0 || i == length {
                // Sneaky, because original code used QUADStrips, and we are just simulating quads here
                // we need to double up on the vertices for each point except the first and last pairs
                // The first and last pair we only add once
                let loop = (i == 0 || i == length) ? 1 : 2
                var v = Vertex()
                for _ in 0 ..< loop {
                    v.position = float4( Float(x), Float(startY), Float(z), 1)
                    v.texCoords = float2( textureS, Float(startY) / Float(SEGMENTS_PER_TEXTURE))
                    vertices.append(v)
                    
                    v.position = float4( Float(x), Float(startY + height), Float(z), 1)
                    v.texCoords = float2( textureS, Float(startY + height) / Float(SEGMENTS_PER_TEXTURE))
                    vertices.append(v)
                }
            }
            
            if !blank && i != length {
                textureS += 1.0 / Float(SEGMENTS_PER_TEXTURE)
            }
            x += step_x
            z += step_z
        }
        
        return (textureS, vertices)
    }
    
    func constructRoof(left:Float, right:Float, front:Float, back:Float, bottom:Float, roofTiers : Int) -> [Vertex] {
        
        var vertices = [Vertex]()
        let roof_tiers = roofTiers + 1
        
        let max_tiers = self.height / 10
        let width = Int(right - left)
        let depth = Int(back - front)
        let roofHeight = Float(5 - roof_tiers)
        //    logo_offset = 0.2f
        
        
        //See if this building is special and worthy of fancy roof decorations.
        var addon = BuildingAddOns.none
        if bottom > 35.0 {
            addon = BuildingAddOns.random()
        }
        
        //Build the roof slab
        var tmpV = constructCube(left: left, right: right, front: front, back: back, bottom: bottom, top: bottom + roofHeight, textured: false)
        vertices.append(contentsOf: tmpV)
        
        /*
         //Consider putting a logo on the roof, if it's tall enough
         if (addon == ADDON_LOGO && !_have_logo)
         {
         d = new CDeco(_state)
         if (width > depth)
         face = COIN_FLIP ? NORTH : SOUTH
         else
         face = COIN_FLIP ? EAST : WEST
         switch (face)
         {
         case NORTH:
         start = glVector ((float)left, (float)back + logo_offset)
         end = glVector ((float)right, (float)back + logo_offset)
         break
         case SOUTH:
         start = glVector ((float)right, (float)front - logo_offset)
         end = glVector ((float)left, (float)front - logo_offset)
         break
         case EAST:
         start = glVector ((float)right + logo_offset, (float)back)
         end = glVector ((float)right + logo_offset, (float)front)
         break
         case WEST:
         default:
         start = glVector ((float)left - logo_offset, (float)front)
         end = glVector ((float)left - logo_offset, (float)back)
         break
         }
         d->CreateLogo (start, end, bottom, WorldLogoIndex (_state), _trim_color)
         _have_logo = true
         }
         else if (addon == ADDON_TRIM)
         {
         d = new CDeco(_state)
         _state->building.vector_buffer[0] = glVector (left, bottom, back)
         _state->building.vector_buffer[1] = glVector (left, bottom, front)
         _state->building.vector_buffer[2] = glVector (right, bottom, front)
         _state->building.vector_buffer[3] = glVector (right, bottom, back)
         d->CreateLightTrim (_state->building.vector_buffer, 4, (float)randomValue(_state, 2) + 1.0f, _seed, _trim_color)
         }
         else
         */

/*
        if addon == ADDON_LIGHTS && !_haveLights {
            Light *l = [[Light alloc] initWithPosition:GLKVector3Make(left, Float(bottom + 2), front) Color:_trim_color Size:2 Blink:NO]
            [state.lights addObject:l]
            [state.lights addObject:[[Light alloc] initWithPosition:GLKVector3Make(right, Float(bottom + 2), front) Color:_trim_color Size:2 Blink:NO]]
            [state.lights addObject:[[Light alloc] initWithPosition:GLKVector3Make(right, Float(bottom + 2), back) Color:_trim_color Size:2 Blink:NO]]
            [state.lights addObject:[[Light alloc] initWithPosition:GLKVector3Make(left, Float(bottom + 2), back) Color:_trim_color Size:2 Blink:NO]]
            _haveLights = true
        }
*/
        
        let newBottom = bottom + roofHeight
        
        //If the roof is big enough, consider making another layer
        if width > 7 && depth > 7 && roof_tiers < max_tiers {
            tmpV = constructRoof(left: left+1, right: right-1, front: front+1, back: back-1, bottom: newBottom, roofTiers: roof_tiers)
            vertices.append(contentsOf: tmpV)

            return vertices
        }

        //1 air conditioner block for every 15 floors sounds reasonble
        let air_conditioners = self.height / 15
        for _ in 0 ..< air_conditioners {
            let ac_size = Float(10 + randomValue(30)) / 10
            let ac_height = Float(randomValue(20)) / 10 + 1.0
            var ac_x = left + Float(randomValue(width))
            var ac_y = front + Float(randomValue(depth))
            
            //make sure the unit doesn't hang off the right edge of the building
            if ac_x + ac_size > right {
                ac_x = right - ac_size
            }
            
            //make sure the unit doesn't hang off the back edge of the building
            if ac_y + ac_size > back {
                ac_y = back - ac_size
            }
            let ac_base = newBottom
            
            //make sure it doesn't hang off the edge
            tmpV = constructCube(left:ac_x , right: ac_x + ac_size, front: ac_y, back: ac_y + ac_size, bottom: ac_base, top: ac_base + ac_height, textured: false)
            vertices.append(contentsOf: tmpV)
        }
        
        if (self.height > 45 && flipCoinIsHeads())
        {
/*
            Decoration *d = [[Decoration alloc] init]
            [d createRadioTower:GLKVector3Make(Float(left + right) / 2.0f, (float)newBottom, Float(front + back) / 2.0f) height:15.0f]
            [state.decorations addObject:d]
*/
        }
        
        return vertices
    }

    func constructCube( left: Float, right: Float, front:Float, back:Float, bottom:Float, top:Float, textured:Bool ) -> [Vertex] {
        let x1 = left
        let x2 = right
        let y1 = bottom
        let y2 = top
        let z1 = front
        let z2 = back
        
        let mapping = Float(SEGMENTS_PER_TEXTURE)
        let u = Float(randomValue() % SEGMENTS_PER_TEXTURE) / Float(SEGMENTS_PER_TEXTURE)
        let u1 = u + Float(width) / Float(SEGMENTS_PER_TEXTURE)
        let u2 = u1 + Float(depth) / Float(SEGMENTS_PER_TEXTURE)
        let u3 = u2 + Float(width) / Float(SEGMENTS_PER_TEXTURE)
        let u4 = u3 + Float(width) / Float(SEGMENTS_PER_TEXTURE)
        let v1 = bottom / mapping
        let v2 = top / mapping
        
        var v : [Vertex] = [
            Vertex(position:vector_float4(x1, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v1)),
            Vertex(position:vector_float4(x1, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u,v2)),
            Vertex(position:vector_float4(x2, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u1,v1)),
            Vertex(position:vector_float4(x2, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u1,v2)),
            Vertex(position:vector_float4(x2, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u2,v1)),
            Vertex(position:vector_float4(x2, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u2,v2)),
            Vertex(position:vector_float4(x1, y1, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u3,v1)),
            Vertex(position:vector_float4(x1, y2, z2, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u3,v2)),
            Vertex(position:vector_float4(x1, y1, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u4,v1)),
            Vertex(position:vector_float4(x1, y2, z1, 1.0), normal:vector_float4( 0, 1, 0, 1.0), color:vector_float4(1,1,1,1), texCoords:vector_float2(u4,v2))]
        
        for i in 0 ..< 10 {
            if textured {
                v[i].texCoords = vector_float2( (v[i].position.x + v[i].position.z) / Float(SEGMENTS_PER_TEXTURE), v[i].texCoords.y )
            } else {
                v[i].texCoords = vector_float2( 0, 0 )
            }
        }
        
        var vlist = [Vertex]()
        for i in stride( from:0, to: 10-2, by:2 ) {
            vlist.append(v[i])
            vlist.append(v[i+1])
            vlist.append(v[i+2])
            vlist.append(v[i+3])
        }
        
        // Top and bottom should have no texture shown
        for i in 0 ..< 10 {
            v[i].texCoords = vector_float2( 0, 0 )
        }
        
        vlist.append(v[1])
        vlist.append(v[7])
        vlist.append(v[3])
        vlist.append(v[5])

        vlist.append(v[0])
        vlist.append(v[6])
        vlist.append(v[2])
        vlist.append(v[4])

        return vlist
    }
    
    func convertQuadsToTriangles( _ vlist : [Vertex] ) {
        var vertices = [Vertex]()
        
        // generate triangles
        let points = vlist.count
        for i in stride( from:0, to: points, by: 4 ) {
            var v1 = vlist[i]
            var v2 = vlist[i+1]
            var v3 = vlist[i+2]
            var v4 = vlist[i+3]
            
            v1.color = self.color
            v2.color = self.color
            v3.color = self.color
            v4.color = self.color
            
            // Triangle1 = v1, v2, v3
            // Triangle2 = v2, v4, v3
            
            let n1 = calculateTriangleSurfaceNormal(v1:v1, v2:v2, v3:v3 )
            let n2 = calculateTriangleSurfaceNormal(v1:v2, v2:v4, v3:v3 )
            
            v1.normal = n1
            v2.normal = n1
            v3.normal = n1
            vertices.append( contentsOf:[v1, v2, v3] )
            
            v2.normal = n2
            v4.normal = n2
            v3.normal = n2
            vertices.append( contentsOf:[v2, v4, v3] )
        }
        
        createVertexBufforFromVertexArray( array:vertices )
    }

    func createVertexBufforFromVertexArray( array:[Vertex] ) {
        vertexCount = array.count
        vertexBuffer = device.makeBuffer(bytes:array, length: array.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices building"
    }
    
}
