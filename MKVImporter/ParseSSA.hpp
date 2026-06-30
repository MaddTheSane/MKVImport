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

extern bool getSubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, LIBEBML_NAMESPACE::EbmlStream & mkvStream, NSMutableSet<NSString*> *__nonnull fontList);
extern bool isSSA1(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);
extern bool isSSA2(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);
extern NSArray<NSString*> * _Nullable fontNamesFromFontData(NSData* _Nonnull rawFont);

#endif /* ParseSSA_hpp */
