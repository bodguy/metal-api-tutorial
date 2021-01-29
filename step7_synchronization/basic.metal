#include <metal_stdlib>

using namespace metal;

typedef struct
{
    float4 position;
    float4 color;
} VertexIn;

typedef struct {
 float4 position [[position]];
 float4 color;
} VertexOut;

typedef struct {
    float brightness;
} FragmentUniforms;

vertex VertexOut main0(
    const device VertexIn *vertices [[buffer(0)]], 
    uint vid [[vertex_id]]
) {
    VertexOut out;
    out.position = vertices[vid].position;
    out.color = vertices[vid].color;
    return out;
}

fragment float4 main1(
    VertexOut in [[stage_in]],
    constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    return float4(uniforms.brightness * in.color.rgb, in.color.a);
}