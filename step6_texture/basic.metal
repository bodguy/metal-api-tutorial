#include <metal_stdlib>

using namespace metal;

typedef struct {
    float3 position [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
} VertexIn;

typedef struct {
 float4 position [[position]];
 float2 texCoords;
} VertexOut;

typedef struct {
    float4x4 model_view_projection_matrix;
} Uniforms;

vertex VertexOut render_vertex(
    VertexIn verts [[stage_in]],
    constant Uniforms &uniforms [[buffer(1)]]
) {
    VertexOut out;
    out.position = uniforms.model_view_projection_matrix * float4(verts.position, 1);
    out.texCoords = verts.texCoords;
    return out;
}

fragment float4 render_fragment(
    VertexOut in [[stage_in]],
    texture2d<float> tex2D [[texture(0)]],
    sampler sampler2D [[sampler(0)]]
) {
    float4 sampledColor = tex2D.sample(sampler2D, in.texCoords);
    return sampledColor;
}