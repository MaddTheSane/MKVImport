//
//  MKVNewImporterExtension.m
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#import "MKVNewImporterExtension.h"
#import <Foundation/Foundation.h>
#include "matroska/FileKax.h"
#include "ebml/StdIOCallback.h"
#include "ebml/EbmlHead.h"
#include "ebml/EbmlSubHead.h"
#include "ebml/EbmlStream.h"
#include "ebml/EbmlContexts.h"
#include "ebml/EbmlVoid.h"
#include "ebml/EbmlCrc32.h"
#include "matroska/KaxSegment.h"
#include "matroska/KaxContexts.h"
#include "matroska/KaxTracks.h"
#include "matroska/KaxInfoData.h"
#include "matroska/KaxCluster.h"
#include "matroska/KaxBlockData.h"
#include "matroska/KaxSeekHead.h"
#include "matroska/KaxCuesData.h"

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
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:anErr.getError() userInfo:@{NSLocalizedFailureErrorKey: @(anErr.what()), NSURLErrorKey: contentURL}];
		}
		return NO;
	} catch (...) {
		if (error) {
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSURLErrorKey: contentURL, NSLocalizedFailureErrorKey: NSLocalizedString(@"Unknown C++ exception caught", @"Unknown C++ exception caught")}];
		}
		return NO;
	}
	return NO;
}

@end

NS_ASSUME_NONNULL_END
