//
//  GetMetadataForFile.m
//  MKVImporter
//
//  Created by C.W. Betts on 1/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include "GetMetadataForFile.h"
#include "matroska/FileKax.h"
#include "ebml/StdIOCallback.h"

//==============================================================================
//
//  Get metadata attributes from document files
//
//  The purpose of this function is to extract useful information from the
//  file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    // Pull any available metadata from the file at the specified path
    // Return the attribute keys and attribute values in the dict
    // Return TRUE if successful, FALSE if there was no data provided
    // The path could point to either a Core Data store file in which
    // case we import the store's metadata, or it could point to a Core
    // Data external record file for a specific record instances

    Boolean ok = FALSE;
    @autoreleasepool {
		
		NSMutableDictionary* nsAttribs = (__bridge NSMutableDictionary*)attributes;
		NSString *nsPath = (__bridge NSString*)pathToFile;
			@try {
			libebml::StdIOCallback ebmlFile(nsPath.fileSystemRepresentation ,MODE_READ);
			libmatroska::FileMatroska matFile(ebmlFile);

		} @catch (NSException *exception) {
			ok = FALSE;
		} @finally {
			;
		}
    }
    
    // Return the status
    return ok;
}
