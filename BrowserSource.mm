//
//  BrowserSource.m
//  OsiriX
//
//  Created by Alessandro Volz on 06.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "BrowserSource.h"
#import "ImageAndTextCell.h"
#import "RemoteDicomDatabase.h"
#import <stdlib.h>

@interface BrowserSource ()

@property(readwrite) NSInteger type;

@end

@implementation BrowserSource

@synthesize type = _type, location = _location, description = _description, dictionary = _dictionary;//, extraView = _extraView;

+(id)browserSourceForLocalPath:(NSString*)path {
	return [[self class] browserSourceForLocalPath:path description:nil dictionary:nil];
}

+(id)browserSourceForLocalPath:(NSString*)path description:(NSString*)description dictionary:(NSDictionary*)dictionary {
	BrowserSource* bs = [[[[self class] alloc] init] autorelease];
	bs.type = BrowserSourceTypeLocal;
	bs.location = path;
	bs.description = description;
	bs.dictionary = dictionary;
	return bs;
}

+(id)browserSourceForAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary {
	BrowserSource* bs = [[[[self class] alloc] init] autorelease];
	bs.type = BrowserSourceTypeRemote;
	bs.location = address;
	bs.description = description;
	bs.dictionary = dictionary;
	return bs;
}

+(id)browserSourceForDicomNodeAtAddress:(NSString*)address description:(NSString*)description dictionary:(NSDictionary*)dictionary {
	BrowserSource* bs = [[[[self class] alloc] init] autorelease];
	bs.type = BrowserSourceTypeDicom;
	bs.location = address;
	bs.description = description;
	bs.dictionary = dictionary;
	return bs;
}

-(void)dealloc {
	self.location = nil;
	self.description = nil;
	self.dictionary = nil;
	[super dealloc];
}

-(BOOL)isEqualToSource:(BrowserSource*)other {
	if (self.type != other.type)
		return NO;
	
	if (self.dictionary && self.dictionary == other.dictionary)
		return YES;
	
	if (self.type == BrowserSourceTypeLocal) {
		if ([[DicomDatabase baseDirPathForPath:self.location] isEqualToString:[DicomDatabase baseDirPathForPath:other.location]])
			return YES;
	} else
	if (self.type == BrowserSourceTypeRemote) {
		NSHost* h1; NSInteger p1; [RemoteDicomDatabase address:self.location toHost:&h1 port:&p1];
		NSHost* h2; NSInteger p2; [RemoteDicomDatabase address:other.location toHost:&h2 port:&p2];
		if (p1 == p2 && [h1 isEqualToHost:h2])
			return YES;
	} else
	if (self.type == BrowserSourceTypeDicom) {
		NSHost* h1; NSInteger p1; NSString* a1; [RemoteDicomDatabase address:self.location toHost:&h1 port:&p1 aet:&a1];
		NSHost* h2; NSInteger p2; NSString* a2; [RemoteDicomDatabase address:other.location toHost:&h2 port:&p2 aet:&a2];
		if (p1 == p2 && [h1 isEqualToHost:h2] && [a1 isEqualToString:a2])
			return YES;
	}
	
	return NO;
}

-(DicomDatabase*)database { // for subclassers
	return nil;
}

-(void)willDisplayCell:(ImageAndTextCell*)cell {
	switch (self.type) {
		case BrowserSourceTypeLocal: {
			BOOL isDir;
			if (![NSFileManager.defaultManager fileExistsAtPath:self.location isDirectory:&isDir]) {
				cell.image = [NSImage imageNamed:@"away.tif"];
				cell.textColor = NSColor.grayColor;
				break;
			}
			
			if (!isDir) {
				cell.image = [NSImage imageNamed:@"FileIcon.tif"];
				break;
			}
			
			BOOL isIPod = [NSFileManager.defaultManager fileExistsAtPath:[self.location stringByAppendingPathComponent:@"iPod_Control"]];
		//	NSLog(@"mountedRemovableMedia %@", [[NSWorkspace sharedWorkspace] mountedRemovableMedia]);
			BOOL atRemovableMediaRoot = [[[NSWorkspace sharedWorkspace] mountedRemovableMedia] containsObject:self.location];
			if (isIPod || atRemovableMediaRoot) {
				cell.lastImage = [NSImage imageNamed:@"iPodEjectOff.tif"];
				cell.lastImageAlternate = [NSImage imageNamed:@"iPodEjectOn.tif"];
			}
			
			NSString* path = self.location;
			BOOL atMediaRoot = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] containsObject:path];
			if (!atMediaRoot)
				path = [path stringByDeletingLastPathComponent];
			
			NSImage* im = [[NSWorkspace sharedWorkspace] iconForFile:self.location];
			[im setSize:NSMakeSize(16,16)];
			cell.image = im;
		} break;
		case BrowserSourceTypeRemote: {
			cell.image = [NSImage imageNamed:@"FixedIP.tif"];
		} break;
		case BrowserSourceTypeDicom: {
			cell.image = [NSImage imageNamed:@"DICOMDestination.tif"];
		} break;
	}
}

-(NSComparisonResult)compare:(BrowserSource*)other {
	if (self.type != other.type) return self.type > other.type;
	return [self.description caseInsensitiveCompare:other.description];
}


@end
