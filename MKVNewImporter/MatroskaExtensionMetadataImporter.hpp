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
#include "MKVSharedImporter.hpp"

NS_ASSUME_NONNULL_BEGIN

class MatroskaExtensionMetadataImporter final: MatroskaSharedImporter {
private:
	MatroskaExtensionMetadataImporter(NSURL* _Nonnull path, CSSearchableItemAttributeSet* _Nonnull attribs);
	virtual ~MatroskaExtensionMetadataImporter() = default;
	bool ReadChapters(libmatroska::KaxChapters &trackEntries) override;
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	void copyDataOver() override;
	
public:
	static bool getMetadata(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nonnull outErr);
	
private:
	CSSearchableItemAttributeSet * _Nonnull attributes;
	
protected:
	virtual void pushTags(NSDictionary<NSString*,id> *theTags) override;
	virtual void pushTitle(NSString *theTags) override;
	virtual void pushDuration(NSNumber *theTags) override;
	virtual void pushCreationDate(NSDate *theTags) override;
	virtual void pushIdentifier(NSString *theTags) override;
	virtual void pushEncodingApplications(NSArray<NSString*> *theTags) override;
	virtual void pushLanguages(NSArray<NSString*> *theTags) override;
	virtual void pushCodecs(NSArray<NSString*> *theTags) override;
	virtual void pushLayerNames(NSArray<NSString*> *theTags) override;
	virtual void pushWidthAndHeight(NSNumber *width, NSNumber *height) override;
	virtual void pushAudioInfo(NSNumber *channelCount, NSNumber *sampleRate) override;
	virtual void pushAttachedFiles(NSArray<NSString*> *theTags) override;
};

NS_ASSUME_NONNULL_END

#endif /* MatroskaMetadataImport_hpp */
