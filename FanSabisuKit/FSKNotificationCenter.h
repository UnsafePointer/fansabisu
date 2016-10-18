#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSKNotificationCenter : NSObject

@property (nonatomic, class, readonly) FSKNotificationCenter *defaultCenter;

- (void)registerNotificationName:(NSString *)name withCallback:(void (^)(NSDictionary * _Nullable))callback;
- (void)unregisterNotificationName:(NSString *)name;
- (void)postNotificationName:(NSString *)name withParameters:(nullable NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
