Native Javascript Bridge
----
It's an bridge for comunicating between native and javascript in WebView.
Now for IOS only.

##Usage

###On Javascript

	//Native will fire NJBridge Ready event, so you have to listen

	function connectNJBridge(callback) {
	    if (window.NJBridge) {
	        callback(NJBridge)
	    } else {
	        document.addEventListener('NJBridgeReady', function() {
	            callback(NJBridge)
	        }, false)
	    }
	}

	//Then you can communicate with the native
	//For example

	connectNJBridge(function(){
		//Tell native with event name 'photo'
		bridge.invoke('photo',function(responseData){
			log('photo callback',responseData);
		});

		//When receive native event 'display'
		bridge.on('display',function(responseData){
			console.info('receive Display Message', responseData);
	    });

	    //Of course you can bind many handlers with same event name
	    bridge.on('display',function(responseData){
			alert('receive Display Message');
	    });
	});


###On Native
	

	
	#import "NJBridge.h"

	//First you have to bridge the webview
	NJBridge* bridge = [NJBridge bridge:self.mainWebView delegate:self];
	
	//If heard photo
	[bridge registerHandler:@"photo" handler:^(id data,NJResponseCallback callback){
		//bala bala
		id data = "i see";
		callback(data);//callback can be async.

		//or you can invoke some events globally
		[bridge invoke:@"display" data:data];
	}];

	//Warning: event may not be fired if the webview is not ready.
	[bridge invoke:@"display"];
	

