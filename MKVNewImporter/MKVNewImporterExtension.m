//
//  MKVNewImporterExtension.m
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKVNewImporterExtension.h"
#import "MatroskaExtensionMetadataImporter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MKVNewImporterExtension

- (BOOL)updateAttributes:(CSSearchableItemAttributeSet * _Nonnull)attributes
			forFileAtURL:(NSURL * _Nonnull)contentURL
				   error:(NSError * _Nullable * _Nonnull)error
{
	return extensionInfoGetter(attributes, contentURL, error);
}

@end

NS_ASSUME_NONNULL_END
