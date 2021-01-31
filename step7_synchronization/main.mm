#define GLFW_INCLUDE_NONE

#import <GLFW/glfw3.h>

#define GLFW_EXPOSE_NATIVE_COCOA

#import <GLFW/glfw3native.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>
#include <cassert>
#include <cstdio>
#include <string>

float deltaTime = 0.0f;    // 마지막 프레임과 현재 프레임 사이의 시간
float lastFrame = 0.0f; // 마지막 프레임의 시간

struct FragmentUniforms {
  FragmentUniforms(float _brightness) : brightness{_brightness} {}

  float brightness;
};

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

static void error_callback(int error, const char *description) {
    fputs(description, stderr);
}

static void key_callback(GLFWwindow *window, int key, int scancode, int action, int mods) {
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GLFW_TRUE);
}

int main(void) {
    id <MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) exit(EXIT_FAILURE);
    CAMetalLayer *layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.opaque = YES;

    glfwSetErrorCallback(error_callback);
    if (!glfwInit()) exit(EXIT_FAILURE);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    GLFWwindow *window = glfwCreateWindow(640, 480, "Metal Example", NULL, NULL);
    if (!window) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    NSWindow *nswin = glfwGetCocoaWindow(window);
    nswin.contentView.layer = layer;
    nswin.contentView.wantsLayer = YES;

    MTLCompileOptions *compileOptions = [MTLCompileOptions new];
    compileOptions.languageVersion = MTLLanguageVersion1_1;
    NSError *compileError;
    std::string shaderSource;
    if (!read_file("../basic.metal", shaderSource)) {
        fprintf(stderr, "Shader not found");
        return EXIT_FAILURE;
    }
    id <MTLLibrary> lib = [device newLibraryWithSource:[NSString stringWithFormat:@"%s", shaderSource.c_str()] options:compileOptions error:&compileError];
    if (!lib) {
        NSLog(@"can't create library: %@", compileError);
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    id <MTLFunction> vs = [lib newFunctionWithName:@"main0"];
    assert(vs);
    id <MTLFunction> fs = [lib newFunctionWithName:@"main1"];
    assert(fs);
    id <MTLCommandQueue> commandQueue = [device newCommandQueue];
    assert(commandQueue);
    MTLRenderPipelineDescriptor *rpd = [MTLRenderPipelineDescriptor new];
    rpd.vertexFunction = vs;
    rpd.fragmentFunction = fs;
    rpd.colorAttachments[0].pixelFormat = layer.pixelFormat;

    NSError *error = NULL;
    MTLPipelineOption option = MTLPipelineOptionBufferTypeInfo | MTLPipelineOptionArgumentInfo;
    MTLRenderPipelineReflection *reflectionObj;
    id <MTLRenderPipelineState> renderPipelineState = [device newRenderPipelineStateWithDescriptor:rpd options:option reflection:&reflectionObj error:&error];
    assert(renderPipelineState);

    for (MTLArgument *arg in reflectionObj.vertexArguments) {
        NSLog(@"Found arg: %@\n", arg.name);

        if (arg.bufferDataType == MTLDataTypeStruct) {
            for (MTLStructMember *uniform in arg.bufferStructType.members) {
                NSLog(@"\tuniform: %@, type:%lu, location: %lu", uniform.name, (unsigned long) uniform.dataType,
                      (unsigned long) uniform.offset);
            }
        }
    }

    for (MTLArgument *arg in reflectionObj.fragmentArguments) {
        NSLog(@"Found arg: %@\n", arg.name);

        if (arg.bufferDataType == MTLDataTypeStruct) {
            for (MTLStructMember *uniform in arg.bufferStructType.members) {
                NSLog(@"\tuniform: %@, type:%lu, location: %lu", uniform.name, (unsigned long) uniform.dataType,
                      (unsigned long) uniform.offset);
            }
        }
    }

    glfwSetKeyCallback(window, key_callback);

    float quadVertexData[] = {
            0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
            -0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
            -0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,

            0.5, 0.5, 0.0, 1.0, 1.0, 1.0, 0.0, 1.0,
            0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
            -0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
    };
    id <MTLBuffer> vertexBuffer = [device newBufferWithBytes:quadVertexData length:sizeof(quadVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    FragmentUniforms fragmentUniforms = FragmentUniforms{1.f};
    id <MTLBuffer> uniformBuffer = [device newBufferWithBytes:&fragmentUniforms length:sizeof(FragmentUniforms) options:MTLResourceOptionCPUCacheModeDefault];

    float elapsedTime = 0.f;
    while (!glfwWindowShouldClose(window)) {
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        layer.drawableSize = CGSizeMake(width, height);
        id <CAMetalDrawable> drawable = [layer nextDrawable];
        assert(drawable);

        float currentFrame = glfwGetTime();
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        // wait

        // update logic
        fragmentUniforms.brightness = 0.5f * std::cos(elapsedTime) + 0.5f;
        memcpy([uniformBuffer contents], &fragmentUniforms, sizeof(FragmentUniforms));
        elapsedTime += deltaTime;

        // render logic
        id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
        MTLRenderPassColorAttachmentDescriptor *cd = renderPassDescriptor.colorAttachments[0];
        cd.texture = drawable.texture;
        cd.loadAction = MTLLoadActionClear;
        cd.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
        cd.storeAction = MTLStoreActionStore;
        id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:renderPipelineState];
        [commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
        [commandEncoder setFragmentBuffer:uniformBuffer offset:0 atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        // signal

        [commandBuffer commit];
        glfwPollEvents();
    }
    glfwDestroyWindow(window);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}
