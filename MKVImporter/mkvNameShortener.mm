//
//  mkvNameShortener.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 1/5/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <MediaToolbox/MediaToolbox.h>
#include "mkvNameShortener.hpp"
#include <string>
#include <unordered_map>
#include "Debugging.h"

using namespace LIBMATROSKA_NAMESPACE;
using std::string;

@interface MKVOnlyClassForGettingBackToOurBundle : NSObject
@end

@implementation MKVOnlyClassForGettingBackToOurBundle
@end

#define kSubFormatSSA @"SSA"
#define kSubFormatASS @"Advanced SSA"
#define kSubFormatSubRip @"SubRip"
#define kSubFormatVobSub @"VobSub"

#define kVideoCodecIndeo3 @"Indeo 3"
#define kVideoCodecIndeo4 @"Indeo 4"
#define kVideoCodecIndeo5 @"Indeo 5"
#define kH264CodecType @"H.264"
#define kMPEG4VisualCodecType @"MPEG 4 Video"
#define kVideoFormatMSMPEG4v3 @"MS-MPEG4v3"
#define kVideoFormatDV @"DV"
#define kMPEG1VisualCodecType @"MPEG 1 Video"
#define kMPEG2VisualCodecType @"MPEG 2 Video"
#define kVideoFormatVP5 @"VP5"
#define kVideoFormatVP8 @"VP8"

#define AudioFormatMPEGLayer1 @"mp1 Audio"
#define AudioFormatMPEGLayer2 @"mp2 Audio"
#define AudioFormatMPEGLayer3 @"mp3 Audio"
#define AudioFormatDTS @"DTS"
#define AudioFormatMPEG4AAC @"MPEG-4 AAC"
#define AudioFormatAC3 @"AC-3"
#define AudioFormatEAC3 @"Enhanced AC-3"
#define AudioFormatXiphFLAC @"FLAC"
#define AudioFormatXiphVorbis @"Vorbis"
#define AudioFormatLinearPCM @"Linear PCM"

struct TypeAndCodec {
	CMMediaType mediaType;
	FourCharCode codec;
};

typedef std::unordered_map<unsigned short, NSString* const> WavCodec;
typedef std::unordered_map<std::string, std::pair<NSString* const, const TypeAndCodec>> MatroskaQT_Codec;

//TODO/FIXME: should this be exaustive?
static const WavCodec kWavCodecIDs = {
	{ 0x50, AudioFormatMPEGLayer2 },
	{ 0x55, AudioFormatMPEGLayer3 },
	{ 0x2000, AudioFormatAC3 },
	{ 0x2001, AudioFormatDTS },
	{ 0xff, AudioFormatMPEG4AAC },
	{ 0xf1ac, AudioFormatXiphFLAC },
	{ 0x0160, @"WMA 1" },
	{ 0x0161, @"WMA 2" },
	{ 0x0162, @"WMA Pro" },
};

