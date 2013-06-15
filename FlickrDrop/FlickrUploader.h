//
//  FlickrUploader.h
//  Cocoa Test
//
//  Created by Oriol Ferrer Mesià on 12/10/09.
//  Copyright 2009 uri.cat. All rights reserved.
//


// armadillu
// 98c7762487de6c70e5e2760a6b6b89ba
// dd2d15086af00435
// experiments set  38803936@N00


#import <Cocoa/Cocoa.h>
#import <ObjectiveFlickr/ObjectiveFlickr.h>
#import "BathFlickrPhotoInfoDownload.h"
#import "BatchDownloader.h"

@interface FlickrUploader : NSObject <OFFlickrAPIRequestDelegate>{

	NSString *					flickrTokenPath;
	NSString *					flickrKeysPath;
	NSString *					flickrSetPath;
	
	OFFlickrAPIContext *		context;
	
	OFFlickrAPIRequest *		frobRequest;
	NSDictionary *				frobResponse;
	
	OFFlickrAPIRequest *		tokenRequest;
	NSDictionary *				tokenResponse;
	
	NSDictionary *				flickrKeys;


	id							delegate;
	//nib
	
	//flickr
	IBOutlet NSTextField *		API_key;
	IBOutlet NSTextField *		API_shared_secret;
	IBOutlet NSTextField *		flickr_GeneralSet_ID;
	

	//windows
	IBOutlet NSPanel *			keysWindow;
	IBOutlet NSPanel *			authWindow;
	
	IBOutlet NSProgressIndicator * progress;
	
	IBOutlet NSButton *			confirmButton;
	
}

- (id)initWithDelegate:(id)del;
- (IBAction)confirmKeys:(id)sender;

- (IBAction)requestAuthorization:(id)sender;
- (IBAction)confirmAuthorization:(id)sender;

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes;

- (void) initiateAuthorization;
- (void) webLoginWithFrob;
- (void) confirmAuthorization;


- (void) uploadImageAt:(NSString*)imagePath withDescription:(NSString*)desc title:(NSString*)title tags:(NSArray*)tags ;
- (void) addPhoto:(NSString*) photo_id toGropPool:(NSString*) group_id;
- (void) fetch:(int) numPhotos PhotosFromGroup:(NSString*) groupID ;
- (void) fetch:(int) numPhotos PhotosFromSet:(NSString*) photoset_id ;
- (void) addGeoLocationForPhoto:(NSString*) photo_id latitude:(NSString*) lat longitude:(NSString*) lon;
- (void) getInfoForPhoto:(NSString*) photo_id ;

@end

