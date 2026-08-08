//
//  SharedImporter.i
//  MKVImporter
//
//  Created by C.W. Betts on 8/8/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

/// Returns the track ID of the specified tag, if any.
///
/// Currently, we only care about track IDs for getting BPS info, otherwise we skip if this returns a value.
/// @returns The track numerical ID linked to the tag, or `std::nullopt` if there isn't one.
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

/// Returns the chapter ID of the specified tag, if any.
/// @returns The chapter numerical ID linked to the tag, or `std::nullopt` if there isn't one.
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

static bool isMultiple(const std::string& spotlightKey)
{
	// ARTIST maps to kMDItemAuthors, while PUBLISHER maps to kMDItemPublishers.
	static const std::unordered_set<std::string> multiTags2 = {"ARTIST", "PUBLISHER", "MOOD"};
	return multiTags2.contains(spotlightKey);
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

bool MatroskaImport::ReadMetaSeek(KaxSeekHead &seekHead)
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

bool MatroskaImport::ProcessLevel1Element()
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
		el_l1->SkipData(_aStream, EBML_CLASS_CONTEXT(KaxCues), dummyElt, true);
		return true;
		
	}
	return true;
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
