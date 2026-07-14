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

@implementation MKVNewImporterExtension

- (BOOL)updateAttributes:(CSSearchableItemAttributeSet * _Nonnull)attributes
			forFileAtURL:(NSURL * _Nonnull)contentURL
				   error:(NSError * _Nullable * _Nonnull)error
{
	return NO;
}

@end

NS_ASSUME_NONNULL_END
