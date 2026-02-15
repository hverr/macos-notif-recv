#import "NotificationManager.h"

@implementation NotificationManager

+ (instancetype)sharedManager {
    static NotificationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NotificationManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)displayNotificationWithTitle:(NSString *)title message:(NSString *)message {
    // Use AppleScript for more reliable notifications
    NSString *script = [NSString stringWithFormat:
        @"display notification \"%@\" with title \"%@\" sound name \"default\"",
        [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""],
        [title stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
    ];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary *errorDict = nil;
    [appleScript executeAndReturnError:&errorDict];

    if (errorDict) {
        NSLog(@"Failed to display notification: %@", errorDict);
    } else {
        NSLog(@"Notification displayed - Title: %@, Message: %@", title, message);
    }
}


@end
