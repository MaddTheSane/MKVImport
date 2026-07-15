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

NS_ASSUME_NONNULL_BEGIN

bool isValidMatroska(EbmlStream &_aStream, NSError * _Nullable * _Nonnull outErr)
{
	bool valid = true;
	int upperLevel;
	EbmlElement *el_l0 = _aStream.FindNextID(EBML_INFO(EbmlHead), ~0);
	if (el_l0 != NULL) {
		EbmlElement *dummyElt = NULL;
		
		el_l0->Read(_aStream, EBML_CLASS_CONTEXT(EbmlHead), upperLevel, dummyElt, true);
		
		if (EbmlId(*el_l0) != EBML_ID(EbmlHead)) {
			if (!outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedFailureErrorKey: NSLocalizedString(@"Not a Matroska file", @"Not a Matroska file")}];
			}
			
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType & docType = GetChild<EDocType>(*head);
		const std::string & cppDocType = std::string(docType);
		if (cppDocType != "matroska" && cppDocType != "webm") {
			if (!outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedFailureErrorKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Unknown Matroska doctype \"%@\"", @"Unknown Matroska doctype"), @(cppDocType.c_str())]}];
			}
			
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion & readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			if (!outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedFailureErrorKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Matroska file too new to be read, version %lld", @"Matroska file too new to be read, version number"), UInt64(readVersion)]}];
			}
			
			valid = false;
			goto exit;
		}
		el_l0->SkipData(_aStream, EBML_CLASS_SEMCONTEXT(EbmlHead));

	} else {
		if (!outErr) {
			*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedFailureErrorKey: NSLocalizedString(@"Matroska file missing EBML Head", @"Matroska file missing EBML Head")}];
		}
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}


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
		StdIOCallback _ebmlFile(contentURL.fileSystemRepresentation, MODE_READ);
		EbmlStream _aStream(_ebmlFile);
		
		if (!isValidMatroska(_aStream, error)) {
			return NO;
		}
		
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
