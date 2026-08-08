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
#include <vector>
#include "ebml/EbmlHead.h"
#include "ebml/EbmlSubHead.h"
#include "ebml/EbmlStream.h"
#include "ebml/EbmlContexts.h"
#include "ebml/EbmlVoid.h"
#include "ebml/EbmlCrc32.h"
#include "ebml/StdIOCallback.h"
#include "matroska/FileKax.h"
#include "matroska/KaxSegment.h"
#include "matroska/KaxContexts.h"
#include "matroska/KaxTracks.h"
#include "matroska/KaxInfoData.h"
#include "matroska/KaxCluster.h"
#include "matroska/KaxBlockData.h"
#include "matroska/KaxSeekHead.h"
#include "matroska/KaxCuesData.h"
#include "MKVSharedImporter.hpp"

NS_ASSUME_NONNULL_BEGIN

class MatroskaExtensionMetadataImporter final: MatroskaSharedImporter {
private:
	MatroskaExtensionMetadataImporter(NSURL* _Nonnull path, CSSearchableItemAttributeSet* _Nonnull attribs);
	virtual ~MatroskaExtensionMetadataImporter();
	bool ReadChapters(libmatroska::KaxChapters &trackEntries) override;
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	void copyDataOver() override;
	
public:
	static bool getMetadata(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nonnull outErr);
	
private:
	CSSearchableItemAttributeSet * _Nonnull attributes;
	
protected:
	virtual void copyTags(NSDictionary<NSString*,id> *theTags) override;
	virtual void setTitle(NSString *theTags) override;
	virtual void setDuration(NSNumber *theTags) override;
	virtual void setCreationDate(NSDate *theTags) override;
	virtual void setIdentifier(NSString *theTags) override;
	virtual void copyEncodingApplications(NSArray<NSString*> *theTags) override;
	virtual void copyLanguages(NSArray<NSString*> *theTags) override;
	virtual void copyCodecs(NSArray<NSString*> *theTags) override;
	virtual void copyLayerNames(NSArray<NSString*> *theTags) override;
	virtual void copyWidthAndHeight(NSNumber *width, NSNumber *height) override;
	virtual void copyAudioInfo(NSNumber *channelCount, NSNumber *sampleRate) override;
	virtual void copyAttachedFiles(NSArray<NSString*> *theTags) override;
};

NS_ASSUME_NONNULL_END

#endif /* MatroskaMetadataImport_hpp */
