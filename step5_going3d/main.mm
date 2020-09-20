#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#include <string>
#include <cstdlib>
#include <cmath>
#include <iostream>

static const int k_WindowWidth  = 1024;
static const int k_WindowHeight = 768;
const float MY_PI = 3.1415926f;
const float degrees_to_radians = MY_PI / 180.f;
float deg_to_rad(float degrees) { return degrees * degrees_to_radians; }

struct vector_float3 {
	vector_float3() :x{0}, y{0}, z{0} {}
	vector_float3(float _x, float _y, float _z) :x{_x}, y{_y}, z{_z} {}
	float x, y, z;
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

    static matrix_float4x4 matrix_float4x4_perspective(float fieldOfView, float aspectRatio, float znear, float zfar) {
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
    vector_float4 color;
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

const float aspect = k_WindowWidth / k_WindowHeight;
const float fov = deg_to_rad(60.f);
const float near = 0.1f;
const float far = 5000.f;
const vector_float3 cameraTranslation = { 0, 0, -5 };
const matrix_float4x4 viewMatrix = matrix_float4x4::matrix_float4x4_translation(cameraTranslation);
const matrix_float4x4 projectionMatrix = matrix_float4x4::matrix_float4x4_perspective(aspect, fov, near, far);

void doUpdate() { 
  rotationAngle++;
	const matrix_float4x4 modelMatrix = matrix_float4x4::rotation_matrix_axis(deg_to_rad(30), vector_float3{1, 1, 1}) * matrix_float4x4::rotation_matrix_axis(deg_to_rad(rotationAngle), vector_float3{0, 1, 0}) 
    * matrix_float4x4::matrix_float4x4_uniform_scale(vector_float3{0.2, 0.2, 0.2});
  g_uniforms.model_view_projection_matrix = modelMatrix;

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
  passDescriptor.colorAttachments[0].clearColor  = MTLClearColorMake(1, 1, 1, 1);
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

  if (err)
  {
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
  if (!g_mtlPipelineState)
  {
    NSLog(@"Failed to create render pipeline state: %@", error);
  }

  static const VertexSemantic vertices[] =
  {
      { .position = { -1,  1,  1, 1 }, .color = { 1, 0, 0, 1 } },
      { .position = { -1, -1,  1, 1 }, .color = { 0, 1, 0, 1 } },
      { .position = {  1, -1,  1, 1 }, .color = { 0, 0, 1, 1 } },
      { .position = {  1,  1,  1, 1 }, .color = { 1, 1, 0, 1 } },
      { .position = { -1,  1, -1, 1 }, .color = { 1, 0, 1, 1 } },
      { .position = { -1, -1, -1, 1 }, .color = { 0, 1, 1, 1 } },
      { .position = {  1, -1, -1, 1 }, .color = { 1, 1, 1, 1 } },
      { .position = {  1,  1, -1, 1 }, .color = { 1, 0, 0, 1 } }
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

  return EXIT_SUCCESS;
}

void renderDestroy()
{
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
  [self.window setTitle:@"Metal C++ Example5"];
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
