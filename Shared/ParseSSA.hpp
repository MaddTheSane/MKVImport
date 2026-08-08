//
//  ParseSSA.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 3/6/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef ParseSSA_hpp
#define ParseSSA_hpp

#import <Foundation/NSSet.h>
#include "matroska/KaxTracks.h"

NS_ASSUME_NONNULL_BEGIN

extern bool getSSASubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, LIBEBML_NAMESPACE::EbmlStream & mkvStream, NSMutableSet<NSString*> *fontList);
extern bool isSSA(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);
extern NSArray<NSString*> * _Nullable fontNamesFromFontData(NSData *rawFont);

/// Separates string by comma, as well as remove any trailing spaces.
extern NSArray<NSString*> *commaSeperation(NSString *sep);

NS_ASSUME_NONNULL_END

#endif /* ParseSSA_hpp */
