//
//  AppDelegate.h
//  FlickrDrop
//
//  Created by Oriol Ferrer Mesià on 15/06/13.
//  Copyright (c) 2013 Oriol Ferrer Mesià. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FlickrUploader.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>{

	FlickrUploader * 				flickr;
	NSMutableArray *				filesToUpload;

	IBOutlet NSProgressIndicator * progress;
	NSProgressIndicator * dockProgress;
	int numToUpload;
	NSDockTile	* dockTile;
}

@property (assign) IBOutlet NSWindow *window;


- (IBAction) confirmAuthorization:(id)sender;
- (IBAction) initiateAuthorization:(id)sender;


@end
