//
//  ParseSSA.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 3/6/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <string>
#include "ParseSSA.hpp"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

bool getSubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, NSMutableSet<NSString*> *fontList)
{
	return false;
}

bool isSSA1(KaxTrackEntry & track)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(track);
	if (tr_codec == NULL)
		return false;

	string codecString(*tr_codec);
	
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
	
	string codecString(*tr_codec);
	
	if (codecString == "S_ASS" || codecString == "S_TEXT/ASS") {
		return true;
	}
	
	return false;
}

