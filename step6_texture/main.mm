#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#include <string>
#include <cstdlib>
#include <cmath>
#include <iostream>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

static const int k_WindowWidth  = 800;
static const int k_WindowHeight = 600;
const float MY_PI = 3.1415926f;
const float degrees_to_radians = MY_PI / 180.f;
float deg_to_rad(float degrees) { return degrees * degrees_to_radians; }

typedef struct {
  int width, height;
  int components;
  uint8_t* buffer;
  void destroy() { 
    stbi_image_free(buffer);
  }
} Texture;

bool load_texture_from_file(const std::string& path, Texture& out_text) {
  out_text.buffer = stbi_load(path.c_str(), &out_text.width, &out_text.height, &out_text.components, 0);
  return out_text.buffer != nullptr;
}

struct vector_float2 {
  float s, t;
};

struct vector_float3 {
	vector_float3() :x{0}, y{0}, z{0} {}
	vector_float3(float _x, float _y, float _z) :x{_x}, y{_y}, z{_z} {}
	float x, y, z;

  static vector_float3 vector_float3_cross(const vector_float3& a, const vector_float3& b) { 
    return vector_float3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x); 
  }

  static float vector_float3_dot(const vector_float3& a, const vector_float3& b) { 
    return a.x * b.x + a.y * b.y + a.z * b.z; 
  }

  vector_float3& vector_float3_normalize() {
    float len = std::sqrt(x * x + y * y + z * z);
    float inv = 1 / len;

    x = x * inv;
    y = y * inv;
    z = z * inv;

    return *this;
  }

  vector_float3 operator-(const vector_float3& other) const { return vector_float3(*this) -= other; }

  vector_float3& operator-=(const vector_float3& other) {
    x -= other.x;
    y -= other.y;
    z -= other.z;
    return *this;
  }
};

struct vector_float4 {
	vector_float4() :x{0}, y{0}, z{0}, w{0} {}
	vector_float4(float _x, float _y, float _z, float _w) :x{_x}, y{_y}, z{_z}, w{_w} {}
	float x, y, z, w;
};

struct matrix_float4x4 {
    matrix_float4x4() { 
			MakeIdentity();
		}
    matrix_float4x4(float m11, float m12, float m13, float m14, 
			float m21, float m22, float m23, float m24, 
			float m31, float m32, float m33, float m34, 
			float m41, float m42, float m43, float m44) {
			m16[0] = m11;
			m16[1] = m12;
			m16[2] = m13;
			m16[3] = m14;
			m16[4] = m21;
			m16[5] = m22;
			m16[6] = m23;
			m16[7] = m24;
			m16[8] = m31;
			m16[9] = m32;
			m16[10] = m33;
			m16[11] = m34;
			m16[12] = m41;
			m16[13] = m42;
			m16[14] = m43;
			m16[15] = m44;
		}

		matrix_float4x4(const matrix_float4x4& other) {
			for (int i = 0; i < 16; i++) {
				m16[i] = other.m16[i];
			}
		}

		matrix_float4x4& operator=(matrix_float4x4 other) {
			Swap(*this, other);
			return *this;
		}

    matrix_float4x4 operator*(const matrix_float4x4& other) const { return matrix_float4x4(*this) *= other; }

