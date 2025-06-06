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
#include <unordered_set>
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
#include "ParseSSA.hpp"
#include "Debugging.h"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

#define kChapterNames @"com_GitHub_MaddTheSane_ChapterNames"
#define kAttachedFiles @"com_GitHub_MaddTheSane_AttachedFiles"

static NSString *getLanguageCode(const string & cppLang);
static NSString *getLanguageCode(KaxTrackEntry & track);
static NSString *getLanguageCode(const KaxLanguageIETF & language);
static NSString *getLocaleCode(const KaxChapterLanguage & language, KaxChapterCountry * country=NULL);
static NSString *getLocaleCode(const KaxChapLanguageIETF * language, KaxChapterCountry * country=NULL);

class MatroskaImport final {
private:
	MatroskaImport(NSString* path, NSMutableDictionary*attribs):
	_ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)),
	_aStream(EbmlStream(_ebmlFile)),
	attributes(attribs),
	seenInfo(false), seenTracks(false), seenChapters(false), seenTags(false) {
		mediaTypes = [[NSMutableSet alloc] initWithCapacity:6];
		fonts = [[NSMutableSet alloc] initWithCapacity:2];
		segmentOffset = 0;
		el_l0 = NULL;
		el_l1 = NULL;
	}
	virtual ~MatroskaImport() {
		attributes = nil;
		mediaTypes = nil;
		if (el_l1) {
			delete el_l1;
			el_l1 = NULL;
		}
		
		if (el_l0) {
			delete el_l0;
			el_l0 = NULL;
		}
	}
	bool ReadSegmentInfo(KaxInfo &segmentInfo);
	bool ReadTracks(KaxTracks &trackEntries);
	bool ReadChapters(KaxChapters &trackEntries);
	bool ReadAttachments(KaxAttachments &trackEntries);
	bool ReadMetaSeek(KaxSeekHead &trackEntries);
	bool ReadTags(const KaxTags &trackEntries);

	bool isValidMatroska();
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	void copyDataOver() {
		attributes[(NSString*)kMDItemMediaTypes] = mediaTypes.allObjects;
		if (fonts.count != 0) {
			attributes[(NSString*)kMDItemFonts] = [fonts.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		}
	}
	EbmlElement * NextLevel1Element();

	//! a list of level one elements and their offsets in the segment
	class MatroskaSeek final {
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
	/// This function saves `el_l1` and the current file position to the returned context
	/// and clears `el_l1` to null in preparation for a seek.
	MatroskaSeek::MatroskaSeekContext SaveContext();
	
	/// This function restores `el_l1` to what is saved in the context, deleting the current
	/// value if not null, and seeks to the specified point in the file.
	void SetContext(MatroskaSeek::MatroskaSeekContext context);

	bool ProcessLevel1Element();
	
	bool iterateData();
	void addMediaType(NSString *theType) {
		[mediaTypes addObject:theType];
	}
	
public:
	static bool getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSString *path);
	
private:
	StdIOCallback _ebmlFile;
	EbmlStream _aStream;
	EbmlElement *el_l0;
	EbmlElement *el_l1;
	NSMutableDictionary<NSString*,id> *attributes;
	NSMutableSet<NSString*> *mediaTypes;
	NSMutableSet<NSString*> *fonts;
	
	// FIXME: we're getting duplicates. This works around it, but doesn't fix it.
	bool seenInfo;
	bool seenTracks;
	bool seenChapters;
	bool seenTags;

	std::vector<MatroskaSeek>	levelOneElements;
	
	uint64_t					segmentOffset;
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
			postError(mkvErrorLevelWarn, CFSTR("Not a Matroska file"));
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType & docType = GetChild<EDocType>(*head);
		const string & cppDocType = string(docType);
		if (cppDocType != "matroska" && cppDocType != "webm") {
			postError(mkvErrorLevelWarn, CFSTR("Unknown Matroska doctype \"%s\""), cppDocType.c_str());
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion & readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			postError(mkvErrorLevelWarn, CFSTR("Matroska file too new to be read, version %lld"), UInt64(readVersion));
			valid = false;
			goto exit;
		}
		el_l0->SkipData(_aStream, EbmlHead_Context);

	} else {
		postError(mkvErrorLevelWarn, CFSTR("Matroska file missing EBML Head"));
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}

