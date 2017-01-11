//
//  mkvNameShortener.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 1/5/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "mkvNameShortener.hpp"
#include <string>

using namespace libmatroska;
using std::string;

typedef struct {
	const char *cType;
	unsigned short twocc;
} WavCodec;

typedef struct {
	const char *cType;
	const char *mkvID;
} MatroskaQT_Codec;


//TODO/FIXME: should this be exaustive?
static const WavCodec kWavCodecIDs[] = {
	{ "mp2", 0x50 },
	{ "mp3", 0x55 },
	{ "ac3", 0x2000 },
	{ "DTS", 0x2001 },
	{ "AAC", 0xff },
	{ "FLAC", 0xf1ac },
	{ 0, 0 }
};

static const MatroskaQT_Codec kMatroskaCodecIDs[] = {
	{ "raw", "V_UNCOMPRESSED" },
	{ "MPEG 4", "V_MPEG4/ISO/ASP" },
	{ "MPEG 4", "V_MPEG4/ISO/SP" },
	{ "MPEG 4", "V_MPEG4/ISO/AP" },
	{ "H.264", "V_MPEG4/ISO/AVC" },
	{ "H.265", "V_MPEGH/ISO/HEVC" },
	{ "MS-MPEG4", "V_MPEG4/MS/V3" },
	{ "MPEG 1", "V_MPEG1" },
	{ "MPEG 2", "V_MPEG2" },
	{ "RealVideo", "V_REAL/RV10" },
	{ "RealVideo", "V_REAL/RV20" },
	{ "RealVideo", "V_REAL/RV30" },
	{ "RealVideo", "V_REAL/RV40" },
	{ "Theora", "V_THEORA" },
	{ "Snow", "V_SNOW" },
	{ "VP8", "V_VP8" },
	{ "VP9", "V_VP9" },
	
	{ "AAC", "A_AAC" },
	{ "AAC", "A_AAC/MPEG4/LC" },
	{ "AAC", "A_AAC/MPEG4/MAIN" },
	{ "AAC", "A_AAC/MPEG4/LC/SBR" },
	{ "AAC", "A_AAC/MPEG4/SSR" },
	{ "AAC", "A_AAC/MPEG4/LTP" },
	{ "AAC", "A_AAC/MPEG2/LC" },
	{ "AAC", "A_AAC/MPEG2/MAIN" },
	{ "AAC", "A_AAC/MPEG2/LC/SBR" },
	{ "AAC", "A_AAC/MPEG2/SSR" },
	{ "mp1", "A_MPEG/L1" },
	{ "mp2", "A_MPEG/L2" },
	{ "mp3", "A_MPEG/L3" },
	{ "ac3", "A_AC3" },
	{ "ac3", "A_AC3" },
	// anything special for these two?
	{ "ac3", "A_AC3/BSID9" },
	{ "ac3", "A_AC3/BSID10" },
	{ "Vorbis", "A_VORBIS" },
	{ "FLAC", "A_FLAC" },
	{ "Linear PCM", "A_PCM/INT/LIT" },
	{ "Linear PCM", "A_PCM/INT/BIG" },
	{ "Linear PCM", "A_PCM/FLOAT/IEEE" },
	{ "DTS", "A_DTS" },
	{ "TrueType Audio", "A_TTA1" },
	{ "WavPack", "A_WAVPACK4" },
	{ "RealAudio", "A_REAL/14_4" },
	{ "RealAudio", "A_REAL/28_8" },
	{ "RealAudio", "A_REAL/COOK" },
	{ "RealAudio", "A_REAL/SIPR" },
	{ "RealAudio Lossless", "A_REAL/RALF" },
	{ "Atrac3", "A_REAL/ATRC" },
	
#if 0
	{ kBMPCodecType, "S_IMAGE/BMP" },
	{ kSubFormatUSF, "S_TEXT/USF" },
#endif
#if 0
	{ kSubFormatSSA, "S_TEXT/SSA" },
	{ kSubFormatSSA, "S_SSA" },
	{ kSubFormatASS, "S_TEXT/ASS" },
	{ kSubFormatASS, "S_ASS" },
	{ kSubFormatUTF8, "S_TEXT/UTF8" },
	{ kSubFormatUTF8, "S_TEXT/ASCII" },
	{ kSubFormatVobSub, "S_VOBSUB" },
#endif
};


// these CodecIDs need special handling since they correspond to many fourccs
#define MKV_V_MS "V_MS/VFW/FOURCC"
#define MKV_A_MS "A_MS/ACM"
#define MKV_V_QT "V_QUICKTIME"

// these codecs have their profile as a part of the CodecID
#define MKV_A_PCM_BIG "A_PCM/INT/BIG"
#define MKV_A_PCM_LIT "A_PCM/INT/LIT"
#define MKV_A_PCM_FLOAT "A_PCM/FLOAT/IEEE"

//TODO: check against common entries, use those names as opposed to just returning raw OSTypes.
static NSString *osType2CodecName(OSType codec, bool macEncoding = true)
{
	union OSTypeBridge {
		char cStr[4];
		OSType type;
	} ourCodec;
	ourCodec.type = CFSwapInt32BigToHost(codec);
	if (macEncoding) {
		return [[NSString alloc] initWithBytes:ourCodec.cStr length: 4 encoding:NSMacOSRomanStringEncoding];
	} else {
		return [[NSString alloc] initWithBytes:ourCodec.cStr length: 4 encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatinUS)];
	}
}

NSString *mkvCodecShortener(KaxTrackEntry *tr_entry)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(*tr_entry);
	KaxCodecName *codecName = FindChild<KaxCodecName>(*tr_entry);
	if (tr_codec == NULL)
		return nil;
	
	if (codecName && codecName->GetSize() != 0) {
		return @(codecName->GetValueUTF8().c_str());
	}
	
	string codecString(*tr_codec);
	
	if (codecString == MKV_V_MS) {
		// avi compatibility mode, 4cc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(*tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= (16+3))
			return nil;
		
		// offset to biCompression in BITMAPINFO
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer() + 16;
		return osType2CodecName((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3], false);
		
	} else if (codecString == MKV_A_MS) {
		// acm compatibility mode, twocc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(*tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= 2)
			return 0;
		
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer();
		unsigned short twocc = p[0] | (p[1] << 8);
		
		for (int i = 0; kWavCodecIDs[i].cType; i++) {
			if (kWavCodecIDs[i].twocc == twocc)
				return @(kWavCodecIDs[i].cType);
		}
		return osType2CodecName('ms\0\0' | twocc, false);
		
	} else if (codecString == MKV_V_QT) {
		// QT compatibility mode, private info is the ImageDescription structure, big endian
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(*tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= 4)
			return 0;
		
		// starts at the 4CC
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer();
		return osType2CodecName((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
		
	} else {
		for (int i = 0; i < sizeof(kMatroskaCodecIDs) / sizeof(MatroskaQT_Codec); i++) {
			if (codecString == kMatroskaCodecIDs[i].mkvID)
				return @(kMatroskaCodecIDs[i].cType);
		}
	}
	return nil;
}
