//
//  BatchDownloader.m
//  Cocoa Test
//
//  Created by Oriol Ferrer Mesià on 13/10/09.
//  Copyright 2009 uri.cat. All rights reserved.
//

#import "BatchDownloader.h"


@implementation BatchDownloader


-(id)initWithDirectoryName:(NSString*) dirName{
	downloading = false;
	urlList = [[NSMutableArray alloc] initWithCapacity:500];
	path = [[NSString stringWithFormat: dirName, [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]] retain]; 
	[[NSFileManager defaultManager] createDirectoryAtPath: path attributes: nil];
	return self;
}


-(NSString*)downloadPath{
	return path;
}


-(void)addURLArray:(NSArray*) array{

	[urlList addObjectsFromArray: array];
	
}


-(void)startDownloading{
	if (downloading == false){
		[NSThread detachNewThreadSelector: @selector(downloadImagesThread) toTarget:self withObject:nil];
	}else{
		NSLog(@"Cant startDownloadng, download is already happening");
	}
}


-(void)downloadImagesThread{

	downloading = true;
	NSAutoreleasePool * p = [[NSAutoreleasePool alloc] init];
	NSLog(@"start downloadImagesThread");

	for (NSString* urlString in urlList){

		NSLog(@"%@", [urlString lastPathComponent]);
		//NSImage* img = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: urlString]];
		
		NSAutoreleasePool * p2 = [[NSAutoreleasePool alloc] init];
		
		BOOL fileIsThere = [[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithFormat:@"%@/%@", path, [urlString lastPathComponent]]];

		if (!fileIsThere){

			NSData * data = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlString]];
			[data writeToFile:[NSString stringWithFormat:@"%@/%@", path, [urlString lastPathComponent]] atomically: YES];
			
			NSLog(@"wrote %@", [urlString lastPathComponent]);
		}
		
		[p2 release];
	}
	
	NSLog(@"end downloadImagesThread");
	[p release];
	downloading = false;
}


@end
