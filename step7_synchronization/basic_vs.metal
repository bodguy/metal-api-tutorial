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

vertex VertexOut main0(VertexIn verts [[stage_in]]) {
    VertexOut out;
    out.position = verts.position;
    out.color = verts.color;
    return out;
}