    matrix_float4x4& operator*=(const matrix_float4x4& other) {
      matrix_float4x4 result;
      result.m16[0] = m16[0] * other.m16[0] + m16[1] * other.m16[4] + m16[2] * other.m16[8] + m16[3] * other.m16[12];
      result.m16[1] = m16[0] * other.m16[1] + m16[1] * other.m16[5] + m16[2] * other.m16[9] + m16[3] * other.m16[13];
      result.m16[2] = m16[0] * other.m16[2] + m16[1] * other.m16[6] + m16[2] * other.m16[10] + m16[3] * other.m16[14];
      result.m16[3] = m16[0] * other.m16[3] + m16[1] * other.m16[7] + m16[2] * other.m16[11] + m16[3] * other.m16[15];

      result.m16[4] = m16[4] * other.m16[0] + m16[5] * other.m16[4] + m16[6] * other.m16[8] + m16[7] * other.m16[12];
      result.m16[5] = m16[4] * other.m16[1] + m16[5] * other.m16[5] + m16[6] * other.m16[9] + m16[7] * other.m16[13];
      result.m16[6] = m16[4] * other.m16[2] + m16[5] * other.m16[6] + m16[6] * other.m16[10] + m16[7] * other.m16[14];
      result.m16[7] = m16[4] * other.m16[3] + m16[5] * other.m16[7] + m16[6] * other.m16[11] + m16[7] * other.m16[15];

      result.m16[8] = m16[8] * other.m16[0] + m16[9] * other.m16[4] + m16[10] * other.m16[8] + m16[11] * other.m16[12];
      result.m16[9] = m16[8] * other.m16[1] + m16[9] * other.m16[5] + m16[10] * other.m16[9] + m16[11] * other.m16[13];
      result.m16[10] = m16[8] * other.m16[2] + m16[9] * other.m16[6] + m16[10] * other.m16[10] + m16[11] * other.m16[14];
      result.m16[11] = m16[8] * other.m16[3] + m16[9] * other.m16[7] + m16[10] * other.m16[11] + m16[11] * other.m16[15];

      result.m16[12] = m16[12] * other.m16[0] + m16[13] * other.m16[4] + m16[14] * other.m16[8] + m16[15] * other.m16[12];
      result.m16[13] = m16[12] * other.m16[1] + m16[13] * other.m16[5] + m16[14] * other.m16[9] + m16[15] * other.m16[13];
      result.m16[14] = m16[12] * other.m16[2] + m16[13] * other.m16[6] + m16[14] * other.m16[10] + m16[15] * other.m16[14];
      result.m16[15] = m16[12] * other.m16[3] + m16[13] * other.m16[7] + m16[14] * other.m16[11] + m16[15] * other.m16[15];

      *this = result;
      return *this;
    }

		matrix_float4x4& MakeIdentity() { return *this = Identity(); }

  	matrix_float4x4 Identity() { return matrix_float4x4(1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f, 0.f, 0.f, 0.f, 0.f, 1.f); }

		static matrix_float4x4 rotation_matrix_axis(float radianAngle, const vector_float3& axis) {
			float c = std::cos(radianAngle);
			float s = std::sin(radianAngle);
			float t = 1.f - c;

			float tx = t * axis.x;
			float ty = t * axis.y;
			float tz = t * axis.z;

			float sx = s * axis.x;
			float sy = s * axis.y;
			float sz = s * axis.z;

			return matrix_float4x4(
				tx * axis.x + c, tx * axis.y + sz, tx * axis.z - sy, 0.f, 
				ty * axis.x - sz, ty * axis.y + c, ty * axis.z + sx, 0.f, 
				tz * axis.x + sy, tz * axis.y - sx, tz * axis.z + c, 0.f, 
				0.f, 0.f, 0.f, 1.f
			);
  	}

    static matrix_float4x4 matrix_float4x4_uniform_scale(const vector_float3& scale) {
      matrix_float4x4 mat;
      mat.m16[0] = scale.x;
      mat.m16[5] = scale.y;
      mat.m16[10] = scale.z;

      return mat;
    }

    static matrix_float4x4 matrix_float4x4_translation(const vector_float3& translation) {
      matrix_float4x4 mat;
      mat.m16[12] = translation.x;
      mat.m16[13] = translation.y;
      mat.m16[14] = translation.z;

      return mat;
    }

    static matrix_float4x4 zero() { return matrix_float4x4(0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f, 0.f); }

    static matrix_float4x4 matrix_float4x4_lookat(const vector_float3& eye, const vector_float3& lookat, const vector_float3& up) {
      vector_float3 zaxis = (eye - lookat).vector_float3_normalize();
      vector_float3 xaxis = vector_float3::vector_float3_cross(up, zaxis).vector_float3_normalize();
      vector_float3 yaxis = vector_float3::vector_float3_cross(zaxis, xaxis);

      return matrix_float4x4(xaxis.x, yaxis.x, zaxis.x, 0.f, 
        xaxis.y, yaxis.y, zaxis.y, 0.f, 
        xaxis.z, yaxis.z, zaxis.z, 0.f, 
        -vector_float3::vector_float3_dot(xaxis, eye), -vector_float3::vector_float3_dot(yaxis, eye), -vector_float3::vector_float3_dot(zaxis, eye), 1.f
      );
    }

    static matrix_float4x4 matrix_from_perspective_fov_aspectLH(float fieldOfView, float aspectRatio, float znear, float zfar) {
      float tanHalfFovy = std::tan(fieldOfView / 2.f);

      matrix_float4x4 mat = matrix_float4x4::zero();
      mat.m16[0] = 1.0f / (aspectRatio * tanHalfFovy);
      mat.m16[5] = 1.0f / tanHalfFovy;
      mat.m16[10] = -(zfar + znear) / (zfar - znear);
      mat.m16[11] = -1.0f;
      mat.m16[14] = -(2.0f * zfar * znear) / (zfar - znear);

      return mat;
    }

