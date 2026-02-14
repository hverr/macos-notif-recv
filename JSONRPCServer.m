#import "JSONRPCServer.h"
#import "NotificationManager.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

@interface JSONRPCServer ()
@property (nonatomic, assign) int serverSocket;
@property (nonatomic, strong) dispatch_source_t serverSource;
@property (nonatomic, strong) dispatch_queue_t serverQueue;
@property (nonatomic, assign, readwrite) BOOL isRunning;
@end

@implementation JSONRPCServer

- (instancetype)initWithPort:(uint16_t)port {
    self = [super init];
    if (self) {
        _port = port;
        _serverSocket = -1;
        _isRunning = NO;
        _serverQueue = dispatch_queue_create("com.notificationreceiver.server", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (BOOL)start:(NSError **)error {
    if (self.isRunning) {
        return YES;
    }

    self.serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (self.serverSocket == -1) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        return NO;
    }

    int opt = 1;
    setsockopt(self.serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(self.port);

    if (bind(self.serverSocket, (struct sockaddr *)&serverAddr, sizeof(serverAddr)) == -1) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        close(self.serverSocket);
        self.serverSocket = -1;
        return NO;
    }

    if (listen(self.serverSocket, 5) == -1) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        }
        close(self.serverSocket);
        self.serverSocket = -1;
        return NO;
    }

    self.serverSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.serverSocket, 0, self.serverQueue);

    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.serverSource, ^{
        [weakSelf acceptConnection];
    });

    dispatch_source_set_cancel_handler(self.serverSource, ^{
        if (weakSelf.serverSocket != -1) {
            close(weakSelf.serverSocket);
            weakSelf.serverSocket = -1;
        }
    });

    dispatch_resume(self.serverSource);
    self.isRunning = YES;

    NSLog(@"JSON-RPC server started on port %d", self.port);
    return YES;
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }

    if (self.serverSource) {
        dispatch_source_cancel(self.serverSource);
        self.serverSource = nil;
    }

    self.isRunning = NO;
    NSLog(@"JSON-RPC server stopped");
}

- (void)acceptConnection {
    struct sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    int clientSocket = accept(self.serverSocket, (struct sockaddr *)&clientAddr, &clientLen);

    if (clientSocket == -1) {
        NSLog(@"Failed to accept connection: %s", strerror(errno));
        return;
    }

    NSLog(@"Accepted connection from %s:%d", inet_ntoa(clientAddr.sin_addr), ntohs(clientAddr.sin_port));

    dispatch_async(self.serverQueue, ^{
        [self handleClient:clientSocket];
    });
}

- (void)handleClient:(int)clientSocket {
    char buffer[4096];
    ssize_t bytesRead = recv(clientSocket, buffer, sizeof(buffer) - 1, 0);

    if (bytesRead <= 0) {
        close(clientSocket);
        return;
    }

    buffer[bytesRead] = '\0';
    NSString *requestString = [NSString stringWithUTF8String:buffer];
    NSLog(@"Received: %@", requestString);

    NSString *response = [self processJSONRPCRequest:requestString];

    const char *responseData = [response UTF8String];
    send(clientSocket, responseData, strlen(responseData), 0);

    close(clientSocket);
}

- (NSString *)processJSONRPCRequest:(NSString *)requestString {
    NSError *error = nil;
    NSData *data = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *request = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error || !request) {
        return [self errorResponse:nil code:-32700 message:@"Parse error"];
    }

    NSString *jsonrpc = request[@"jsonrpc"];
    NSString *method = request[@"method"];
    id params = request[@"params"];
    id requestId = request[@"id"];

    if (![jsonrpc isEqualToString:@"2.0"]) {
        return [self errorResponse:requestId code:-32600 message:@"Invalid Request"];
    }

    if (![method isEqualToString:@"notify"]) {
        return [self errorResponse:requestId code:-32601 message:@"Method not found"];
    }

    if (![params isKindOfClass:[NSDictionary class]]) {
        return [self errorResponse:requestId code:-32602 message:@"Invalid params"];
    }

    NSString *title = params[@"title"];
    NSString *message = params[@"message"];

    if (!title || !message) {
        return [self errorResponse:requestId code:-32602 message:@"Missing title or message"];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NotificationManager sharedManager] displayNotificationWithTitle:title message:message];
    });

    return [self successResponse:requestId result:@"success"];
}

- (NSString *)successResponse:(id)requestId result:(id)result {
    NSDictionary *response = @{
        @"jsonrpc": @"2.0",
        @"result": result,
        @"id": requestId ?: [NSNull null]
    };

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];
    if (error) {
        return @"{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Internal error\"},\"id\":null}";
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)errorResponse:(id)requestId code:(NSInteger)code message:(NSString *)message {
    NSDictionary *response = @{
        @"jsonrpc": @"2.0",
        @"error": @{
            @"code": @(code),
            @"message": message
        },
        @"id": requestId ?: [NSNull null]
    };

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];
    if (error) {
        return @"{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Internal error\"},\"id\":null}";
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)dealloc {
    [self stop];
}

@end
