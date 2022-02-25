#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <string>
#include <cmath>
#include <mutex>
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

struct vector_float2 {
    float x, y;
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

struct Texture {
    int width, height;
    int components;
    uint8_t* buffer;

    void destroy();
};

void Texture::destroy() {
    stbi_image_free(buffer);
}

bool load_texture_from_file(const std::string& path, Texture& out_text) {
    out_text.buffer = stbi_load(path.c_str(), &out_text.width, &out_text.height, &out_text.components, 4);
    return out_text.buffer != nullptr;
}

struct Vertex {
    vector_float3 position;
    vector_float2 texCoord;
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

struct MyUniform {
    matrix_float4x4 model_view_projection_matrix{};
};

@class MetalView;
MetalView *g_nsView;

using high_resolution_clock = std::chrono::high_resolution_clock;
using hr_time_point = std::chrono::time_point<high_resolution_clock>;
using millisecond = std::chrono::duration<float, std::milli>;

float rotationAngle = 10.f;
id <MTLDevice> g_mtlDevice;
id <MTLCommandQueue> g_mtlCommandQueue;
id <MTLRenderPipelineState> g_baseRenderPipelineState;
id <MTLRenderPipelineState> g_finalRenderPipelineState;
id <MTLDepthStencilState> g_depthStencilState;
id <MTLBuffer> g_vertexBuffer;
id <MTLBuffer> g_vertexBuffer2;
id <MTLBuffer> g_indexBuffer;
id <MTLBuffer> g_uniformBuffer;
id<MTLTexture> g_baseColorTexture;
id<MTLTexture> g_depthTexture;
id<MTLTexture> g_cubeTexture;
id<MTLSamplerState> g_cubeSampler;
static const int k_WindowWidth = 800;
static const int k_WindowHeight = 600;
const float MY_PI = 3.1415926f;
const float degrees_to_radians = MY_PI / 180.f;
float deg_to_rad(float degrees) { return degrees * degrees_to_radians; }
static MyUniform g_uniforms;
static Semaphore sem{1};
hr_time_point t1, t2;
float elapsedTime = 0.f;
const matrix_float4x4 viewMatrix = matrix_float4x4::matrix_float4x4_lookat({0, 0, 4}, {0, 0, 0}, {0, 1, 0});
const matrix_float4x4 projectionMatrix = matrix_float4x4::matrix_from_perspective_fov_aspectLH(k_WindowWidth / k_WindowHeight, deg_to_rad(60.f), 0.1f, 5000.f);

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

