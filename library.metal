#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

vertex float4 vertexShader(uint vertexID [[vertex_id]], constant float2 *vertices [[buffer(0)]])
{
    float2 in = vertices[vertexID];
    float4 output = vector_float4(in, 0, 1);
    return output;
}

fragment float4 fragmentShader(float4 in [[stage_in]])
{
    return float4(1,0,0,1);
}