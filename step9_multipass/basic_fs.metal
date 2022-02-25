#include <metal_stdlib>

using namespace metal;

typedef struct {
  float4 position [[position]];
  float2 texCoords;
} VertexOut;

fragment float4 main0(VertexOut in [[stage_in]], texture2d<float> tex2D [[texture(0)]], sampler sampler2D [[sampler(0)]]) {
    float4 sampledColor = tex2D.sample(sampler2D, in.texCoords);
    return sampledColor;
}