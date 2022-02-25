#include <metal_stdlib>

using namespace metal;

typedef struct {
  float4 position [[position]];
  float2 texCoords;
} VertexOut;

fragment float4 main0(VertexOut in [[stage_in]], texture2d<float> baseTexture [[ texture(0) ]]) {
    constexpr sampler s;
    constexpr float offset = 1.0 / 300.0;

    float2 texCoords = in.texCoords;

    float2 offsets[9] = {
        float2(-offset,  offset), // top-left
        float2( 0.0f,    offset), // top-center
        float2( offset,  offset), // top-right
        float2(-offset,  0.0f),   // center-left
        float2( 0.0f,    0.0f),   // center-center
        float2( offset,  0.0f),   // center-right
        float2(-offset, -offset), // bottom-left
        float2( 0.0f,   -offset), // bottom-center
        float2( offset, -offset)  // bottom-right
    };
    float kerneleff[9] = {
        1, 1, 1,
        1, -8, 1,
        1, 1, 1
    };

    float4 sampleTex[9];
    for (int i = 0; i < 9; i++) {
        sampleTex[i] = baseTexture.sample(s, texCoords.xy + offsets[i]);
    }
    float3 col = float3(0.0);
    for(int i = 0; i < 9; i++) {
        col += float3(sampleTex[i]) * kerneleff[i];
    }

    return float4(col, 1.0);
}