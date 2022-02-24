#include <metal_stdlib>

using namespace metal;

typedef struct {
  float3 position [[attribute(0)]];
  float2 textureCoordinate [[attribute(1)]];
} VertexIn;

typedef struct {
  float4 position [[position]];
  float2 textureCoordinate;
} VertexOut;

vertex VertexOut main0(VertexIn verts [[stage_in]]) {
    VertexOut out;
    out.position = float4(verts.position, 1);
    out.textureCoordinate = verts.textureCoordinate;
    return out;
}