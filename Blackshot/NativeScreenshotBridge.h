#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, BSNativeSubmissionResult) {
    BSNativeSubmissionResultSubmitted,
    BSNativeSubmissionResultFailed,
    BSNativeSubmissionResultUncertain
};
// Submitted means flushed to XPC, not a native UI/save acknowledgement.
FOUNDATION_EXPORT void BSSubmitNativeScreenshot(NSData *png, CGRect rect, double scale,
    uint32_t displayID, BOOL windowCapture, BOOL hasShadow,
    void (^completion)(BSNativeSubmissionResult result));
NS_ASSUME_NONNULL_END
