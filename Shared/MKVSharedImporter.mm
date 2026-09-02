//
//  MKVSharedImporter.mm
//  MKVImporter
//
//  Created by C.W. Betts on 8/8/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <MediaToolbox/MediaToolbox.h>
#include "GetMetadataForFile.h"
#include "matroska/FileKax.h"
#include "ebml/StdIOCallback.h"
#include "MKVSharedImporter.hpp"

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

// I have no idea where this even comes from...
#define nvd "no_variable_data"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

static inline NSString *getLanguageCode(const string & cppLang);
static NSString *getLanguageCode(KaxTrackEntry & track);
static inline NSString *getLanguageCode(const KaxLanguageIETF & language);
static bool MIMEIsFont(const string &mimeName);
static std::string get_simple_name(const KaxTagSimple &tag);
static NSString *get_simple_value(const KaxTagSimple &tag);

/// If a Matroska tag is mapped to a Spotlight entry that has multiple values (an array).
static bool isMultipleTag(const std::string& spotlightKey);

/// Returns the track ID of the specified tag, if any.
///
/// Currently, we only care about track IDs for getting BPS info, otherwise we skip if this returns a value.
/// @returns The track numerical ID linked to the tag, or `std::nullopt` if there isn't one.
static std::optional<uint64_t> get_tuid(const KaxTag &tag);

/// Returns the chapter ID of the specified tag, if any.
/// @returns The chapter numerical ID linked to the tag, or `std::nullopt` if there isn't one.
static std::optional<uint64_t> get_cuid(const KaxTag &tag);

template <typename T>
const T *
FindChild(libebml::EbmlMaster const &m) {
	return static_cast<const T *>(m.FindFirstElt(EBML_INFO(T)));
}

template <typename T>
const T *
FindChild(libebml::EbmlElement const &e) {
	auto &m = dynamic_cast<libebml::EbmlMaster const &>(e);
	return static_cast<const T *>(m.FindFirstElt(EBML_INFO(T)));
}

template <typename A> const A*
FindChild(libebml::EbmlMaster const *m) {
	return static_cast<const A *>(m->FindFirstElt(EBML_INFO(A)));
}

template <typename A> const A*
FindChild(libebml::EbmlElement const *e) {
	auto m = dynamic_cast<libebml::EbmlMaster const *>(e);
	assert(m);
	return static_cast<const A *>(m->FindFirstElt(EBML_INFO(A)));
}

MatroskaSharedImporter::MatroskaSharedImporter(NSURL* path):
_ebmlFile(StdIOCallback(path.fileSystemRepresentation, MODE_READ)),
_aStream(EbmlStream(_ebmlFile)),
fileURL(path),
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

MatroskaSharedImporter::~MatroskaSharedImporter() {
	if (el_l1) {
		delete el_l1;
		el_l1 = NULL;
	}
	
	if (el_l0) {
		delete el_l0;
		el_l0 = NULL;
	}
}

bool MatroskaSharedImporter::isValidMatroska(NSError * _Nullable * _Nonnull outErr)
{
	bool valid = true;
	int upperLevel;
	EbmlElement *el_l0 = _aStream.FindNextID(EBML_INFO(EbmlHead), ~0);
	if (el_l0 != NULL) {
		EbmlElement *dummyElt = NULL;
		
		el_l0->Read(_aStream, EBML_CLASS_CONTEXT(EbmlHead), upperLevel, dummyElt, true);
		if (dummyElt) {
			// prevent a memory leak.
			delete dummyElt;
			dummyElt = NULL;
		}
		
		if (EbmlId(*el_l0) != EBML_ID(EbmlHead)) {
			if (outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not a Matroska file", @"Not a Matroska file"), NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: @"Not a Matroska file"}];
			}
			
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType & docType = GetChild<EDocType>(*head);
		const std::string & cppDocType = std::string(docType);
		if (cppDocType != "matroska" && cppDocType != "webm") {
			if (outErr) {
				NSString *theDocType = @(cppDocType.c_str());
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Unknown Matroska doctype \"%@\"", @"Unknown Matroska doctype"), theDocType], NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: [NSString stringWithFormat:@"Unknown Matroska doctype \"%@\"", theDocType]}];
			}
			
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion & readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			if (outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Matroska file too new to be read, version %lld", @"Matroska file too new to be read, version number"), UInt64(readVersion)], NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: [NSString stringWithFormat:@"Matroska file too new to be read, version %lld", UInt64(readVersion)]}];
			}
			
			valid = false;
			goto exit;
		}
		el_l0->SkipData(_aStream, EBML_CLASS_SEMCONTEXT(EbmlHead));

	} else {
		if (outErr) {
			*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Matroska file missing EBML Head", @"Matroska file missing EBML Head"), NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: @"Matroska file missing EBML Head"}];
		}
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}

