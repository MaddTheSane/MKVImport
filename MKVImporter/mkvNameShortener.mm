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

typedef NS_ENUM(int, MKVCodecLocations) {
	MKVCodecLocationQuickTimeVideo,
	MKVCodecLocationQuickTimeAudio,
	MKVCodecLocationVideoForWindows,
	MKVCodecLocationWindowsSound,
	MKVCodecLocationBare,
};

struct CodecMapping;

typedef NSString* _Nullable (ExpandedCodecInfo)(KaxTrackEntry &tr_entry, MKVCodecLocations location, CodecMapping const* mappedCodec, NSMutableDictionary *_Nullable additionalMetadata);

struct CodecMapping {
	NSString *const codecName;
	CMMediaType mediaType=0;
	FourCharCode codec=0;
	ExpandedCodecInfo *moreComplex=NULL;
	
	CodecMapping(NSString *const acodecName,
				 CMMediaType amediaType=0,
				 FourCharCode acodec=0,
				 ExpandedCodecInfo *amoreComplex=NULL):
	codecName(acodecName),
	mediaType(amediaType),
	codec(acodec),
	moreComplex(amoreComplex) {}
};

#pragma mark - ExpandedCodecInfo function declarations

static NSString* _Nullable ExpandedCodecInfo_PRORES(libmatroska::KaxTrackEntry &tr_entry, MKVCodecLocations location, CodecMapping const* _Nonnull mappedCodec, NSMutableDictionary *_Nullable additionalMetadata);
static NSString* _Nullable ExpandedCodecInfo_RAWVideo(libmatroska::KaxTrackEntry &tr_entry, MKVCodecLocations location, CodecMapping const* _Nonnull mappedCodec, NSMutableDictionary *_Nullable additionalMetadata);

#pragma mark -

typedef std::unordered_map<unsigned short, const CodecMapping> WavCodec;
typedef std::unordered_map<std::string, const CodecMapping> MatroskaQT_Codec;

//TODO/FIXME: should this be exaustive?
static const WavCodec kWavCodecIDs = {
	{ 0x50, CodecMapping(AudioFormatMPEGLayer2, kCMMediaType_Audio, kAudioFormatMPEGLayer2) },
	{ 0x55, CodecMapping(AudioFormatMPEGLayer3, kCMMediaType_Audio, kAudioFormatMPEGLayer3) },
	{ 0x2000, CodecMapping(AudioFormatAC3, kCMMediaType_Audio, kAudioFormatAC3) },
	{ 0x2001, CodecMapping(AudioFormatDTS, kCMMediaType_Audio, 'DTS ') },
	{ 0xff, CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ 0xf1ac, CodecMapping(AudioFormatXiphFLAC, kCMMediaType_Audio, kAudioFormatFLAC) },
	{ 0x0160, CodecMapping(@"WMA 1") },
	{ 0x0161, CodecMapping(@"WMA 2") },
	{ 0x0162, CodecMapping(@"WMA Pro") },
};

