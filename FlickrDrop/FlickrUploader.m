//
//  FlickrUploader.m
//  Cocoa Test
//
//  Created by Oriol Ferrer Mesià on 12/10/09.
//  Copyright 2009 uri.cat. All rights reserved.
//

#import "FlickrUploader.h"
#import "constants.h"


@implementation FlickrUploader

-(id)initWithDelegate:(id)del{

	delegate = del;
	
	flickrKeysPath = [[NSString stringWithFormat:@"%@/FlickrKeys.plist", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]] retain]; 
	flickrTokenPath = [[NSString stringWithFormat:@"%@/FlickrToken.plist", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]] retain];
	flickrSetPath = [[NSString stringWithFormat:@"%@/FlickrSet.txt", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]] retain];

	tokenResponse = [NSDictionary dictionaryWithContentsOfFile: flickrTokenPath];
	if (tokenResponse) [tokenResponse retain];
		
	flickrKeys = [NSDictionary dictionaryWithContentsOfFile: flickrKeysPath];
	if (flickrKeys) [flickrKeys retain];
	
	[NSBundle loadNibNamed:@"Flickr" owner:self];
		
	if ( flickrKeys == nil){
		NSBeep();
		[keysWindow center];
		[keysWindow makeKeyAndOrderFront: self];
		[keysWindow setLevel: NSScreenSaverWindowLevel];
	}else{
		[self dealWithAuthorization];
	}
	return self;
}

-(BOOL) isReady{

	return (flickrKeys != nil);
}


- (void) dealWithAuthorization{

	context = [[OFFlickrAPIContext alloc] initWithAPIKey:[self apiKey] sharedSecret: [self sharedSecret]];

	if (tokenResponse == nil){
		NSLog(@"FlickrUploader: No tokenResponse available, YOU NEED TO AUTHORIZE!");
		NSBeep();
		[authWindow center];
		[authWindow makeKeyAndOrderFront: self];
		[authWindow setLevel: NSScreenSaverWindowLevel];
		
	}else{
		[context setAuthToken: [self token]];
		NSLog(@"FlickrUploader: tokenResponse available, NO NEED TO AUTHORIZE! %@", tokenResponse);
	}
}


- (IBAction)confirmKeys:(id)sender{

	[keysWindow close];
	[self storeKeysWindowValues];
	[self dealWithAuthorization];
}



#pragma mark Flickr API Requests

- (IBAction)requestAuthorization:(id)sender;{

	NSLog(@"FlickrUploader: initiateAuthorization");
	frobRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[frobRequest setDelegate:self];
	[frobRequest callAPIMethodWithGET:@"flickr.auth.getFrob" arguments:nil];
	[confirmButton setEnabled:YES];
}


- (void) webLoginWithFrob{

	NSLog(@"FlickrUploader: webLoginWithFrob");
	NSURL * url = [context loginURLFromFrobDictionary:frobResponse requestedPermission:OFFlickrWritePermission];
	NSLog(@"authorize: %@", url);
	[[NSWorkspace sharedWorkspace] openURL: url];
}


- (IBAction)confirmAuthorization:(id)sender{

	NSLog(@"FlickrUploader: confirmAuthorization");
	[progress startAnimation:self];
	tokenRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[tokenRequest setDelegate:self];
	
	NSDictionary * arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
										[[frobResponse objectForKey:@"frob"] objectForKey:@"_text"],	@"frob", 
	 									[self apiKey], 													@"api_key",
										nil];

	NSLog(@"FlickrUploader: confirmAuthorization args: %@", arguments);
	[tokenRequest callAPIMethodWithGET: @"flickr.auth.getToken" arguments: arguments ];
}



