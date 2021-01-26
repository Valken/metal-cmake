#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <simd/simd.h>
#include "imgui.h"
#include "imgui_impl_metal.h"
#include "imgui_impl_osx.h"

static const vector_float2 triangleVertices[] =
{
    {  1,  -1 },
    { -1,  -1 },
    {  0,   1 },
};

@interface AppDelegate : NSObject<NSApplicationDelegate, NSWindowDelegate>
{
    NSWindow* window;
    NSView* view;
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLRenderPipelineState> pipelineState;
    MTLRenderPassDescriptor* renderPassDescriptor;
    CAMetalLayer* layer;
    CVDisplayLinkRef displayLink;
}
- (BOOL)update:(CVTimeStamp const *)timeStamp;
- (void)renderUI:(MTLRenderPassDescriptor *)descriptor :(id<MTLCommandBuffer>)buffer :(id <MTLRenderCommandEncoder>)encoder;
@end

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext)
{
    // It's okay to return within an autoreleasepool
    // https://clang.llvm.org/docs/AutomaticReferenceCounting.html#autoreleasepool
    @autoreleasepool
    {
        AppDelegate *appDelegate = (__bridge AppDelegate *)displayLinkContext;
        CVTimeStamp const * const thing = outputTime;
        return [appDelegate update:thing];
    }
}

@implementation AppDelegate

-(void)dealloc
{
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSRect contentRect = NSMakeRect(200, 200, 800, 600);
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable;
    window = [[NSWindow alloc] initWithContentRect:contentRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
    [window setTitle:@"Metal ImGui"];
    view = [[NSView alloc] initWithFrame:contentRect];
    window.contentView = view;
    window.delegate = self;
    
    device = MTLCreateSystemDefaultDevice();

    layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    view.wantsLayer = YES;
    view.layer = layer;
    view.needsDisplay = NO;
    
    commandQueue = [device newCommandQueue];
    id<MTLLibrary> library = [device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor* pipelineDesc = [MTLRenderPipelineDescriptor new];
    id<MTLFunction> vertexShader = [library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentShader = [library newFunctionWithName:@"fragmentShader"];
    pipelineDesc.vertexFunction = vertexShader;
    pipelineDesc.fragmentFunction = fragmentShader;
    pipelineDesc.colorAttachments[0].pixelFormat = layer.pixelFormat;
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDesc error:nil];
    
    renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();
    ImGui_ImplMetal_Init(device);
    
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &DisplayLinkCallback, (__bridge void *)self);
    
    [window makeKeyAndOrderFront:nil];
    CVDisplayLinkStart(displayLink);
}

- (BOOL)update:(CVTimeStamp const *)timeStamp
{
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    // TODO: signal a semaphore in commandBuffer's completion handler here...
    
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [encoder setRenderPipelineState:pipelineState];

    [encoder setVertexBytes:triangleVertices length:sizeof(triangleVertices) atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

    [self renderUI :renderPassDescriptor :commandBuffer :encoder];

    [encoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];

    return YES;
}

static void ShowExampleAppSimpleOverlay(bool*);

- (void)renderUI:(MTLRenderPassDescriptor *)renderPassDescriptor
                :(id<MTLCommandBuffer>)commandBuffer
                :(id <MTLRenderCommandEncoder>)renderEncoder;
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = 800; //view.bounds.size.width;
    io.DisplaySize.y = 600; //view.bounds.size.height;

    //io.DisplayFramebufferScale = ImVec2(1, 1);
    io.DeltaTime = 1 / 60;
    static bool show_demo_window = true;

    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui_ImplOSX_NewFrame(nullptr /*view*/);
    ImGui::NewFrame();

    ImGui::ShowDemoWindow(&show_demo_window);
    ShowExampleAppSimpleOverlay(&show_demo_window);

    ImGui::Render();
    ImDrawData* draw_data = ImGui::GetDrawData();
    draw_data->FramebufferScale = ImVec2(1, 1);
    ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
    
}
@end


int main(int argc, char *argv[])
{
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    @autoreleasepool
    {
        NSMenu* bar = [[NSMenu alloc] init];
        [NSApp setMainMenu:bar];
        
        NSMenuItem* appMenuItem = [bar addItemWithTitle:@""
                                                 action:NULL
                                          keyEquivalent:@""];
        NSMenu* appMenu = [[NSMenu alloc] init];
        [appMenuItem setSubmenu:appMenu];
        
        [appMenu addItemWithTitle:@"Quit"
                           action:@selector(terminate:)
                    keyEquivalent:@"q"];
    
        NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];
        [image lockFocus];
        [[NSColor redColor] setFill];
        [NSBezierPath fillRect:NSMakeRect(0, 0, 128, 128)];
        [image unlockFocus];

        [NSApp setApplicationIconImage:image];
    }
    
    AppDelegate* delegate = [[AppDelegate alloc] init];
    if (delegate == nil)
        return -1;
    
    [NSApp setDelegate:delegate];
    [NSApp run];
    
    return 0;
}

// Copied from demo
static void ShowExampleAppSimpleOverlay(bool* p_open)
{
    const float DISTANCE = 10.0f;
    static int corner = 0;
    ImGuiIO& io = ImGui::GetIO();
    ImGuiWindowFlags window_flags = ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoFocusOnAppearing | ImGuiWindowFlags_NoNav;
    if (corner != -1)
    {
        window_flags |= ImGuiWindowFlags_NoMove;
        ImVec2 window_pos = ImVec2((corner & 1) ? io.DisplaySize.x - DISTANCE : DISTANCE, (corner & 2) ? io.DisplaySize.y - DISTANCE : DISTANCE);
        ImVec2 window_pos_pivot = ImVec2((corner & 1) ? 1.0f : 0.0f, (corner & 2) ? 1.0f : 0.0f);
        ImGui::SetNextWindowPos(window_pos, ImGuiCond_Always, window_pos_pivot);
    }
    ImGui::SetNextWindowBgAlpha(0.35f); // Transparent background
    if (ImGui::Begin("Example: Simple overlay", p_open, window_flags))
    {
        ImGui::Text("Simple overlay\n" "in the corner of the screen.\n" "(right-click to change position)");
        ImGui::Separator();
        if (ImGui::IsMousePosValid())
            ImGui::Text("Mouse Position: (%.1f,%.1f)", io.MousePos.x, io.MousePos.y);
        else
            ImGui::Text("Mouse Position: <invalid>");
        if (ImGui::BeginPopupContextWindow())
        {
            if (ImGui::MenuItem("Custom",       NULL, corner == -1)) corner = -1;
            if (ImGui::MenuItem("Top-left",     NULL, corner == 0)) corner = 0;
            if (ImGui::MenuItem("Top-right",    NULL, corner == 1)) corner = 1;
            if (ImGui::MenuItem("Bottom-left",  NULL, corner == 2)) corner = 2;
            if (ImGui::MenuItem("Bottom-right", NULL, corner == 3)) corner = 3;
            if (p_open && ImGui::MenuItem("Close")) *p_open = false;
            ImGui::EndPopup();
        }
    }
    ImGui::End();
}
