//
//  BathFlickrPhotoInfoDownload.h
//  Cocoa Test
//
//  Created by Oriol Ferrer Mesià on 05/11/09.
//  Copyright 2009 uri.cat. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>

@interface BathFlickrPhotoInfoDownload : NSObject {

	OFFlickrAPIContext *		context;
	NSArray*					IDList;
}


-(id) initWithFlickrContext:(OFFlickrAPIContext *) context_;
-(void)downloadInfoForList:(NSArray*) IDList;

@end
