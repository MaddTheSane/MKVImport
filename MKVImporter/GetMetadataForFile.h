//
//  GetMetadataForFile.h
//  MKVImporter
//
//  Created by C.W. Betts on 1/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#ifndef GetMetadataForFile_h
#define GetMetadataForFile_h

#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFPlugInCOM.h>
#include <CoreServices/CoreServices.h>

#ifdef __cplusplus
extern "C" {
#endif

/// The import function to be implemented in GetMetadataForFile.c
extern Boolean GetMetadataForURL(void *thisInterface,
								 CFMutableDictionaryRef attributes,
								 CFStringRef contentTypeUTI,
								 CFURLRef pathToFile);

#ifdef __cplusplus
}
#endif


#endif /* GetMetadataForFile_h */
