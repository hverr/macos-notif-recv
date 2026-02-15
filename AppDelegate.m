#import "AppDelegate.h"
#import "JSONRPCServer.h"
#import "NotificationManager.h"

@interface AppDelegate ()
@property (strong, nonatomic) JSONRPCServer *rpcServer;
@property (strong, nonatomic) NSMenu *statusMenu;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self setupMenuBar];
    [self startServer];
}

- (void)setupMenuBar {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"ninja" ofType:@"png"];

    if (iconPath) {
        NSImage *icon = [[NSImage alloc] initWithContentsOfFile:iconPath];

        if (icon) {
            [icon setSize:NSMakeSize(18, 18)];
            self.statusItem.button.image = icon;
        } else {
            self.statusItem.button.title = @"🥷";
        }
    } else {
        self.statusItem.button.title = @"🥷";
    }

    self.statusMenu = [[NSMenu alloc] init];

    NSMenuItem *portItem = [[NSMenuItem alloc] initWithTitle:@"Port: 9090" action:nil keyEquivalent:@""];
    [portItem setEnabled:NO];
    [self.statusMenu addItem:portItem];

    [self.statusMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                      action:@selector(quit:)
                                               keyEquivalent:@"q"];
    [quitItem setTarget:self];
    [self.statusMenu addItem:quitItem];

    self.statusItem.menu = self.statusMenu;
}

- (void)startServer {
    self.rpcServer = [[JSONRPCServer alloc] initWithPort:9090];

    NSError *error = nil;
    BOOL started = [self.rpcServer start:&error];

    if (started) {
        NSLog(@"Server started successfully");
    } else {
        NSLog(@"Failed to start server: %@", error);

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Server Error";
        alert.informativeText = [NSString stringWithFormat:@"Failed to start server on port 8080: %@", error.localizedDescription];
        alert.alertStyle = NSAlertStyleCritical;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

- (void)quit:(id)sender {
    [self.rpcServer stop];
    [NSApp terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.rpcServer stop];
}

@end