bool MatroskaSharedImporter::iterateData(NSError * _Nullable * _Nullable outErr)
{
	bool done = false;
	bool good = true;
	el_l0 = _aStream.FindNextID(EBML_INFO(KaxSegment), ~0);
	if (!el_l0) {
		if (outErr) {
			*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSURLErrorKey: fileURL, NSLocalizedDescriptionKey: NSLocalizedString(@"Matroska file is empty", @"Matroska file is empty"), NSDebugDescriptionErrorKey: @"Matroska file is empty"}];
		}
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

bool MatroskaSharedImporter::ProcessLevel1Element()
{
	int upperLevel = 0;
	EbmlElement *dummyElt = NULL;
	const EbmlId theID(*el_l1);
	
	if (theID == EBML_ID(KaxInfo)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxInfo), upperLevel, dummyElt, true);
		return ReadSegmentInfo(*static_cast<KaxInfo *>(el_l1));
		
	} else if (theID == EBML_ID(KaxTracks)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxTracks), upperLevel, dummyElt, true);
		return ReadTracks(*static_cast<KaxTracks *>(el_l1));
		
	} else if (theID == EBML_ID(KaxChapters)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxChapters), upperLevel, dummyElt, true);
		return ReadChapters(*static_cast<KaxChapters *>(el_l1));
		
	} else if (theID == EBML_ID(KaxAttachments)) {
		// As attachments can be fairly large, don't read them again.
		if (seenAttachments) {
			el_l1->SkipData(_aStream, EBML_CLASS_CONTEXT(KaxAttachments), dummyElt, true);
			return true;
		}
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxAttachments), upperLevel, dummyElt, true);
		return ReadAttachments(*static_cast<KaxAttachments *>(el_l1));
		
	} else if (theID == EBML_ID(KaxSeekHead)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxSeekHead), upperLevel, dummyElt, true);
		return ReadMetaSeek(*static_cast<KaxSeekHead *>(el_l1));
		
	} else if (theID == EBML_ID(KaxTags)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxTags), upperLevel, dummyElt, true);
		return ReadTags(*static_cast<KaxTags *>(el_l1));
		
	} else if (theID == EBML_ID(KaxCues)) {
		el_l1->SkipData(_aStream, EBML_CLASS_CONTEXT(KaxCues), dummyElt, true);
		return true;
		
	}
	return true;
}

bool MatroskaSharedImporter::ReadSegmentInfo(KaxInfo &segmentInfo)
{
	if (seenInfo) {
		return true;
	}
	
	KaxDuration & duration = GetChild<KaxDuration>(segmentInfo);
	KaxTimecodeScale & timecodeScale = GetChild<KaxTimecodeScale>(segmentInfo);
	KaxTitle * title = FindChild<KaxTitle>(segmentInfo);
	KaxDateUTC * date = FindChild<KaxDateUTC>(segmentInfo);
	KaxWritingApp & writingApp = GetChild<KaxWritingApp>(segmentInfo);
	KaxMuxingApp & muxingApp = GetChild<KaxMuxingApp>(segmentInfo);
	KaxSegmentUID * kaxUID = FindChild<KaxSegmentUID>(segmentInfo);
	if (kaxUID && kaxUID->GetSize() == 16) {
		NSUUID *theUUID = [[NSUUID alloc] initWithUUIDBytes:kaxUID->GetBuffer()];
		pushIdentifier(theUUID.UUIDString);
	}

	double movieDuration = double(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	pushDuration(@((movieDuration * timecodeScale1) / 1e9));
	
	if (date && !date->IsDefaultValue() && date->GetValue() != 0) {
		NSDate *createDate = [[NSDate alloc] initWithTimeIntervalSince1970:date->GetEpochDate()];
		pushCreationDate(createDate);
	}
	
	//Using GetValueUTF8() here to prevent a costly copy of UTFstring
	if (title && !title->IsDefaultValue() && title->GetValueUTF8().length() != 0) {
		NSString *nsTitle = getNSStringFromUTFstring(*title);
		pushTitle(nsTitle);
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
			pushEncodingApplications(creator);
		}
	}
	
	seenInfo = true;
	return true;
}

