//
//  GetMetadataForFile.m
//  MKVImporter
//
//  Created by C.W. Betts on 1/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include "GetMetadataForFile.h"
#include "matroska/FileKax.h"
#include "ebml/StdIOCallback.h"

#include <string>
#include <vector>
#include "ebml/EbmlHead.h"
#include "ebml/EbmlSubHead.h"
#include "ebml/EbmlStream.h"
#include "ebml/EbmlContexts.h"
#include "ebml/EbmlVoid.h"
#include "ebml/EbmlCrc32.h"
#include "matroska/FileKax.h"
#include "matroska/KaxSegment.h"
#include "matroska/KaxContexts.h"
#include "matroska/KaxTracks.h"
#include "matroska/KaxInfoData.h"
#include "matroska/KaxCluster.h"
#include "matroska/KaxBlockData.h"
#include "matroska/KaxSeekHead.h"
#include "matroska/KaxCuesData.h"

#include <iostream>
#include <functional>
#include <algorithm>

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using namespace std;
using std::string;
using std::vector;





class MatroskaImport {
private:
	MatroskaImport(NSString* path, NSMutableDictionary*attribs): _ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)), _aStream(EbmlStream(_ebmlFile)), attributes(attribs), seenInfo(false), seenTracks(false), seenChapters(false) {
		newAttribs = [[NSMutableDictionary alloc] init];
	}
	virtual ~MatroskaImport() {
		attributes = nil;
		newAttribs = nil;
	};
	bool ReadSegmentInfo(KaxInfo &segmentInfo);
	
	bool isValidMatroska();
	void copyDataOver() {
		[attributes addEntriesFromDictionary:newAttribs];
	}
	EbmlElement * NextLevel1Element();

	//! a list of level one elements and their offsets in the segment
	class MatroskaSeek {
	public:
		struct MatroskaSeekContext {
			EbmlElement		*el_l1;
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
	/// This function saves el_l1 and the current file position to the returned context
	/// and clears el_l1 to null in preparation for a seek.
	MatroskaSeek::MatroskaSeekContext SaveContext();
	
	/// This function restores el_l1 to what is saved in the context, deleting the current
	/// value if not null, and seeks to the specified point in the file.
	void SetContext(MatroskaSeek::MatroskaSeekContext context);

	
public:
	static bool getMetadata(NSMutableDictionary *attribs, NSString *uti, NSString *path);
	
private:
	StdIOCallback _ebmlFile;
	EbmlStream _aStream;
	EbmlElement *el_l0;
	EbmlElement *el_l1;
	NSMutableDictionary *attributes;
	NSMutableDictionary *newAttribs;
	
	bool seenInfo;
	bool seenTracks;
	bool seenChapters;

	//vector<MatroskaTrack>	tracks;
	vector<MatroskaSeek>	levelOneElements;
	
	uint64_t				segmentOffset;

};

bool MatroskaImport::isValidMatroska()
{
	bool valid;
	int upperLevel;
	auto el_l0 = _aStream.FindNextID(EbmlHead::ClassInfos, ~0);
	if (el_l0 != NULL) {
		EbmlElement *dummyElt = NULL;
		
		el_l0->Read(_aStream, EbmlHead::ClassInfos.Context, upperLevel, dummyElt, true);
		
		if (EbmlId(*el_l0) != EBML_ID(EbmlHead)) {
			fprintf(stderr, "Not a Matroska file\n");
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType docType = GetChild<EDocType>(*head);
		if (string(docType) != "matroska" && string(docType) != "webm") {
			fprintf(stderr, "Unknown Matroska doctype\n");
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			fprintf(stderr, "Matroska file too new to be read\n");
			valid = false;
		}
	} else {
		fprintf(stderr, "Matroska file missing EBML Head\n");
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}

bool MatroskaImport::getMetadata(NSMutableDictionary *attribs, NSString *uti, NSString *path)
{
	auto generatorClass = new MatroskaImport(path, attribs);
	if (!generatorClass->isValidMatroska()) {
		delete generatorClass;
		return false;
	}
	
	generatorClass->copyDataOver();
	delete generatorClass;
	return false;
}

bool MatroskaImport::ReadSegmentInfo(KaxInfo &segmentInfo)
{
	if (seenInfo)
		return true;
	
	KaxDuration & duration = GetChild<KaxDuration>(segmentInfo);
	KaxTimecodeScale & timecodeScale = GetChild<KaxTimecodeScale>(segmentInfo);
	KaxTitle & title = GetChild<KaxTitle>(segmentInfo);
	KaxWritingApp & writingApp = GetChild<KaxWritingApp>(segmentInfo);
	KaxMuxingApp & muxingApp = GetChild<KaxMuxingApp>(segmentInfo);

	Float64 movieDuration = Float64(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	newAttribs[(NSString*)kMDItemDurationSeconds] = @((movieDuration * timecodeScale1) / 1e9);
	
	if (!title.IsDefaultValue()) {
		newAttribs[(NSString*)kMDItemTitle] = @(title.GetValueUTF8().c_str());
	}
	
	if (!writingApp.IsDefaultValue()) {
		newAttribs[(NSString*)kMDItemCreator] = @(writingApp.GetValueUTF8().c_str());
	}
	if (writingApp.IsDefaultValue() && !muxingApp.IsDefaultValue()) {
		newAttribs[(NSString*)kMDItemCreator] = @(muxingApp.GetValueUTF8().c_str());
	}
	
	return false;
}

//==============================================================================
//
//  Get metadata attributes from document files
//
//  The purpose of this function is to extract useful information from the
//  file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    // Pull any available metadata from the file at the specified path
    // Return the attribute keys and attribute values in the dict
    // Return TRUE if successful, FALSE if there was no data provided
    // The path could point to either a Core Data store file in which
    // case we import the store's metadata, or it could point to a Core
    // Data external record file for a specific record instances

    Boolean ok = FALSE;
    @autoreleasepool {
		
		NSMutableDictionary* nsAttribs = (__bridge NSMutableDictionary*)attributes;
		NSString *nsPath = (__bridge NSString*)pathToFile;
		@try {
			matroska_init();
			ok = MatroskaImport::getMetadata(nsAttribs, (__bridge NSString*)contentTypeUTI, nsPath);
		} @catch (NSException *exception) {
			ok = FALSE;
		} @finally {
			matroska_done();
		}
    }
	
    // Return the status
    return ok;
}

EbmlElement * MatroskaImport::NextLevel1Element()
{
	int upperLevel = 0;
	
	if (el_l1) {
		el_l1->SkipData(_aStream, el_l1->Generic().Context);
		delete el_l1;
		el_l1 = NULL;
	}
	
	el_l1 = _aStream.FindNextElement(el_l0->Generic().Context, upperLevel, 0xFFFFFFFFL, true);
	
	// dummy element -> probably corrupt file, search for next element in meta seek and continue from there
	if (el_l1 && el_l1->IsDummy()) {
		vector<MatroskaSeek>::iterator nextElt;
		MatroskaSeek currElt;
		currElt.segmentPos = el_l1->GetElementPosition();
		currElt.idLength = currElt.ebmlID = 0;
		
		nextElt = find_if(levelOneElements.begin(), levelOneElements.end(), bind2nd(greater<MatroskaSeek>(), currElt));
		if (nextElt != levelOneElements.end()) {
			SetContext(nextElt->GetSeekContext(segmentOffset));
			NextLevel1Element();
		}
	}
	
	return el_l1;
}


MatroskaImport::MatroskaSeek::MatroskaSeekContext MatroskaImport::SaveContext()
{
	MatroskaSeek::MatroskaSeekContext ret = { el_l1, _ebmlFile.getFilePointer() };
	el_l1 = NULL;
	return ret;
}

void MatroskaImport::SetContext(MatroskaSeek::MatroskaSeekContext context)
{
	if (el_l1)
		delete el_l1;
	
	el_l1 = context.el_l1;
	_ebmlFile.setFilePointer(context.position);
}

