#import <Foundation/Foundation.h>

@interface JSONRPCServer : NSObject

@property (nonatomic, assign) uint16_t port;
@property (nonatomic, assign, readonly) BOOL isRunning;

- (instancetype)initWithPort:(uint16_t)port;
- (BOOL)start:(NSError **)error;
- (void)stop;

@end