bool MatroskaSharedImporter::ReadTracks(KaxTracks &trackEntries)
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
			KaxTrackName * trackName = FindChild<KaxTrackName>(track);
			//Using GetValueUTF8() here to prevent a costly copy of UTFstring
			if (trackName && !trackName->IsDefaultValue() && trackName->GetValueUTF8().length() != 0) {
				NSString *nsTrackName = getNSStringFromUTFstring(*trackName);
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
				double curSampling(curKaxSampling);
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
		pushLanguages(langSet.array);
	}
	pushCodecs(codecSet.array);
	if (trackNames.count > 0) {
		pushLayerNames(trackNames);
	}
	if (biggestWidth != 0 && biggestHeight != 0) {
		pushWidthAndHeight(@(biggestWidth), @(biggestHeight));
	}
	if (maxChannels != 0) {
		pushAudioInfo(@(maxChannels), @(sampleRate));
	}
	
	seenTracks = true;
	return true;
}

bool MatroskaSharedImporter::ReadChapters(KaxChapters &chapterEntries)
{
	if (seenChapters) {
		return true;
	}
	addMediaType(@"Chapters");
	
#ifdef EXAMPLE_CHAPTER_INDEXER
	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	NSMutableArray<NSDictionary<NSString*,NSString*>*> *chapters = [[NSMutableArray alloc] initWithCapacity:edition.ListSize()];
	KaxChapterAtom *chapterAtom = FindChild<KaxChapterAtom>(edition);
	while (chapterAtom && chapterAtom->GetSize() > 0) {
		KaxChapterDisplay * chapDisplay = FindChild<KaxChapterDisplay>(*chapterAtom);
		NSMutableDictionary *locString = [[NSMutableDictionary alloc] initWithCapacity:chapDisplay ? chapDisplay->ListSize() : 0];
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
				chapLocale = getLocaleCode(chapLang, chapCountry) ?: @"und";
			}
			locString[chapLocale] = getNSStringFromUTFstring(chapString) ?: @"";

			chapDisplay = FindNextChild<KaxChapterDisplay>(*chapterAtom, *chapDisplay);
		}
		
		[chapters addObject:locString];

		chapterAtom = FindNextChild<KaxChapterAtom>(edition, *chapterAtom);
	}
	
	if (chapters.count != 0) {
#warning implement for your plug-in!
		postError(mkvErrorLevelWarn, CFSTR("Incomplete Metadata fetch found chapters %@ from the file at %@"), chapters, fileURL.path);
	}
	
#else
	postError(mkvErrorLevelSerious, CFSTR("MatroskaSharedImporter::ReadChapters was called directly. This should not happen, as subclasses should implement their own version!"));
#endif
	
	seenChapters = true;
	return true;
}

bool MatroskaSharedImporter::ReadAttachments(KaxAttachments &attachmentEntries)
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
	pushAttachedFiles(attachmentFiles);
	seenAttachments = true;
	return true;
}

