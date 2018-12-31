//
//  ShaderTypes.h
//  MetalSample
//
//  Created by Andy Qua on 28/06/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name: _type _name; enum _name: _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>


typedef struct
{
    packed_float4 position;
    packed_float4 normal;
    packed_float4 color;
    packed_float2 texCoords;
} Vertex;


typedef struct
{
    matrix_float4x4 viewProjectionMatrix;
} Uniforms;

typedef struct
{
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
    float r,g,b,a;
    int textureNr;
} PerInstanceUniforms;

#endif /* ShaderTypes_h */

