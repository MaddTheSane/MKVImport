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
#include "matroska/KaxTracks.h"

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

@class NSString;

__private_extern NSString *__nullable mkvCodecShortener(libmatroska::KaxTrackEntry *__nonnull tr_entry);

#endif /* mkvNameShortener_hpp */
