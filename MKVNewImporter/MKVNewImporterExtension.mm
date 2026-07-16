//
//  MKVNewImporterExtension.m
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#import "MKVNewImporterExtension.h"
#import <Foundation/Foundation.h>

#include "mkvNameShortener.hpp"
#include "ParseSSA.hpp"
#include "Debugging.h"
#include "MatroskaMetadataImport.hpp"

NS_ASSUME_NONNULL_BEGIN

@implementation MKVNewImporterExtension

- (BOOL)updateAttributes:(CSSearchableItemAttributeSet * _Nonnull)attributes
			forFileAtURL:(NSURL * _Nonnull)contentURL
				   error:(NSError * _Nullable * _Nonnull)error
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		matroska_init();
		atexit_b(^{
			matroska_done();
		});
	});

	try {
		return MatroskaMetadataImport::getMetadata(attributes, contentURL, error);
	} catch (CRTError &anErr) {
		if (error) {
			NSString *what = @(anErr.what());
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:anErr.getError() userInfo:@{NSLocalizedDescriptionKey: what, NSURLErrorKey: contentURL, NSLocalizedFailureErrorKey: NSLocalizedString(@"CRTError exception caught", @"CRTError exception caught"), NSDebugDescriptionErrorKey: what}];
		}
		return NO;
	} catch (...) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSURLErrorKey: contentURL, NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown C++ exception caught", @"Unknown C++ exception caught"), NSDebugDescriptionErrorKey: @"Unknown C++ exception caught"}];
		}
		return NO;
	}
	return NO;
}

@end

NS_ASSUME_NONNULL_END
