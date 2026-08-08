//
//  SharedImporter.h
//  MKVImporter
//
//  Created by C.W. Betts on 8/8/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#ifndef __SHAREDIMPORTER_H__
#define __SHAREDIMPORTER_H__

#define kChapterNames @"com_GitHub_MaddTheSane_ChapterNames"
#define kAttachedFiles @"com_GitHub_MaddTheSane_AttachedFiles"

static inline NSString *getLanguageCode(const string & cppLang);
static NSString *getLanguageCode(KaxTrackEntry & track);
static inline NSString *getLanguageCode(const KaxLanguageIETF & language);
static NSString *getLocaleCode(const KaxChapterLanguage & language, KaxChapterCountry * country=NULL);
static NSString *getLocaleCode(const KaxChapLanguageIETF * language);
static bool isMultiple(const std::string& spotlightKey);
static bool MIMEIsFont(const string &mimeName);
static std::string get_simple_name(const KaxTagSimple &tag);
static NSString *get_simple_value(const KaxTagSimple &tag);
static std::optional<uint64_t> get_tuid(const KaxTag &tag);
static std::optional<uint64_t> get_cuid(const KaxTag &tag);

#pragma mark - Templates

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

#endif