static const MatroskaQT_Codec kMatroskaCodecIDs = {
	// video codecs:
	{ "V_AV1", CodecMapping(@"AV1", kCMMediaType_Video, kCMVideoCodecType_AV1) },
	{ "V_UNCOMPRESSED", CodecMapping(@"Raw Video", 0, 0, ExpandedCodecInfo_RAWVideo) },
	{ "V_MPEG4/ISO/ASP", CodecMapping(kMPEG4VisualCodecType, kCMMediaType_Video, kCMVideoCodecType_MPEG4Video) },
	{ "V_MPEG4/ISO/SP", CodecMapping(kMPEG4VisualCodecType, kCMMediaType_Video, kCMVideoCodecType_MPEG4Video) },
	{ "V_MPEG4/ISO/AP", CodecMapping(kMPEG4VisualCodecType, kCMMediaType_Video, kCMVideoCodecType_MPEG4Video) },
	{ "V_MPEG4/ISO/AVC", CodecMapping(kH264CodecType, kCMMediaType_Video, kCMVideoCodecType_H264) },
	{ "V_MPEGH/ISO/HEVC", CodecMapping(@"HEVC", kCMMediaType_Video, kCMVideoCodecType_HEVC) },
	{ "V_MPEG4/MS/V3", CodecMapping(kVideoFormatMSMPEG4v3, kCMMediaType_Video, 'MP43') },
	{ "V_MPEG1", CodecMapping(kMPEG1VisualCodecType, kCMMediaType_Video, kCMVideoCodecType_MPEG1Video) },
	{ "V_MPEG2", CodecMapping(kMPEG2VisualCodecType, kCMMediaType_Video, kCMVideoCodecType_MPEG2Video) },
	{ "V_REAL/RV10", CodecMapping(@"RealVideo 1.0", kCMMediaType_Video, 'RV10') },
	{ "V_REAL/RV20", CodecMapping(@"RealVideo G2", kCMMediaType_Video, 'RV20') },
	{ "V_REAL/RV30", CodecMapping(@"RealVideo 8", kCMMediaType_Video, 0x30335652) },
	{ "V_REAL/RV40", CodecMapping(@"RealVideo 9", kCMMediaType_Video, 0x30345652) },
	{ "V_THEORA", CodecMapping(@"Theora", 0, 0) },
	{ "V_SNOW", CodecMapping(@"Snow", kCMMediaType_Video, 0x574F4E53) },
	{ "V_VP8", CodecMapping(kVideoFormatVP8, kCMMediaType_Video, 'VP80') },
	{ "V_VP9", CodecMapping(@"VP9", kCMMediaType_Video, kCMVideoCodecType_VP9) },
	{ "V_PRORES", CodecMapping(@"ProRes", 0, 0, ExpandedCodecInfo_PRORES) },
	{ "V_MJPEG", CodecMapping(@"Motion JPEG", kCMMediaType_Video, 'mjpa') },
	{ "V_FFV1", CodecMapping(@"FF Video Codec 1", kCMMediaType_Video, 'ffv1') },
	{ "V_CAVS", CodecMapping(@"AVS1-P2", kCMMediaType_Video, 'avs1') },
	{ "V_AVS2", CodecMapping(@"AVS2-P2", kCMMediaType_Video, 'avs2') },
	{ "V_AVS3", CodecMapping(@"AVS3-P2", kCMMediaType_Video, 'avs3') },
	{ "V_VC1", CodecMapping(@"VC-1") },
//	{ "V_MPEGI/ISO/VVC", CodecMapping(@"VVC") }, // Not in common use/not complete?
	{ "V_DIRAC", CodecMapping(@"BBC Dirac") },
	
	// audio codecs:
	{ "A_EAC3", CodecMapping(AudioFormatEAC3, kCMMediaType_Audio, kAudioFormatEnhancedAC3) },
	{ "A_AAC", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG4/LC", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG4/MAIN", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG4/LC/SBR", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG4/SSR", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG4/LTP", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG2/LC", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG2/MAIN", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG2/LC/SBR", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_AAC/MPEG2/SSR", CodecMapping(AudioFormatMPEG4AAC, kCMMediaType_Audio, kAudioFormatMPEG4AAC) },
	{ "A_MPEG/L1", CodecMapping(AudioFormatMPEGLayer1, kCMMediaType_Audio, kAudioFormatMPEGLayer1) },
	{ "A_MPEG/L2", CodecMapping(AudioFormatMPEGLayer2, kCMMediaType_Audio, kAudioFormatMPEGLayer2) },
	{ "A_TRUEHD", CodecMapping(@"TrueHD", kCMMediaType_Audio, 'mlpa') },
	{ "A_MPEG/L3", CodecMapping(AudioFormatMPEGLayer3, kCMMediaType_Audio, kAudioFormatMPEGLayer3) },
	{ "A_AC3", CodecMapping(AudioFormatAC3, kCMMediaType_Audio, kAudioFormatAC3) },
	{ "A_AC3/BSID9", CodecMapping(AudioFormatAC3, kCMMediaType_Audio, kAudioFormatAC3) },
	{ "A_AC3/BSID10", CodecMapping(AudioFormatAC3, kCMMediaType_Audio, kAudioFormatAC3) },
	{ "A_VORBIS", CodecMapping(AudioFormatXiphVorbis, 0, 0) },
	{ "A_FLAC", CodecMapping(AudioFormatXiphFLAC, kCMMediaType_Audio, kAudioFormatFLAC) },
	{ "A_PCM/INT/LIT", CodecMapping(AudioFormatLinearPCM, kCMMediaType_Audio, kAudioFormatLinearPCM) },
	{ "A_PCM/INT/BIG", CodecMapping(AudioFormatLinearPCM, kCMMediaType_Audio, kAudioFormatLinearPCM) },
	{ "A_PCM/FLOAT/IEEE", CodecMapping(AudioFormatLinearPCM, kCMMediaType_Audio, kAudioFormatLinearPCM) },
	{ "A_DTS", CodecMapping(AudioFormatDTS, kCMMediaType_Audio, 'DTS ') },
	{ "A_DTS/LOSSLESS", CodecMapping(@"DTS Lossless", kCMMediaType_Audio, 'dtsl') },
	{ "A_DTS/EXPRESS", CodecMapping(@"DTS Express", kCMMediaType_Audio, 'dtse') },
	{ "A_TTA1", CodecMapping(@"The True Audio", kCMMediaType_Audio, 'tta1') },
	{ "A_WAVPACK4", CodecMapping(@"WavPack", 0, 0) },
	{ "A_REAL/14_4", CodecMapping(@"RealAudio 1", 0, 0) },
	{ "A_REAL/28_8", CodecMapping(@"RealAudio 2", 0, 0) },
	{ "A_REAL/COOK", CodecMapping(@"RealAudio Cook", 0, 0) },
	{ "A_REAL/SIPR", CodecMapping(@"Sipro Voice", 0, 0) },
	{ "A_REAL/RALF", CodecMapping(@"RealAudio Lossless", 0, 0) },
	{ "A_REAL/ATRC", CodecMapping(@"ATRAC3", 0, 0) },
	{ "A_OPUS", CodecMapping(@"Opus", kCMMediaType_Audio, kAudioFormatOpus) },
	{ "A_ALAC", CodecMapping(@"Apple Lossless", kCMMediaType_Audio, kAudioFormatAppleLossless) },
	{ "A_ATRAC/AT1", CodecMapping(@"ATRAC1", 0, 0) },
	{ "A_MLP", CodecMapping(@"MLP (DVD-Audio)", 0, 0) },
	
	// subtitles:
#if 0
	{ "S_IMAGE/BMP", CodecMapping(kBMPCodecType, 0, 0) },
#endif
	{ "S_TEXT/USF", CodecMapping(@"Universal Subtitles", kCMMediaType_Subtitle, 'usf ') },
	{ "S_TEXT/SSA", CodecMapping(kSubFormatSSA, 0, 0) },
	{ "S_SSA", CodecMapping(kSubFormatSSA, 0, 0) },
	{ "S_TEXT/ASS", CodecMapping(kSubFormatASS, 0, 0) },
	{ "S_ASS", CodecMapping(kSubFormatASS, 0, 0) },
	{ "S_TEXT/UTF8", CodecMapping(kSubFormatSubRip, kCMMediaType_Subtitle, kCMSubtitleFormatType_3GText) },
	{ "S_TEXT/ASCII", CodecMapping(kSubFormatSubRip, kCMMediaType_Subtitle, kCMSubtitleFormatType_3GText) },
	{ "S_VOBSUB", CodecMapping(kSubFormatVobSub, 0, 0) },
	{ "S_DVBSUB", CodecMapping(@"DVB Subtitles", 0, 0) },
	{ "S_KATE", CodecMapping(@"Karaoke And Text Encapsulation", 0, 0) },
	{ "S_TEXT/WEBVTT", CodecMapping(@"WebVTT", kCMMediaType_Subtitle, kCMSubtitleFormatType_WebVTT) },
	{ "S_HDMV/PGS", CodecMapping(@"HDMV PGS", 0, 0) },
	{ "S_HDMV/TEXTST", CodecMapping(@"HDMV Text", kCMMediaType_Subtitle, 'hdmt') },
	{ "S_ARIBSUB", CodecMapping(@"ARIB Caption") },
	
#ifdef UNSUPPORTEDCODECS
	// Currently unsupported codecs:
	{ "V_MSWMV", CodecMapping(@"WMV", 0, 0) }, // Video, Microsoft Video
	{ "V_INDEO5", CodecMapping(kVideoCodecIndeo5, kCMMediaType_Video, 'IV50') }, // Video, Indeo 5; transmuxed from AVI or created using VfW codec
	{ "V_MJPEG2000", CodecMapping(@"Motion JPEG2000", 0, 0) }, // Video, MJpeg 2000
	{ "V_MJPEG2000LL", CodecMapping(@"Motion JPEG2000 Lossless", 0, 0) }, // Video, MJpeg Lossless
	{ "V_DV", CodecMapping(@"DV Video", 0, 0) }, // Video, DV Video, type 1 (audio and video mixed)
	{ "V_TARKIN", CodecMapping(@"Ogg Tarkin", 0, 0) }, // Video, Ogg Tarkin
	{ "V_ON2VP4", CodecMapping(@"VP4", 0, 0) }, // Video, ON2, VP4
	{ "V_ON2VP5", CodecMapping(kVideoFormatVP5, 0, 0) }, // Video, ON2, VP5
	{ "V_3IVX", CodecMapping(@"3ivx", kCMMediaType_Video, '3ivx') }, // Video, 3ivX (is D4 decoder downwards compatible?)
	{ "V_HUFFYUV", CodecMapping(@"HuffYuv", 0, 0) }, // Video, HuffYuv, lossless; auch als VfW möglich
	{ "V_COREYUV", CodecMapping(@"CoreYuv", 0, 0) }, // Video, CoreYuv, lossless; auch als VfW möglich
	{ "V_RUDUDU", CodecMapping(@"Rududu Wavelet", 0, 0) }, // Nicola's Rududu Wavelet codec
	{ "A_MPC", CodecMapping(@"musepack SV8", 0, 0) },
#endif
	
#ifndef NO_DEPRECATED_CODECS
	{ "A_QUICKTIME/QDMC", CodecMapping(@"QDesign Music", kCMMediaType_Audio, kAudioFormatQDesign) },
	{ "A_QUICKTIME/QDM2", CodecMapping(@"QDesign Music v2", kCMMediaType_Audio, kAudioFormatQDesign2) },
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

NSString *mkvCodecShortener(KaxTrackEntry &tr_entry, NSMutableDictionary *_Nullable outExtended)
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
			if (location->second.moreComplex != NULL) {
				NSString *toOut = (*location->second.moreComplex)(tr_entry, MKVCodecLocationWindowsSound, &(location->second), outExtended);
				if (toOut) {
					return toOut;
				}
			}
			if (location->second.mediaType != 0) {
				NSString *localizedCodec = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(location->second.mediaType, location->second.codec));
				if (localizedCodec) {
					return localizedCodec;
				}
			}
			return location->second.codecName;
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
			CMMediaType mediaType = location->second.mediaType;
			if (location->second.moreComplex != NULL) {
				NSString *toOut = (*location->second.moreComplex)(tr_entry, MKVCodecLocationBare, &(location->second), outExtended);
				if (toOut) {
					return toOut;
				}
			}
			if (mediaType != 0) {
				NSString *localizedCodec = CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(mediaType, location->second.codec));
				if (localizedCodec && ![localizedCodec isEqualToString:OSTypeToString(location->second.codec, true) ?: @""]) {
					return localizedCodec;
				}
			}
			return location->second.codecName;
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
	
	//Encountered in one webm file:
	if (sourceString.length() == 1 && sourceString.c_str()[0] == 0) {
		return @"";
	}
	
	NSString *toRet = [[NSString alloc] initWithBytes:sourceString.c_str() length:sourceString.length() * sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
	if (!toRet) {
		// huh, odd. Try the UTF-8 string instead
		toRet = [NSString stringWithUTF8String:sourceString.GetUTF8().c_str()];
	}
	
	return toRet;
}

