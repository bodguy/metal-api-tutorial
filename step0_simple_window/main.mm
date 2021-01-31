#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>

@class NSView;
NSView* g_nsView;
CVDisplayLinkRef g_displayLink;
static const int k_WindowWidth  = 800;
static const int k_WindowHeight = 600;

static CVReturn displayLinkCallback(
    CVDisplayLinkRef displayLink,
    const CVTimeStamp* now,
    const CVTimeStamp* outputTime,
    CVOptionFlags flagsIn,
    CVOptionFlags* flagsOut,
    void* displayLinkContext)
{
  return kCVReturnSuccess;
}

@interface MyNSWindow : NSWindow
- (BOOL)canBecomeMainWindow;
- (BOOL)canBecomeKeyWindow;
- (BOOL)acceptsFirstResponder;
- (void)keyDown:(NSEvent *)anEvent;
@end

@interface MetalView : NSView
@property (nonatomic, assign) CAMetalLayer* metalLayer;
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow* window;
@end

int main(int argc, char *argv[])
{
  @autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    
    AppDelegate *applicationDelegate = [[[AppDelegate alloc] init] autorelease];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
    [application setDelegate:applicationDelegate];

    [application run];
  }

  return EXIT_SUCCESS;
}

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
    self.metalLayer.device = nullptr;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  }
  return self;
}

- (void)awakeFromNib
{
  CVDisplayLinkCreateWithActiveCGDisplays(&g_displayLink);
  CVDisplayLinkSetOutputCallback(g_displayLink, &displayLinkCallback, 0);
  CVDisplayLinkSetCurrentCGDisplay(g_displayLink, 0);
  CVDisplayLinkStart(g_displayLink);
}

- (void)dealloc
{
  CVDisplayLinkStop(g_displayLink);
  CVDisplayLinkRelease(g_displayLink);
  [super dealloc];
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
  [self.window setTitle:@"Metal C++ Example"];
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