static const MatroskaQT_Codec kMatroskaCodecIDs = {
	// video codecs:
	{ "V_AV1", {@"AV1", TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_AV1)} },
	{ "V_UNCOMPRESSED", {@"Raw Video", TypeAndCodec(0, 0)} },
	{ "V_MPEG4/ISO/ASP", {kMPEG4VisualCodecType, TypeAndCodec(0, 0)} },
	{ "V_MPEG4/ISO/SP", {kMPEG4VisualCodecType, TypeAndCodec(0, 0)} },
	{ "V_MPEG4/ISO/AP", {kMPEG4VisualCodecType, TypeAndCodec(0, 0)} },
	{ "V_MPEG4/ISO/AVC", {kH264CodecType, TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_H264)} },
	{ "V_MPEGH/ISO/HEVC", {@"HEVC", TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_HEVC)} },
	{ "V_MPEG4/MS/V3", {kVideoFormatMSMPEG4v3, TypeAndCodec(kCMMediaType_Video, 'MP43')} },
	{ "V_MPEG1", {kMPEG1VisualCodecType, TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_MPEG1Video)} },
	{ "V_MPEG2", {kMPEG2VisualCodecType, TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_MPEG2Video)} },
	{ "V_REAL/RV10", {@"RealVideo 1.0", TypeAndCodec(0, 0)} },
	{ "V_REAL/RV20", {@"RealVideo G2", TypeAndCodec(0, 0)} },
	{ "V_REAL/RV30", {@"RealVideo 8", TypeAndCodec(0, 0)} },
	{ "V_REAL/RV40", {@"RealVideo 9", TypeAndCodec(0, 0)} },
	{ "V_THEORA", {@"Theora", TypeAndCodec(0, 0)} },
	{ "V_SNOW", {@"Snow", TypeAndCodec(0, 0)} },
	{ "V_VP8", {kVideoFormatVP8, TypeAndCodec(kCMMediaType_Video, 'VP80')} },
	{ "V_VP9", {@"VP9", TypeAndCodec(kCMMediaType_Video, kCMVideoCodecType_VP9)} },
	{ "V_PRORES", {@"ProRes", TypeAndCodec(0, 0)} }, // NOT MediaToolboxing this because there are too many variants.
	{ "V_MJPEG", {@"Motion JPEG", TypeAndCodec(kCMMediaType_Video, 'mjpa')} },
	{ "V_FFV1", {@"FF Video Codec 1", TypeAndCodec(0, 0)} },
	{ "V_AVS2", {@"AVS2-P2", TypeAndCodec(0, 0)} },
	{ "V_AVS3", {@"AVS3-P2", TypeAndCodec(0, 0)} },
	
	// audio codecs:
	{ "A_EAC3", {AudioFormatEAC3, TypeAndCodec(kCMMediaType_Audio, kAudioFormatEnhancedAC3)} },
	{ "A_AAC", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG4/LC", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG4/MAIN", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG4/LC/SBR", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG4/SSR", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG4/LTP", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG2/LC", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG2/MAIN", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG2/LC/SBR", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_AAC/MPEG2/SSR", {AudioFormatMPEG4AAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEG4AAC)} },
	{ "A_MPEG/L1", {AudioFormatMPEGLayer1, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEGLayer1)} },
	{ "A_MPEG/L2", {AudioFormatMPEGLayer2, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEGLayer2)} },
	{ "A_TRUEHD", {@"TrueHD", TypeAndCodec(0, 0)} },
	{ "A_MPEG/L3", {AudioFormatMPEGLayer3, TypeAndCodec(kCMMediaType_Audio, kAudioFormatMPEGLayer3)} },
	{ "A_AC3", {AudioFormatAC3, TypeAndCodec(kCMMediaType_Audio, kAudioFormatAC3)} },
	// FIXME: anything special for these two?
	{ "A_AC3/BSID9", {AudioFormatAC3, TypeAndCodec(kCMMediaType_Audio, kAudioFormatAC3)} },
	{ "A_AC3/BSID10", {AudioFormatAC3, TypeAndCodec(kCMMediaType_Audio, kAudioFormatAC3)} },
	{ "A_VORBIS", {AudioFormatXiphVorbis, TypeAndCodec(0, 0)} },
	{ "A_FLAC", {AudioFormatXiphFLAC, TypeAndCodec(kCMMediaType_Audio, kAudioFormatFLAC)} },
	{ "A_PCM/INT/LIT", {AudioFormatLinearPCM, TypeAndCodec(kCMMediaType_Audio, kAudioFormatLinearPCM)} },
	{ "A_PCM/INT/BIG", {AudioFormatLinearPCM, TypeAndCodec(kCMMediaType_Audio, kAudioFormatLinearPCM)} },
	{ "A_PCM/FLOAT/IEEE", {AudioFormatLinearPCM, TypeAndCodec(kCMMediaType_Audio, kAudioFormatLinearPCM)} },
	{ "A_DTS", {AudioFormatDTS, TypeAndCodec(0, 0)} },
	{ "A_DTS/LOSSLESS", {@"DTS Lossless", TypeAndCodec(0, 0)} },
	{ "A_DTS/EXPRESS", {@"DTS Express", TypeAndCodec(0, 0)} },
	{ "A_TTA1", {@"The True Audio", TypeAndCodec(kCMMediaType_Audio, 'tta1')} },
	{ "A_WAVPACK4", {@"WavPack", TypeAndCodec(0, 0)} },
	{ "A_REAL/14_4", {@"RealAudio 1", TypeAndCodec(0, 0)} },
	{ "A_REAL/28_8", {@"RealAudio 2", TypeAndCodec(0, 0)} },
	{ "A_REAL/COOK", {@"RealAudio Cook", TypeAndCodec(0, 0)} },
	{ "A_REAL/SIPR", {@"Sipro Voice", TypeAndCodec(0, 0)} },
	{ "A_REAL/RALF", {@"RealAudio Lossless", TypeAndCodec(0, 0)} },
	{ "A_REAL/ATRC", {@"ATRAC3", TypeAndCodec(0, 0)} },
	{ "A_OPUS", {@"Opus", TypeAndCodec(kCMMediaType_Audio, kAudioFormatOpus)} },
	{ "A_ALAC", {@"Apple Lossless", TypeAndCodec(kCMMediaType_Audio, kAudioFormatAppleLossless)} },
	{ "A_ATRAC/AT1", {@"ATRAC1", TypeAndCodec(0, 0)} },
	
	// subtitles:
#if 0
	{ "S_IMAGE/BMP", {kBMPCodecType, TypeAndCodec(0, 0)} },
#endif
	{ "S_TEXT/USF", {@"Universal Subtitles", TypeAndCodec(0, 0)} },
	{ "S_TEXT/SSA", {kSubFormatSSA, TypeAndCodec(0, 0)} },
	{ "S_SSA", {kSubFormatSSA, TypeAndCodec(0, 0)} },
	{ "S_TEXT/ASS", {kSubFormatASS, TypeAndCodec(0, 0)} },
	{ "S_ASS", {kSubFormatASS, TypeAndCodec(0, 0)} },
	{ "S_TEXT/UTF8", {kSubFormatSubRip, TypeAndCodec(kCMMediaType_Subtitle, kCMSubtitleFormatType_3GText)} },
	{ "S_TEXT/ASCII", {kSubFormatSubRip, TypeAndCodec(kCMMediaType_Subtitle, kCMSubtitleFormatType_3GText)} },
	{ "S_VOBSUB", {kSubFormatVobSub, TypeAndCodec(0, 0)} },
	{ "S_DVBSUB", {@"DVB Subtitles", TypeAndCodec(0, 0)} },
	{ "S_KATE", {@"Karaoke And Text Encapsulation", TypeAndCodec(0, 0)} },
	{ "S_TEXT/WEBVTT", {@"WebVTT", TypeAndCodec(kCMMediaType_Subtitle, kCMSubtitleFormatType_WebVTT)} },
	{ "S_HDMV/PGS", {@"HDMV PGS", TypeAndCodec(0, 0)} },
	{ "S_HDMV/TEXTST", {@"HDMV Text", TypeAndCodec(0, 0)} },
	
#ifdef UNSUPPORTEDCODECS
	// Currently unsupported codecs:
	{ "V_MSWMV", {@"WMV", TypeAndCodec(0, 0)} }, // Video, Microsoft Video
	{ "V_INDEO5", {kVideoCodecIndeo5, TypeAndCodec(kCMMediaType_Video, 'Jvt3')} }, // Video, Indeo 5; transmuxed from AVI or created using VfW codec
	{ "V_MJPEG2000", {@"Motion JPEG2000", TypeAndCodec(0, 0)} }, // Video, MJpeg 2000
	{ "V_MJPEG2000LL", {@"Motion JPEG2000 Lossless", TypeAndCodec(0, 0)} }, // Video, MJpeg Lossless
	{ "V_DV", {@"DV Video", TypeAndCodec(0, 0)} }, // Video, DV Video, type 1 (audio and video mixed)
	{ "V_TARKIN", {@"Ogg Tarkin", TypeAndCodec(0, 0)} }, // Video, Ogg Tarkin
	{ "V_ON2VP4", {@"VP4", TypeAndCodec(0, 0)} }, // Video, ON2, VP4
	{ "V_ON2VP5", {kVideoFormatVP5, TypeAndCodec(0, 0)} }, // Video, ON2, VP5
	{ "V_3IVX", {@"3ivx", TypeAndCodec(kCMMediaType_Video, '3ivx')} }, // Video, 3ivX (is D4 decoder downwards compatible?)
	{ "V_HUFFYUV", {@"HuffYuv", TypeAndCodec(0, 0)} }, // Video, HuffYuv, lossless; auch als VfW möglich
	{ "V_COREYUV", {@"CoreYuv", TypeAndCodec(0, 0)} }, // Video, CoreYuv, lossless; auch als VfW möglich
	{ "V_RUDUDU", {@"Rududu Wavelet", TypeAndCodec(0, 0)} }, // Nicola's Rududu Wavelet codec
	{ "A_MPC", {@"musepack SV8", TypeAndCodec(0, 0)} },
#endif
	
