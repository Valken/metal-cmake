#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface AppDelegate : NSObject<NSApplicationDelegate>
{
    NSWindow* window;
    NSView* view;
    id<MTLDevice> device;
    CAMetalLayer* layer;
    CVDisplayLinkRef displayLink;
    id<MTLCommandQueue> commandQueue;
}
- (BOOL)update:(CVTimeStamp const *)timeStamp;
@end

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink,
                                    const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut,
                                    void* displayLinkContext)
{
    AppDelegate *appDelegate = (__bridge AppDelegate *)displayLinkContext;
    return [appDelegate update:outputTime];
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
    view = [[NSView alloc] initWithFrame:contentRect];
    window.contentView =view;
    
    device = MTLCreateSystemDefaultDevice();
    layer = [CAMetalLayer layer];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    commandQueue = [device newCommandQueue];
    
    view.wantsLayer = YES;
    view.layer = layer;
    
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &DisplayLinkCallback, (__bridge void *)self);
    
    [window makeKeyAndOrderFront:nil];
    CVDisplayLinkStart(displayLink);
}

- (BOOL)update:(CVTimeStamp const *)timeStamp
{
    id<CAMetalDrawable> drawable = [layer nextDrawable];
    MTLRenderPassDescriptor*   renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    MTLRenderPassColorAttachmentDescriptor* colorAttachment = [MTLRenderPassColorAttachmentDescriptor new];
    colorAttachment.texture = drawable.texture;
    colorAttachment.clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0);
    colorAttachment.loadAction = MTLLoadActionClear;
    colorAttachment.storeAction = MTLStoreActionStore;
    [renderPassDescriptor.colorAttachments setObject:colorAttachment atIndexedSubscript:0];
    
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Do actual rendering here...
    
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];

    
    return YES;
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
        
        NSMenuItem* appMenuItem = [bar addItemWithTitle:@"" action:NULL keyEquivalent:@""];
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
