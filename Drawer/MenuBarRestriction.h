#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// macOS 27's menu bar allowlist (the facility behind assessment mode), from the private
/// MenuBarClientCore framework. While an assertion is held, only the listed apps' status
/// items are drawn. The newest assertion wins; invalidating it, or quitting, restores
/// everything.
@interface DRMenuBarRestriction : NSObject

/// NO if the framework or its classes are missing (a macOS update may remove them).
+ (BOOL)isAvailable;

/// Activates a new assertion allowing only these apps (and every system item).
/// Returns a token for `invalidate:`, or nil if the facility is unavailable.
+ (nullable id)activateAllowing:(NSArray<NSString *> *)bundleIdentifiers
                     completion:(void (^)(NSError *_Nullable error))completion;

+ (void)invalidate:(id)token;

@end

NS_ASSUME_NONNULL_END