bool MatroskaImport::getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSString *path)
{
	MatroskaImport *generatorClass = new MatroskaImport(path, attribs);
	if (!generatorClass->isValidMatroska()) {
		delete generatorClass;
		return false;
	}
	
	bool isSuccessful = generatorClass->iterateData();
	if (isSuccessful) generatorClass->copyDataOver();
	
	delete generatorClass;
	return isSuccessful;
}

bool MatroskaImport::iterateData()
{
	bool done = false;
	bool good = true;
	el_l0 = _aStream.FindNextID(KaxSegment::ClassInfos, ~0);
	if (!el_l0) {
		return false;		// nothing in the file
	}
	
	segmentOffset = static_cast<KaxSegment *>(el_l0)->GetDataStart();

	while (!done && NextLevel1Element()) {
		if (EbmlId(*el_l1) == KaxCluster::ClassInfos.GlobalId) {
			// all header elements are before clusters in sane files
			done = true;
		} else {
			good = ProcessLevel1Element();
		}
		
		if (!good) {
			return false;
		}
	}
	
	return true;
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
		el_l1->Read(_aStream, KaxAttachments::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadAttachments(*static_cast<KaxAttachments *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxSeekHead::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxSeekHead::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadMetaSeek(*static_cast<KaxSeekHead *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxTags::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxTags::ClassInfos.Context, upperLevel, dummyElt, true);
		return ReadTags(*static_cast<KaxTags *>(el_l1));
		
	} else if (EbmlId(*el_l1) == KaxCues::ClassInfos.GlobalId) {
		el_l1->Read(_aStream, KaxCues::ClassInfos.Context, upperLevel, dummyElt, true);
		return true;
		
	}
	return true;
}

// I have no idea where this even comes from...
#define nvd "no_variable_data"

bool MatroskaImport::ReadSegmentInfo(KaxInfo &segmentInfo)
{
	if (seenInfo) {
		return true;
	}
	
	KaxDuration & duration = GetChild<KaxDuration>(segmentInfo);
	KaxTimecodeScale & timecodeScale = GetChild<KaxTimecodeScale>(segmentInfo);
	KaxTitle & title = GetChild<KaxTitle>(segmentInfo);
	KaxDateUTC * date = FindChild<KaxDateUTC>(segmentInfo);
	KaxWritingApp & writingApp = GetChild<KaxWritingApp>(segmentInfo);
	KaxMuxingApp & muxingApp = GetChild<KaxMuxingApp>(segmentInfo);
	KaxSegmentUID * kaxUID = FindChild<KaxSegmentUID>(segmentInfo);
	if (kaxUID && kaxUID->GetSize() == 16) {
		NSUUID *theUUID = [[NSUUID alloc] initWithUUIDBytes:kaxUID->GetBuffer()];
		attributes[(NSString*)kMDItemIdentifier] = theUUID.UUIDString;
	}

	Float64 movieDuration = Float64(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	attributes[(NSString*)kMDItemDurationSeconds] = @((movieDuration * timecodeScale1) / 1e9);
	
	if (date && !date->IsDefaultValue() && date->GetValue() != 0) {
		NSDate *createDate = [[NSDate alloc] initWithTimeIntervalSince1970:date->GetValue()];
		attributes[(NSString*)kMDItemRecordingDate] = createDate;
	}
	
	if (!title.IsDefaultValue() && title.GetValue().length() != 0) {
		NSString *nsTitle = @(title.GetValueUTF8().c_str());
		attributes[(NSString*)kMDItemTitle] = nsTitle;
	}
	
	{
		NSMutableArray *creator = [NSMutableArray arrayWithCapacity:2];
		if (!writingApp.IsDefaultValue() && writingApp.GetValueUTF8() != nvd) {
			[creator addObject:@(writingApp.GetValueUTF8().c_str())];
		}
		if (!muxingApp.IsDefaultValue() && muxingApp.GetValueUTF8() != nvd) {
			[creator addObject:@(muxingApp.GetValueUTF8().c_str())];
		}
		
		if (creator.count != 0) {
			attributes[(NSString*)kMDItemEncodingApplications] = [creator copy];
		}
	}
	
	seenInfo = true;
	return true;
}

bool MatroskaImport::ReadTracks(KaxTracks &trackEntries)
{
	if (seenTracks) {
		return true;
	}
	
	NSMutableSet<NSString*> *langSet = [[NSMutableSet alloc] init];
	NSMutableSet<NSString*> *codecSet = [[NSMutableSet alloc] init];
	NSMutableArray<NSString*> *trackNames = [[NSMutableArray alloc] init];
	//Because there may be more than one video track
	uint32 biggestWidth = 0;
	uint32 biggestHeight = 0;
	int maxChannels = 0;
	double sampleRate = 0;
	
	for (auto trackEntry: trackEntries) {
		if (EbmlId(*trackEntry) != KaxTrackEntry::ClassInfos.GlobalId) {
			continue;
		}
		KaxTrackEntry & track = *static_cast<KaxTrackEntry *>(trackEntry);
		KaxTrackType & type = GetChild<KaxTrackType>(track);
		//KaxTrackFlagLacing & lacing = GetChild<KaxTrackFlagLacing>(track);
		
		//KaxContentEncodings * encodings = FindChild<KaxContentEncodings>(track);
		{
			NSString *nsLang = getLanguageCode(track);
			if (nsLang) {
				[langSet addObject:[NSLocale canonicalLocaleIdentifierFromString:nsLang]];
			}
		}
		{
			KaxTrackName & trackName = GetChild<KaxTrackName>(track);
			if (!trackName.IsDefaultValue() && trackName.GetValue().length() != 0) {
				const string cppTrackName = trackName.GetValueUTF8();
				NSString *nsTrackName = @(cppTrackName.c_str());
				[trackNames addObject:nsTrackName];
			}
		}
		NSString *codec;
		switch (uint8(type)) {
			case track_video:
				addMediaType(@"Video");
			{
				KaxTrackVideo &vidTrack = GetChild<KaxTrackVideo>(track);
				KaxVideoPixelWidth &curKaxWidth = GetChild<KaxVideoPixelWidth>(vidTrack);
				KaxVideoPixelHeight &curKaxHeight = GetChild<KaxVideoPixelHeight>(vidTrack);
				///KaxVideoColourSpace
				uint32 curWidth = uint32(curKaxWidth);
				uint32 curHeight = uint32(curKaxHeight);
#ifdef USE_DISPLAY_SIZE
				KaxVideoDisplayWidth *dispWidth = FindChild<KaxVideoDisplayWidth>(vidTrack);
				KaxVideoDisplayHeight *dispHeight = FindChild<KaxVideoDisplayHeight>(vidTrack);
				if (dispWidth && dispWidth->GetValue() != 0) {
					curWidth = uint32(*dispWidth);
				}
				if (dispHeight && dispHeight->GetValue() != 0) {
					curHeight = uint32(*dispHeight);
				}
#endif
				if (curWidth >= biggestWidth && curHeight >= biggestHeight) {
					biggestWidth = curWidth;
					biggestHeight = curHeight;
				}
			}
				codec = mkvCodecShortener(track);
				break;
				
			case track_audio:
				addMediaType(@"Sound");
			{
				KaxTrackAudio &audTrack = GetChild<KaxTrackAudio>(track);
				KaxAudioSamplingFreq &curKaxSampling = GetChild<KaxAudioSamplingFreq>(audTrack);
				KaxAudioChannels &curKaxChannels = GetChild<KaxAudioChannels>(audTrack);
				//KaxAudioBitDepth &curKaxBitDepth = GetChild<KaxAudioBitDepth>(audTrack);
				double curSampling = curKaxSampling.GetValue();
				int curChannels = uint32(curKaxChannels);
				if (curSampling > sampleRate) {
					sampleRate = curSampling;
				}
				if (curChannels > maxChannels) {
					maxChannels = curChannels;
				}
			}
				codec = mkvCodecShortener(track);
				break;
				
			case track_subtitle:
				addMediaType(@"Subtitles");
			if (isSSA1(track) || isSSA2(track)) {
				NSMutableSet *tmpFonts = [[NSMutableSet alloc] init];
				bool success = getSubtitleFontList(track, _aStream, tmpFonts);
				if (success) {
					[fonts unionSet:tmpFonts];
				}
			}
				codec = mkvCodecShortener(track);
				break;
				
			case track_complex:
				addMediaType(@"Muxed");
			{
				KaxTrackVideo *vidTrack = FindChild<KaxTrackVideo>(track);
				if (vidTrack) {
					KaxVideoPixelWidth &curKaxWidth = GetChild<KaxVideoPixelWidth>(*vidTrack);
					KaxVideoPixelHeight &curKaxHeight = GetChild<KaxVideoPixelHeight>(*vidTrack);
					///KaxVideoColourSpace
					uint32 curWidth = uint32(curKaxWidth);
					uint32 curHeight = uint32(curKaxHeight);
#ifdef USE_DISPLAY_SIZE
					KaxVideoDisplayWidth *dispWidth = FindChild<KaxVideoDisplayWidth>(*vidTrack);
					KaxVideoDisplayHeight *dispHeight = FindChild<KaxVideoDisplayHeight>(*vidTrack);
					if (dispWidth && dispWidth->GetValue() != 0) {
						curWidth = uint32(*dispWidth);
					}
					if (dispHeight && dispHeight->GetValue() != 0) {
						curHeight = uint32(*dispHeight);
					}
#endif
					if (curWidth >= biggestWidth && curHeight >= biggestHeight) {
						biggestWidth = curWidth;
						biggestHeight = curHeight;
					}
				}
			}
			{
				KaxTrackAudio *audTrack = FindChild<KaxTrackAudio>(track);
				if (audTrack) {
					KaxAudioSamplingFreq &curKaxSampling = GetChild<KaxAudioSamplingFreq>(*audTrack);
					KaxAudioChannels &curKaxChannels = GetChild<KaxAudioChannels>(*audTrack);
					//KaxAudioBitDepth &curKaxBitDepth = GetChild<KaxAudioBitDepth>(audTrack);
					double curSampling = curKaxSampling.GetValue();
					int curChannels = uint32(curKaxChannels.GetValue());
					if (curSampling > sampleRate) {
						sampleRate = curSampling;
					}
					if (curChannels > maxChannels) {
						maxChannels = curChannels;
					}
				}
			}

				codec = mkvCodecShortener(track);
				break;
				
			case track_logo:
				addMediaType(@"Logo");
				break;
				
			case track_buttons:
				addMediaType(@"Buttons");
				break;
				
			case track_control:
				addMediaType(@"Control");
				break;
				
			default:
				break;
		}
		if (codec && codec.length != 0) {
			[codecSet addObject:codec];
		}
	}
	
	if (langSet.count > 0) {
		attributes[(NSString*)kMDItemLanguages] = langSet.allObjects;
	}
	attributes[(NSString*)kMDItemCodecs] = codecSet.allObjects;
	if (trackNames.count > 0) {
		attributes[(NSString*)kMDItemLayerNames] = [trackNames copy];
	}
	if (biggestWidth != 0 && biggestHeight != 0) {
		attributes[(NSString*)kMDItemPixelHeight] = @(biggestHeight);
		attributes[(NSString*)kMDItemPixelWidth] = @(biggestWidth);
	}
	if (maxChannels != 0) {
		attributes[(NSString*)kMDItemAudioChannelCount] = @(maxChannels);
		attributes[(NSString*)kMDItemAudioSampleRate] = @(sampleRate);
	}
	
	seenTracks = true;
	return true;
}

bool MatroskaImport::ReadChapters(KaxChapters &chapterEntries)
{
	if (seenChapters) {
		return true;
	}
	addMediaType(@"Chapters");

	NSMutableDictionary<NSString*,NSMutableArray<NSString*>*> *chapters = [[NSMutableDictionary alloc] init];
	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	KaxChapterAtom *chapterAtom = FindChild<KaxChapterAtom>(edition);
	while (chapterAtom && chapterAtom->GetSize() > 0) {
		KaxChapterDisplay * chapDisplay = FindChild<KaxChapterDisplay>(*chapterAtom);
		while (chapDisplay && chapDisplay->GetSize() > 0) {
			KaxChapterString & chapString = GetChild<KaxChapterString>(*chapDisplay);
			KaxChapterLanguage & chapLang = GetChild<KaxChapterLanguage>(*chapDisplay);
			KaxChapterCountry * chapCountry = FindChild<KaxChapterCountry>(*chapDisplay);
			KaxChapLanguageIETF * chapIETF = FindChild<KaxChapLanguageIETF>(*chapDisplay);
			NSString *chapLocale;
			if (chapIETF) {
				chapLocale = getLocaleCode(chapIETF, chapCountry);
			}
			if (!chapLocale) {
				chapLocale = getLocaleCode(chapLang, chapCountry) ?: @"";
			}
			if (![chapters objectForKey:chapLocale]) {
				chapters[chapLocale] = [[NSMutableArray alloc] init];
			}
			[chapters[chapLocale] addObject:chapString.GetValue().length() ? @(chapString.GetValueUTF8().c_str()) : @""];
			chapDisplay = FindNextChild<KaxChapterDisplay>(*chapterAtom, *chapDisplay);
		}

		chapterAtom = FindNextChild<KaxChapterAtom>(edition, *chapterAtom);
	}
	
	if (chapters.count == 1 && ([chapters.allKeys.firstObject isEqualToString:@"en"] || [chapters.allKeys.firstObject isEqualToString:@""])) {
		attributes[kChapterNames] = [[NSArray alloc] initWithArray:chapters[chapters.allKeys.firstObject] copyItems:YES];
	} else {
		attributes[kChapterNames] = [[NSDictionary alloc] initWithDictionary:chapters copyItems:YES];
	}
	seenChapters = true;

	return true;
}

static bool MIMEIsFont(const string &mimeName) {
	static const std::unordered_set<std::string> fontTypes =
	{"application/x-font-truetype", "application/x-font-opentype", "font/opentype",
		"font/truetype", "application/font-sfnt", "application/vnd.ms-opentype",
		"application/x-font-ttf", "application/x-truetype-font"};
	
#ifdef USE_STRICT_CASING
	NSString *preName = @(mimeName.c_str());
	preName = [preName lowercaseString];
	string postString = string(preName.UTF8String);
	auto idx = fontTypes.find(postString);
#else
	auto idx = fontTypes.find(mimeName);
#endif
	bool success = (idx != fontTypes.end());
	return success;
}

bool MatroskaImport::ReadAttachments(KaxAttachments &attachmentEntries)
{
	addMediaType(@"Attachments");
	KaxAttached *attachedFile = FindChild<KaxAttached>(attachmentEntries);
	NSMutableArray<NSString*> *attachmentFiles = [[NSMutableArray alloc] init];
	NSMutableArray<NSString*> *fonts = [[NSMutableArray alloc] init];
	
	while (attachedFile && attachedFile->GetSize() > 0) {
		const std::string fileName = GetChild<KaxFileName>(*attachedFile).GetValueUTF8();
		const std::string mime = GetChild<KaxMimeType>(*attachedFile).GetValue();
		if (MIMEIsFont(mime)) {
			const auto &rawData = GetChild<KaxFileData>(*attachedFile);
			NSData *data = [NSData dataWithBytesNoCopy:rawData.GetBuffer() length:rawData.GetSize() freeWhenDone:NO];
			NSArray *fontArray = fontNamesFromFontData(data);
			if (fontArray) {
				[fonts addObjectsFromArray:fontArray];
			}
		}
		[attachmentFiles addObject:@(fileName.c_str())];
		
		attachedFile = FindNextChild<KaxAttached>(attachmentEntries, *attachedFile);
	}
	if ([fonts count] > 0) {
		[this->fonts addObjectsFromArray:fonts];
	}
	attributes[kAttachedFiles] = [attachmentFiles copy];
	return true;
}

bool MatroskaImport::ReadMetaSeek(KaxSeekHead &seekHead)
{
	bool okay = true;
	KaxSeek *seekEntry = FindChild<KaxSeek>(seekHead);
	
	// don't re-read a seek head that's already been read
	uint64_t currPos = seekHead.GetElementPosition();
	std::vector<MatroskaSeek>::iterator itr = levelOneElements.begin();
	for (; itr != levelOneElements.end(); itr++) {
		if (itr->GetID() == KaxSeekHead::ClassInfos.GlobalId &&
			itr->segmentPos + segmentOffset == currPos) {
			return true;
		}
	}
	
	while (seekEntry && seekEntry->GetSize() > 0) {
		MatroskaSeek newSeekEntry;
		KaxSeekID & seekID = GetChild<KaxSeekID>(*seekEntry);
		KaxSeekPosition & position = GetChild<KaxSeekPosition>(*seekEntry);
		EbmlId elementID = EbmlId(seekID.GetBuffer(), (unsigned int)seekID.GetSize());
		
		newSeekEntry.ebmlID = elementID.Value;
		newSeekEntry.idLength = elementID.Length;
		newSeekEntry.segmentPos = position;
		
		// recursively read seek heads that are pointed to by the current one
		// as well as the level one elements we care about
		if (elementID == KaxInfo::ClassInfos.GlobalId ||
			elementID == KaxTracks::ClassInfos.GlobalId ||
			elementID == KaxChapters::ClassInfos.GlobalId ||
			elementID == KaxAttachments::ClassInfos.GlobalId ||
			elementID == KaxSeekHead::ClassInfos.GlobalId ||
			elementID == KaxTags::ClassInfos.GlobalId ||
			elementID == KaxCues::ClassInfos.GlobalId) {
			
			MatroskaSeek::MatroskaSeekContext savedContext = SaveContext();
			SetContext(newSeekEntry.GetSeekContext(segmentOffset));
			if (NextLevel1Element()) @autoreleasepool {
				okay = ProcessLevel1Element();
			}
			
			SetContext(savedContext);
			if (!okay) {
				return false;
			}
		}
		
		levelOneElements.push_back(newSeekEntry);
		seekEntry = FindNextChild<KaxSeek>(seekHead, *seekEntry);
	}
	
	sort(levelOneElements.begin(), levelOneElements.end());
	
	return true;
}

template <typename T>
T *
FindChild(libebml::EbmlMaster const &m) {
	return static_cast<T *>(m.FindFirstElt(EBML_INFO(T)));
}

template <typename T>
T *
FindChild(libebml::EbmlElement const &e) {
	auto &m = dynamic_cast<libebml::EbmlMaster const &>(e);
	return static_cast<T *>(m.FindFirstElt(EBML_INFO(T)));
}

template <typename A> A*
FindChild(libebml::EbmlMaster const *m) {
	return static_cast<A *>(m->FindFirstElt(EBML_INFO(A)));
}

template <typename A> A*
FindChild(libebml::EbmlElement const *e) {
	auto m = dynamic_cast<libebml::EbmlMaster const *>(e);
	assert(m);
	return static_cast<A *>(m->FindFirstElt(EBML_INFO(A)));
}

static std::string get_simple_name(const KaxTagSimple &tag)
{
	const KaxTagName *tname = FindChild<KaxTagName>(tag);
	return tname ? tname->GetValueUTF8() : "";
}

static std::string get_simple_value(const KaxTagSimple &tag)
{
	const KaxTagString *tstring = FindChild<KaxTagString>(tag);
	return tstring ? tstring->GetValueUTF8() : "";
}
//KaxTagLangue
static std::string get_simple_language(const KaxTagSimple &tag)
{
	KaxTagLanguageIETF *tlanguage = FindChild<KaxTagLanguageIETF>(tag);
	KaxTagLangue *tlang = FindChild<KaxTagLangue>(tag);
	if (tlanguage) {
		return tlanguage->GetValue();
	}
	if (tlang) {
		return tlang->GetValue();
	}
	
	return "";
}

static int64_t get_tuid(const KaxTag &tag)
{
	auto targets = FindChild<KaxTagTargets>(&tag);
	if (!targets) {
		return -1;
	}
	
	auto tuid = FindChild<KaxTagTrackUID>(targets);
	if (!tuid) {
		return -1;
	}
	
	return tuid->GetValue();
}

static int64_t get_cuid(const KaxTag &tag)
{
	auto targets = FindChild<KaxTagTargets>(&tag);
	if (!targets) {
		return -1;
	}
	
	auto cuid = FindChild<KaxTagChapterUID>(targets);
	if (!cuid) {
		return -1;
	}
	
	return cuid->GetValue();
}

static bool isMultiple(const std::string& spotlightKey)
{
	// ARTIST maps to kMDItemAuthors, while PUBLISHER maps to kMDItemPublishers.
	static const std::unordered_set<std::string> multiTags2 = {"ARTIST", "PUBLISHER"};
	if (multiTags2.find(spotlightKey) != multiTags2.end()) {
		return true;
	}
	return false;
}

static NSString *toSpotlightKey(NSString *matroskaKey)
{
	static NSDictionary *const matroskaToSpotlightMapping
	= @{
		@"ARTIST": (NSString*)kMDItemAuthors,
		@"ALBUM": (NSString*)kMDItemAlbum,
		@"LYRICIST": (NSString*)kMDItemLyricist,
		@"PUBLISHER": (NSString*)kMDItemPublishers,
		@"COPYRIGHT": (NSString*)kMDItemCopyright,
		@"DIRECTOR": (NSString*)kMDItemDirector,
		@"PRODUCER": (NSString*)kMDItemProducer,
		@"GENRE": (NSString*)kMDItemGenre,
		@"COMMENT": (NSString*)kMDItemComment,
		@"SHOW": (NSString*)kMDItemAlbum
		};
	
	return matroskaToSpotlightMapping[matroskaKey];
}

static NSDictionary<NSString*,id> *trimLocales(NSDictionary<NSString*,NSDictionary<NSString*,id>*>*);

bool MatroskaImport::ReadTags(const KaxTags &trackEntries)
{
	if (seenTags) {
		return true;
	}
	NSMutableDictionary<NSString*,NSMutableDictionary<NSString*,id>*>
	*tagDict = [[NSMutableDictionary alloc] init];
	//trackEntries
	for (const auto child : trackEntries) {
		auto tag = dynamic_cast<const KaxTag *>(child);
		if (!tag) {
			continue;
		}

		// exclude tags that refer to specific tracks...
		if (get_tuid(*tag) != -1) {
			continue;
		}
		
		// ...or chapters
		if (get_cuid(*tag) != -1) {
			continue;
		}

		for (auto const simple_tag_elt : *tag) {
			const auto simple_tag = dynamic_cast<KaxTagSimple *const>(simple_tag_elt);
			if (!simple_tag) {
				continue;
			}
			string lang = get_simple_language(*simple_tag);
			NSString *nsLang = getLanguageCode(lang) ?: @"";
			if ([nsLang length] != 0) {
				nsLang = [NSLocale canonicalLocaleIdentifierFromString:nsLang];
			}
			if (!tagDict[nsLang]) {
				tagDict[nsLang] = [[NSMutableDictionary alloc] init];
			}
			string simpleName = get_simple_name(*simple_tag);
			string simpleVal = get_simple_value(*simple_tag);
			if (isMultiple(simpleName)) {
				tagDict[nsLang][@(simpleName.c_str())] = @[@(simpleVal.c_str())];
			} else {
				tagDict[nsLang][@(simpleName.c_str())] = @(simpleVal.c_str());
			}
		}
	}
	
	NSMutableDictionary<NSString*,NSMutableDictionary<NSString*,id>*>
	*toSet = [[NSMutableDictionary alloc] init];
	
	for (NSString *lang in tagDict) {
		auto subLangDict = tagDict[lang];
		for (NSString *key in subLangDict) {
			id val = subLangDict[key];
			NSString *MDVal = toSpotlightKey(key);
			if (!MDVal) {
				continue;
			}
			if (!toSet[MDVal]) {
				toSet[MDVal] = [[NSMutableDictionary alloc] init];
			}
			toSet[MDVal][lang] = val;
		}
		
	}
	NSDictionary *copyDict = trimLocales(toSet);
	[attributes addEntriesFromDictionary:copyDict];
	seenTags = true;
	return true;
}


NSDictionary<NSString*,id> *trimLocales(NSDictionary<NSString*, NSDictionary<NSString*, id>*>* toSet) {
	NSMutableDictionary *newDict = [[NSMutableDictionary alloc] initWithCapacity:toSet.count];
	for (NSString *mdKey in toSet) {
		NSDictionary<NSString*,id> *langDict = toSet[mdKey];
		if (langDict.count == 1) {
			newDict[mdKey] = [langDict[langDict.allKeys.firstObject] copy];
		} else {
			newDict[mdKey] = [[NSDictionary alloc] initWithDictionary:langDict copyItems:YES];
		}
	}
	return newDict;
}

#pragma mark -

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
	static dispatch_once_t onceToken;
	Boolean ok = FALSE;
	dispatch_once(&onceToken, ^{
		matroska_init();
		atexit_b(^{
			matroska_done();
		});
	});
	@autoreleasepool {
		auto nsAttribs = (__bridge NSMutableDictionary<NSString*,id>*)attributes;
		NSString *nsPath = (__bridge NSString*)pathToFile;
		NSString *nsUTI = (__bridge NSString*)contentTypeUTI;
		try {
			ok = MatroskaImport::getMetadata(nsAttribs, nsUTI, nsPath);
		} catch (CRTError anErr) {
			postError(mkvErrorLevelSerious, CFSTR("Exception caught! %s"), anErr.what());
			ok = FALSE;
		} catch (...) {
			postError(mkvErrorLevelSerious, CFSTR("Unknown exception!"));
			ok = FALSE;
		}
	}
	
	// Return the status
	return ok;
}

#pragma mark - Element code

EbmlElement * MatroskaImport::NextLevel1Element()
{
	int upperLevel = 0;
	
	if (el_l1) {
		el_l1->SkipData(_aStream, el_l1->Generic().Context);
		delete el_l1;
		el_l1 = NULL;
	}
	
	el_l1 = _aStream.FindNextElement(el_l0->Generic().Context, upperLevel, ~0, true);
	
	// dummy element -> probably corrupt file, search for next element in meta seek and continue from there
	if (el_l1 && el_l1->IsDummy()) {
		std::vector<MatroskaSeek>::iterator nextElt;
		MatroskaSeek currElt;
		currElt.segmentPos = el_l1->GetElementPosition();
		currElt.idLength = currElt.ebmlID = 0;
		
		nextElt = find_if(levelOneElements.begin(), levelOneElements.end(), bind(std::greater<MatroskaSeek>(), std::placeholders::_1, currElt));
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
	if (el_l1) {
		delete el_l1;
	}
	
	el_l1 = context.el_l1;
	_ebmlFile.setFilePointer(context.position);
}

#pragma mark -

static NSString *getLanguageCode(const string & cppLang)
{
	if (cppLang == "und") {
		return nil;
	}
	NSString *threeCharLang = @(cppLang.c_str());
	return threeCharLang;
}

static NSString *getLanguageCode(KaxTrackEntry & track)
{
	const KaxLanguageIETF * ietfLang = FindChild<KaxLanguageIETF>(track);
	if (ietfLang) {
		NSString *toRet = getLanguageCode(*ietfLang);
		if (toRet) {
			return toRet;
		}
	}
	const KaxTrackLanguage & trackLang = GetChild<KaxTrackLanguage>(track);
	const string &cppLang(trackLang);
	return getLanguageCode(cppLang);
}

static NSString *getLanguageCode(const KaxLanguageIETF & language)
{
	const string &threeLang(language);
	NSString *locale = getLanguageCode(threeLang);
	if (!locale) {
		return nil;
	}
	return locale;
}

static NSString *getLocaleCode(const KaxChapterLanguage & language, KaxChapterCountry * country)
{
	const string &threeLang(language);
	NSString *locale = getLanguageCode(threeLang);
	if (!locale) {
		return nil;
	}
	if (country) {
		string theCountry(*country);
		if (theCountry.length() == 0) {
			return locale;
		}
		locale = [locale stringByAppendingFormat:@"_%s", theCountry.c_str()];
	}
	locale = [NSLocale canonicalLocaleIdentifierFromString:locale];
	return locale;
}

static NSString *getLocaleCode(const KaxChapLanguageIETF * language, KaxChapterCountry * country)
{
	const string &threeLang(*language);
	NSString *locale = getLanguageCode(threeLang);
	if (!locale) {
		return nil;
	}
	if (country) {
		string theCountry(*country);
		if (theCountry.length() == 0) {
			return locale;
		}
		locale = [locale stringByAppendingFormat:@"_%s", theCountry.c_str()];
	}
	locale = [NSLocale canonicalLocaleIdentifierFromString:locale];
	return locale;
}
