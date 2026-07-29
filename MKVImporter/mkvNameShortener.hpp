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

NS_ASSUME_NONNULL_BEGIN

/// Returns a human-readable codec name.
///
/// This is probably the most complex part of the code, just based on how it gets the information.
extern NSString *__nullable mkvCodecShortener(LIBMATROSKA_NAMESPACE::KaxTrackEntry & tr_entry);

/// Create from ``libebml::UTFstring``'s UTF-32 data instead of from its UTF-8 data.
///
/// Hopefully it'll be faster than converting from UTF-8 to UTF-16.
///
/// Falls back to reading the UTF-8 string if NSString can't understand the UTF-32 values. Also will
/// return an empty string if `UTFstring` is empty.
///
/// Will return `nil` if the value cannot be converted to an NSString.
extern NSString * _Nullable getNSStringFromUTFstring(const LIBEBML_NAMESPACE::UTFstring &sourceString);

extern NSString * const MKVIMediaToolboxVideoCodePrefix;
extern NSString * const MKVIMediaToolboxAudioCodePrefix;
extern NSString * const MKVIMediaToolboxSubtitleCodePrefix;
extern NSString * const MKVIMediaToolboxMuxedCodePrefix;

/// Get a localized string from the Media Toolbox framework bundle's Strings table *"MediaAndSubtypes"*.
///
/// Most localized keys in *"MediaAndSubtypes"* are a collection of one or two FourChars.
/// The one FourChar are usually media types, such as *"vide"* for "video".
/// The two FourChars are usually codecs with the type of codec before the codec identifier, such as *"videsmc "* for the video codec
/// Smacker (with the value of "Graphics" for legacy reasons).
///
/// If the bundle wasn't found, returns the content of `value`.
///
/// @returns depends on a few factors:
/// 1. If the MediaToolbox framework wasn't found successfully, returns `value` (which may be `nil`).
/// 2. If the MediaToolbox framework is found and contains a localization for `key`, returns the localized value.
/// 3. If the MediaToolbox framework is found but doesn't contain the localized `key`, returns `value` if `value` is non-`nil`, otherwise the `key` will be returned.
extern NSString * _Nullable localizedMediaToolboxMediaAndSubtypes(NSString *key, NSString * _Nullable value);

NS_ASSUME_NONNULL_END

#endif /* mkvNameShortener_hpp */
