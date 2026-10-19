// Experimental, undocumented screencaptureui protocol. No system patches or injection.
#import <AppKit/AppKit.h>
#import <CoreImage/CoreImage.h>
#import <xpc/xpc.h>

static xpc_connection_t connection;
static xpc_object_t captureRect(CGFloat width, CGFloat height) {
    xpc_object_t rect = xpc_array_create(NULL, 0);
    for (NSNumber *value in @[@0, @0, @(width), @(height)]) {
        xpc_array_append_value(rect, xpc_double_create(value.doubleValue));
    }
    return rect;
}

static NSData *demoImage(void) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL pixelsWide:640 pixelsHigh:360
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    for (int y = 0; y < 360; y++) {
        for (int x = 0; x < 640; x++) {
            [bitmap setColor:[NSColor colorWithCalibratedRed:x < 320 ? 0.05 : 0.9
                green:y < 180 ? 0.1 : 0.8 blue:0.25 alpha:1] atX:x y:y];
        }
    }
    return [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

static NSData *invert(NSData *data) {
    CIImage *input = [CIImage imageWithData:data];
    if (!input || CGRectIsEmpty(input.extent) || CGRectIsInfinite(input.extent)) return nil;
    CIImage *output = [input imageByApplyingFilter:@"CIColorInvert"];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef image = [context createCGImage:output fromRect:input.extent];
    if (!image) return nil;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
    CGImageRelease(image);
    return [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2 || (strcmp(argv[1], "--demo") && strcmp(argv[1], "--capture") &&
                         !(argc == 3 && !strcmp(argv[1], "--file")))) {
            fprintf(stderr, "Usage: native-screenshot-bridge --demo | --capture | --file IMAGE\n"
                "Hands inverted PNG to macOS screenshot UI; native save preferences apply.\n");
            return 2;
        }
        NSError *error = nil;
        NSData *input = nil;
        if (!strcmp(argv[1], "--demo")) {
            input = demoImage();
        } else if (!strcmp(argv[1], "--file")) {
            input = [NSData dataWithContentsOfFile:@(argv[2]) options:0 error:&error];
        } else {
            // Use a unique file, preserve the clipboard on normal capture/cancellation.
            NSURL *temporary = [NSURL fileURLWithPath:[NSTemporaryDirectory()
                stringByAppendingPathComponent:[NSString stringWithFormat:@"blackshot-%@.png", NSUUID.UUID.UUIDString]]];
            NSTask *task = [[NSTask alloc] init];
            task.executableURL = [NSURL fileURLWithPath:@"/usr/sbin/screencapture"];
            task.arguments = @[@"-i", @"-t", @"png", temporary.path];
            if (![task launchAndReturnError:&error]) {
                fprintf(stderr, "Capture launch failed: %s\n", error.localizedDescription.UTF8String);
                return 1;
            }
            [task waitUntilExit];
            input = [NSData dataWithContentsOfURL:temporary];
            [[NSFileManager defaultManager] removeItemAtURL:temporary error:nil];
            if (!input.length) {
                fprintf(stderr, "No capture file: cancelled, permission denied, or Control redirected to clipboard.\n");
                return 1;
            }
        }
        NSData *png = input ? invert(input) : nil;
        NSBitmapImageRep *bitmap = png ? [NSBitmapImageRep imageRepWithData:png] : nil;
        if (!bitmap) {
            fprintf(stderr, "Cannot load/invert image: %s\n", error ? error.localizedDescription.UTF8String : "invalid image");
            return 1;
        }
        // Keep a copy for comparison with the file saved by macOS.
        NSString *evidence = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"blackshot-inverted-%@.png", NSUUID.UUID.UUIDString]];
        if (![png writeToFile:evidence options:NSDataWritingAtomic error:&error]) {
            fprintf(stderr, "Cannot save evidence PNG: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }
        xpc_object_t image = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_data(image, "dta", png.bytes, png.length);
        xpc_dictionary_set_value(image, "frm", captureRect(bitmap.pixelsWide, bitmap.pixelsHigh));
        xpc_dictionary_set_double(image, "sca", 1);
        xpc_dictionary_set_uint64(image, "did", CGMainDisplayID());
        xpc_object_t images = xpc_array_create(NULL, 0);
        xpc_array_append_value(images, image);
        xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_uint64(message, "msg", 20);
        xpc_dictionary_set_value(message, "img", images);
        xpc_dictionary_set_bool(message, "shd", false);
        xpc_dictionary_set_string(message, "uti", "public.png");
        xpc_dictionary_set_string(message, "cpt", "selection");
        xpc_dictionary_set_bool(message, "tbr", false);
        xpc_dictionary_set_double(message, "tim", CFAbsoluteTimeGetCurrent());
        connection = xpc_connection_create_mach_service("com.apple.screencaptureui", dispatch_get_main_queue(), 0);
        xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
            if (xpc_get_type(event) == XPC_TYPE_ERROR) {
                fprintf(stderr, "Native service: %s\n", xpc_dictionary_get_string(event, XPC_ERROR_KEY_DESCRIPTION));
            }
        });
        xpc_connection_resume(connection);
        // The native receiver does not acknowledge this message. A sent message is not proof of success.
        xpc_connection_send_message(connection, message);
        fprintf(stderr, "Submitted %ld x %ld inverted PNG. Compare native output with:\n%s\n"
            "Waiting 30 seconds for native UI; submission is not a delivery acknowledgement.\n",
            (long)bitmap.pixelsWide, (long)bitmap.pixelsHigh, evidence.UTF8String);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ exit(0); });
        dispatch_main();
    }
}
