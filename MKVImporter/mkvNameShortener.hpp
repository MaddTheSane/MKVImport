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

#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns a human-readable codec name.
///
/// This is probably the most complex part of the code, just based on how it gets the information.
extern NSString *__nullable mkvCodecShortener(LIBMATROSKA_NAMESPACE::KaxTrackEntry & tr_entry, NSMutableDictionary *_Nullable outExtended = nullptr);

/// Create from ``libebml::UTFstring``'s UTF-32 data instead of from its UTF-8 data.
///
/// Hopefully it'll be faster than converting from UTF-8 to UTF-16.
///
/// Falls back to reading the UTF-8 string if NSString can't understand the UTF-32 values. Also will
/// return an empty string if `UTFstring` is empty.
///
/// Will return `nil` if the value cannot be converted to an NSString.
extern NSString * _Nullable getNSStringFromUTFstring(const LIBEBML_NAMESPACE::UTFstring &sourceString);

NS_ASSUME_NONNULL_END

#endif /* mkvNameShortener_hpp */