#pragma mark -

/// Gets the localized codec name from a ProRes-defined Matroska track.
///
/// From the [Matroska Codec Specs](https://www.matroska.org/technical/codec_specs.html#v_prores)
///
/// Codec Name: Apple ProRes
///
/// Initialization: The `CodecPrivate` contains the FourCC as found in MP4 movies:
///
/// * ap4x: ProRes 4444 XQ
/// * ap4h: ProRes 4444
/// * apch: ProRes 422 High Quality
/// * apcn: ProRes 422 Standard Definition
/// * apcs: ProRes 422 LT
/// * apco: ProRes 422 Proxy
/// * aprh: ProRes RAW High Quality
/// * aprn: ProRes RAW Standard Definition
NSString* _Nullable ExpandedCodecInfo_PRORES(libmatroska::KaxTrackEntry &tr_entry, MKVCodecLocations location, CodecMapping const* _Nonnull mappedCodec, NSMutableDictionary *_Nullable additionalMetadata)
{
	KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
	if (codecPrivate == NULL || codecPrivate->GetSize() <= 3) {
		// Too small (or not present)!
		return nil;
	}
	
	unsigned char *ourVals = (unsigned char *)codecPrivate->GetBuffer();
	
	OSType toRet = 0;
	toRet  = ourVals[3];
	toRet |= ourVals[2] << 8;
	toRet |= ourVals[1] << 16;
	toRet |= ourVals[0] << 24;

	NSString *fullTest = (NSString *)CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Video, toRet));

	if (fullTest && ![fullTest isEqualToString:OSTypeToString(toRet, true) ?: @""]) {
		return fullTest;
	}
	
	return nil;
}