#ifndef NO_DEPRECATED_CODECS
	{"A_QUICKTIME/QDMC", {@"QDesign Music", TypeAndCodec(kCMMediaType_Audio, kAudioFormatQDesign)}},
	{"A_QUICKTIME/QDM2", {@"QDesign Music v2", TypeAndCodec(kCMMediaType_Audio, kAudioFormatQDesign2)}},
#endif
};


// these CodecIDs need special handling since they correspond to many fourccs
#define MKV_V_MS "V_MS/VFW/FOURCC"
#define MKV_A_MS "A_MS/ACM"
#define MKV_V_QT "V_QUICKTIME"
#define MKV_A_QT "A_QUICKTIME"

static OSType StringToOSType(NSString *theString);
static NSString *OSTypeToString(OSType codec, bool macEncoding);

typedef NS_ENUM(NSInteger, MKVMediaType) {
	MKVMediaTypeVideo,
	MKVMediaTypeAudio,
	MKVMediaTypeSubtitles
};

static OSType StringToOSType(NSString *theString)
{
#if __is_target_os(macosx)
	return UTGetOSTypeFromString((__bridge CFStringRef)theString);
#else
	//TODO: fix endian issues… when a new Big Endian Mac comes forward, I guess.
	unsigned char ourVals[5] = {0};
	if ([theString getBytes:ourVals maxLength:5 usedLength:NULL encoding:NSMacOSRomanStringEncoding options:0 range:NSMakeRange(0, 4) remainingRange:NULL]) {
		OSType toRet = 0;
		toRet = ourVals[3];
		toRet |= ourVals[2] << 8;
		toRet |= ourVals[1] << 16;
		toRet |= ourVals[0] << 24;

		return toRet;
	} else {
		NSData *ourDat = [theString dataUsingEncoding:NSMacOSRomanStringEncoding];
		if (ourDat.length == 4) {
			OSType ourType = 0;
			[ourDat getBytes:&ourType range:NSMakeRange(0, 4)];
			return __builtin_bswap32(ourType);
		}
	}
	postError(mkvErrorLevelWarn, CFSTR("Could not get an OSType encoding for '%@'"), theString);
	return 0;
#endif
}

static NSString *OSTypeToString(OSType codec, bool macEncoding)
{
	union OSTypeBridge {
		char cStr[4];
		OSType type;
	} ourCodec;
	ourCodec.type = CFSwapInt32BigToHost(codec);
	NSString *outName;
	if (macEncoding) {
		outName = [[NSString alloc] initWithBytes:ourCodec.cStr length: 4 encoding:NSMacOSRomanStringEncoding];
	} else {
		outName = CFBridgingRelease(::CFStringCreateWithBytes(kCFAllocatorDefault, (const unsigned char*)ourCodec.cStr, 4, kCFStringEncodingDOSLatinUS, false));
	}
	if (outName.length != 4) {
		return nil;
	}
	return outName;
}

static NSString *osType2CodecName(OSType codec, MKVMediaType mediaType, bool macEncoding = true)
{
	static NSDictionary<NSNumber*, NSString*> *osTypeCodecMap;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		@autoreleasepool {
			NSMutableDictionary<NSNumber*, NSString*> *osTypeCodecMap2 = [[NSMutableDictionary alloc] init];
			NSBundle *ourBundle = [NSBundle bundleForClass:[MKVOnlyClassForGettingBackToOurBundle class]];
			NSURL *osTypeMapURL = [ourBundle URLForResource:@"OSTypeMap" withExtension:@"plist"];
			if (!osTypeMapURL) {
				//Just use the four-char code instead, I guess
				postError(mkvErrorLevelTrivial, CFSTR("Unable to find OSType mapping for AVI/QT codecs. They will appear as their raw four characters."));
				return;
			}
			NSDictionary<NSString*,NSArray<id>*> *mapDict = [[NSDictionary alloc] initWithContentsOfURL:osTypeMapURL];
			if (!mapDict) {
				//Just use the four-char code instead, I guess
				postError(mkvErrorLevelTrivial, CFSTR("Unable to load OSType mapping for AVI/QT codecs. They will appear as their raw four characters."));
				return;
			}
			for (NSString *key in mapDict) {
				NSArray<id>* ourArr = mapDict[key];
				for (id entry in ourArr) {
					if ([entry isKindOfClass:[NSNumber class]]) {
						osTypeCodecMap2[(NSNumber*)entry] = key;
					} else /* NSString */ {
						OSType properOSType = StringToOSType(entry);
						osTypeCodecMap2[@(properOSType)] = key;
					}
				}
			}
			osTypeCodecMap = [osTypeCodecMap2 copy];
		}
	});
	{
		NSString *fullTest = nil;
		switch(mediaType) {
			case MKVMediaTypeVideo:
				fullTest = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Video, codec));
				break;
			case MKVMediaTypeAudio:
				fullTest = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Audio, codec));
				break;
			case MKVMediaTypeSubtitles:
				fullTest = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Subtitle, codec));
				break;
		}
		
		if (fullTest && ![fullTest isEqualToString:OSTypeToString(codec, macEncoding) ?: @""]) {
			return fullTest;
		}
	}
	
	NSString *codecName = osTypeCodecMap[@(codec)];
	if (codecName) {
		return codecName;
	}
	union OSTypeBridge {
		char cStr[4];
		OSType type;
	} ourCodec;
	ourCodec.type = CFSwapInt32BigToHost(codec);
	NSString *outName;
	if (macEncoding) {
		outName = [[NSString alloc] initWithBytes:ourCodec.cStr length: 4 encoding:NSMacOSRomanStringEncoding];
	} else {
		outName = CFBridgingRelease(::CFStringCreateWithBytes(kCFAllocatorDefault, (const unsigned char*)ourCodec.cStr, 4, kCFStringEncodingDOSLatinUS, false));
	}
	if ([outName length] != 0) {
		//TODO: expand string to be four characters.
//		if ([outName length] != 4) {
//			while ([outName length] != 4) {
//				outName = [outName stringByAppendingString:@" "];
//			}
//		}
		outName = [NSString stringWithFormat:@"“%@”", outName];
	}
	return outName;
}

