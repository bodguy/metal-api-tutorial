#include <metal_stdlib>

using namespace metal;

typedef struct {
  float4 position [[position]];
  float2 textureCoordinate;
} VertexOut;

fragment float4 main0(VertexOut in [[stage_in]], texture2d<float> baseTexture [[ texture(0) ]]) {
    constexpr sampler s;

    float2 textureCoordinate = in.textureCoordinate;
    textureCoordinate.y = 1 - textureCoordinate.y;

    float4 color = baseTexture.sample(s, textureCoordinate);
    return color;
}