-(void) uploadImageAt:(NSString*)imagePath withDescription:(NSString*)desc title:(NSString*)title tags:(NSArray*)tags {
	
	NSLog(@"FlickrUploader: uploadImage");
	OFFlickrAPIRequest *request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	
	NSInputStream *imageStream = [NSInputStream inputStreamWithData: [NSData dataWithContentsOfFile:imagePath]];
	NSString * tagsSpaceSeparated = @"";
	
	for (id tag in tags){
		tagsSpaceSeparated = [tagsSpaceSeparated stringByAppendingString: [NSString stringWithFormat:@"\"%@\" ", tag] ];
	}

	NSString * mime;
	if ([[imagePath lowercaseString] hasSuffix:@"jpg"] || [[imagePath lowercaseString] hasSuffix:@"jpeg"] ) {
		mime = @"image/jpeg";
	}
	if ([[imagePath lowercaseString] hasSuffix:@"png"] ) {
		mime = @"image/png";
	}
	if ([[imagePath lowercaseString] hasSuffix:@"gif"] ) {
		mime = @"image/gif";
	}


    [request uploadImageStream: imageStream
			 suggestedFilename: title
					  MIMEType: mime
					 arguments: [NSDictionary dictionaryWithObjectsAndKeys:
								 	@"1", @"is_public", 
								 	desc, @"description",
								   	tagsSpaceSeparated, @"tags",
								 	nil]
	];
	NSLog(@"upload request issued");
}


- (void) addPhoto:(NSString*) photo_id toGropPool:(NSString*) group_id{

	NSLog(@"FlickrUploader: addPhoto Photo %@ to Group Pool %@", photo_id, group_id );
	NSDictionary * arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
									[self apiKey],			@"api_key",
									photo_id, 				@"photo_id",
									group_id, 				@"group_id",
									nil];

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	[request callAPIMethodWithGET:@"flickr.groups.pools.add" arguments: arguments];
}



- (void) addPhoto:(NSString*) photo_id toSet:(NSString*) photoset_id{

	NSLog(@"FlickrUploader: addPhoto Photo %@ to toSet %@", photo_id, photoset_id );
	NSDictionary * arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
									[self apiKey],			@"api_key",
									photo_id, 				@"photo_id",
									photoset_id, 			@"photoset_id",
									nil];

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	[request callAPIMethodWithGET:@"flickr.photosets.addPhoto" arguments: arguments];
}


- (void) getInfoForPhoto:(NSString*) photo_id {

	NSLog(@"FlickrUploader: getInfoForPhoto %@", photo_id );
	NSDictionary * arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
									[self apiKey],			@"api_key",
									photo_id, 				@"photo_id",
									nil];

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	[request callAPIMethodWithGET:@"flickr.photos.getInfo" arguments: arguments];
}



- (void) addGeoLocationForPhoto:(NSString*) photo_id latitude:(NSString*) lat longitude:(NSString*) lon{

	NSLog(@"FlickrUploader: addGeoLocationForPhoto Photo %@ latitude: %@ longitude: %@", photo_id, lat, lon );
	NSDictionary * arguments = [NSDictionary dictionaryWithObjectsAndKeys: 
									[self apiKey],			@"api_key",
									photo_id, 				@"photo_id",
									lat, 					@"lat",
									lon,					@"lon",
									nil];

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	[request callAPIMethodWithPOST:@"flickr.photos.geo.setLocation" arguments: arguments];
}



- (void) fetch:(int) numPhotos PhotosFromGroup:(NSString*) groupID {

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	
	int n = numPhotos;
	if (n > 500)
		n = 500;
	NSDictionary * arg = [NSDictionary dictionaryWithObjectsAndKeys:
												[self apiKey],									@"api_key",
												groupID,										@"group_id",
												[NSString stringWithFormat:@"%d", n], 			@"per_page",
						  						@"url_l, url_o, url_m",										@"extras",
												//page ?
												nil
						];
	
	[request callAPIMethodWithGET:@"flickr.groups.pools.getPhotos" arguments: arg];
}


