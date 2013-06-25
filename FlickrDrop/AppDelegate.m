//
//  AppDelegate.m
//  FlickrDrop
//
//  Created by Oriol Ferrer Mesià on 15/06/13.
//  Copyright (c) 2013 Oriol Ferrer Mesià. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)dealloc{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	// Insert code here to initialize your application
	NSLog(@"applicationDidFinishLaunching");

	[progress setUsesThreadedAnimation:YES];
	[progress startAnimation:self];
	[progress setIndeterminate:NO];
	[progress setNeedsDisplay:YES];
	[progress display];
	[self.window setLevel:NSScreenSaverWindowLevel];

	dockTile = [[NSApplication sharedApplication] dockTile];
    NSImageView *iv = [[NSImageView alloc] init];
    [iv setImage:[[NSApplication sharedApplication] applicationIconImage]];
    [dockTile setContentView:iv];
	[dockTile setShowsApplicationBadge:YES];

	dockProgress = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, dockTile.size.width, 20)];
    [dockProgress setStyle:NSProgressIndicatorBarStyle];
	[dockProgress setUsesThreadedAnimation:YES];
	[dockProgress setIndeterminate:NO];
	[dockProgress startAnimation:self];
	[dockProgress setMinValue:0];
	[dockProgress setBezeled:YES];
    [dockProgress setMaxValue:1];
	[dockProgress setNeedsDisplay:YES];
	[dockProgress setHidden:NO];
	[iv addSubview:dockProgress];


	flickr = [[FlickrUploader alloc] initWithDelegate:self];
	if ([flickr isReady]){

		if (filesToUpload != nil){
			//[NSThread detachNewThreadSelector:@selector(startUploads) toTarget:self withObject:nil];
			[self performSelector:@selector(startUploads) withObject:nil afterDelay:0.1];
		}
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename{

	if (filesToUpload==nil){
		filesToUpload = [[NSMutableArray alloc] initWithCapacity:5];
	}
	NSLog(@"application openFile: %@", filename);
	[filesToUpload addObject:filename];
}


int uploadedSoFar = 0;

-(void)startUploads{


	uploadedSoFar = 0;
	numToUpload = [filesToUpload count];
	NSLog(@"startUploads");

	NSString *tags = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/FlickrTags.txt", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]]];
	NSString *desc = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/FlickrDescription.txt", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]]];
	NSString *desc2 = [NSString stringWithFormat:@"%@\n\nUploaded With <a href='https://github.com/armadillu/FlickrDrop'>FlickrDrop</a>", desc];
	NSArray * tagArray = [tags componentsSeparatedByString:@","];
	for(NSString * file in filesToUpload){
		[flickr uploadImageAt:file withDescription:desc2 title:[file lastPathComponent] tags:tagArray];
	}
	[filesToUpload removeAllObjects];
}

//delegation method from flickr
-(void)didUploadPhoto{
	//uploadedSoFar++;
	//[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:(float)(uploadedSoFar)/(numToUpload)] waitUntilDone: YES];
	NSLog(@"didUploadPhoto! so far %d", uploadedSoFar);
}

-(void)didPutPhotoInSet{
	uploadedSoFar++;
	[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:(float)(uploadedSoFar)/(numToUpload)] waitUntilDone: YES];
	NSLog(@"didPutPhotoInSet! so far %d", uploadedSoFar);

	if (uploadedSoFar == numToUpload){
		NSLog(@"All Done! bye bye!");
		NSString * url = [NSString stringWithContentsOfFile: [NSString stringWithFormat:@"%@/PhotoStreamURL.txt", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]]];
		NSLog(@"opening URL %@", url);
		[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url] ];
		[[NSApplication sharedApplication] performSelector:@selector(terminate:) withObject:self afterDelay:1.0];
	}
}


-(void)updateProgress:(NSNumber*)percent{
	NSLog(@"updateProgress: %f", [percent floatValue] );
	[progress setDoubleValue:[percent floatValue]];
	[dockProgress setDoubleValue:[percent floatValue]];
	[dockTile display];
}


- (IBAction) initiateAuthorization:(id)sender{
	[flickr initiateAuthorization];
}


- (IBAction) confirmAuthorization:(id)sender{
	[flickr confirmAuthorization];
}

@end
