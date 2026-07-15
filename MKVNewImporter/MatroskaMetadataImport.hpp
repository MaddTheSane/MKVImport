//
//  MatroskaMetadataImport.hpp
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

class MatroskaMetadataImport final {
private:
	MatroskaMetadataImport(NSURL* _Nonnull path, CSSearchableItemAttributeSet* _Nonnull attribs):
	_ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)),
	_aStream(EbmlStream(_ebmlFile)),
	attributes(attribs),
	fileURL(path),
	seenInfo(false), seenTracks(false), seenChapters(false), seenTags(false) {
		mediaTypes = [[NSMutableOrderedSet alloc] initWithCapacity:6];
		fonts = [[NSMutableSet alloc] initWithCapacity:50];
		segmentOffset = 0;
		el_l0 = NULL;
		el_l1 = NULL;
		bpsStorage = [[NSMutableDictionary alloc] init];
		trackIDAndTypes = [[NSMutableDictionary alloc] init];
	}
	virtual ~MatroskaMetadataImport();
	bool ReadSegmentInfo(libmatroska::KaxInfo &segmentInfo);
	bool ReadTracks(libmatroska::KaxTracks &trackEntries);
	bool ReadChapters(libmatroska::KaxChapters &trackEntries);
	bool ReadAttachments(libmatroska::KaxAttachments &trackEntries);
	bool ReadMetaSeek(libmatroska::KaxSeekHead &trackEntries);
	bool ReadTags(const libmatroska::KaxTags &trackEntries);

	bool isValidMatroska(NSError * _Nullable * _Nonnull outErr);
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	void copyDataOver();
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
	
	bool iterateData(NSError * _Nullable * _Nonnull outErr);
	inline void addMediaType(NSString * _Nonnull theType) {
		[mediaTypes addObject:theType];
	}
	
public:
	static bool getMetadata(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nonnull outErr);
	
private:
	StdIOCallback _ebmlFile;
	EbmlStream _aStream;
	EbmlElement * _Nullable el_l0;
	EbmlElement * _Nullable el_l1;
	CSSearchableItemAttributeSet * _Nonnull attributes;
	NSMutableOrderedSet<NSString*> * _Nonnull mediaTypes;
	NSMutableSet<NSString*> * _Nonnull fonts;
	NSMutableDictionary<NSNumber*,NSString*> * _Nonnull bpsStorage;
	NSMutableDictionary<NSNumber*,NSNumber*> * _Nonnull trackIDAndTypes;
	//Kept mainly for debugging
	NSURL * _Nonnull fileURL;
	
	// FIXME: we're getting duplicates. This works around it, but doesn't fix it.
	bool seenInfo;
	bool seenTracks;
	bool seenChapters;
	bool seenTags;

	std::vector<MatroskaSeek>	levelOneElements;
	
	uint64_t					segmentOffset;
};


#endif /* MatroskaMetadataImport_hpp */
