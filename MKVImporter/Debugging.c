//
//  Debugging.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 9/24/19.
//  Copyright © 2019 C.W. Betts. All rights reserved.
//

#include "Debugging.h"
#include <os/log.h>

void postError(mkvErrorLevel level, CFStringRef format, ...)
{
	va_list theList;
	va_start(theList, format);
	if (__builtin_available(macOS 10.12, *)) {
		os_log_type_t logtypes;
		switch (level) {
			case mkvErrorLevelTrivial:
				logtypes = OS_LOG_TYPE_INFO;
				break;
				
			case mkvErrorLevelWarn:
				logtypes = OS_LOG_TYPE_DEBUG;
				break;
				
			case mkvErrorLevelSerious:
				logtypes = OS_LOG_TYPE_ERROR;
				break;
				
			case mkvErrorLevelFatal:
				logtypes = OS_LOG_TYPE_FAULT;
				break;
				
			default:
				logtypes = OS_LOG_TYPE_DEFAULT;
				break;
		}
		CFStringRef formatted = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, NULL, format, theList);
		os_log_with_type(OS_LOG_DEFAULT, logtypes, "%{public}@", formatted);
		CFRelease(formatted);
	} else {
		// TODO: use ACL?
		char buffer[512] = {0};
		CFStringRef formatted = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, NULL, format, theList);
		CFStringGetCString(formatted, buffer, sizeof(buffer), kCFStringEncodingUTF8);
		CFRelease(formatted);
		printf("%s\n", buffer);
	}
	va_end(theList);
}
