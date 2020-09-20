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
    float4x4 rotation_matrix;
} Uniforms;

vertex VertexOut render_vertex(
    const device VertexIn *vertices [[buffer(0)]], 
    constant Uniforms &uniforms [[buffer(1)]],
    uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = uniforms.rotation_matrix * vertices[vid].position;
    out.color = vertices[vid].color;
    return out;
}

fragment float4 render_fragment(VertexOut in [[stage_in]])
{
    return in.color;
}