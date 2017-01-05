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
#include <iostream>
#include <functional>
#include <algorithm>
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

#include "mkvNameShortener.hpp"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using namespace std;

#define kChapterNames @"com_GitHub_MaddTheSane_ChapterNames"

class MatroskaImport {
private:
	MatroskaImport(NSString* path, NSMutableDictionary*attribs): _ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)), _aStream(EbmlStream(_ebmlFile)), attributes(attribs), seenInfo(false), seenTracks(false), seenChapters(false) {
		newAttribs = [[NSMutableDictionary alloc] init];
		segmentOffset = 0;
		el_l0 = NULL;
		el_l1 = NULL;
	}
	virtual ~MatroskaImport() {
		attributes = nil;
		newAttribs = nil;
	};
	bool ReadSegmentInfo(KaxInfo &segmentInfo);
	bool ReadTracks(KaxTracks &trackEntries);
	bool ReadChapters(KaxChapters &trackEntries);
	bool ReadAttachments(KaxAttachments &trackEntries);
	bool ReadMetaSeek(KaxSeekHead &trackEntries);

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

	bool ProcessLevel1Element();
	//void ImportCluster(KaxCluster &cluster, bool addToTrack);
	
	void iterateData();
	
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
	bool valid = true;
	int upperLevel;
	el_l0 = _aStream.FindNextID(EbmlHead::ClassInfos, ~0);
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
			goto exit;
		}
		el_l0->SkipData(_aStream, EbmlHead_Context);

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
	MatroskaImport *generatorClass = new MatroskaImport(path, attribs);
	if (!generatorClass->isValidMatroska()) {
		delete generatorClass;
		return false;
	}
	
	generatorClass->iterateData();
	
	generatorClass->copyDataOver();
	delete generatorClass;
	return true;
}

void MatroskaImport::iterateData()
{
	bool done = false;
	bool good = true;
	el_l0 = _aStream.FindNextID(KaxSegment::ClassInfos, ~0);
	if (!el_l0)
		return;		// nothing in the file
	
	segmentOffset = static_cast<KaxSegment *>(el_l0)->GetDataStart();

	while (!done && NextLevel1Element()) {
		if (EbmlId(*el_l1) == KaxCluster::ClassInfos.GlobalId) {
			// all header elements are before clusters in sane files
			done = true;
		} else
			good = ProcessLevel1Element();
		
		if (!good)
			return;
	}

#if 0
	do {
		if (EbmlId(*el_l1) == KaxCluster::ClassInfos.GlobalId) {
			int upperLevel = 0;
			EbmlElement *dummyElt = NULL;
			
			el_l1->Read(_aStream, KaxCluster::ClassInfos.Context, upperLevel, dummyElt, true);
			KaxCluster & cluster = *static_cast<KaxCluster *>(el_l1);
			
			//ImportCluster(cluster, false);
		}
	} while (NextLevel1Element());
#endif
}




