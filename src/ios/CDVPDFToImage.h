#import <Cordova/CDVPlugin.h>

@interface CDVPDFToImage : CDVPlugin

- (void) getPageCount:(CDVInvokedUrlCommand*)command;
- (void) convertToImage:(CDVInvokedUrlCommand*)command;

@end