NSString *mkvCodecShortener(KaxTrackEntry &tr_entry)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(tr_entry);
	KaxCodecName *codecName = FindChild<KaxCodecName>(tr_entry);
	if (tr_codec == NULL) {
		return nil;
	}
	
	if (codecName && codecName->GetSize() != 0) {
		return getNSStringFromUTFstring(*codecName);
	}
	
	const string &codecString(*tr_codec);
	
	if (codecString == MKV_V_MS) {
		// avi compatibility mode, 4cc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= (16+3)) {
			return nil;
		}
		
		// offset to biCompression in BITMAPINFO
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer() + 16;
		return osType2CodecName((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3], MKVMediaTypeVideo, false);
		
	} else if (codecString == MKV_A_MS) {
		// acm compatibility mode, twocc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= 2) {
			return nil;
		}
		
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer();
		unsigned short twocc = p[0] | (p[1] << 8);
		
		auto location = kWavCodecIDs.find(twocc);
		bool isFound = location != kWavCodecIDs.end();
		if (isFound) {
			return location->second;
		}
		return osType2CodecName('ms\0\0' | twocc, MKVMediaTypeAudio, false);
		
	} else if (codecString == MKV_V_QT || codecString == MKV_A_QT) {
		// QT compatibility mode, private info is the ImageDescription structure, big endian
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= 8) {
			return nil;
		}
		
		// starts at the 4CC
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer();
		return osType2CodecName((p[4] << 24) | (p[5] << 16) | (p[6] << 8) | p[7], codecString == MKV_V_QT ? MKVMediaTypeVideo : MKVMediaTypeAudio);
		
	} else {
		auto location = kMatroskaCodecIDs.find(codecString);
		bool isFound = location != kMatroskaCodecIDs.end();
		if (isFound) {
			CMMediaType mediaType = location->second.second.mediaType;
			if (mediaType != 0) {
				NSString *localizedCodec = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(mediaType, location->second.second.codec));
				if (localizedCodec && ![localizedCodec isEqualToString:OSTypeToString(location->second.second.codec, true) ?: @""]) {
					return localizedCodec;
				}
			}
			return location->second.first;
		}
	}
	postError(mkvErrorLevelWarn, CFSTR("Unknown codec type %@"), @(codecString.c_str()));

	return nil;
}

NSString *getNSStringFromUTFstring(const UTFstring &sourceString)
{
	//simple sanity check, just in case...
	if (sourceString.length() == 0) {
		return @"";
	}
	
	NSString *toRet = [[NSString alloc] initWithBytes:sourceString.c_str() length:sourceString.length() * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	if (!toRet) {
		// huh, odd. Try the UTF-8 string instead
		toRet = [NSString stringWithUTF8String:sourceString.GetUTF8().c_str()];
	}
	
	return toRet;
}