    baseRenderPassDescriptor.depthAttachment.texture = g_depthTexture;
    baseRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    baseRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    baseRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;

    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:baseRenderPassDescriptor];
    [commandEncoder setRenderPipelineState:g_baseRenderPipelineState];
    [commandEncoder setDepthStencilState:g_depthStencilState];
    [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [commandEncoder setCullMode:MTLCullModeNone];
    [commandEncoder setVertexBuffer:g_vertexBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:g_uniformBuffer offset:0 atIndex:1];
    [commandEncoder setFragmentTexture:g_cubeTexture atIndex:0];
    [commandEncoder setFragmentSamplerState:g_cubeSampler atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
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
    elapsedTime += dt;
    rotationAngle++;
    const matrix_float4x4 modelMatrix = matrix_float4x4::rotation_matrix_axis(deg_to_rad(rotationAngle), {0, 1, 0})
                                        * matrix_float4x4::matrix_float4x4_uniform_scale({0.5, 0.5, 0.5});
    g_uniforms.model_view_projection_matrix = modelMatrix * viewMatrix * projectionMatrix;

    memcpy([g_uniformBuffer contents], &g_uniforms, sizeof(MyUniform));
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

    Texture texture{};
    if (!load_texture_from_file("./cube.png", texture)) {
        fprintf(stderr, "Texture load failed\n");
        return EXIT_FAILURE;
    }
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = static_cast<NSUInteger>(texture.width);
    textureDescriptor.height = static_cast<NSUInteger>(texture.height);
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    g_cubeTexture = [g_mtlDevice newTextureWithDescriptor:textureDescriptor];
    MTLRegion region = { { 0, 0, 0}, { static_cast<NSUInteger>(texture.width), static_cast<NSUInteger>(texture.height), 1} };
    [g_cubeTexture replaceRegion:region mipmapLevel:0 withBytes:texture.buffer bytesPerRow:static_cast<NSUInteger>(4 * texture.width)];
    texture.destroy();

    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
    samplerDescriptor.maxAnisotropy = 1;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.rAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.normalizedCoordinates = YES;
    samplerDescriptor.lodMinClamp = 0;
    samplerDescriptor.lodMaxClamp = FLT_MAX;

    g_cubeSampler = [g_mtlDevice newSamplerStateWithDescriptor:samplerDescriptor];

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

    MTLDepthStencilDescriptor* depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    g_depthStencilState = [g_mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];

    MTLTextureDescriptor* depthTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                                      width:k_WindowWidth
                                                                                                     height:k_WindowHeight
                                                                                                  mipmapped:NO];
    depthTextureDescriptor.usage = MTLTextureUsageRenderTarget;
    depthTextureDescriptor.storageMode = MTLStorageModePrivate;
    g_depthTexture = [g_mtlDevice newTextureWithDescriptor:depthTextureDescriptor];

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

    float vertexData[] = {
            //Front
            -1.0,  1.0,  1.0, 0.25, 0.25,
            -1.0, -1.0,  1.0, 0.25, 0.50,
            1.0, -1.0,  1.0, 0.50, 0.50,
            -1.0,  1.0,  1.0, 0.25, 0.25,
            1.0, -1.0,  1.0, 0.50, 0.50,
            1.0,  1.0,  1.0, 0.50, 0.25,

            //Left
            -1.0,  1.0, -1.0, 0.00, 0.25,
            -1.0, -1.0, -1.0, 0.00, 0.50,
            -1.0, -1.0,  1.0, 0.25, 0.50,
            -1.0,  1.0, -1.0, 0.00, 0.25,
            -1.0, -1.0,  1.0, 0.25, 0.50,
            -1.0,  1.0,  1.0, 0.25, 0.25,

            //Right
            1.0,  1.0,  1.0, 0.50, 0.25,
            1.0, -1.0,  1.0, 0.50, 0.50,
            1.0, -1.0, -1.0, 0.75, 0.50,
            1.0,  1.0,  1.0, 0.50, 0.25,
            1.0, -1.0, -1.0, 0.75, 0.50,
            1.0,  1.0, -1.0, 0.75, 0.25,

            //Top
            -1.0,  1.0, -1.0, 0.25, 0.00,
            -1.0,  1.0,  1.0, 0.25, 0.25,
            1.0,  1.0,  1.0, 0.50, 0.25,
            -1.0,  1.0, -1.0, 0.25, 0.00,
            1.0,  1.0,  1.0, 0.50, 0.25,
            1.0,  1.0, -1.0, 0.50, 0.00,

            //Bottom
            -1.0, -1.0,  1.0, 0.25, 0.50,
            -1.0, -1.0, -1.0, 0.25, 0.75,
            1.0, -1.0, -1.0, 0.50, 0.75,
            -1.0, -1.0,  1.0, 0.25, 0.50,
            1.0, -1.0, -1.0, 0.50, 0.75,
            1.0, -1.0,  1.0, 0.50, 0.50,

            //Back
            1.0,  1.0, -1.0, 0.75, 0.25,
            1.0, -1.0, -1.0, 0.75, 0.50,
            -1.0, -1.0, -1.0, 1.00, 0.50,
            1.0,  1.0, -1.0, 0.75, 0.25,
            -1.0, -1.0, -1.0, 1.00, 0.50,
            -1.0,  1.0, -1.0, 1.00, 0.25
    };
    static Vertex vertexData2[] = {
            Vertex{.position = {1.0, -1.0, 0.0}, .texCoord = {1.0, 1.0}},
            Vertex{.position = {-1.0, -1.0, 0.0}, .texCoord = {0.0, 1.0}},
            Vertex{.position = {-1.0, 1.0, 0.0}, .texCoord = {0.0, 0.0}},
            Vertex{.position = {1.0, 1.0, 0.0}, .texCoord = {1.0, 0.0}}
    };
    static uint16_t indexData[] = {
            0, 2, 1,
            0, 3, 2
    };
    g_vertexBuffer = [g_mtlDevice newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceOptionCPUCacheModeDefault];
    g_vertexBuffer2 = [g_mtlDevice newBufferWithBytes:vertexData2 length:sizeof(vertexData2) options:MTLResourceOptionCPUCacheModeDefault];
    g_indexBuffer = [g_mtlDevice newBufferWithBytes:indexData length:sizeof(indexData) options:MTLResourceOptionCPUCacheModeDefault];
    g_uniformBuffer = [g_mtlDevice newBufferWithBytes:&g_uniforms length:sizeof(MyUniform) options:MTLResourceOptionCPUCacheModeDefault];

    return true;
}

void renderDestroy() {
    [g_uniformBuffer release];
    [g_vertexBuffer release];
    [g_vertexBuffer2 release];
    [g_indexBuffer release];
    [g_cubeSampler release];
    [g_cubeTexture release];
    [g_depthStencilState release];
    [g_depthTexture release];
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