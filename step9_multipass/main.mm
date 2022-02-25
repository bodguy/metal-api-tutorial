#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <string>
#include <cmath>
#include <mutex>

struct Vec3 {
    float x, y, z;
};
struct Vec2 {
    float u, v;
};
struct Vec4 {
    float r, g, b, a;
};
struct Vertex {
    Vec3 position;
    Vec4 color;
};
struct Vertex2 {
    Vec3 position;
    Vec2 texCoord;
};

class Semaphore {
public:
    Semaphore(int count_ = 0) : count{count_} {}

    inline void notify() {
        std::unique_lock<std::mutex> lock(mtx);
        count++;
        //notify the waiting thread
        cv.notify_one();
    }

    inline void wait() {
        std::unique_lock<std::mutex> lock(mtx);
        while (count == 0) {
            //wait on the mutex until notify is called
            cv.wait(lock);
        }
        count--;
    }

private:
    std::mutex mtx;
    std::condition_variable cv;
    int count;
};

struct FragmentUniforms {
    FragmentUniforms(float _brightness) : brightness{_brightness} {}

    float brightness;
};

@class MetalView;
MetalView *g_nsView;

using high_resolution_clock = std::chrono::high_resolution_clock;
using hr_time_point = std::chrono::time_point<high_resolution_clock>;
using millisecond = std::chrono::duration<float, std::milli>;

id <MTLDevice> g_mtlDevice;
id <MTLCommandQueue> g_mtlCommandQueue;
id <MTLRenderPipelineState> g_baseRenderPipelineState;
id <MTLRenderPipelineState> g_finalRenderPipelineState;
id <MTLBuffer> g_vertexBuffer;
id <MTLBuffer> g_vertexBuffer2;
id <MTLBuffer> g_indexBuffer;
id <MTLBuffer> g_uniformBuffer;
id<MTLTexture> g_baseColorTexture;
static const int k_WindowWidth = 800;
static const int k_WindowHeight = 600;
static FragmentUniforms g_fragmentUniforms{1.f};
static Semaphore sem{1};
hr_time_point t1, t2;
float elapsedTime = 0.f;

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong, nonatomic) NSWindow *window;
@end

@interface MetalView : NSView
@property(nonatomic, assign) CAMetalLayer *metalLayer;
@end

bool read_file(const std::string &filepath, std::string &out_source) {
    FILE *fp = nullptr;
    fp = fopen(filepath.c_str(), "r");
    if (!fp) return false;
    fseek(fp, 0, SEEK_END);
    auto size = static_cast<size_t>(ftell(fp));
    fseek(fp, 0, SEEK_SET);
    char *buffer = (char *) malloc(sizeof(char) * size);
    if (!buffer) return false;
    fread(buffer, size, 1, fp);
    out_source.assign(buffer, size);
    free(buffer);
    fclose(fp);
    return true;
}

bool loadShader(const std::string &filename, id <MTLLibrary> &library) {
    MTLCompileOptions *compileOptions = [MTLCompileOptions new];
    compileOptions.languageVersion = MTLLanguageVersion1_1;
    NSError *compileError = nullptr;
    std::string source;
    if (!read_file(filename, source)) {
        NSLog(@"Shader not found");
        return false;
    }
    library = [g_mtlDevice newLibraryWithSource:[NSString stringWithFormat:@"%s", source.c_str()] options:compileOptions error:&compileError];
    if (!library) {
        NSLog(@"can't create library: %@", compileError);
        return false;
    }
    [compileOptions release];
    [compileError release];

    return true;
}

void baseRenderPass(id<MTLCommandBuffer> commandBuffer) {
    // base render pass
    MTLRenderPassDescriptor *baseRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    baseRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    baseRenderPassDescriptor.colorAttachments[0].texture = g_baseColorTexture;
    baseRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    baseRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:baseRenderPassDescriptor];
    [commandEncoder setRenderPipelineState:g_baseRenderPipelineState];
    [commandEncoder setVertexBuffer:g_vertexBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentBuffer:g_uniformBuffer offset:0 atIndex:0];
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:6
                                indexType:MTLIndexTypeUInt16
                              indexBuffer:g_indexBuffer
                        indexBufferOffset:0];
    [commandEncoder endEncoding];
}

