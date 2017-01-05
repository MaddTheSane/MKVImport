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

@class NSString;

NSString *mkvCodecShortener(libmatroska::KaxTrackEntry *tr_entry);

#endif /* mkvNameShortener_hpp */