- (void) fetch:(int) numPhotos PhotosFromSet:(NSString*) photoset_id {

	OFFlickrAPIRequest * request = [[OFFlickrAPIRequest alloc] initWithAPIContext:context];
	[request setDelegate:self];
	
	int n = numPhotos;
	if (n > 500)
		n = 500;
	NSDictionary * arg = [NSDictionary dictionaryWithObjectsAndKeys:
												[self apiKey],									@"api_key",
												photoset_id,									@"photoset_id",
												[NSString stringWithFormat:@"%d", n], 			@"per_page",
						  						@"url_l, url_o, url_m",							@"extras",
												//page ?
												nil
						];
	
	[request callAPIMethodWithGET:@"flickr.photosets.getPhotos" arguments: arg];
}


#pragma mark OFFlickrAPIRequest delegate methods

//order is important here, see how we return early inside each "if".
//last "if" is very generic, first ones are more restrictive
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary{

	NSLog(@"FlickrUploader:  ## didCompleteWithResponse: %@", inResponseDictionary);

	if (inRequest == frobRequest){	//reply to "initiateAuthorization"
		NSLog(@"FlickrUploader:   -frobRequest succeed");
		frobResponse = [inResponseDictionary retain];
		[self webLoginWithFrob];
		return;
	}

	if (inRequest == tokenRequest){	//reply to "confirmAuthorization"
		NSLog(@"FlickrUploader:   -tokenRequest succeed");
		tokenResponse = [inResponseDictionary retain];
		[self storeFlickrToken];
		[context setAuthToken: [self token]];
		[progress stopAnimation:self];
		[authWindow close];
		NSRunAlertPanel(@"Authorization Success", @"Sucessfully authorized this flickr account" , @"OK", nil, nil);
		return;
	}

	if ( [inResponseDictionary objectForKey:@"photos"] || [inResponseDictionary objectForKey:@"photoset"]){	//most likely is the success of a "fetchRandomPhotosFromGroup" || fetchRandomPhotosFromSet
		
		NSDictionary * d = [inResponseDictionary objectForKey:@"photos"];
		if (d== nil)
			d = [inResponseDictionary objectForKey:@"photoset"];
		
		for (NSDictionary* photo in [d objectForKey:@"photo"]){	//NSArray with photo objects, "url_o" holds URL of file

			NSMutableDictionary * photoInfo = [NSMutableDictionary dictionaryWithCapacity:3];

			NSString* info = [photo objectForKey:@"title"];
			NSArray * infoSplit = [info componentsSeparatedByString:@" - "];
			NSString * storeName;
			NSString * date;
			
			if (infoSplit){
				if( [infoSplit count] >= 1 ){
					storeName = [infoSplit objectAtIndex:0];
				}
				if( [infoSplit count] >= 2 ){
					date = [infoSplit objectAtIndex:1];			
				}
			}
					
			NSString* url = [photo objectForKey:@"url_o"];
			
			if (url == nil)
				url = [photo objectForKey:@"url_l"];
			
			if (url == nil)
				url = [photo objectForKey:@"url_m"];

			if (storeName)
				[photoInfo setObject: storeName forKey: @"storeName"];
			if (date)
				[photoInfo setObject: date forKey: @"date"];
			
			NSString * path = [NSString stringWithFormat:@"%@/%@/%@.plist", [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent], GROUP_PHOTOS_DIR_NAME, [url lastPathComponent] ]; 
			[photoInfo writeToFile: path atomically:YES];
		}
		return;
	}

	
	if ( [inResponseDictionary objectForKey:@"photoid"]){	//most likely is the success of a "photo upload"
		NSString* photoID = [[inResponseDictionary objectForKey:@"photoid"] objectForKey: @"_text"];
		NSLog(@"FlickrUploader: Photo uploaded ok (?) : %@", photoID );
		//[self addPhoto: photoID toGropPool: [self  groupID]];
		[delegate didUploadPhoto];
		[self addPhoto: photoID toSet: [self flickrSet]];
		//[self addGeoLocationForPhoto: photoID latitude: [meta objectForKey:@"storeLatitude"] longitude: [meta objectForKey:@"storeLongitude"]];
		return;
	}
	
	if ( [inResponseDictionary objectForKey:@"stat"] ){	//most likely is the success of a "addPhotoToGroup"
		NSLog(@"FlickrUploader: Photo Added To Set/Group OK (?)");
		[delegate didPutPhotoInSet];
		return;
	}
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError{
	
	NSString * err = [NSString stringWithFormat: @"FlickrUploader:  ## didFailWithError: %@", inError];
	NSLog( err );
	
	NSRunAlertPanel(@"Flickr API Request Failed", err , @"OK", nil, nil);

	if (inRequest == frobRequest){
		NSLog(@"FlickrUploader:    -frobRequest fail");		
	}

	if (inRequest == tokenRequest){
		NSLog(@"FlickrUploader:    -tokenRequest fail");		
	}
}


- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes{
	NSLog(@"FlickrUploader:  imageUploadSentBytes: %d/%d (%0.1f)", (int)inSentBytes, (int)inTotalBytes, 100.0*inSentBytes/(float)inTotalBytes );
}


#pragma mark Small Widgets

-(void) storeKeysWindowValues{

	NSDictionary * d = [NSDictionary dictionaryWithObjectsAndKeys: 
								[API_key stringValue], @"API_key",
								[API_shared_secret stringValue], @"API_shared_secret",
								nil
						];
	
	[d writeToFile: flickrKeysPath atomically: YES];
	[[flickr_GeneralSet_ID stringValue] writeToFile: flickrSetPath atomically:YES];
}


-(void) storeFlickrToken{

	if (tokenResponse == nil){
		NSLog(@"Trying to storeFlickrToken when we dont really have it");
		return;
	}
	
	NSDictionary * d = [NSDictionary dictionaryWithObjectsAndKeys: 
								[self keyFromTokenResponseMemory], 			@"token",
								[self usernameFromTokenResponseMemory] , 	@"username",
								nil
						];
	[d writeToFile: flickrTokenPath atomically: YES];
}


//read from file	///////////////////////////////////////////////////////



-(NSString*) flickrSet{
   return [NSString stringWithContentsOfFile:flickrSetPath];
}


-(NSString*) apiKey{
	NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: flickrKeysPath];
	if (d == nil)
		return nil;
	return [d objectForKey:@"API_key"];
}

