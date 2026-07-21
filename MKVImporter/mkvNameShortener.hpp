//
//  mkvNameShortener.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 1/5/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef mkvNameShortener_hpp
#define mkvNameShortener_hpp

#include <stdio.h>
#include "ebml/EbmlUnicodeString.h"
#include "matroska/KaxTracks.h"

@class NSString;

extern NSString *__nullable mkvCodecShortener(LIBMATROSKA_NAMESPACE::KaxTrackEntry & tr_entry);

/// Create from ``libebml::UTFstring``'s UTF-32 data instead of from its UTF-8 data.
///
/// Hopefully it'll be faster than converting from UTF-8 to UTF-16.
extern NSString * _Nullable getNSStringFromUTFstring(const LIBEBML_NAMESPACE::UTFstring &sourceString);

#endif /* mkvNameShortener_hpp */
