//
//  MatroskaExtensionMetadataImporter.cpp
//  MKVNewImporter
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#include "MatroskaExtensionMetadataImporter.hpp"
#import <CoreSpotlight/CoreSpotlight.h>
#include <MediaToolbox/MediaToolbox.h>
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

MatroskaExtensionMetadataImporter::MatroskaExtensionMetadataImporter(NSURL* _Nonnull path,
											   CSSearchableItemAttributeSet* _Nonnull attribs):
MatroskaSharedImporter(path),
attributes(attribs) {}

void MatroskaExtensionMetadataImporter::copyDataOver() {
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
		
		for (NSNumber *key in bpsStorage) {
			NSNumber *trackType = trackIDAndTypes[key];
			NSString *bpsStr = bpsStorage[key];
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

bool MatroskaExtensionMetadataImporter::getMetadata(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nullable outErr)
{
	MatroskaExtensionMetadataImporter *generatorClass = new MatroskaExtensionMetadataImporter(path, attribs);
	if (!generatorClass->isValidMatroska(outErr)) {
		delete generatorClass;
		return false;
	}
	
	bool isSuccessful = generatorClass->iterateData(outErr);
	if (isSuccessful) generatorClass->copyDataOver();
	
	delete generatorClass;
	return isSuccessful;
}

bool MatroskaExtensionMetadataImporter::ReadChapters(KaxChapters &chapterEntries)
{
	if (seenChapters) {
		return true;
	}
	addMediaType(@"Chapters");

	KaxEditionEntry & edition = GetChild<KaxEditionEntry>(chapterEntries);
	NSMutableArray<CSLocalizedString*> *chapters = [[NSMutableArray alloc] initWithCapacity:edition.ListSize()];
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

#pragma mark -

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

void MatroskaExtensionMetadataImporter::pushTags(NSDictionary<NSString*,id> *tagDict)
{
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
			if (attributes.title == nil) {
				attributes.title = (NSString*)theval;
			}
		} else {
			postError(mkvErrorLevelWarn, CFSTR("Unmapped tag %@"), key);
		}
	}
}

void MatroskaExtensionMetadataImporter::pushTitle(NSString *theTags)
{
	attributes.title = theTags;
}

void MatroskaExtensionMetadataImporter::pushDuration(NSNumber *theTags)
{
	attributes.duration = theTags;
}

void MatroskaExtensionMetadataImporter::pushCreationDate(NSDate *theTags)
{
	attributes.contentCreationDate = theTags;
}

void MatroskaExtensionMetadataImporter::pushIdentifier(NSString *theTags)
{
	attributes.identifier = theTags;
}

void MatroskaExtensionMetadataImporter::pushEncodingApplications(NSArray<NSString*> *theTags)
{
	attributes.encodingApplications = theTags;
}

void MatroskaExtensionMetadataImporter::pushLanguages(NSArray<NSString*> *theTags)
{
	attributes.languages = theTags;
}

void MatroskaExtensionMetadataImporter::pushCodecs(NSArray<NSString*> *theTags)
{
	attributes.codecs = theTags;
}

void MatroskaExtensionMetadataImporter::pushLayerNames(NSArray<NSString*> *theTags)
{
	attributes.layerNames = theTags;
}

void MatroskaExtensionMetadataImporter::pushWidthAndHeight(NSNumber *width, NSNumber *height)
{
	attributes.pixelWidth = width;
	attributes.pixelHeight = height;
}

void MatroskaExtensionMetadataImporter::pushAudioInfo(NSNumber *channelCount, NSNumber *sampleRate)
{
	attributes.audioChannelCount = channelCount;
	attributes.audioSampleRate = sampleRate;
}

void MatroskaExtensionMetadataImporter::pushAttachedFiles(NSArray<NSString*> *theTags)
{
	CSCustomAttributeKey *attribKey = [[CSCustomAttributeKey alloc] initWithKeyName:kAttachedFiles searchable:YES searchableByDefault:NO unique:NO multiValued:YES];
	[attributes setValue:[theTags copy] forCustomKey:attribKey];
}

#pragma mark -

bool extensionInfoGetter(CSSearchableItemAttributeSet * _Nonnull attribs, NSURL * _Nonnull path, NSError * _Nullable * _Nullable outErr)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		matroska_init();
		atexit_b(^{
			matroska_done();
		});
	});

	try {
		return MatroskaExtensionMetadataImporter::getMetadata(attribs, path, outErr);
	} catch (CRTError &anErr) {
		if (outErr) {
			NSString *what = @(anErr.what());
			*outErr = [NSError errorWithDomain:NSPOSIXErrorDomain code:anErr.getError() userInfo:@{NSLocalizedDescriptionKey: what, NSURLErrorKey: path, NSLocalizedFailureErrorKey: NSLocalizedString(@"CRTError exception caught", @"CRTError exception caught"), NSDebugDescriptionErrorKey: what}];
		}
		return NO;
	} catch (...) {
		if (outErr) {
			*outErr = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSURLErrorKey: path, NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown C++ exception caught", @"Unknown C++ exception caught"), NSDebugDescriptionErrorKey: @"Unknown C++ exception caught"}];
		}
		return NO;
	}
	return NO;
}
