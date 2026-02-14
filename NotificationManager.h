#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface NotificationManager : NSObject <NSUserNotificationCenterDelegate>

+ (instancetype)sharedManager;
- (void)displayNotificationWithTitle:(NSString *)title message:(NSString *)message;

@end
