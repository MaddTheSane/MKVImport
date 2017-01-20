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

@interface MKVOnlyClassForGettingBackToOurBundle : NSObject
@end

@implementation MKVOnlyClassForGettingBackToOurBundle
@end

#define kSubFormatSSA "SSA"
#define kSubFormatASS "Advanced SSA"
#define kSubFormatUTF8 "UTF-8"
#define kSubFormatVobSub "VobSub"

#define kVideoCodecIndeo3 "Indeo 3"
#define kVideoCodecIndeo4 "Indeo 4"
#define kVideoCodecIndeo5 "Indeo 5"
#define kH264CodecType "H.264"
#define kMPEG4VisualCodecType "MPEG 4"
//#define kMPEG4VisualCodecType "MPEG 4"
#define kVideoFormatMSMPEG4v1 "MS-MPEG4v1"
#define kVideoFormatMSMPEG4v2 "MS-MPEG4v2"
#define kVideoFormatMSMPEG4v3 "MS-MPEG4v3"
#define kVideoFormatDV "DV"
#define kMPEG1VisualCodecType "MPEG 1"
#define kMPEG2VisualCodecType "MPEG 2"
#define kVideoFormatVP3 "VP3"
#define kVideoFormatVP5 "VP5"
#define kVideoFormatVP6 "VP6"
#define kVideoFormatVP8 "VP8"
#define kVideoFormatMSVideo "MS Video 1"
#define kVideoFormatMSRLE "MS RLE"

#define kAudioFormatMPEGLayer1 "mp1"
#define kAudioFormatMPEGLayer2 "mp2"
#define kAudioFormatMPEGLayer3 "mp3"
#define kAudioCodecIndeo2 "Indeo Audio"
#define kAudioFormatDTS "DTS"
#define kAudioFormatMPEG4AAC "AAC"
#define kAudioFormatAC3 "ac3"
#define kAudioFormatXiphFLAC "FLAC"
#define kAudioFormatXiphVorbis "Vorbis"
#define kAudioFormatLinearPCM "Linear PCM"

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
	{ kAudioFormatMPEGLayer2, 0x50 },
	{ kAudioFormatMPEGLayer3, 0x55 },
	{ kAudioFormatAC3, 0x2000 },
	{ kAudioFormatDTS, 0x2001 },
	{ kAudioFormatMPEG4AAC, 0xff },
	{ kAudioFormatXiphFLAC, 0xf1ac },
	{ "WMA 1", 0x0160 },
	{ "WMA 2", 0x0161 },
	{ 0, 0 }
};

