#import "FSKNotificationCenter.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSKNotificationCenter ()

@property (nonatomic, readonly) NSMutableDictionary *callbacks;
@property (nonatomic, readonly) NSMutableDictionary *parameters;

@end

@implementation FSKNotificationCenter

+ (FSKNotificationCenter *)defaultCenter {
    static FSKNotificationCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FSKNotificationCenter alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _callbacks = [NSMutableDictionary dictionary];
        _parameters = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerNotificationName:(NSString *)name withCallback:(void (^)(NSDictionary * _Nullable))callback {
    NSParameterAssert(name);
    NSParameterAssert(callback);

    if ([self.callbacks objectForKey:name]) {
        @throw [NSException exceptionWithName:@"Name already registered"
                                       reason:nil
                                     userInfo:nil];
    }

    self.callbacks[name] = callback;
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, (__bridge const void *)(self), defaultNotificationCallback, (__bridge CFStringRef)name, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)unregisterNotificationName:(NSString *)name {
    NSParameterAssert(name);

    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveObserver(center, (__bridge const void *)(self), (__bridge CFStringRef)name, NULL);
    [self.callbacks removeObjectForKey:name];
    [self.parameters removeObjectForKey:name];
}

- (void)postNotificationName:(NSString *)name withParameters:(nullable NSDictionary *)parameters {
    NSParameterAssert(name);

    if (parameters) {
        self.parameters[name] = parameters;
    }

    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(center, (__bridge CFStringRef)name, NULL, NULL, YES);
}

- (void)didReceiveNotificationCallbackForName:(NSString *)name {
    NSParameterAssert(name);

    void (^callback)(NSDictionary *_Nullable) = self.callbacks[name];
    NSDictionary *_Nullable parameters = [self.parameters objectForKey:name];
    callback(parameters);
}

void defaultNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString *notificationName = (__bridge NSString *)name;
    [FSKNotificationCenter.defaultCenter didReceiveNotificationCallbackForName:notificationName];
}

@end

NS_ASSUME_NONNULL_END