void finalRenderPass(MetalView* mtkView, id<MTLCommandBuffer> commandBuffer) {
    // final render pass: render to the views drawable texture
    MTLRenderPassDescriptor* finalRenderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    id <CAMetalDrawable> drawable = [g_nsView.metalLayer nextDrawable];
    finalRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    finalRenderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    finalRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    finalRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:finalRenderPassDescriptor];
    [commandEncoder setRenderPipelineState:g_finalRenderPipelineState];
    [commandEncoder setVertexBuffer:g_vertexBuffer2 offset:0 atIndex:0];
    [commandEncoder setFragmentTexture:g_baseColorTexture atIndex:0];
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:6
                                indexType:MTLIndexTypeUInt16
                              indexBuffer:g_indexBuffer
                        indexBufferOffset:0];
    [commandEncoder endEncoding];

    [commandBuffer presentDrawable:drawable];
}

void doUpdate(float dt) {
    g_fragmentUniforms.brightness = 0.5f * std::cos(elapsedTime) + 0.5f;
    memcpy([g_uniformBuffer contents], &g_fragmentUniforms, sizeof(FragmentUniforms));
    elapsedTime += dt;
}

void doRender() {
    t1 = high_resolution_clock::now();
    float deltaTime = std::chrono::duration_cast<millisecond>(t2 - t1).count() * 0.001;
    t2 = t1;

    // wait
    sem.wait();

    doUpdate(deltaTime);

    id <MTLCommandBuffer> commandBuffer = [g_mtlCommandQueue commandBuffer];
    baseRenderPass(commandBuffer);
    finalRenderPass(g_nsView, commandBuffer);

    // signal
    [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> _) {
        sem.notify();
    }];

    [commandBuffer commit];
}

bool initBaseRenderPipelineState(id <MTLRenderPipelineState>& renderPipelineState) {
    id <MTLLibrary> vs_library, fs_library;
    if (!loadShader("./basic_vs.metal", vs_library)) {
        return false;
    }
    if (!loadShader("./basic_fs.metal", fs_library)) {
        return false;
    }

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = [vs_library newFunctionWithName:@"main0"];
    pipelineDescriptor.fragmentFunction = [fs_library newFunctionWithName:@"main0"];
    [vs_library release];
    [fs_library release];

    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = 12;
    vertexDescriptor.layouts[0].stride = 28;
    [pipelineDescriptor setVertexDescriptor:vertexDescriptor];
    [vertexDescriptor release];

    NSError *pipelineError = nullptr;
    renderPipelineState = [g_mtlDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&pipelineError];
    if (!renderPipelineState) {
        NSLog(@"Failed to create render pipeline state: %@", pipelineError);
        return false;
    }
    [pipelineDescriptor release];
    [pipelineError release];

    return true;
}

bool initFinalRenderPipelineState(id <MTLRenderPipelineState>& renderPipelineState) {
    id <MTLLibrary> vs_library, fs_library;
    if (!loadShader("./basic_vs2.metal", vs_library)) {
        return false;
    }
    if (!loadShader("./basic_fs2.metal", fs_library)) {
        return false;
    }

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = [vs_library newFunctionWithName:@"main0"];
    pipelineDescriptor.fragmentFunction = [fs_library newFunctionWithName:@"main0"];
    [vs_library release];
    [fs_library release];

    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].offset = 12;
    vertexDescriptor.layouts[0].stride = 20;
    [pipelineDescriptor setVertexDescriptor:vertexDescriptor];
    [vertexDescriptor release];

    NSError *pipelineError = nullptr;
    renderPipelineState = [g_mtlDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&pipelineError];
    if (!renderPipelineState) {
        NSLog(@"Failed to create render pipeline state: %@", pipelineError);
        return false;
    }
    [pipelineDescriptor release];
    [pipelineError release];

    return true;
}

