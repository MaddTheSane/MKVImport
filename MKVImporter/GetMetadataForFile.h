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

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/// The import function to be implemented in GetMetadataForFile.c
__private_extern extern
Boolean GetMetadataForFile(void *thisInterface,
						   CFMutableDictionaryRef attributes,
						   CFStringRef contentTypeUTI,
						   CFStringRef pathToFile);

/// The import function to be implemented in GetMetadataForFile.c
__private_extern extern
Boolean GetMetadataForURL(void *thisInterface,
						  CFMutableDictionaryRef attributes,
						  CFStringRef contentTypeUTI,
						  CFURLRef pathToFile);

#ifdef __cplusplus
}
#endif


#endif /* GetMetadataForFile_h */
