#import "MenuBarRestriction.h"
#import <dlfcn.h>

@interface NSObject (DRMenuBarClientCore)
- (instancetype)initWithAllowedSystemItems:(NSArray *)systemItems allowedBundleIdentifiers:(NSArray *)bundleIdentifiers;
- (void)activateWithConfiguration:(id)configuration completionHandler:(void (^)(NSError *))handler;
- (void)invalidate;
@end

static NSString *const DRFrameworkPath = @"/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore";

@implementation DRMenuBarRestriction

+ (BOOL)isAvailable {
    static BOOL available;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        available = dlopen(DRFrameworkPath.fileSystemRepresentation, RTLD_NOW) != NULL
            && [NSClassFromString(@"MBAssessmentModeConfiguration") instancesRespondToSelector:@selector(initWithAllowedSystemItems:allowedBundleIdentifiers:)]
            && [NSClassFromString(@"MBAssessmentModeAssertion") instancesRespondToSelector:@selector(activateWithConfiguration:completionHandler:)]
            && [NSClassFromString(@"MBAssessmentModeAssertion") instancesRespondToSelector:@selector(invalidate)];
    });
    return available;
}

/// System items are numbered; 0...255 keeps them all (0...63 drops Screen Mirroring).
+ (NSArray<NSNumber *> *)allSystemItems {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:256];
    for (NSInteger i = 0; i <= 255; i++) [items addObject:@(i)];
    return items;
}

+ (id)activateAllowing:(NSArray<NSString *> *)bundleIdentifiers completion:(void (^)(NSError *))completion {
    if (!self.isAvailable) return nil;
    // Only an NSArray is accepted; an NSSet throws.
    id configuration = [[NSClassFromString(@"MBAssessmentModeConfiguration") alloc]
        initWithAllowedSystemItems:self.allSystemItems allowedBundleIdentifiers:[bundleIdentifiers copy]];
    id assertion = [[NSClassFromString(@"MBAssessmentModeAssertion") alloc] init];
    if (!configuration || !assertion) return nil;
    [assertion activateWithConfiguration:configuration completionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    }];
    return assertion;
}

+ (void)invalidate:(id)token {
    [token invalidate];
}

@end
