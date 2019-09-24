//
//  Debugging.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 9/24/19.
//  Copyright © 2019 C.W. Betts. All rights reserved.
//

#ifndef Debugging_hpp
#define Debugging_hpp

#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

typedef CF_ENUM(int, mkvErrorLevel) {
	mkvErrorLevelTrivial = 0,
	mkvErrorLevelWarn = 1,
	mkvErrorLevelSerious = 2,
	mkvErrorLevelFatal = 3
};

__private_extern
void postError(mkvErrorLevel level, CFStringRef format, ...) CF_FORMAT_FUNCTION(2,3);

#endif /* Debugging_hpp */
