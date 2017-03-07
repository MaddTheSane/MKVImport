//
//  ParseSSA.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 3/6/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef ParseSSA_hpp
#define ParseSSA_hpp

#include "matroska/KaxTracks.h"

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

@class NSMutableSet<ObjectType>;

__private_extern bool getSubtitleFontList(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track, NSMutableSet<NSString*> *__nonnull fontList);
__private_extern bool isSSA1(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);
__private_extern bool isSSA2(LIBMATROSKA_NAMESPACE::KaxTrackEntry & track);

#endif /* ParseSSA_hpp */