bool init() {
    g_mtlDevice = MTLCreateSystemDefaultDevice();
    g_mtlCommandQueue = [g_mtlDevice newCommandQueue];

    MTLTextureDescriptor* textureDescriptor = [MTLTextureDescriptor new];
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = k_WindowWidth;
    textureDescriptor.height = k_WindowHeight;
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.mipmapLevelCount = 1;
    g_baseColorTexture = [g_mtlDevice newTextureWithDescriptor:textureDescriptor];

    if (!initBaseRenderPipelineState(g_baseRenderPipelineState)) {
        return false;
    }
    if (!initFinalRenderPipelineState(g_finalRenderPipelineState)) {
        return false;
    }

    static Vertex vertexData[] = {
            Vertex{.position = {0.5, -0.5, 0.0}, .color = {1.0, 0.0, 0.0, 1.0}},
            Vertex{.position = {-0.5, -0.5, 0.0}, .color = {0.0, 1.0, 0.0, 1.0}},
            Vertex{.position = {-0.5, 0.5, 0.0}, .color = {0.0, 0.0, 1.0, 1.0}},
            Vertex{.position = {0.5, 0.5, 0.0}, .color = {1.0, 1.0, 0.0, 1.0}}
    };
    static Vertex2 vertexData2[] = {
            Vertex2{.position = {1.0, -1.0, 0.0}, .texCoord = {1.0, 1.0}},
            Vertex2{.position = {-1.0, -1.0, 0.0}, .texCoord = {0.0, 1.0}},
            Vertex2{.position = {-1.0, 1.0, 0.0}, .texCoord = {0.0, 0.0}},
            Vertex2{.position = {1.0, 1.0, 0.0}, .texCoord = {1.0, 0.0}}
    };
    static uint16_t indexData[] = {
            0, 2, 1,
            0, 3, 2
    };
    g_vertexBuffer = [g_mtlDevice newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceOptionCPUCacheModeDefault];
    g_vertexBuffer2 = [g_mtlDevice newBufferWithBytes:vertexData2 length:sizeof(vertexData2) options:MTLResourceOptionCPUCacheModeDefault];
    g_indexBuffer = [g_mtlDevice newBufferWithBytes:indexData length:sizeof(indexData) options:MTLResourceOptionCPUCacheModeDefault];
    g_uniformBuffer = [g_mtlDevice newBufferWithBytes:&g_fragmentUniforms length:sizeof(FragmentUniforms) options:MTLResourceOptionCPUCacheModeDefault];

    return true;
}

void renderDestroy() {
    [g_uniformBuffer release];
    [g_vertexBuffer release];
    [g_vertexBuffer2 release];
    [g_indexBuffer release];
    [g_baseRenderPipelineState release];
    [g_finalRenderPipelineState release];
    [g_baseColorTexture release];
    [g_mtlCommandQueue release];
    [g_mtlDevice release];
}

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (!init()) {
        return EXIT_FAILURE;
    }

    NSApplication *application = [NSApplication sharedApplication];

    AppDelegate *applicationDelegate = [[[AppDelegate alloc] init] autorelease];
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application activateIgnoringOtherApps:YES];
    [application setDelegate:applicationDelegate];
    [application run];
    [pool drain];

    return EXIT_SUCCESS;
}

CVDisplayLinkRef g_displayLink;

static CVReturn displayLinkCallback(
        CVDisplayLinkRef displayLink,
        const CVTimeStamp *now,
        const CVTimeStamp *outputTime,
        CVOptionFlags flagsIn,
        CVOptionFlags *flagsOut,
        void *displayLinkContext) {
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

- (void)keyDown:(NSEvent *)anEvent {
    unsigned short keyCode = [anEvent keyCode];
    if (keyCode == 53 || keyCode == 49) {
        [self close];
    }
}
@end

@implementation AppDelegate
- (id)init {
    if (self = [super init]) {}
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSRect contentSize = NSMakeRect(0.0f, 0.0f, k_WindowWidth, k_WindowHeight);
    g_nsView = [[MetalView alloc] initWithFrame:contentSize];

    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
    self.window = [[MyNSWindow alloc] initWithContentRect:contentSize
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:YES];
    [self.window setTitle:@"Metal C++ Example9"];
    [self.window setOpaque:YES];
    [self.window setContentView:g_nsView];
    [self.window makeMainWindow];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:nil];

    [self.window makeKeyAndOrderFront:self];

    [g_nsView awakeFromNib];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return true;
}
@end

@implementation MetalView
+ (id)layerClass {
    return [NSValue valueWithPointer:[CAMetalLayer class]];
}

- (CALayer *)makeBackingLayer {
    CAMetalLayer *backingLayer = [CAMetalLayer layer];
    self.metalLayer = backingLayer;
    return self.metalLayer;
}

- (instancetype)initWithFrame:(CGRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES; // Providing Metal layer through makeBackingLayer

        if (!g_mtlDevice) {
            fprintf(stderr, "MetalView: ERROR - Metal device has not be created.\n");
        }

        self.metalLayer.device = g_mtlDevice;
        self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return self;
}

- (void)awakeFromNib {
    // As the last thing we do, fire up the display link timer for rendering.
    // Create callback for rendering purposes. Need to check thread ids. I
    // presume this CVDisplayLink callback is issued from the CFRunLoop
    // generated by issuing a call to [NSApp run].
    CVDisplayLinkCreateWithActiveCGDisplays(&g_displayLink);
    CVDisplayLinkSetOutputCallback(g_displayLink, &displayLinkCallback, 0);
    CVDisplayLinkSetCurrentCGDisplay(g_displayLink, 0);
    CVDisplayLinkStart(g_displayLink);
}

- (void)dealloc {
    CVDisplayLinkStop(g_displayLink);
    CVDisplayLinkRelease(g_displayLink);
    renderDestroy();
    [super dealloc];
}
@end