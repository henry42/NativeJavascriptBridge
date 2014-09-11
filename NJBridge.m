//
//  NJBridge.m
//  WebView
//
//  Created by Henry on 14-8-26.
//  Copyright (c) 2014 Henry. All rights reserved.
//

#import "NJBridge.h"

@implementation NJBridge

__weak NJB_WEBVIEW_TYPE * _webView;

NSUInteger _requestingNumber;
NSMutableDictionary* _messageHandlers;

-(id) init{
    id result = [super init];
    
    _messageHandlers = [NSMutableDictionary dictionary];
    
    return result;
}

-(void) registerHandler:(NSString *)name handler:(NJHandler) handler
{
    [_messageHandlers setObject:[handler copy] forKey:name];
}

-(NSString*) _packData:(id)data
{
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    message[@"data"] = data;
    NSString *messageJson = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
    return messageJson;
}


-(void) _invokeEvent:(NSString *)name data:(id)data type:(NSString*) type
{
    
    NSString *messageJson = [self _packData:data];
    
    NSString* command = [NSString stringWithFormat:@"NJBridge.%@('%@',%@);",type,name, messageJson];
    if ([[NSThread currentThread] isMainThread]) {
        [_webView stringByEvaluatingJavaScriptFromString:command];
    } else {
        NJB_WEBVIEW_TYPE* strongWebView = _webView;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [strongWebView stringByEvaluatingJavaScriptFromString:command];
        });
    }
}

-(void) invoke:(NSString *)name data:(id)data
{
    [self _invokeEvent:name data:data type:@"_dispatchNativeEvent"];
}

-(void) _invokeCallback:(NSString *)callbackId data:(id)data
{
    [self _invokeEvent:callbackId data:data type:@"_dispatchCallbackEvent"];
}

-(void)setup:(NJB_WEBVIEW_TYPE*) webView
{
    _webView = webView;
    [webView setDelegate:self];
    [self reset];
}
+(instancetype) bridge:(NJB_WEBVIEW_TYPE*)webView
{
    NJBridge* bridge = [[NJBridge alloc] init];
    [bridge setup:webView];
    return bridge;
}
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    _requestingNumber++;
}
-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    
    _requestingNumber--;
    
    if (_requestingNumber == 0 && ![[webView stringByEvaluatingJavaScriptFromString:@"typeof NJBridge == 'object'"] isEqualToString:@"true"]) {
        
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *filePath = [bundle pathForResource:@"NJBridge.js" ofType:@"txt"];
        NSString *js = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        [webView stringByEvaluatingJavaScriptFromString:js];
    }
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView != _webView) { return YES; }
    NSURL *url = [request URL];

    if ([[url scheme] isEqualToString:customProtocolScheme]) {
        if ([[url host] isEqualToString:messageInAir]) {
            [self _processBridgeMessages];
        }
        return NO;
    }
    return YES;
}

- (void)_processBridgeMessages {
    
    NSString *messagesJson = [_webView stringByEvaluatingJavaScriptFromString:@"NJBridge._popAllMessage();"];
    
    id messages = [NSJSONSerialization JSONObjectWithData:[messagesJson dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    
    if (![messages isKindOfClass:[NSArray class]]) {
        return;
    }
    for (NSDictionary* message in messages) {
        if (![message isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSString* name = message[@"name"];
        NSString* callbackId = message[@"id"];
        
        if( _messageHandlers[name]){
            @try {
                NJHandler handler = ((NJHandler)[_messageHandlers objectForKey:name]);
                handler(message,^(id data){
                    [self _invokeCallback:callbackId data:data];
                });
            }
            @catch (NSException *exception) {
                NSLog(@"NJBridge: WARNING: OC Exception. %@ %@", message, exception);
            }
        }
    }
}

-(void)reset
{
    [_messageHandlers removeAllObjects];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

-(void)dealloc
{
    if( _webView )
    {
        [_webView setDelegate:nil];
        _webView = nil;
    }
    
    [_messageHandlers removeAllObjects];
    
    _messageHandlers = nil;
    
}
@end
