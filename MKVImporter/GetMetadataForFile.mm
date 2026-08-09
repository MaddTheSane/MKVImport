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
#include "MKVSharedImporter.hpp"

#include "mkvNameShortener.hpp"
#include "Debugging.h"

using namespace LIBMATROSKA_NAMESPACE;
using namespace LIBEBML_NAMESPACE;
using std::string;

class MatroskaPlugInMetadataImporter final: MatroskaSharedImporter {
private:
	MatroskaPlugInMetadataImporter(NSURL* path, NSMutableDictionary*attribs):
	MatroskaSharedImporter(path),
	attributes(attribs) { }
	virtual ~MatroskaPlugInMetadataImporter() = default;
	
	bool ReadChapters(KaxChapters &trackEntries) override;
	
	//! Copies over data to `attributes` that can't be done in one iteration.
	void copyDataOver() override {
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
	
public:
	static bool getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSURL *path);
	
private:
	NSMutableDictionary<NSString*,id> *attributes;
	
protected:
	virtual void copyTags(NSDictionary<NSString*,id> *theTags) override;
	virtual void setTitle(NSString *theTags) override;
	virtual void setDuration(NSNumber *theTags) override;
	virtual void setCreationDate(NSDate *theTags) override;
	virtual void setIdentifier(NSString *theTags) override;
	virtual void copyEncodingApplications(NSArray<NSString*> *theTags) override;
	virtual void copyLanguages(NSArray<NSString*> *theTags) override;
	virtual void copyCodecs(NSArray<NSString*> *theTags) override;
	virtual void copyLayerNames(NSArray<NSString*> *theTags) override;
	virtual void copyWidthAndHeight(NSNumber *width, NSNumber *height) override;
	virtual void copyAudioInfo(NSNumber *channelCount, NSNumber *sampleRate) override;
	virtual void copyAttachedFiles(NSArray<NSString*> *theTags) override;
};

bool MatroskaPlugInMetadataImporter::getMetadata(NSMutableDictionary<NSString*,id> *attribs, NSString *uti, NSURL *path)
{
	MatroskaPlugInMetadataImporter *generatorClass = new MatroskaPlugInMetadataImporter(path, attribs);
	NSError *err = nil;
	if (!generatorClass->isValidMatroska(&err)) {
		if (err) {
			postError(mkvErrorLevelWarn, CFSTR("%@"), err.debugDescription);
		}
		delete generatorClass;
		return false;
	}
	
	bool isSuccessful = generatorClass->iterateData(NULL);
	if (isSuccessful) generatorClass->copyDataOver();
	
	delete generatorClass;
	return isSuccessful;
}

bool MatroskaPlugInMetadataImporter::ReadChapters(KaxChapters &chapterEntries)
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

#pragma mark -

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

void MatroskaPlugInMetadataImporter::copyTags(NSDictionary<NSString*,id> *tagDict)
{
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
}

void MatroskaPlugInMetadataImporter::setTitle(NSString *nsTitle)
{
	attributes[(NSString*)kMDItemTitle] = nsTitle;
}

void MatroskaPlugInMetadataImporter::setDuration(NSNumber *theTags)
{
	attributes[(NSString*)kMDItemDurationSeconds] = theTags;
}

void MatroskaPlugInMetadataImporter::setCreationDate(NSDate *createDate)
{
	attributes[(NSString*)kMDItemContentCreationDate] = createDate;
}

void MatroskaPlugInMetadataImporter::setIdentifier(NSString *theTags)
{
	attributes[(NSString*)kMDItemIdentifier] = [theTags copy];
}

void MatroskaPlugInMetadataImporter::copyEncodingApplications(NSArray<NSString*> *creator)
{
	attributes[(NSString*)kMDItemEncodingApplications] = [creator copy];
}

void MatroskaPlugInMetadataImporter::copyLanguages(NSArray<NSString*> *langSet)
{
	attributes[(NSString*)kMDItemLanguages] = [langSet copy];
}

void MatroskaPlugInMetadataImporter::copyCodecs(NSArray<NSString*> *theTags)
{
	attributes[(NSString*)kMDItemCodecs] = [theTags copy];
}

void MatroskaPlugInMetadataImporter::copyLayerNames(NSArray<NSString*> *trackNames)
{
	attributes[(NSString*)kMDItemLayerNames] = [trackNames copy];
}

void MatroskaPlugInMetadataImporter::copyWidthAndHeight(NSNumber *width, NSNumber *height)
{
	attributes[(NSString*)kMDItemPixelHeight] = height;
	attributes[(NSString*)kMDItemPixelWidth] = width;
}

void MatroskaPlugInMetadataImporter::copyAudioInfo(NSNumber *channelCount, NSNumber *sampleRate)
{
	attributes[(NSString*)kMDItemAudioChannelCount] = channelCount;
	attributes[(NSString*)kMDItemAudioSampleRate] = sampleRate;
}

void MatroskaPlugInMetadataImporter::copyAttachedFiles(NSArray<NSString*> *attachmentFiles)
{
	attributes[kAttachedFiles] = [attachmentFiles copy];
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
			ok = MatroskaPlugInMetadataImporter::getMetadata(nsAttribs, nsUTI, nsPath);
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
