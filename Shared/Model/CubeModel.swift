//
//  CubeModel.swift
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import MetalKit

class CubeModel : Model {
    var name : String = ""
    var nrVertices : Int = 0
    
    init( device: MTLDevice, vertexShader : String = "objectVertexShader", fragmentShader : String = "objectFragmentShader" ) {
        
        super.init()
        
        self.renderPipelineState = createLibraryAndRenderPipeline( device: device,vertexFunction: vertexShader, fragmentFunction: fragmentShader  )
        createAsset( device: device  )
    }
    
    func createAsset( device : MTLDevice ) {
        //Front
        
        let cubeSize : Float = 1.0
        let A = Vertex(position:vector_float4(-cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 0.0, 1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 1.0))
        let B = Vertex(position:vector_float4(-cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 0.0, 1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 0.0))
        let C = Vertex(position:vector_float4( cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 0.0, 1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 0.0))
        let D = Vertex(position:vector_float4( cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 0.0, 1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 1.0))

        //Left
        let E = Vertex(position:vector_float4(-cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(-1.0, 0.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 1.0, 0.00 ))
        let F = Vertex(position:vector_float4(-cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(-1.0, 0.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 0.0, 0.0 ))
        let G = Vertex(position:vector_float4(-cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(-1.0, 0.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 0.0, 1.0 ))
        let H = Vertex(position:vector_float4(-cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(-1.0, 0.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 1.0, 1.0 ))

        //Right
        let I = Vertex(position:vector_float4( cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(1.0, 0.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 1.0))
        let J = Vertex(position:vector_float4( cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(1.0, 0.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 1.0))
        let K = Vertex(position:vector_float4( cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(1.0, 0.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 0.0))
        let L = Vertex(position:vector_float4( cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(1.0, 0.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 0.0))

        //Top
        let M = Vertex(position:vector_float4(-cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 0.0))
        let N = Vertex(position:vector_float4(-cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 1.0))
        let O = Vertex(position:vector_float4( cubeSize,  cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 1.0))
        let P = Vertex(position:vector_float4( cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 1.0, 0.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 0.0))

        //Bottom
        let Q = Vertex(position:vector_float4(-cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, -1.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 0.0, 1.0))
        let R = Vertex(position:vector_float4(-cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, -1.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 0.0, 0.0))
        let S = Vertex(position:vector_float4( cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, -1.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 1.0, 0.0))
        let T = Vertex(position:vector_float4( cubeSize, -cubeSize,  cubeSize, 1.0), normal:vector_float4(0.0, -1.0, 0.0, 1.0), color:float4(1,1,1,1), texCoords:vector_float2( 1.0, 1.0))

        //Back
        let U = Vertex(position:vector_float4( cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 0.0, -1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 1.0))
        let V = Vertex(position:vector_float4( cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 0.0, -1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(1.0, 0.0))
        let W = Vertex(position:vector_float4(-cubeSize, -cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 0.0, -1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 0.0))
        let X = Vertex(position:vector_float4(-cubeSize,  cubeSize, -cubeSize, 1.0), normal:vector_float4(0.0, 0.0, -1.0, 1.0),  color:float4(1,1,1,1), texCoords:vector_float2(0.0, 1.0))

        let verticesArray:Array<Vertex> = [
             A,B,C ,A,C,D,   //Front
             E,F,G ,E,G,H,   //Left
             I,J,K ,I,K,L,   //Right
             M,N,O ,M,O,P,   //Top
             Q,R,S ,Q,S,T,   //Bot
             U,V,W ,U,W,X    //Back
         ]
        nrVertices = verticesArray.count

        vertexBuffer = device.makeBuffer(bytes:verticesArray, length: verticesArray.count * MemoryLayout<Vertex>.stride, options: [])!
        vertexBuffer.label = "vertices cube"
    }
    
}
