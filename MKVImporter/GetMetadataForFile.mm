//
//  GetMetadataForFile.m
//  MKVImporter
//
//  Created by C.W. Betts on 1/3/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <MediaToolbox/MediaToolbox.h>
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

#include "SharedImporter.h"

class MatroskaImport final {
private:
	MatroskaImport(NSURL* path, NSMutableDictionary*attribs):
	_ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)),
	_aStream(EbmlStream(_ebmlFile)),
	attributes(attribs),
	seenInfo(false), seenTracks(false), seenChapters(false), seenTags(false),
	seenAttachments(false) {
		mediaTypes = [[NSMutableOrderedSet alloc] initWithCapacity:6];
		fonts = [[NSMutableSet alloc] initWithCapacity:50];
		segmentOffset = 0;
		el_l0 = NULL;
		el_l1 = NULL;
		bpsStorage = [[NSMutableDictionary alloc] init];
		trackIDAndTypes = [[NSMutableDictionary alloc] init];
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
		attributes[(NSString*)kMDItemMediaTypes] = [mediaTypes.array copy];
		if (fonts.count != 0) {
			attributes[(NSString*)kMDItemFonts] = [fonts.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		}
		
		if (bpsStorage.count != 0) {
			// How we're doing this:
			// * `kMDItemTotalBitRate` is the bitrate of all the tracks.
			// * `kMDItemVideoBitRate` and `kMDItemAudioBitRate` will be the track with the largest number.
			long long biggestVid = 0;
			long long biggestAud = 0;
			uint64_t all = 0;
			
			for (NSNumber *key in bpsStorage) {
				NSNumber *trackType = trackIDAndTypes[key];
				NSString *bpsStr = bpsStorage[key];
				//Convert bps to a numerical value.
				long long bps = bpsStr.longLongValue;
				all += bps;
				
				// We only care about `track_video`, `track_audio`
				switch (trackType.unsignedCharValue) {
					case track_video:
						biggestVid = std::max(biggestVid, bps);
						break;
						
					case track_audio:
						biggestAud = std::max(biggestAud, bps);
						break;
						
					case track_complex:
						//Not dealing with this.
						break;
						
					case track_subtitle:
						// There's no key for subtitle BPS.
						break;
						
					default:
						break;
				}
			}
			
			if (all != 0) {
				attributes[(NSString*)kMDItemTotalBitRate] = @(all);
				if (biggestVid != 0) {
					attributes[(NSString*)kMDItemVideoBitRate] = @(biggestVid);
				}
				if (biggestAud != 0) {
					attributes[(NSString*)kMDItemAudioBitRate] = @(biggestAud);
				}
			}
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
	inline void addMediaType(NSString *theType) {
		[mediaTypes addObject:theType];
	}
	
	inline void addMediaType(CFStringRef CF_CONSUMED theType) {
		addMediaType((NSString*)CFBridgingRelease(theType));
	}
	
public:
	static bool getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSURL *path);
	
private:
	StdIOCallback _ebmlFile;
	EbmlStream _aStream;
	EbmlElement *el_l0;
	EbmlElement *el_l1;
	NSMutableDictionary<NSString*,id> *attributes;
	NSMutableOrderedSet<NSString*> *mediaTypes;
	NSMutableSet<NSString*> *fonts;
	NSMutableDictionary<NSNumber*,NSString*> *bpsStorage;
	NSMutableDictionary<NSNumber*,NSNumber*> *trackIDAndTypes;
	
	// FIXME: we're getting duplicates. This works around it, but doesn't fix it.
	bool seenInfo;
	bool seenTracks;
	bool seenChapters;
	bool seenTags;
	bool seenAttachments;

	std::vector<MatroskaSeek>	levelOneElements;
	
	uint64_t					segmentOffset;
};

bool MatroskaImport::isValidMatroska()
{
	bool valid = true;
	int upperLevel;
	el_l0 = _aStream.FindNextID(EBML_INFO(EbmlHead), ~0);
	if (el_l0 != NULL) {
		EbmlElement *dummyElt = NULL;
		
		el_l0->Read(_aStream, EBML_CLASS_CONTEXT(EbmlHead), upperLevel, dummyElt, true);
		
		if (EbmlId(*el_l0) != EBML_ID(EbmlHead)) {
			postError(mkvErrorLevelWarn, CFSTR("Not a Matroska file"));
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType & docType = GetChild<EDocType>(*head);
		const string & cppDocType = string(docType);
		if (cppDocType != "matroska" && cppDocType != "webm") {
			postError(mkvErrorLevelWarn, CFSTR("Unknown Matroska doctype \"%@\""), @(cppDocType.c_str()));
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion & readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			postError(mkvErrorLevelWarn, CFSTR("Matroska file too new to be read, version %lld"), UInt64(readVersion));
			valid = false;
			goto exit;
		}
		el_l0->SkipData(_aStream, EBML_CLASS_SEMCONTEXT(EbmlHead));

	} else {
		postError(mkvErrorLevelWarn, CFSTR("Matroska file missing EBML Head"));
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}

bool MatroskaImport::getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSURL *path)
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
	el_l0 = _aStream.FindNextID(EBML_INFO(KaxSegment), ~0);
	if (!el_l0) {
		return false;		// nothing in the file
	}
	
	segmentOffset = static_cast<KaxSegment *>(el_l0)->GetDataStart();

	while (!done && NextLevel1Element()) {
		if (EbmlId(*el_l1) == EBML_ID(KaxCluster)) {
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
		uint8_t *const theBytes = kaxUID->GetBuffer();
		CFUUIDBytes theUUIDBytes;
		memcpy(&theUUIDBytes, theBytes, sizeof(CFUUIDBytes));
		CFUUIDRef theUUID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, theUUIDBytes);
		attributes[(NSString*)kMDItemIdentifier] = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
		CFRelease(theUUID);
	}

	double movieDuration = double(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	attributes[(NSString*)kMDItemDurationSeconds] = @((movieDuration * timecodeScale1) / 1e9);
	
	if (date && !date->IsDefaultValue() && date->GetValue() != 0) {
		NSDate *createDate = [[NSDate alloc] initWithTimeIntervalSince1970:date->GetEpochDate()];
		attributes[(NSString*)kMDItemContentCreationDate] = createDate;
	}
	
	if (!title.IsDefaultValue() && title.GetValue().length() != 0) {
		NSString *nsTitle = getNSStringFromUTFstring(title);
		attributes[(NSString*)kMDItemTitle] = nsTitle;
	}
	
	{
		NSMutableArray *creator = [NSMutableArray arrayWithCapacity:2];
		if (!writingApp.IsDefaultValue() && writingApp.GetValueUTF8() != nvd) {
			[creator addObject:getNSStringFromUTFstring(writingApp)];
		}
		if (!muxingApp.IsDefaultValue() && muxingApp.GetValueUTF8() != nvd) {
			[creator addObject:getNSStringFromUTFstring(muxingApp)];
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
	
	NSMutableOrderedSet<NSString*> *langSet = [[NSMutableOrderedSet alloc] init];
	NSMutableOrderedSet<NSString*> *codecSet = [[NSMutableOrderedSet alloc] init];
	NSMutableArray<NSString*> *trackNames = [[NSMutableArray alloc] init];
	//Because there may be more than one video track
	uint32 biggestWidth = 0;
	uint32 biggestHeight = 0;
	int maxChannels = 0;
	double sampleRate = 0;
	
	for (auto trackEntry: trackEntries) {
		if (EbmlId(*trackEntry) != EBML_ID(KaxTrackEntry)) {
			continue;
		}
		KaxTrackEntry & track = *static_cast<KaxTrackEntry *>(trackEntry);
		KaxTrackType & type = GetChild<KaxTrackType>(track);
		KaxTrackUID & tuid = GetChild<KaxTrackUID>(track);
		//KaxTrackFlagLacing & lacing = GetChild<KaxTrackFlagLacing>(track);
		
		//KaxContentEncodings * encodings = FindChild<KaxContentEncodings>(track);
		trackIDAndTypes[@(tuid.GetValue())] = @(uint8(type));
		{
			NSString *nsLang = getLanguageCode(track);
			if (nsLang) {
				[langSet addObject:[NSLocale canonicalLocaleIdentifierFromString:nsLang]];
			}
		}
		{
			KaxTrackName & trackName = GetChild<KaxTrackName>(track);
			if (!trackName.IsDefaultValue() && trackName.GetValue().length() != 0) {
				NSString *nsTrackName = getNSStringFromUTFstring(trackName);
				[trackNames addObject:nsTrackName];
			}
		}
		NSString *codec;
		switch (uint8(type)) {
			case track_video:
				addMediaType(MTCopyLocalizedNameForMediaType(kCMMediaType_Video));
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
				addMediaType(MTCopyLocalizedNameForMediaType(kCMMediaType_Audio));
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
				addMediaType(MTCopyLocalizedNameForMediaType(kCMMediaType_Subtitle));
			if (isSSA(track)) {
				NSMutableSet *tmpFonts = [[NSMutableSet alloc] init];
				bool success = getSSASubtitleFontList(track, _aStream, tmpFonts);
				if (success) {
					[fonts unionSet:tmpFonts];
				}
			}
				codec = mkvCodecShortener(track);
				break;
				
			case track_complex:
				addMediaType(MTCopyLocalizedNameForMediaType(kCMMediaType_Muxed));
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
					int curChannels = uint32(curKaxChannels);
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
		attributes[(NSString*)kMDItemLanguages] = [langSet.array copy];
	}
	attributes[(NSString*)kMDItemCodecs] = [codecSet.array copy];
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

	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	NSMutableDictionary<NSString*,NSMutableArray<NSString*>*> *chapters = [[NSMutableDictionary alloc] init];
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
				chapLocale = getLocaleCode(chapIETF);
			}
			if (!chapLocale) {
				chapLocale = getLocaleCode(chapLang, chapCountry) ?: @"";
			}
			if (chapters[chapLocale] == nil) {
				chapters[chapLocale] = [[NSMutableArray alloc] initWithCapacity:edition.ListSize()];
			}
			[chapters[chapLocale] addObject:getNSStringFromUTFstring(chapString) ?: @""];
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

bool MatroskaImport::ReadAttachments(KaxAttachments &attachmentEntries)
{
	if (seenAttachments) {
		return true;
	}
	addMediaType(@"Attachments");
	KaxAttached *attachedFile = FindChild<KaxAttached>(attachmentEntries);
	NSMutableArray<NSString*> *attachmentFiles = [[NSMutableArray alloc] initWithCapacity:attachmentEntries.ListSize()];
	NSMutableArray<NSString*> *fonts = [[NSMutableArray alloc] initWithCapacity:attachmentEntries.ListSize()];
	
	while (attachedFile && attachedFile->GetSize() > 0) {
		NSString *fileName = getNSStringFromUTFstring(GetChild<KaxFileName>(*attachedFile)) ?: @"";
		const std::string mime = GetChild<KaxMimeType>(*attachedFile).GetValue();
		if (MIMEIsFont(mime)) {
			const auto &rawData = GetChild<KaxFileData>(*attachedFile);
			NSData *data = [NSData dataWithBytesNoCopy:rawData.GetBuffer() length:rawData.GetSize() freeWhenDone:NO];
			NSArray *fontArray = fontNamesFromFontData(data);
			if (fontArray) {
				[fonts addObjectsFromArray:fontArray];
			}
		}
		[attachmentFiles addObject:fileName];
		
		attachedFile = FindNextChild<KaxAttached>(attachmentEntries, *attachedFile);
	}
	if ([fonts count] > 0) {
		[this->fonts addObjectsFromArray:fonts];
	}
	attributes[kAttachedFiles] = [attachmentFiles copy];
	seenAttachments = true;
	return true;
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
		@"SHOW": (NSString*)kMDItemAlbum,
		@"SYNOPSIS": (NSString*)kMDItemHeadline,
		@"LYRICS": (NSString*)kMDItemTextContent,
		@"MOOD": (NSString*)kMDItemAudiences,
		@"KEYWORDS": (NSString*)kMDItemKeywords,
		@"TITLE": (NSString*)kMDItemTitle,
		};
	
	return matroskaToSpotlightMapping[matroskaKey];
}

bool MatroskaImport::ReadTags(const KaxTags &trackEntries)
{
	if (seenTags) {
		return true;
	}
	NSMutableDictionary<NSString*,id> *tagDict = [[NSMutableDictionary alloc] initWithCapacity:trackEntries.ListSize()];
	//trackEntries
	for (const auto child : trackEntries) {
		auto tag = dynamic_cast<const KaxTag *>(child);
		if (!tag) {
			continue;
		}

		// only get the BPS tag from track tags.
		auto trackID = get_tuid(*tag);
		if (trackID.has_value()) {
			for (auto const simple_tag_elt : *tag) {
				const auto simple_tag = dynamic_cast<KaxTagSimple *const>(simple_tag_elt);
				if (!simple_tag) {
					continue;
				}
				string simpleName = get_simple_name(*simple_tag);
				NSString *simpleVal = get_simple_value(*simple_tag);
				if (simpleName == "BPS") {
					bpsStorage[@(trackID.value())] = simpleVal;
					break;
				}
			}
			// otherwise exclude tags that refer to specific tracks...
			continue;
		}
		
		// exclude tags that refer to specific chapters
		if (get_cuid(*tag).has_value()) {
			continue;
		}

		for (auto const simple_tag_elt : *tag) {
			const auto simple_tag = dynamic_cast<KaxTagSimple *const>(simple_tag_elt);
			if (!simple_tag) {
				continue;
			}
			string simpleName = get_simple_name(*simple_tag);
			NSString *simpleVal = get_simple_value(*simple_tag);
			NSString *objcName = @(simpleName.c_str());
			if ([tagDict objectForKey:objcName] != nil) {
				postError(mkvErrorLevelWarn, CFSTR("File already has an entry for tag %@! Possibility of multiple languages for same tag?"), objcName);
			}
			if (simpleVal.length == 0) {
				continue;
			}
			// FIXME: HACK: work around "KEYWORDS"
			if (simpleName == "KEYWORDS") {
				tagDict[objcName] = commaSeperation(simpleVal);
			} else {
				if (isMultiple(simpleName)) {
					tagDict[objcName] = @[simpleVal];
				} else {
					tagDict[objcName] = simpleVal;
				}
			}
		}
	}
	
	if (tagDict.count == 0) {
		// return early.
		seenTags = true;
		return true;
	}
	
	NSMutableDictionary<NSString*,id>
	*toSet = [[NSMutableDictionary alloc] initWithCapacity:tagDict.count];
	
	for (NSString *key in tagDict) {
		id val = tagDict[key];
		NSString *MDVal = toSpotlightKey(key);
		if (!MDVal) {
			continue;
		}
		toSet[MDVal] = val;
	}
	[attributes addEntriesFromDictionary:toSet];
	seenTags = true;
	return true;
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

Boolean GetMetadataForURL(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFURLRef pathToFile)
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
		NSURL *nsPath = (__bridge NSURL*)pathToFile;
		NSString *nsUTI = (__bridge NSString*)contentTypeUTI;
		try {
			ok = MatroskaImport::getMetadata(nsAttribs, nsUTI, nsPath);
		} catch (CRTError &anErr) {
			postError(mkvErrorLevelSerious, CFSTR("Exception caught! %@"), @(anErr.what()));
			ok = FALSE;
		} catch (...) {
			postError(mkvErrorLevelSerious, CFSTR("Unknown exception!"));
			ok = FALSE;
		}
	}
	
	// Return the status
	return ok;
}

#include "SharedImporter.i"
