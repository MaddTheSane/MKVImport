//
//  MatroskaMetadataImport.cpp
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#include "MatroskaMetadataImport.hpp"
#import <CoreSpotlight/CoreSpotlight.h>
#include <string>
#include <vector>
#include <iostream>
#include <functional>
#include <algorithm>
#include <unordered_set>
#include "mkvNameShortener.hpp"
#include "ParseSSA.hpp"
#include "Debugging.h"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

#define kChapterNames @"com_GitHub_MaddTheSane_ChapterNames"
#define kAttachedFiles @"com_GitHub_MaddTheSane_AttachedFiles"

static inline NSString *getLanguageCode(const string & cppLang);
static NSString *getLanguageCode(KaxTrackEntry & track);
static NSString *getLanguageCode(const KaxLanguageIETF & language);
static NSString *getLocaleCode(const KaxChapterLanguage & language, KaxChapterCountry * country=NULL);
static NSString *getLocaleCode(const KaxChapLanguageIETF * language);


void MatroskaMetadataImport::copyDataOver() {
	attributes.mediaTypes = mediaTypes.array;
	if (fonts.count != 0) {
		attributes.fontNames = [fonts.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	
	if (bpsStorage.count != 0) {
		// How we're doing this:
		// * `kMDItemTotalBitRate` is the bitrate of all the tracks.
		// * `kMDItemVideoBitRate` and `kMDItemAudioBitRate` will be the track with the highest bitrate.
		long long biggestVid = 0;
		long long biggestAud = 0;
		uint64_t all = 0;
		
		//combine the two.
		NSMutableDictionary<NSNumber*, NSArray*> *combinedDict = [[NSMutableDictionary alloc] initWithCapacity: [trackIDAndTypes count]];
		for (NSNumber *value in trackIDAndTypes) {
			NSString *bps = bpsStorage[value];
			if (!bps) {
				continue;
			}
			combinedDict[value] = @[trackIDAndTypes[value], bps];
		}
		
		for (NSArray *ourArray in [combinedDict allValues]) {
			NSNumber *trackType = ourArray[0];
			NSString *bpsStr = ourArray[1];
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
			attributes.totalBitRate = @(all);
			if (biggestVid != 0) {
				attributes.videoBitRate = @(biggestVid);
			}
			if (biggestAud != 0) {
				attributes.audioBitRate = @(biggestAud);
			}
		}
	}
}

MatroskaMetadataImport::~MatroskaMetadataImport() {
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


bool MatroskaMetadataImport::isValidMatroska(NSError * _Nullable * _Nonnull outErr)
{
	bool valid = true;
	int upperLevel;
	EbmlElement *el_l0 = _aStream.FindNextID(EBML_INFO(EbmlHead), ~0);
	if (el_l0 != NULL) {
		EbmlElement *dummyElt = NULL;
		
		el_l0->Read(_aStream, EBML_CLASS_CONTEXT(EbmlHead), upperLevel, dummyElt, true);
		
		if (EbmlId(*el_l0) != EBML_ID(EbmlHead)) {
			if (!outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Not a Matroska file", @"Not a Matroska file"), NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: @"Not a Matroska file"}];
			}
			
			valid = false;
			goto exit;
		}
		
		EbmlHead *head = static_cast<EbmlHead *>(el_l0);
		
		EDocType & docType = GetChild<EDocType>(*head);
		const std::string & cppDocType = std::string(docType);
		if (cppDocType != "matroska" && cppDocType != "webm") {
			if (!outErr) {
				NSString *theDocType = @(cppDocType.c_str());
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Unknown Matroska doctype \"%@\"", @"Unknown Matroska doctype"), theDocType], NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: [NSString stringWithFormat:@"Unknown Matroska doctype \"%@\"", theDocType]}];
			}
			
			valid = false;
			goto exit;
		}
		
		EDocTypeReadVersion & readVersion = GetChild<EDocTypeReadVersion>(*head);
		if (UInt64(readVersion) > 2) {
			if (!outErr) {
				*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: [NSString localizedStringWithFormat: NSLocalizedString(@"Matroska file too new to be read, version %lld", @"Matroska file too new to be read, version number"), UInt64(readVersion)], NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: [NSString stringWithFormat:@"Matroska file too new to be read, version %lld", UInt64(readVersion)]}];
			}
			
			valid = false;
			goto exit;
		}
		el_l0->SkipData(_aStream, EBML_CLASS_SEMCONTEXT(EbmlHead));

	} else {
		if (!outErr) {
			*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Matroska file missing EBML Head", @"Matroska file missing EBML Head"), NSURLErrorKey: fileURL, NSDebugDescriptionErrorKey: @"Matroska file missing EBML Head"}];
		}
		valid = false;
	}
	
exit:
	
	delete el_l0;
	el_l0 = NULL;
	return valid;
}

bool MatroskaMetadataImport::getMetadata(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nonnull outErr)
{
	MatroskaMetadataImport *generatorClass = new MatroskaMetadataImport(path, attribs);
	if (!generatorClass->isValidMatroska(outErr)) {
		delete generatorClass;
		return false;
	}
	
	bool isSuccessful = generatorClass->iterateData(outErr);
	if (isSuccessful) generatorClass->copyDataOver();
	
	delete generatorClass;
	return isSuccessful;
}