-(NSString*)token{
	NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: flickrTokenPath];
	if (d == nil)
		return nil;
	return [d objectForKey:@"token"];
}

-(NSString*)username{
	NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: flickrTokenPath];
	if (d == nil)
		return nil;
	return [d objectForKey:@"username"];
}


-(NSString*) sharedSecret{
	NSDictionary * d = [NSDictionary dictionaryWithContentsOfFile: flickrKeysPath];
	if (d == nil)
		return nil;
	return [d objectForKey:@"API_shared_secret"];
}

-(NSString*) apiKeyFromMemory{
	if ( flickrKeys ){
	 	NSString* key = [flickrKeys objectForKey:@"API_key"];
		NSLog(@"api key: \"%@\"", key);
		return key;
	}else
		return nil;
}


-(NSString*) sharedSecretFromMemory{
	if ( flickrKeys ){
	 	NSString* key = [flickrKeys objectForKey:@"API_shared_secret"];
		NSLog(@"api shared secret: \"%@\"", key);
		return key;
	}else
		return nil;
}

-(NSString*) keyFromTokenResponseMemory{
 	NSString* key = [[[tokenResponse objectForKey:@"auth"] objectForKey:@"token"] objectForKey:@"_text"];
	NSLog(@"key: \"%@\"", key);
	return key;
}

-(NSString*)usernameFromTokenResponseMemory{
 	NSString* usr = [[[tokenResponse objectForKey:@"auth"] objectForKey:@"user"] objectForKey:@"username"];
	NSLog(@"username: \"%@\"", usr);
	return usr;
}



@end
