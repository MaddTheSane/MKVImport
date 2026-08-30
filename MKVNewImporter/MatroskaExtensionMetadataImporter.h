//
//  MatroskaExtensionMetadataImporter.hpp
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#ifndef MatroskaMetadataImport_hpp
#define MatroskaMetadataImport_hpp

#import <Foundation/Foundation.h>
#import <CoreSpotlight/CSSearchableItemAttributeSet.h>

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

extern bool extensionInfoGetter(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nullable outErr);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif

#endif /* MatroskaMetadataImport_hpp */
