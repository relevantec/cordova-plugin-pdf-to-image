#import "CDVPDFToImage.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "PDFView.h"
#import "UIImage+PDF.h"

static NSString* const kPNGExtension = @"png";
static NSString* const kJPEGExtension = @"jpg";

static NSString* const kPNGMediatype = @"image/png";
static NSString* const kJPEGMediatype = @"image/jpeg";

static NSString* const kBase64 = @"base64";  

@implementation CDVPDFToImage

- (void) getPageCount:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{

        NSString* target = (NSString*)[command argumentAtIndex:0];

        NSURL* url = [NSURL URLWithString:target];
        CDVPluginResult* pluginResult = nil;

        if (!url) {
            NSString* errorMessage = @"Argument is invalid";
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        } else {
            NSUInteger pageCount = [PDFView pageCountForURL:url];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:(int)pageCount];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (NSString*) base64EncodedString:(NSData*)data
{  
    NSString* base64String;

    if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        // iOS7 or later
        base64String = [data base64EncodedStringWithOptions:kNilOptions];
    } else {
        base64String = [data base64Encoding];
    }

    return base64String;
}

- (void) convertToImage:(CDVInvokedUrlCommand*)command
{
    NSString* source = (NSString*)[command argumentAtIndex:0];
    NSString* target = (NSString*)[command argumentAtIndex:1];
    NSNumber* shouldUseJpeg = (NSNumber*)[command argumentAtIndex:2];
    NSNumber* minWidth = (NSNumber*)[command argumentAtIndex:4];
    NSNumber* maxWidth = (NSNumber*)[command argumentAtIndex:5];

    [self.commandDelegate runInBackground:^{
        NSArray* pageNumbers = (NSArray*)[command argumentAtIndex:3];
        NSURL* sourceURL = [NSURL URLWithString:source];
        NSURL* targetURL = [NSURL URLWithString:target];
        
        // Total Page
        int pageCount = (int)[PDFView pageCountForURL:sourceURL];

        if (!pageNumbers.count) {
            NSMutableArray* array = @[].mutableCopy;

            for (int i = 0; i < pageCount; i++) {
                [array addObject: @(i + 1)];
            }

            pageNumbers = array;
        }

        NSString* errorMessage = nil;
        NSString* fileNameBase = [[source lastPathComponent] stringByDeletingPathExtension];
        NSMutableArray* resultStrings = @[].mutableCopy;
        NSString* extension = nil;
        NSString* mediatype = nil;
        NSString* dataURLPrefix = nil;

        NSError* error = nil;

        // JPEG
        if (shouldUseJpeg) {
            extension = kJPEGExtension;
            mediatype = kJPEGMediatype;
        } else {
            extension = kPNGExtension;
            mediatype = kPNGMediatype;
        }

        if (target) {
            // Create a directory
            BOOL isCreated = [[NSFileManager defaultManager] createDirectoryAtPath:targetURL.path withIntermediateDirectories:YES attributes:nil error:&error];
            // Error has occurred
            if (!isCreated) {	
                errorMessage = error.userInfo.description;
                NSLog(@"%@ %d %@", error.domain, error.code, error.userInfo.description);
            }
        } else {
            dataURLPrefix = [NSString stringWithFormat:@"data:%@;%@,", mediatype, kBase64];
        }
        
        if (!errorMessage) {
            for (int i = 0; i < pageNumbers.count; i++) {
                int pageNumber = [(NSNumber*)pageNumbers[i] intValue];
                // Invalid page
                if (pageNumber <= 0 || pageCount < pageNumber) {
                    errorMessage = [NSString stringWithFormat:@"Page Number Error: error page number %d, max page number %d", pageNumber, pageCount];
                    NSLog(@"%@", errorMessage);
                    break;
                }
                
                @autoreleasepool {
                    // Get the image of the relevant page
                    UIImage* image = [UIImage originalSizeImageWithPDFURL:sourceURL atPage:pageNumber minWidth: minWidth maxWidth: maxWidth];
                    NSData* imageData = nil;
                    NSString* resultString = nil;

                    // JPEG
                    if (shouldUseJpeg) {
                        imageData = UIImageJPEGRepresentation(image, 0.9);
                    } else {
                        imageData = UIImagePNGRepresentation(image);
                    }

                    // To save the file
                    if (target) {
                        // file name
                        NSString* fileName = [[fileNameBase stringByAppendingFormat:@".%d", pageNumber] stringByAppendingPathExtension:extension];
                        NSString* filePath = [target stringByAppendingPathComponent:fileName];
                        NSURL* fileURL = [NSURL URLWithString:filePath];
                        // Write to the file
                        BOOL isSaved = [imageData writeToFile:fileURL.path options:NSDataWritingAtomic error:&error];
                        // Error has occurred
                        if (!isSaved) {
                            errorMessage = error.userInfo.description;
                            NSLog(@"%@ %d %@", error.domain, error.code, error.userInfo.description);
                            break;
                        }
                        resultString = filePath;
                        
                    } else {
                        // data URL scheme
                        // NSData -> Base64
                        NSString* base64String = [self base64EncodedString:imageData];
                        resultString = [dataURLPrefix stringByAppendingString:base64String];
                    }

                    [resultStrings addObject:resultString]; 
                }
            }
        }

        CDVPluginResult* pluginResult = nil;

        // No Error
        if (!errorMessage) {		
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
        } else {		
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

@end