bool MatroskaMetadataImport::iterateData(NSError * _Nullable * _Nonnull outErr)
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

bool MatroskaMetadataImport::ProcessLevel1Element()
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
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxAttachments), upperLevel, dummyElt, true);
		return ReadAttachments(*static_cast<KaxAttachments *>(el_l1));
		
	} else if (theID == EBML_ID(KaxSeekHead)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxSeekHead), upperLevel, dummyElt, true);
		return ReadMetaSeek(*static_cast<KaxSeekHead *>(el_l1));
		
	} else if (theID == EBML_ID(KaxTags)) {
		el_l1->Read(_aStream, EBML_CLASS_CONTEXT(KaxTags), upperLevel, dummyElt, true);
		return ReadTags(*static_cast<KaxTags *>(el_l1));
		
	} else if (theID == EBML_ID(KaxCues)) {
		el_l1->SkipData(_aStream, EBML_CLASS_SEMCONTEXT(KaxCues), dummyElt, true);
		return true;
		
	}
	return true;
}

// I have no idea where this even comes from...
#define nvd "no_variable_data"

bool MatroskaMetadataImport::ReadSegmentInfo(KaxInfo &segmentInfo)
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
		attributes.identifier = theUUID.UUIDString;
	}

	double movieDuration = double(duration);
	UInt64 timecodeScale1 = UInt64(timecodeScale);

	attributes.duration = @((movieDuration * timecodeScale1) / 1e9);
	
	if (date && !date->IsDefaultValue() && date->GetValue() != 0) {
		NSDate *createDate = [[NSDate alloc] initWithTimeIntervalSince1970:date->GetValue()];
		attributes.contentCreationDate = createDate;
	}
	
	if (!title.IsDefaultValue() && title.GetValue().length() != 0) {
		NSString *nsTitle = @(title.GetValueUTF8().c_str());
		attributes.title = nsTitle;
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
			attributes.encodingApplications = creator;
		}
	}
	
	seenInfo = true;
	return true;
}

bool MatroskaMetadataImport::ReadTracks(KaxTracks &trackEntries)
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
		attributes.languages = langSet.array;
	}
	attributes.codecs = codecSet.array;
	if (trackNames.count > 0) {
		attributes.layerNames = [trackNames copy];
	}
	if (biggestWidth != 0 && biggestHeight != 0) {
		attributes.pixelHeight = @(biggestHeight);
		attributes.pixelWidth = @(biggestWidth);
	}
	if (maxChannels != 0) {
		attributes.audioChannelCount = @(maxChannels);
		attributes.audioSampleRate = @(sampleRate);
	}
	
	seenTracks = true;
	return true;
}

bool MatroskaMetadataImport::ReadChapters(KaxChapters &chapterEntries)
{
	if (seenChapters) {
		return true;
	}
	addMediaType(@"Chapters");

	NSMutableArray<CSLocalizedString*> *chapters = [[NSMutableArray alloc] init];
	
	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	KaxChapterAtom *chapterAtom = FindChild<KaxChapterAtom>(edition);
	while (chapterAtom && chapterAtom->GetSize() > 0) {
		KaxChapterDisplay * chapDisplay = FindChild<KaxChapterDisplay>(*chapterAtom);
		NSMutableDictionary *locString = [[NSMutableDictionary alloc] init];
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
			locString[chapLocale] = chapString.GetValue().length() != 0 ? @(chapString.GetValueUTF8().c_str()) : @"";

			chapDisplay = FindNextChild<KaxChapterDisplay>(*chapterAtom, *chapDisplay);
		}
		
		[chapters addObject:[[CSLocalizedString alloc] initWithLocalizedStrings:locString]];

		chapterAtom = FindNextChild<KaxChapterAtom>(edition, *chapterAtom);
	}
	
	if (chapters.count != 0) {
		CSCustomAttributeKey *attribKey = [[CSCustomAttributeKey alloc] initWithKeyName:kChapterNames searchable:YES searchableByDefault:NO unique:NO multiValued:YES];
		[attributes setValue:chapters forCustomKey:attribKey];
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
	bool success = fontTypes.contains(postString);
#else
	bool success = fontTypes.contains(mimeName);
#endif
	return success;
}

bool MatroskaMetadataImport::ReadAttachments(KaxAttachments &attachmentEntries)
{
	addMediaType(@"Attachments");
	KaxAttached *attachedFile = FindChild<KaxAttached>(attachmentEntries);
	NSMutableArray<NSString*> *attachmentFiles = [[NSMutableArray alloc] initWithCapacity:attachmentEntries.ListSize()];
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
	CSCustomAttributeKey *attribKey = [[CSCustomAttributeKey alloc] initWithKeyName:kAttachedFiles searchable:YES searchableByDefault:NO unique:NO multiValued:YES];
	[attributes setValue:attachmentFiles forCustomKey:attribKey];
	
	return true;
}

bool MatroskaMetadataImport::ReadMetaSeek(KaxSeekHead &seekHead)
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