bool MatroskaSharedImporter::ReadMetaSeek(KaxSeekHead &seekHead)
{
	bool okay = true;
	KaxSeek *seekEntry = FindChild<KaxSeek>(seekHead);
	
	// don't re-read a seek head that's already been read
	uint64_t currPos = seekHead.GetElementPosition();
	std::vector<MatroskaSeek>::iterator itr = levelOneElements.begin();
	for (; itr != levelOneElements.end(); itr++) {
		if (itr->GetID() == EBML_ID(KaxSeekHead) &&
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
		if (elementID == EBML_ID(KaxInfo) ||
			elementID == EBML_ID(KaxTracks) ||
			elementID == EBML_ID(KaxChapters) ||
			elementID == EBML_ID(KaxAttachments) ||
			elementID == EBML_ID(KaxSeekHead) ||
			elementID == EBML_ID(KaxTags) ||
			elementID == EBML_ID(KaxCues)) {
			
			MatroskaSeek::MatroskaSeekContext savedContext = SaveContext();
			SetContext(newSeekEntry.GetSeekContext(segmentOffset));
			if (NextLevel1Element()) {
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

bool MatroskaSharedImporter::ReadTags(const KaxTags &trackEntries)
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
				if (isMultipleTag(simpleName)) {
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
	
	pushTags(tagDict);
	
	seenTags = true;
	return true;
}

#pragma mark - Element code

EbmlElement * MatroskaSharedImporter::NextLevel1Element()
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

MatroskaSharedImporter::MatroskaSeek::MatroskaSeekContext MatroskaSharedImporter::SaveContext()
{
	MatroskaSeek::MatroskaSeekContext ret = { el_l1, _ebmlFile.getFilePointer() };
	el_l1 = NULL;
	return ret;
}

void MatroskaSharedImporter::SetContext(MatroskaSeek::MatroskaSeekContext context)
{
	if (el_l1) {
		delete el_l1;
	}
	
	el_l1 = context.el_l1;
	_ebmlFile.setFilePointer(context.position);
}

#pragma mark -

static inline NSString *getLanguageCode(const string & cppLang)
{
	if (cppLang == "und" || cppLang == "") {
		return nil;
	}
	return @(cppLang.c_str());
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
	return getLanguageCode(threeLang);
}

NSString *getLocaleCode(const KaxChapterLanguage & language, KaxChapterCountry * country)
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

NSString *getLocaleCode(const KaxChapLanguageIETF * language)
{
	const string &threeLang(*language);
	NSString *locale = getLanguageCode(threeLang);
	if (!locale) {
		return nil;
	}
	locale = [NSLocale canonicalLocaleIdentifierFromString:locale];
	return locale;
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
	bool success = fontTypes.contains(postString);
#else
	bool success = fontTypes.contains(mimeName);
#endif
	return success;
}

static std::string get_simple_name(const KaxTagSimple &tag)
{
	const KaxTagName *tname = FindChild<KaxTagName>(tag);
	return tname ? tname->GetValueUTF8() : "";
}

static NSString *get_simple_value(const KaxTagSimple &tag)
{
	const KaxTagString *tstring = FindChild<KaxTagString>(tag);
	return tstring ? getNSStringFromUTFstring(*tstring) : @"";
}

static std::optional<uint64_t> get_tuid(const KaxTag &tag)
{
	auto targets = FindChild<KaxTagTargets>(&tag);
	if (!targets) {
		return std::nullopt;
	}
	
	auto tuid = FindChild<KaxTagTrackUID>(targets);
	if (!tuid) {
		return std::nullopt;
	}
	
	return tuid->GetValue();
}

static std::optional<uint64_t> get_cuid(const KaxTag &tag)
{
	auto targets = FindChild<KaxTagTargets>(&tag);
	if (!targets) {
		return std::nullopt;
	}
	
	auto cuid = FindChild<KaxTagChapterUID>(targets);
	if (!cuid) {
		return std::nullopt;
	}
	
	return cuid->GetValue();
}

static bool isMultipleTag(const std::string& spotlightKey)
{
	// ARTIST maps to kMDItemAuthors, while PUBLISHER maps to kMDItemPublishers.
	static const std::unordered_set<std::string> multiTags2 = {"ARTIST", "PUBLISHER", "MOOD"};
	return multiTags2.contains(spotlightKey);
}
