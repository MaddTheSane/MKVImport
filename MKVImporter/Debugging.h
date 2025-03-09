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

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

typedef CF_ENUM(int, mkvErrorLevel) {
	//! Annoying, but won't crash.
	mkvErrorLevelTrivial = 0,
	//! Debug info.
	mkvErrorLevelWarn = 1,
	//! *Might* crash the importer.
	mkvErrorLevelSerious = 2,
	//! **Will** crash the metadata importer.
	mkvErrorLevelFatal = 3
};

__private_extern
void postError(mkvErrorLevel level, CFStringRef format, ...) CF_FORMAT_FUNCTION(2,3);

#ifdef __cplusplus
}
#endif

#endif /* Debugging_hpp */
