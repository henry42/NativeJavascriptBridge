//
//  NJBridge.h
//  WebView
//
//  Created by Henry on 14-8-26.
//  Copyright (c) 2014 Henry. All rights reserved.
//

#import <Foundation/Foundation.h>


#define customProtocolScheme @"njscheme"
#define messageInAir @"MessageOnAir"

#define NJB_PLATFORM_IOS
#define NJB_WEBVIEW_TYPE UIWebView
#define NJB_WEBVIEW_DELEGATE_TYPE NSObject<UIWebViewDelegate>

typedef void (^NJResponseCallback)(id responseData);
typedef void (^NJHandler)(id data, NJResponseCallback responseCallback);

@interface NJBridge : NJB_WEBVIEW_DELEGATE_TYPE
+(instancetype)bridge:(NJB_WEBVIEW_TYPE*)webView;
-(void)invoke:(NSString*)name data:(id)data;
-(void)registerHandler:(NSString*)name handler:(NJHandler)handler;
-(void)setup:(NJB_WEBVIEW_TYPE*)webView;
-(void)reset;
@end