bool MatroskaImport::ProcessLevel1Element()
{
	int upperLevel = 0;
	EbmlElement *dummyElt = NULL;
	
	if (EbmlId(*el_l1) == KaxInfo::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxInfo::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadSegmentInfo(*static_cast<KaxInfo *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxTracks::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxTracks::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadTracks(*static_cast<KaxTracks *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxChapters::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxChapters::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadChapters(*static_cast<KaxChapters *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxAttachments::ClassInfos.GlobalId) {
		//ComponentResult res;
		el_l1->Read(_aStream, KaxAttachments::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadAttachments(*static_cast<KaxAttachments *>(el_l1));
		//PrerollSubtitleTracks();
		//return res;
	} else if (EbmlId(*el_l1) == KaxSeekHead::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxSeekHead::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadMetaSeek(*static_cast<KaxSeekHead *>(el_l1));
	}
	return true;
}


bool MatroskaImport::ReadSegmentInfo(KaxInfo &segmentInfo)
{
	if (seenInfo)
		return true;
	
	KaxDuration & duration = GetChild<KaxDuration>(segmentInfo);
	KaxTimecodeScale & timecodeScale = GetChild<KaxTimecodeScale>(segmentInfo);
	KaxTitle & title = GetChild<KaxTitle>(segmentInfo);
	KaxDateUTC * date = FindChild<KaxDateUTC>(segmentInfo);
	KaxWritingApp & writingApp = GetChild<KaxWritingApp>(segmentInfo);
	KaxMuxingApp & muxingApp = GetChild<KaxMuxingApp>(segmentInfo);

	Float64 movieDuration = Float64(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	newAttribs[(NSString*)kMDItemDurationSeconds] = @((movieDuration * timecodeScale1) / 1e9);
	
	if (date) {
		NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:date->GetValue()];
		newAttribs[(NSString*)kMDItemRecordingDate] = createDate;
	}
	
	if (!title.IsDefaultValue()) {
		NSString *nsTitle = @(title.GetValueUTF8().c_str());
		if (![nsTitle isEqualToString:@""]) {
			newAttribs[(NSString*)kMDItemTitle] = nsTitle;
		}
	}
	
	if (!writingApp.IsDefaultValue()) {
		newAttribs[(NSString*)kMDItemCreator] = @(writingApp.GetValueUTF8().c_str());
	} else if (!muxingApp.IsDefaultValue()) {
		newAttribs[(NSString*)kMDItemCreator] = @(muxingApp.GetValueUTF8().c_str());
	}
	seenInfo = true;
	
	return true;
}

bool MatroskaImport::ReadTracks(KaxTracks &trackEntries)
{
	if (seenTracks)
		return true;
	
	NSMutableSet<NSString*> *langSet = [[NSMutableSet alloc] init];
	NSMutableSet<NSString*> *codecSet = [[NSMutableSet alloc] init];
	NSMutableArray<NSString*> *trackNames = [[NSMutableArray alloc] init];
	//Because there may be more than one video track
	uint32 biggestWidth = 0;
	uint32 biggestHeight = 0;
	int maxChannels = 0;
	double sampleRate = 0;
	
	for (int i = 0; i < trackEntries.ListSize(); i++) {
		if (EbmlId(*trackEntries[i]) != KaxTrackEntry::ClassInfos.GlobalId)
			continue;
		KaxTrackEntry & track = *static_cast<KaxTrackEntry *>(trackEntries[i]);
		//KaxTrackNumber & number = GetChild<KaxTrackNumber>(track);
		KaxTrackType & type = GetChild<KaxTrackType>(track);
		//KaxTrackDefaultDuration * defaultDuration = FindChild<KaxTrackDefaultDuration>(track);
		//KaxTrackFlagDefault & enabled = GetChild<KaxTrackFlagDefault>(track);
		//KaxTrackFlagLacing & lacing = GetChild<KaxTrackFlagLacing>(track);
		
		KaxTrackLanguage & trackLang = GetChild<KaxTrackLanguage>(track);
		KaxTrackName & trackName = GetChild<KaxTrackName>(track);
		//KaxContentEncodings * encodings = FindChild<KaxContentEncodings>(track);
		NSString *threeCharLang = @(string(trackLang).c_str());
		NSString *nsLang = CFBridgingRelease(CFLocaleCreateCanonicalLanguageIdentifierFromString(kCFAllocatorDefault, (CFStringRef)threeCharLang));
		if (nsLang && ![nsLang isEqualToString:@"und"]) {
			[langSet addObject:nsLang];
		}
		NSString *codec;
		switch (uint8(type)) {
			case track_video:
			{
				KaxTrackVideo &vidTrack = GetChild<KaxTrackVideo>(track);
				KaxVideoPixelWidth &curKaxWidth = GetChild<KaxVideoPixelWidth>(vidTrack);
				KaxVideoPixelHeight &curKaxHeight = GetChild<KaxVideoPixelHeight>(vidTrack);
				///KaxVideoColourSpace
				uint32 curWidth = uint32(curKaxWidth);
				uint32 curHeight = uint32(curKaxHeight);
				if (curWidth >= biggestWidth && curHeight >= biggestHeight) {
					biggestWidth = curWidth;
					biggestHeight = curHeight;
				}
			}
				codec = mkvCodecShortener(&track);
				if (codec) {
					[codecSet addObject:codec];
				}
				
				break;
				
			case track_audio:
			{
				KaxTrackAudio &audTrack = GetChild<KaxTrackAudio>(track);
				KaxAudioSamplingFreq &curKaxSampling = GetChild<KaxAudioSamplingFreq>(audTrack);
				KaxAudioChannels &curKaxChannels = GetChild<KaxAudioChannels>(audTrack);
				//KaxAudioBitDepth &curKaxBitDepth = GetChild<KaxAudioBitDepth>(audTrack);
				double curSampling = curKaxSampling.GetValue();
				int curChannels = (int)curKaxChannels.GetValue();
				if (curSampling > sampleRate) {
					sampleRate = curSampling;
				}
				if (curChannels > maxChannels) {
					maxChannels = curChannels;
				}
			}
				codec = mkvCodecShortener(&track);
				if (codec) {
					[codecSet addObject:codec];
				}

				break;
				
			case track_subtitle:
				//TODO: parse SSA, get font list?
				break;
				
			case track_complex:
			case track_logo:
			case track_buttons:
			case track_control:
				// not likely to be implemented soon
			default:
				continue;
		}
		
		//SetMediaLanguage(mkvTrack.theMedia, qtLang);
		
		if (!trackName.IsDefaultValue()) {
			const char *cTrackName = UTFstring(trackName).GetUTF8().c_str();
			NSString *nsTrackName = @(cTrackName);
			if (![nsTrackName isEqualToString:@""]) {
				[trackNames addObject:nsTrackName];
			}
		}
	}
	
	if (langSet.count > 0) {
		newAttribs[(NSString*)kMDItemLanguages] = langSet.allObjects;
	}
	newAttribs[(NSString*)kMDItemCodecs] = codecSet.allObjects;
	if (trackNames.count > 0) {
		newAttribs[(NSString*)kMDItemLayerNames] = [trackNames copy];
	}
	if (biggestWidth != 0 && biggestHeight != 0) {
		newAttribs[(NSString*)kMDItemPixelHeight] = @(biggestHeight);
		newAttribs[(NSString*)kMDItemPixelWidth] = @(biggestWidth);
	}
	if (maxChannels == 0) {
		newAttribs[(NSString*)kMDItemAudioChannelCount] = @(maxChannels);
		newAttribs[(NSString*)kMDItemAudioSampleRate] = @(sampleRate);
	}
	
	seenTracks = true;
	return true;
}

bool MatroskaImport::ReadChapters(KaxChapters &chapterEntries)
{
	NSMutableArray<NSString*> *chapters = [[NSMutableArray alloc] init];
	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	KaxChapterAtom *chapterAtom = FindChild<KaxChapterAtom>(edition);
	while (chapterAtom && chapterAtom->GetSize() > 0) {
		//AddChapterAtom(chapterAtom);
		KaxChapterDisplay & chapDisplay = GetChild<KaxChapterDisplay>(*chapterAtom);
		KaxChapterString & chapString = GetChild<KaxChapterString>(chapDisplay);
		[chapters addObject:@(chapString.GetValueUTF8().c_str())];

		chapterAtom = &GetNextChild<KaxChapterAtom>(edition, *chapterAtom);
	}
	
	newAttribs[kChapterNames] = [chapters copy];
	seenChapters = true;

	return true;
}

bool MatroskaImport::ReadAttachments(KaxAttachments &attachmentEntries)
{
	return true;
}

bool MatroskaImport::ReadMetaSeek(KaxSeekHead &seekHead)
{
	bool okay = true;
	KaxSeek *seekEntry = FindChild<KaxSeek>(seekHead);
	
	// don't re-read a seek head that's already been read
	uint64_t currPos = seekHead.GetElementPosition();
	vector<MatroskaSeek>::iterator itr = levelOneElements.begin();
	for (; itr != levelOneElements.end(); itr++) {
		if (itr->GetID() == KaxSeekHead::ClassInfos.GlobalId &&
			itr->segmentPos + segmentOffset == currPos)
			return true;
	}
	
	while (seekEntry && seekEntry->GetSize() > 0) {
		MatroskaSeek newSeekEntry;
		KaxSeekID & seekID = GetChild<KaxSeekID>(*seekEntry);
		KaxSeekPosition & position = GetChild<KaxSeekPosition>(*seekEntry);
		EbmlId elementID = EbmlId(seekID.GetBuffer(), seekID.GetSize());
		
		newSeekEntry.ebmlID = elementID.Value;
		newSeekEntry.idLength = elementID.Length;
		newSeekEntry.segmentPos = position;
		
		// recursively read seek heads that are pointed to by the current one
		// as well as the level one elements we care about
		if (elementID == KaxInfo::ClassInfos.GlobalId ||
			elementID == KaxTracks::ClassInfos.GlobalId ||
			elementID == KaxChapters::ClassInfos.GlobalId ||
			elementID == KaxAttachments::ClassInfos.GlobalId ||
			elementID == KaxSeekHead::ClassInfos.GlobalId) {
			
			MatroskaSeek::MatroskaSeekContext savedContext = SaveContext();
			SetContext(newSeekEntry.GetSeekContext(segmentOffset));
			if (NextLevel1Element())
				okay = ProcessLevel1Element();
			
			SetContext(savedContext);
			if (!okay) return false;
		}
		
		levelOneElements.push_back(newSeekEntry);
		seekEntry = &GetNextChild<KaxSeek>(seekHead, *seekEntry);
	}
	
	sort(levelOneElements.begin(), levelOneElements.end());
	
	return true;
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
		// Obj-C @try blocks do capture c++ exceptions when using the newer OBJ-C ABI.
		// NOT available in 32-bit Mac code only.
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