static const MatroskaQT_Codec kMatroskaCodecIDs[] = {
	{ "raw", "V_UNCOMPRESSED" },
	{ kMPEG4VisualCodecType, "V_MPEG4/ISO/ASP" },
	{ kMPEG4VisualCodecType, "V_MPEG4/ISO/SP" },
	{ kMPEG4VisualCodecType, "V_MPEG4/ISO/AP" },
	{ kH264CodecType, "V_MPEG4/ISO/AVC" },
	{ "H.265", "V_MPEGH/ISO/HEVC" },
	{ kVideoFormatMSMPEG4v3, "V_MPEG4/MS/V3" },
	{ kMPEG1VisualCodecType, "V_MPEG1" },
	{ kMPEG2VisualCodecType, "V_MPEG2" },
	{ "RealVideo", "V_REAL/RV10" },
	{ "RealVideo", "V_REAL/RV20" },
	{ "RealVideo", "V_REAL/RV30" },
	{ "RealVideo", "V_REAL/RV40" },
	{ "Theora", "V_THEORA" },
	{ "Snow", "V_SNOW" },
	{ kVideoFormatVP8, "V_VP8" },
	{ "VP9", "V_VP9" },
	
	{ kAudioFormatMPEG4AAC, "A_AAC" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG4/LC" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG4/MAIN" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG4/LC/SBR" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG4/SSR" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG4/LTP" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG2/LC" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG2/MAIN" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG2/LC/SBR" },
	{ kAudioFormatMPEG4AAC, "A_AAC/MPEG2/SSR" },
	{ kAudioFormatMPEGLayer1, "A_MPEG/L1" },
	{ kAudioFormatMPEGLayer2, "A_MPEG/L2" },
	{ kAudioFormatMPEGLayer3, "A_MPEG/L3" },
	{ kAudioFormatAC3, "A_AC3" },
	{ kAudioFormatAC3, "A_AC3" },
	// anything special for these two?
	{ kAudioFormatAC3, "A_AC3/BSID9" },
	{ kAudioFormatAC3, "A_AC3/BSID10" },
	{ kAudioFormatXiphVorbis, "A_VORBIS" },
	{ kAudioFormatXiphFLAC, "A_FLAC" },
	{ kAudioFormatLinearPCM, "A_PCM/INT/LIT" },
	{ kAudioFormatLinearPCM, "A_PCM/INT/BIG" },
	{ kAudioFormatLinearPCM, "A_PCM/FLOAT/IEEE" },
	{ kAudioFormatDTS, "A_DTS" },
	{ "TrueType Audio", "A_TTA1" },
	{ "WavPack", "A_WAVPACK4" },
	{ "RealAudio", "A_REAL/14_4" },
	{ "RealAudio", "A_REAL/28_8" },
	{ "RealAudio", "A_REAL/COOK" },
	{ "RealAudio", "A_REAL/SIPR" },
	{ "RealAudio Lossless", "A_REAL/RALF" },
	{ "Atrac3", "A_REAL/ATRC" },
	{ "Opus", "A_OPUS" },
	
#if 0
	{ kBMPCodecType, "S_IMAGE/BMP" },
	{ kSubFormatUSF, "S_TEXT/USF" },
#endif
	{ kSubFormatSSA, "S_TEXT/SSA" },
	{ kSubFormatSSA, "S_SSA" },
	{ kSubFormatASS, "S_TEXT/ASS" },
	{ kSubFormatASS, "S_ASS" },
	{ kSubFormatUTF8, "S_TEXT/UTF8" },
	{ kSubFormatUTF8, "S_TEXT/ASCII" },
	{ kSubFormatVobSub, "S_VOBSUB" },
};


// these CodecIDs need special handling since they correspond to many fourccs
#define MKV_V_MS "V_MS/VFW/FOURCC"
#define MKV_A_MS "A_MS/ACM"
#define MKV_V_QT "V_QUICKTIME"

// these codecs have their profile as a part of the CodecID
#define MKV_A_PCM_BIG "A_PCM/INT/BIG"
#define MKV_A_PCM_LIT "A_PCM/INT/LIT"
#define MKV_A_PCM_FLOAT "A_PCM/FLOAT/IEEE"

static NSDictionary<NSNumber*, NSString*> *osTypeCodecMap;

static NSString *osType2CodecName(OSType codec, bool macEncoding = true)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableDictionary<NSNumber*, NSString*> *osTypeCodecMap2 = [[NSMutableDictionary alloc] init];
		@autoreleasepool {
		NSBundle *ourBundle = [NSBundle bundleForClass:[MKVOnlyClassForGettingBackToOurBundle class]];
		NSURL *osTypeMapURL = [ourBundle URLForResource:@"OSTypeMap" withExtension:@"plist"];
		if (!osTypeMapURL) {
			//Just use the four-char code instead, I guess
			return;
		}
		NSDictionary<NSString*,NSArray<id>*> *mapDict = [[NSDictionary alloc] initWithContentsOfURL:osTypeMapURL];
		for (NSString *key in mapDict) {
			NSArray<id>* ourArr = mapDict[key];
			for (id entry in ourArr) {
				if ([entry isKindOfClass:[NSNumber class]]) {
					osTypeCodecMap2[(NSNumber*)entry] = key;
				} else /* NSString */ {
					OSType properOSType = UTGetOSTypeFromString((__bridge CFStringRef)entry);
					osTypeCodecMap2[@(properOSType)] = key;
				}
			}
		}
		}
		osTypeCodecMap = [osTypeCodecMap2 copy];
	});
	NSString *codecName = osTypeCodecMap[@(codec)];
	if (codecName) {
		return codecName;
	}
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
