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

extern bool getSSASubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, LIBEBML_NAMESPACE::EbmlStream & mkvStream, NSMutableSet<NSString*> *__nonnull fontList);
extern bool isSSA(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);
extern NSArray<NSString*> * _Nullable fontNamesFromFontData(NSData* _Nonnull rawFont);

/// Separates string by comma, as well as remove any trailing spaces.
extern NSArray<NSString*> * _Nonnull commaSeperation(NSString * _Nonnull sep);

#endif /* ParseSSA_hpp */
