//
//  BatchDownloader.h
//  Cocoa Test
//
//  Created by Oriol Ferrer Mesià on 13/10/09.
//  Copyright 2009 uri.cat. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BatchDownloader : NSObject {

	NSMutableArray * urlList;
	BOOL downloading;
	NSString * path;
}

@end