static bool isMultiple(const std::string& spotlightKey)
{
	// ARTIST maps to kMDItemAuthors, while PUBLISHER maps to kMDItemPublishers.
	static const std::unordered_set<std::string> multiTags2 = {"ARTIST", "PUBLISHER", "MOOD"};
	return multiTags2.contains(spotlightKey);
}

static NSString * const MDItemAuthors = @"ARTIST";
static NSString * const MDItemAlbum = @"ALBUM";
static NSString * const MDItemLyricist = @"LYRICIST";
static NSString * const MDItemPublishers = @"PUBLISHER";
static NSString * const MDItemCopyright = @"COPYRIGHT";
static NSString * const MDItemDirector = @"DIRECTOR";
static NSString * const MDItemProducer = @"PRODUCER";
static NSString * const MDItemGenre = @"GENRE";
static NSString * const MDItemComment = @"COMMENT";
static NSString * const MDItemHeadline = @"SYNOPSIS";
static NSString * const MDItemTextContent = @"LYRICS";
static NSString * const MDItemAudiences = @"MOOD";
static NSString * const MDItemKeywords = @"KEYWORDS";
static NSString * const MDItemTitle = @"TITLE";

bool MatroskaMetadataImport::ReadTags(const KaxTags &trackEntries)
{
	if (seenTags) {
		return true;
	}
	NSMutableDictionary<NSString*,id>
	*tagDict = [[NSMutableDictionary alloc] init];
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
				string simpleVal = get_simple_value(*simple_tag);
				if (simpleName == "BPS") {
					bpsStorage[@(trackID.value())] = @(simpleVal.c_str());
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
			string simpleVal = get_simple_value(*simple_tag);
			NSString *objcName = @(simpleName.c_str());
			if ([tagDict objectForKey:objcName] != nil) {
				postError(mkvErrorLevelWarn, CFSTR("File already has an entry for tag %@! Possibility of multiple languages for same tag?"), objcName);
			}
			// FIXME: HACK: work around "KEYWORDS"
			if (simpleName == "KEYWORDS") {
				tagDict[objcName] = commaSeperation(@(simpleVal.c_str()));
			} else {
				if (isMultiple(simpleName)) {
					tagDict[objcName] = @[@(simpleVal.c_str())];
				} else {
					tagDict[objcName] = @(simpleVal.c_str());
				}
			}
		}
	}
	
	for (NSString *key in tagDict) {
		id theval = tagDict[key];
		if ([key isEqualToString: MDItemAuthors]) {
			attributes.authorNames = (NSArray<NSString*>*)theval;
		} else if ([key isEqualToString: MDItemAlbum]) {
			attributes.album = (NSString*)theval;
		} else if ([key isEqualToString: MDItemLyricist]) {
			attributes.lyricist = (NSString*)theval;
		} else if ([key isEqualToString: MDItemPublishers]) {
			attributes.publishers = (NSArray<NSString*>*)theval;
		} else if ([key isEqualToString: MDItemCopyright]) {
			attributes.copyright = (NSString*)theval;
		} else if ([key isEqualToString: MDItemDirector]) {
			attributes.director = (NSString*)theval;
		} else if ([key isEqualToString: MDItemProducer]) {
			attributes.producer = (NSString*)theval;
		} else if ([key isEqualToString: MDItemGenre]) {
			attributes.genre = (NSString*)theval;
		} else if ([key isEqualToString: MDItemComment]) {
			attributes.comment = (NSString*)theval;
		} else if ([key isEqualToString: MDItemHeadline]) {
			attributes.headline = (NSString*)theval;
		} else if ([key isEqualToString: MDItemTextContent]) {
			attributes.textContent = (NSString*)theval;
		} else if ([key isEqualToString: MDItemAudiences]) {
			attributes.audiences = (NSArray<NSString*>*)theval;
		} else if ([key isEqualToString: MDItemKeywords]) {
			attributes.keywords = (NSArray<NSString*>*)theval;
		} else if ([key isEqualToString:MDItemTitle]) {
			attributes.title = (NSString*)theval;
		} else {
			postError(mkvErrorLevelWarn, CFSTR("Unmapped tag %@"), key);
		}
	}
	seenTags = true;
	return true;
}

#pragma mark - Element code

EbmlElement * MatroskaMetadataImport::NextLevel1Element()
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

MatroskaMetadataImport::MatroskaSeek::MatroskaSeekContext MatroskaMetadataImport::SaveContext()
{
	MatroskaSeek::MatroskaSeekContext ret = { el_l1, _ebmlFile.getFilePointer() };
	el_l1 = NULL;
	return ret;
}

void MatroskaMetadataImport::SetContext(MatroskaSeek::MatroskaSeekContext context)
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
	if (cppLang == "und") {
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

static NSString *getLocaleCode(const KaxChapLanguageIETF * language)
{
	const string &threeLang(*language);
	NSString *locale = getLanguageCode(threeLang);
	if (!locale) {
		return nil;
	}
	locale = [NSLocale canonicalLocaleIdentifierFromString:locale];
	return locale;
}
