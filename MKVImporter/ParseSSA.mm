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
#include "ParseSSA.hpp"
#include "ebml/EbmlStream.h"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

bool getSubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, LIBEBML_NAMESPACE::EbmlStream & mkvStream, NSMutableSet<NSString*> *__nonnull fontList)
{
	auto startLoc = mkvStream.I_O().getFilePointer();
	
	KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(track);
	if (codecPrivate == NULL) {
		//mkvStream.I_O().setFilePointer(startLoc);
		return false;
	}
	//track.Read(<#EbmlStream &inDataStream#>, <#const EbmlSemanticContext &Context#>, <#int &UpperEltFound#>, <#EbmlElement *&FoundElt#>, <#bool AllowDummyElt#>)

	mkvStream.I_O().setFilePointer(startLoc);
	return false;
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
	if (arr.count > 1) {
		NSMutableArray *fontNames = [[NSMutableArray alloc] initWithCapacity:arr.count];
		for (id des in arr) {
			CTFontDescriptorRef des2 = (__bridge CTFontDescriptorRef)des;
			NSString *fontName = CFBridgingRelease(CTFontDescriptorCopyAttribute(des2, kCTFontNameAttribute));
			[fontNames addObject:fontName];
		}
		
		return fontNames;
	}
	CGDataProviderRef dataProv = CGDataProviderCreateWithCFData((CFDataRef)rawFont);
	CGFontRef theFont = CGFontCreateWithDataProvider(dataProv);
	CGDataProviderRelease(dataProv);
	if (!theFont) {
		return nil;
	}
	NSString *hi = (NSString*)CFBridgingRelease(CGFontCopyFullName(theFont));
	CGFontRelease(theFont);
	
	return @[hi];
}
