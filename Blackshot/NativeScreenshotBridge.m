#import "NativeScreenshotBridge.h"
#import <xpc/xpc.h>

@interface BSSubmission : NSObject
@property(nonatomic, strong) xpc_connection_t connection;
@property(nonatomic, copy) void (^completion)(BSNativeSubmissionResult);
@property(nonatomic) BOOL completed;
- (void)finish:(BSNativeSubmissionResult)result;
@end
@implementation BSSubmission
- (void)finish:(BSNativeSubmissionResult)result {
    if (self.completed) return;
    self.completed = YES;
    if (self.completion) self.completion(result);
    self.completion = nil;
}
@end

void BSSubmitNativeScreenshot(NSData *png, CGRect rect, double scale,
    uint32_t displayID, BOOL windowCapture, BOOL hasShadow,
    void (^completion)(BSNativeSubmissionResult)) {
    NSCAssert([NSThread isMainThread], @"Submit native screenshots on the main thread");
    if (!png.length || CGRectIsEmpty(rect) || !isfinite(scale) || scale <= 0 || !displayID) {
        completion(BSNativeSubmissionResultFailed);
        return;
    }
    // Undocumented protocol, verified on macOS 27.2 (26B5112a).
    // Keep all wire keys and types here. Never retry a possibly delivered message.
    xpc_object_t frame = xpc_array_create(NULL, 0);
    double components[] = {rect.origin.x, rect.origin.y, rect.size.width, rect.size.height};
    for (int i = 0; i < 4; i++) xpc_array_append_value(frame, xpc_double_create(components[i]));
    xpc_object_t image = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_data(image, "dta", png.bytes, png.length);
    xpc_dictionary_set_value(image, "frm", frame);
    xpc_dictionary_set_double(image, "sca", scale);
    xpc_dictionary_set_uint64(image, "did", displayID);
    xpc_object_t images = xpc_array_create(NULL, 0);
    xpc_array_append_value(images, image);
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(message, "msg", 20);
    xpc_dictionary_set_value(message, "img", images);
    xpc_dictionary_set_bool(message, "shd", hasShadow);
    xpc_dictionary_set_string(message, "uti", "public.png");
    xpc_dictionary_set_string(message, "cpt", windowCapture ? "window" : "selection");
    xpc_dictionary_set_bool(message, "tbr", false);
    xpc_dictionary_set_double(message, "tim", CFAbsoluteTimeGetCurrent());

    BSSubmission *submission = [BSSubmission new];
    submission.completion = completion;
    submission.connection = xpc_connection_create_mach_service("com.apple.screencaptureui", dispatch_get_main_queue(), 0);
    __weak BSSubmission *weakSubmission = submission;
    xpc_connection_set_event_handler(submission.connection, ^(xpc_object_t event) {
        BSSubmission *current = weakSubmission;
        if (!current || xpc_get_type(event) != XPC_TYPE_ERROR) return;
        // Interruption also occurs after successful native presentation. It is ambiguous.
        [current finish:event == XPC_ERROR_CONNECTION_INVALID ? BSNativeSubmissionResultFailed : BSNativeSubmissionResultUncertain];
    });
    xpc_connection_resume(submission.connection);
    xpc_connection_send_message(submission.connection, message);
    xpc_connection_send_barrier(submission.connection, ^{
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSubmission finish:BSNativeSubmissionResultSubmitted]; });
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [submission finish:BSNativeSubmissionResultUncertain];
    });
    // Native UI owns its image and temporary files after receipt; keep transport alive briefly.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        xpc_connection_cancel(submission.connection);
        submission.connection = nil;
    });
}