    float m16[16];

		void Swap(matrix_float4x4& first, matrix_float4x4& second) {
			using std::swap;
			for (int i = 0; i < 16; i++) {
				swap(first.m16[i], second.m16[i]);
			}
		}
};

typedef struct {
    matrix_float4x4 model_view_projection_matrix{};
} Uniforms;

typedef struct
{
    vector_float4 position;
    vector_float2 texCoords;
} VertexSemantic;

@class MetalView;
MetalView* g_nsView;
float rotationAngle = 10.f;

id<MTLDevice>               g_mtlDevice;
id<MTLCommandQueue>         g_mtlCommandQueue;
id<MTLRenderPipelineState>  g_mtlPipelineState;
id<MTLBuffer>               g_vertexBuffer;
id<MTLBuffer>               g_uniformBuffer;
id<MTLBuffer>               g_indexBuffer;
id<MTLTexture>              g_depthTexture;
id<MTLDepthStencilState>    g_depthStencilState;
id<MTLTexture>              g_MTLTexture;
id<MTLSamplerState>         g_sampler;
Uniforms g_uniforms;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow* window;
@end

@interface MetalView : NSView
@property (nonatomic, assign) CAMetalLayer* metalLayer;
@end

bool read_file(const std::string& filepath, std::string& out_source) {
    FILE* fp = nullptr;
    fp = fopen(filepath.c_str(), "r");
    if (!fp) return false;
    fseek(fp, 0, SEEK_END);
    auto size = static_cast<size_t>(ftell(fp));
    fseek(fp, 0, SEEK_SET);
    char* buffer = (char*)malloc(sizeof(char) * size);
    if (!buffer) return false;
    fread(buffer, size, 1, fp);
    out_source.assign(buffer, size);
    free(buffer);
    fclose(fp);
    return true;
}

const matrix_float4x4 viewMatrix = matrix_float4x4::matrix_float4x4_lookat({0, 0, 7}, {0, 0, 0}, {0, 1, 0});
const matrix_float4x4 projectionMatrix = matrix_float4x4::matrix_from_perspective_fov_aspectLH(k_WindowWidth / k_WindowHeight, deg_to_rad(60.f), 0.1f, 5000.f);

void doUpdate() { 
  rotationAngle++;
	const matrix_float4x4 modelMatrix = matrix_float4x4::rotation_matrix_axis(deg_to_rad(rotationAngle), {0, 1, 0})
    * matrix_float4x4::matrix_float4x4_uniform_scale({1, 1, 1});
  g_uniforms.model_view_projection_matrix = modelMatrix * viewMatrix * projectionMatrix;

  memcpy([g_uniformBuffer contents], &g_uniforms, sizeof(g_uniforms));
}

