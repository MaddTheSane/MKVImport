//
//  MKVSharedImporter.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 8/8/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#ifndef __MKVSharedImporter_hpp__
#define __MKVSharedImporter_hpp__

#import <Foundation/Foundation.h>

#include <string>
#include <vector>
#include "ebml/EbmlHead.h"
#include "ebml/EbmlSubHead.h"
#include "ebml/EbmlStream.h"
#include "ebml/StdIOCallback.h"
#include "matroska/FileKax.h"
#include "matroska/KaxTracks.h"
#include "matroska/KaxCluster.h"
#include "matroska/KaxSeekHead.h"

NS_ASSUME_NONNULL_BEGIN

class MatroskaSharedImporter {
public:
	MatroskaSharedImporter(NSURL* path);
	virtual ~MatroskaSharedImporter();
	
protected:
	bool ReadSegmentInfo(libmatroska::KaxInfo &segmentInfo);
	bool ReadTracks(libmatroska::KaxTracks &trackEntries);
	virtual bool ReadChapters(libmatroska::KaxChapters &trackEntries);
	bool ReadAttachments(libmatroska::KaxAttachments &trackEntries);
	bool ReadMetaSeek(libmatroska::KaxSeekHead &trackEntries);
	bool ReadTags(const libmatroska::KaxTags &trackEntries);

	bool isValidMatroska(NSError * _Nullable * _Nonnull outErr);
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	virtual void copyDataOver() = 0;
	
	EbmlElement * _Nullable NextLevel1Element();

	//! a list of level one elements and their offsets in the segment
	class MatroskaSeek final {
	public:
		struct MatroskaSeekContext {
			EbmlElement		* _Nullable el_l1;
			uint64_t		position;
		};
		
		EbmlId GetID() const { return EbmlId(ebmlID, idLength); }
		bool operator<(const MatroskaSeek &rhs) const { return segmentPos < rhs.segmentPos; }
		bool operator>(const MatroskaSeek &rhs) const { return segmentPos > rhs.segmentPos; }
		
		MatroskaSeekContext GetSeekContext(uint64_t segmentOffset = 0) const {
			return (MatroskaSeekContext){ NULL, segmentPos + segmentOffset };
		}
		
		uint32_t		ebmlID;
		uint8_t			idLength;
		uint64_t		segmentPos;
	};
	
	/// we need to save a bit of context when seeking if we're going to seek back
	/// This function saves `el_l1` and the current file position to the returned context
	/// and clears `el_l1` to null in preparation for a seek.
	MatroskaSeek::MatroskaSeekContext SaveContext();
	
	/// This function restores `el_l1` to what is saved in the context, deleting the current
	/// value if not null, and seeks to the specified point in the file.
	void SetContext(MatroskaSeek::MatroskaSeekContext context);

	bool ProcessLevel1Element();
	
	bool iterateData(NSError * _Nullable * _Nullable outErr);
	inline void addMediaType(NSString *theType) {
		[mediaTypes addObject:theType];
	}
	
	inline void addMediaType(CFStringRef CF_CONSUMED theType) {
		addMediaType((NSString*)CFBridgingRelease(theType));
	}
	
protected:
	StdIOCallback _ebmlFile;
	EbmlStream _aStream;
	EbmlElement * _Nullable el_l0;
	EbmlElement * _Nullable el_l1;
	NSMutableOrderedSet<NSString*> *mediaTypes;
	NSMutableSet<NSString*> *fonts;
	NSMutableDictionary<NSNumber*,NSString*> *bpsStorage;
	NSMutableDictionary<NSNumber*,NSNumber*> *trackIDAndTypes;
	//Kept mainly for debugging
	NSURL *fileURL;
	
private:
	// FIXME: we're getting duplicates. This works around it, but doesn't fix it.
	bool seenInfo;
	bool seenTracks;
protected:
	bool seenChapters;
private:
	bool seenTags;
	bool seenAttachments;

	std::vector<MatroskaSeek>	levelOneElements;
	
	uint64_t					segmentOffset;
	
protected:
	/// Is given Matroska tags. Subclasses must match the tags with what the metadata system expects.
	virtual void pushTags(NSDictionary<NSString*,id> *theTags) = 0;
	
	virtual void pushTitle(NSString *theTags) = 0;
	virtual void pushDuration(NSNumber *theTags) = 0;
	virtual void pushCreationDate(NSDate *theTags) = 0;
	virtual void pushIdentifier(NSString *theTags) = 0;
	virtual void pushEncodingApplications(NSArray<NSString*> *theTags) = 0;
	virtual void pushLanguages(NSArray<NSString*> *theTags) = 0;
	virtual void pushCodecs(NSArray<NSString*> *theTags) = 0;
	virtual void pushLayerNames(NSArray<NSString*> *theTags) = 0;
	virtual void pushWidthAndHeight(NSNumber *width, NSNumber *height) = 0;
	virtual void pushAudioInfo(NSNumber *channelCount, NSNumber *sampleRate) = 0;
	virtual void pushAttachedFiles(NSArray<NSString*> *theTags) = 0;

};

#define kChapterNames @"com_GitHub_MaddTheSane_ChapterNames"
#define kAttachedFiles @"com_GitHub_MaddTheSane_AttachedFiles"

extern NSString *getLocaleCode(const libmatroska::KaxChapterLanguage & language, libmatroska::KaxChapterCountry * _Nullable country);
extern NSString *getLocaleCode(const libmatroska::KaxChapLanguageIETF * language);

NS_ASSUME_NONNULL_END

#endif
