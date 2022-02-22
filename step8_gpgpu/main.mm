#import <Metal/Metal.h>
#include <string>
#include <cmath>

id<MTLDevice> g_mtlDevice;

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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        g_mtlDevice = MTLCreateSystemDefaultDevice();
        id<MTLCommandQueue> commandQueue = [g_mtlDevice newCommandQueue];

        id <MTLLibrary> computeLibrary;
        if (!loadShader("./basic.metal", computeLibrary)) {
            return -1;
        }

        MTLComputePipelineDescriptor *pipelineDescriptor = [MTLComputePipelineDescriptor new];
        pipelineDescriptor.computeFunction = [computeLibrary newFunctionWithName:@"add"];
        pipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
        [computeLibrary release];

        NSError *pipelineError = nullptr;
        id<MTLComputePipelineState> pipelineState = [g_mtlDevice newComputePipelineStateWithDescriptor:pipelineDescriptor options:MTLPipelineOptionNone reflection:NULL error:&pipelineError];
        if (!pipelineState) {
            NSLog(@"Failed to create render pipeline state: %@", pipelineError);
            return -1;
        }
        [pipelineDescriptor release];
        [pipelineError release];

        float input[] = {1.0, 2.0};
        id<MTLBuffer> inputBuffer = [g_mtlDevice newBufferWithBytes:input length:sizeof(input) options:MTLResourceOptionCPUCacheModeDefault];
        id<MTLBuffer> outputBuffer = [g_mtlDevice newBufferWithLength:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];

        // render
        id <MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:pipelineState];
        [computeEncoder setBuffer:inputBuffer offset:0 atIndex:0];
        [computeEncoder setBuffer:outputBuffer offset:0 atIndex:1];
        MTLSize numThreadgroups = {1,1,1};
        MTLSize numgroups = {1,1,1};
        [computeEncoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:numgroups];
        [computeEncoder endEncoding];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];

        float *output = static_cast<float *>([outputBuffer contents]);
        printf("result = %f\n", output[0]);

        [inputBuffer release];
        [outputBuffer release];
        [pipelineState release];
        [commandQueue release];
        [g_mtlDevice release];
    }
    return 0;
}