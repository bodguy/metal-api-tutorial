#include <metal_stdlib>

using namespace metal;

typedef struct {
  float4 position [[position]];
  float4 color;
} VertexOut;

typedef struct {
  float brightness;
} FragmentUniforms;

fragment float4 main0(VertexOut in [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
    return float4(uniforms.brightness * in.color.rgb, in.color.a);
}