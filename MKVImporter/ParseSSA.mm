//
//  ParseSSA.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 3/6/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <CoreText/CoreText.h>
#include <string>
#include "Debugging.h"
#include "ParseSSA.hpp"
#include "ebml/EbmlStream.h"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

/// Separates string by comma, as well as remove any trailing spaces.
static NSArray<NSString*> *commaSeperation(NSString *sep);

bool getSubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, LIBEBML_NAMESPACE::EbmlStream & mkvStream, NSMutableSet<NSString*> *__nonnull fontList)
{
	KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(track);
	if (codecPrivate == NULL) {
		return false;
	}
	NSData *preString = [NSData dataWithBytesNoCopy:codecPrivate->GetBuffer() length:codecPrivate->GetSize() freeWhenDone:NO];
	NSString *theString = [[NSString alloc] initWithData:preString encoding:NSUTF8StringEncoding];
	if (!theString) {
		postError(mkvErrorLevelSerious, CFSTR("Decoding of SSA header to UTF-8 failed."));
		return false;
	}
	// Because a lot of subtitle files are written on Windows
	theString = [theString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
	//TODO: better parsing? How does libass do this?
	NSArray<NSString*> *lines = [theString componentsSeparatedByString:@"\n"];
	NSInteger styleLines = [lines indexOfObject:@"[V4+ Styles]"];
	if (styleLines == NSNotFound) {
		styleLines = [lines indexOfObject:@"[V4 Styles]"];
	}
	if (styleLines == NSNotFound) {
		// Bad ssa file?
		return false;
	}
	NSInteger eventsLine = [lines indexOfObject:@"[Events]"];
	if (eventsLine == NSNotFound) {
		// so just use the remainder
		eventsLine = lines.count;
	}
	NSString *formatLine = lines[styleLines + 1];
	if (![formatLine hasPrefix:@"Format:"]) {
		// Bad ssa file?
		return false;
	}
	formatLine = [formatLine substringFromIndex:7];
	NSArray<NSString*> *formatArray = commaSeperation(formatLine);
	NSArray<NSString*> *styles = [lines subarrayWithRange:NSMakeRange(styleLines + 2, eventsLine - (styleLines + 2))];
	//TODO: bold/italic styles? How do I figure out actual names without looking at actual font files?
	NSInteger fontIndex = [formatArray indexOfObject:@"Fontname"];
	if (fontIndex == NSNotFound) {
		// Bad ssa file?
		return false;
	}
	for (NSString *style in styles) {
		if ([style length] == 0) {
			continue;
		}
		NSArray<NSString*> *styleArray = commaSeperation(style);
		if (styleArray.count <= fontIndex) {
			continue;
		}
		NSString *fontName = styleArray[fontIndex];
		if (fontIndex == 0) {
			if ([fontName hasPrefix:@"Style:"]) {
				fontName = [fontName substringFromIndex:6];
				if ([fontName hasPrefix:@" "]) {
					fontName = [fontName substringFromIndex:1];
				}
			}
		}
		// Some fonts start with an '@'. Can't remember why...
		if ([fontName hasPrefix:@"@"]) {
			fontName = [fontName substringFromIndex:1];
		}
		[fontList addObject:fontName];
	}

	//TODO: parse rest of track, look for specific font requests?
	return true;
}

bool isSSA1(KaxTrackEntry & track)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(track);
	if (tr_codec == NULL)
		return false;

	const string &codecString(*tr_codec);
	
	if (codecString == "S_SSA" || codecString == "S_TEXT/SSA") {
		return true;
	}

	return false;
}

bool isSSA2(KaxTrackEntry & track)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(track);
	if (tr_codec == NULL)
		return false;
	
	const string &codecString(*tr_codec);
	
	if (codecString == "S_ASS" || codecString == "S_TEXT/ASS") {
		return true;
	}
	
	return false;
}

NSArray<NSString*> * fontNamesFromFontData(NSData* rawFont)
{
	NSArray *arr = (NSArray*)CFBridgingRelease(CTFontManagerCreateFontDescriptorsFromData((CFDataRef)rawFont));
	NSMutableArray *fontNames = [[NSMutableArray alloc] initWithCapacity:arr.count];
	for (id des in arr) {
		NSString *fontName = CFBridgingRelease(CTFontDescriptorCopyAttribute((__bridge CTFontDescriptorRef)des, kCTFontDisplayNameAttribute));
		[fontNames addObject:fontName];
	}
	
	return fontNames;
}

static NSArray<NSString*> *commaSeperation(NSString *sep)
{
	NSMutableArray *mutArr = [[sep componentsSeparatedByString:@","] mutableCopy];
	for (NSInteger i = 0; i < mutArr.count; i++) {
		NSString *aStr = mutArr[i];
		mutArr[i] = [aStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	
	return mutArr;
}
