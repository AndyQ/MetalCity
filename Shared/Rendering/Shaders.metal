
#include <metal_stdlib>
using namespace metal;

constant float3 kLightDirection(-0.43, -1.0, 0.8);

struct InVertex
{
    packed_float4 position;// [[attribute(0)]];
    packed_float4 normal;// [[attribute(1)]];
    packed_float4 color;// [[attribute(2)]];
    packed_float2 texCoords;// [[attribute(2)]];
};

struct ProjectedVertex
{
    float4 position [[position]];
    float3 normal [[user(normal)]];
    float2 texCoords [[user(tex_coords)]];
    float4 color;
    int textureNr;
};



struct Uniforms
{
    float4x4 viewProjectionMatrix;
};

struct PerInstanceUniforms
{
    float4x4 modelMatrix;
    float3x3 normalMatrix;
    float4 color;
    int textureNr;
};

vertex ProjectedVertex objectVertexShader(const device InVertex *vertices [[buffer(0)]],
                                          const device Uniforms &uniforms [[buffer(1)]],
                                          unsigned int vid [[vertex_id]],
                                          unsigned int iid [[instance_id]])
{
    InVertex v = vertices[vid];
    
    float4 color = float4(0.5, 0.5, 0.5, 1.0);
    
    ProjectedVertex outVert;
    outVert.position = uniforms.viewProjectionMatrix  * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = v.texCoords;
    outVert.color = color;
    
    return outVert;
}

vertex ProjectedVertex objectVertexShaderb(const device InVertex *vertices [[buffer(0)]],
                                          const device Uniforms &uniforms [[buffer(1)]],
                                          const device PerInstanceUniforms *perInstanceUniforms [[buffer(2)]],
                                          unsigned int vid [[vertex_id]],
                                          unsigned int iid [[instance_id]])
{
    InVertex v = vertices[vid];
    PerInstanceUniforms pu = perInstanceUniforms[iid];
    
    float4x4 instanceModelMatrix = pu.modelMatrix;
    float3x3 instanceNormalMatrix = pu.normalMatrix;
    float4 color = pu.color;
    
    ProjectedVertex outVert;
    outVert.position = uniforms.viewProjectionMatrix * instanceModelMatrix * float4(v.position);
    outVert.normal = instanceNormalMatrix * float4(v.normal).xyz;
    outVert.texCoords = v.texCoords;
    outVert.color = color;
    
    return outVert;
}

fragment half4 objectFragmentShader(ProjectedVertex vert [[stage_in]] )
{
    float diffuseIntensity = max(0.33, dot(normalize(vert.normal), -kLightDirection));
    float a = vert.color.a;
    float4 color = vert.color * diffuseIntensity;
    return half4(color.r, color.g, color.b, a);
}

vertex ProjectedVertex indexedVertexShader( const device InVertex *vertices [[buffer(0)]],
                                           const device Uniforms &uniforms [[buffer(1)]],
                                           unsigned int  vertexId [[vertex_id]],
                                           unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;

    return outVert;
}


fragment half4 indexedFragmentShader(ProjectedVertex fragments [[stage_in]],
                                     texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::linear);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    float4 baseColor = fragments.color * 0.25;// * 0.075;
    baseColor.a = 1;
    
    if ( texture.x > 0.5 || texture.y > 0.5 || texture.z > 0.5 ) {
        return half4(baseColor + texture);
    }
    
    return half4(texture);
}

// Lights shader
vertex ProjectedVertex lightsVertexShader( const device InVertex *vertices [[buffer(0)]],
                                           const device Uniforms &uniforms [[buffer(1)]],
                                           unsigned int  vertexId [[vertex_id]],
                                           unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;
    
    return outVert;
}


fragment half4 lightsFragmentShader(ProjectedVertex fragments [[stage_in]],
                                     texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::linear);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    float4 baseColor = fragments.color;
    
//    if ( texture.a != 0 ) {
        return half4(baseColor * texture);
//    }
    
    return half4(texture);
}

// Building Shader
vertex ProjectedVertex buildingVertexShader( const device InVertex *vertices [[buffer(0)]],
                                            const device Uniforms &uniforms [[buffer(1)]],
                                            unsigned int  vertexId [[vertex_id]],
                                            unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;
    
    return outVert;
}

fragment half4 buildingFragmentShader(ProjectedVertex fragments [[stage_in]],
                                      texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::linear);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    float4 baseColor = float4(0.075, 0.075, 0.075, 0);
    if ( texture.x > 0.5 || texture.y > 0.5 || texture.z > 0.5 ) {
        baseColor = fragments.color * 0.25;// * 0.075;
        baseColor.a = 1;
    }
    return half4(baseColor + texture);
}

// Logo Shader
vertex ProjectedVertex logoVertexShader( const device InVertex *vertices [[buffer(0)]],
                                           const device Uniforms &uniforms [[buffer(1)]],
                                           unsigned int  vertexId [[vertex_id]],
                                           unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;
    
    return outVert;
}

fragment half4 logoFragmentShader(ProjectedVertex fragments [[stage_in]],
                                     texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::linear);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    float4 baseColor = fragments.color;
    
//    return half4(baseColor * texture);
    
    return half4(texture);
}

// Radio Tower Shader
vertex ProjectedVertex radioTowerVertexShader( const device InVertex *vertices [[buffer(0)]],
                                            const device Uniforms &uniforms [[buffer(1)]],
                                            unsigned int  vertexId [[vertex_id]],
                                            unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;
    
    return outVert;
}

fragment half4 radioTowerFragmentShader(ProjectedVertex fragments [[stage_in]],
                                      texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::nearest);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    return half4(texture);
}

vertex ProjectedVertex carVertexShader( const device InVertex *vertices [[buffer(0)]],
                                           const device Uniforms &uniforms [[buffer(1)]],
                                           unsigned int  vertexId [[vertex_id]],
                                           unsigned int iid [[instance_id]])
{
    
    InVertex v = vertices[vertexId];
    
    ProjectedVertex outVert;
    
    outVert.position = uniforms.viewProjectionMatrix * float4(v.position);
    outVert.normal = float4(v.normal).xyz;
    outVert.texCoords = vertices[vertexId].texCoords;
    outVert.color = v.color;
    
    return outVert;
}

fragment half4 carFragmentShader(ProjectedVertex fragments [[stage_in]],
                                     texture2d<float> textures [[texture(0)]])
{
    constexpr sampler samplers(coord::normalized,
                               address::repeat,
                               filter::linear);
    float4 texture = textures.sample(samplers, fragments.texCoords);
    
    float4 baseColor = fragments.color;
    baseColor.a = 1;
    return half4(baseColor * texture);
}