void doRender()
{
  if (!g_nsView.metalLayer)
  {
    fprintf(stderr, "Warning: No metal layer, skipping render.\n");
    return;
  }

  id<CAMetalDrawable> drawable = [g_nsView.metalLayer nextDrawable];
  id<MTLTexture> framebufferTexture = drawable.texture;

  MTLRenderPassDescriptor* passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  passDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(1, 0, 0, 1);
  passDescriptor.colorAttachments[0].texture     = framebufferTexture;
  passDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
  passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

  passDescriptor.depthAttachment.texture = g_depthTexture;
  passDescriptor.depthAttachment.clearDepth = 1.0;
  passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
  passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;

  id<MTLCommandBuffer> commandBuffer = [g_mtlCommandQueue commandBuffer];

  id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
  [commandEncoder setRenderPipelineState:g_mtlPipelineState];
  [commandEncoder setDepthStencilState:g_depthStencilState];
  [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
  [commandEncoder setCullMode:MTLCullModeBack];
  [commandEncoder setVertexBuffer:g_vertexBuffer offset:0 atIndex:0];
  [commandEncoder setVertexBuffer:g_uniformBuffer offset:0 atIndex:1];
  [commandEncoder setFragmentTexture:g_MTLTexture atIndex:0];
  [commandEncoder setFragmentSamplerState:g_sampler atIndex:0];

  [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                        indexCount:[g_indexBuffer length] / sizeof(uint16_t)
                                        indexType:MTLIndexTypeUInt16
                                        indexBuffer:g_indexBuffer
                                        indexBufferOffset:0];

  [commandEncoder endEncoding];

  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

int renderInit()
{
  g_mtlDevice = MTLCreateSystemDefaultDevice();
  if (!g_mtlDevice)
  {
    fprintf(stderr, "System does not support metal.\n");
    return EXIT_FAILURE;
  }

  g_mtlCommandQueue = [g_mtlDevice newCommandQueue];
	std::string shaderCode;
	if (!read_file("./basic.metal", shaderCode)) {
		fprintf(stderr, "Shader not found");
		return EXIT_FAILURE;
	}
  
  NSString* source = [[NSString alloc] initWithUTF8String:shaderCode.c_str()];
  MTLCompileOptions* compileOpts = [[MTLCompileOptions alloc] init];
  compileOpts.languageVersion = MTLLanguageVersion2_0;

  NSError* err = nil;
  id<MTLLibrary> library = [g_mtlDevice newLibraryWithSource:source options:compileOpts error:&err];

  [compileOpts release];
  [source release];

  if (err) {
    NSLog(@"%@", err);
    [library release];
    return EXIT_FAILURE;
  }

  // Create pipeline state.
  MTLRenderPipelineDescriptor* pipelineDescriptor = [MTLRenderPipelineDescriptor new];
  pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"render_vertex"];
  pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"render_fragment"];
  pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
  [library release];

  MTLDepthStencilDescriptor* depthStencilDescriptor = [MTLDepthStencilDescriptor new];
  depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
  depthStencilDescriptor.depthWriteEnabled = YES;
  g_depthStencilState = [g_mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];

  MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                    width:k_WindowWidth
                                                                                    height:k_WindowHeight
                                                                                    mipmapped:NO];
  desc.usage = MTLTextureUsageRenderTarget;
  desc.storageMode = MTLStorageModePrivate;
  g_depthTexture = [g_mtlDevice newTextureWithDescriptor:desc];

  NSError* error = nil;
  g_mtlPipelineState = [g_mtlDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (!g_mtlPipelineState) {
    NSLog(@"Failed to create render pipeline state: %@", error);
  }

  static const VertexSemantic vertices[] =
  {
      { .position = { -1,  1,  1, 1 }, .texCoords = { 0.25, 0.25 } },
      { .position = { -1, -1,  1, 1 }, .texCoords = { 0.25, 0.50 } },
      { .position = {  1, -1,  1, 1 }, .texCoords = { 0.50, 0.50 } },
      { .position = {  1,  1,  1, 1 }, .texCoords = { 0.50, 0.25 } },
      { .position = { -1,  1, -1, 1 }, .texCoords = { 0.25, 0.00 } },
      { .position = { -1, -1, -1, 1 }, .texCoords = { 0.25, 0.75 } },
      { .position = {  1, -1, -1, 1 }, .texCoords = { 0.50, 0.75 } },
      { .position = {  1,  1, -1, 1 }, .texCoords = { 0.75, 0.25 } },
  };

  static const uint16_t indices[] =
  {
      3, 2, 6, 6, 7, 3,
      4, 5, 1, 1, 0, 4,
      4, 0, 3, 3, 7, 4,
      1, 5, 6, 6, 2, 1,
      0, 1, 2, 2, 3, 0,
      7, 6, 5, 5, 4, 7
  };

  g_vertexBuffer = [g_mtlDevice newBufferWithBytes:vertices
                                  length:sizeof(vertices)
                                  options:MTLResourceOptionCPUCacheModeDefault];

  g_indexBuffer = [g_mtlDevice newBufferWithBytes:indices
                                  length:sizeof(indices)
                                  options:MTLResourceOptionCPUCacheModeDefault];

  g_uniformBuffer = [g_mtlDevice newBufferWithBytes:&g_uniforms
                                  length:sizeof(g_uniforms)
                                  options:MTLResourceOptionCPUCacheModeDefault];

  Texture texture;
  if (!load_texture_from_file("./texture.png", texture)) {
    fprintf(stderr, "Texture load failed\n");
    return EXIT_FAILURE;
  }

  MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                   width:texture.width-1
                                                   height:texture.height-1
                                                   mipmapped:YES];
  textureDescriptor.usage = MTLTextureUsageShaderRead;
  g_MTLTexture = [g_mtlDevice newTextureWithDescriptor:textureDescriptor];
  MTLRegion region = MTLRegionMake2D(0, 0, texture.width-1, texture.height-1);
  int rowPerBytes = (texture.width-1) * texture.components;
  [g_MTLTexture replaceRegion:region mipmapLevel:0 withBytes:texture.buffer bytesPerRow:rowPerBytes];
  texture.destroy();

  MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
  samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
  samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
  samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
  samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
  samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
  
  g_sampler = [g_mtlDevice newSamplerStateWithDescriptor:samplerDescriptor];

  return EXIT_SUCCESS;
}