NSString* _Nullable ExpandedCodecInfo_RAWVideo(libmatroska::KaxTrackEntry &tr_entry, MKVCodecLocations location, CodecMapping const* _Nonnull mappedCodec, NSMutableDictionary *_Nullable additionalMetadata)
{
	auto & videoTrack = GetChild<KaxTrackVideo>(tr_entry);
	auto colorspace = FindChild<KaxVideoColourSpace>(videoTrack);
	if (colorspace == NULL || colorspace->GetSize() <= 3) {
		return nil;
	}
	
	unsigned char *ourVals = (unsigned char *)colorspace->GetBuffer();

	//TODO: fill this out!
	static const std::unordered_map<OSType, CMPixelFormatType> mapRaw = {
//		{'Y42B', std::nullopt},// No 1:1 conversion
		{'I420', kCVPixelFormatType_420YpCbCr8Planar},
		{'v408', kCMPixelFormat_4444YpCbCrA8},
	};
	
	OSType toRet = 0;
	toRet  = ourVals[3];
	toRet |= ourVals[2] << 8;
	toRet |= ourVals[1] << 16;
	toRet |= ourVals[0] << 24;
	
	NSString *fullTest = nil;
	auto iter = mapRaw.find(toRet);
	bool isFound = iter != mapRaw.end();
	if (!isFound) {
		fullTest = (NSString *)CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Video, toRet));
		if (fullTest && ![fullTest isEqualToString:OSTypeToString(toRet, true) ?: @""]) {
			return fullTest;
		}
	} else {
		fullTest = (NSString *)CFBridgingRelease(MTCopyLocalizedNameForMediaSubType(kCMMediaType_Video, iter->second));
		if (fullTest && ![fullTest isEqualToString:OSTypeToString(iter->second, true) ?: @""]) {
			return fullTest;
		}
	}
	
	return nil;
}
