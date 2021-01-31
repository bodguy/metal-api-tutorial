#include <metal_stdlib>

using namespace metal;

typedef struct {
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
} VertexIn;

typedef struct {
 float4 position [[position]];
 float4 color;
} VertexOut;

typedef struct {
    float brightness;
} FragmentUniforms;

vertex VertexOut main0(VertexIn verts [[stage_in]]) {
    VertexOut out;
    out.position = verts.position;
    out.color = verts.color;
    return out;
}

fragment float4 main1(
    VertexOut in [[stage_in]],
    constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    return float4(uniforms.brightness * in.color.rgb, in.color.a);
}