void renderDestroy()
{
  [g_sampler release];
  [g_MTLTexture release];
  [g_depthStencilState release];
  [g_depthTexture release];
  [g_indexBuffer release];
  [g_uniformBuffer release];
  [g_vertexBuffer release];
  [g_mtlPipelineState release];
  [g_mtlCommandQueue release];
  [g_mtlDevice release];
}

int main(int argc, char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  if (renderInit() != EXIT_SUCCESS)
  {
    return EXIT_FAILURE;
  }

  NSApplication * application = [NSApplication sharedApplication];
  
  AppDelegate * applicationDelegate = [[[AppDelegate alloc] init] autorelease];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSApp activateIgnoringOtherApps:YES];
  [application setDelegate:applicationDelegate];

  [application run];

  // Will never get here.
  [pool drain];

  return EXIT_SUCCESS;
}

CVDisplayLinkRef g_displayLink;

static CVReturn displayLinkCallback(
    CVDisplayLinkRef displayLink,
    const CVTimeStamp* now,
    const CVTimeStamp* outputTime,
    CVOptionFlags flagsIn,
    CVOptionFlags* flagsOut,
    void* displayLinkContext)
{
  doUpdate();
  doRender();
  return kCVReturnSuccess;
}

@interface MyNSWindow : NSWindow
- (BOOL)canBecomeMainWindow;
- (BOOL)canBecomeKeyWindow;
- (BOOL)acceptsFirstResponder;
- (void)keyDown:(NSEvent *)anEvent;
@end

@implementation MyNSWindow
- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)anEvent
{
  unsigned short keyCode = [anEvent keyCode];
  printf("Key code: %d\n", keyCode);
  if (keyCode == 53 || keyCode == 49)
  {
    [self close];
  }
}
@end

@implementation AppDelegate
- (id)init
{
  if ( self = [super init] ) { }
  return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  NSRect contentSize = NSMakeRect(0.0f, 0.0f, k_WindowWidth, k_WindowHeight);
  g_nsView    = [[MetalView alloc]  initWithFrame:contentSize];

  const int style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
  self.window = [[MyNSWindow alloc] initWithContentRect:contentSize
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:YES];
  [self.window setTitle:@"Metal C++ Example6"];
  [self.window setOpaque:YES];
  [self.window setContentView:g_nsView];
  [self.window makeMainWindow];
  [self.window makeKeyAndOrderFront:nil];
  [self.window makeFirstResponder:nil];

  [self.window makeKeyAndOrderFront:self];

  [g_nsView awakeFromNib];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication
{
  return true;
}
@end

@implementation MetalView
+ (id)layerClass
{
  return [CAMetalLayer class];
}

- (CALayer*)makeBackingLayer
{
  CAMetalLayer* backingLayer = [CAMetalLayer layer];
  self.metalLayer = backingLayer;
  return self.metalLayer;
}

- (instancetype)initWithFrame:(CGRect)frameRect
{
  if ((self = [super initWithFrame:frameRect]))
  {
    self.wantsLayer = YES; // Providing Metal layer through makeBackingLayer

    if (!g_mtlDevice)
    {
      fprintf(stderr, "MetalView: ERROR - Metal device has not be created.\n");
    }

    self.metalLayer.device = g_mtlDevice;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  }
  return self;
}

- (void)awakeFromNib
{
  // As the last thing we do, fire up the display link timer for rendering.
  // Create callback for rendering purposes. Need to check thread ids. I
  // presume this CVDisplayLink callback is issued from the CFRunLoop
  // generated by issuing a call to [NSApp run].
  CVDisplayLinkCreateWithActiveCGDisplays(&g_displayLink);
  CVDisplayLinkSetOutputCallback(g_displayLink, &displayLinkCallback, 0);
  CVDisplayLinkSetCurrentCGDisplay(g_displayLink, 0);
  CVDisplayLinkStart(g_displayLink);
}

- (void)dealloc
{
  CVDisplayLinkStop(g_displayLink);
  CVDisplayLinkRelease(g_displayLink);
  renderDestroy();
  [super dealloc];
}
@end
