//
//  NameShortener.swift
//  MKVImporter
//
//  Created by C.W. Betts on 3/8/25.
//  Copyright © 2025 C.W. Betts. All rights reserved.
//

import Foundation

private let kSubFormatSSA = "SSA"
private let kSubFormatASS = "Advanced SSA"
private let kSubFormatSubRip = "SubRip"
private let kSubFormatVobSub = "VobSub"

private let kVideoCodecIndeo3 = "Indeo 3"
private let kVideoCodecIndeo4 = "Indeo 4"
private let kVideoCodecIndeo5 = "Indeo 5"
private let kH264CodecType = "H.264"
private let kMPEG4VisualCodecType = "MPEG 4"
//private let kMPEG4VisualCodecType = "MPEG 4"
private let kVideoFormatMSMPEG4v1 = "MS-MPEG4v1"
private let kVideoFormatMSMPEG4v2 = "MS-MPEG4v2"
private let kVideoFormatMSMPEG4v3 = "MS-MPEG4v3"
private let kVideoFormatDV = "DV"
private let kMPEG1VisualCodecType = "MPEG 1"
private let kMPEG2VisualCodecType = "MPEG 2"
private let kVideoFormatVP3 = "VP3"
private let kVideoFormatVP5 = "VP5"
private let kVideoFormatVP6 = "VP6"
private let kVideoFormatVP8 = "VP8"
private let kVideoFormatMSVideo = "MS Video 1"
private let kVideoFormatMSRLE = "MS RLE"

private let kAudioFormatMPEGLayer1 = "mp1"
private let kAudioFormatMPEGLayer2 = "mp2"
private let kAudioFormatMPEGLayer3 = "mp3"
private let kAudioCodecIndeo2 = "Indeo Audio"
private let kAudioFormatDTS = "DTS"
private let kAudioFormatMPEG4AAC = "AAC"
private let kAudioFormatAC3 = "AC-3"
private let kAudioFormatEAC3 = "Enhanced AC-3"
private let kAudioFormatXiphFLAC = "FLAC"
private let kAudioFormatXiphVorbis = "Vorbis"
private let kAudioFormatLinearPCM = "Linear PCM"

private struct WavCodec {
	let cType: String
	let twocc: UInt16
}

private struct MatroskaCodec {
	let cType: String
	let mkvID: String
}

//TODO/FIXME: should this be exaustive?
private let kWavCodecIDs: [WavCodec] = [
	.init(cType: kAudioFormatMPEGLayer2, twocc: 0x50),
	.init(cType: kAudioFormatMPEGLayer3, twocc: 0x55),
	.init(cType: kAudioFormatAC3, twocc: 0x2000),
	.init(cType: kAudioFormatDTS, twocc: 0x2001),
	.init(cType: kAudioFormatMPEG4AAC, twocc: 0xff),
	.init(cType: kAudioFormatXiphFLAC, twocc: 0xf1ac),
	.init(cType: "WMA 1", twocc: 0x0160),
	.init(cType: "WMA 2", twocc: 0x0161),
	]

private let kMatroskaCodecIDs: [MatroskaCodec] = [
	.init(cType: kH264CodecType, mkvID: "V_MPEG4/ISO/AVC"),
	.init(cType: kAudioFormatXiphVorbis, mkvID: "A_VORBIS"),
	.init(cType: kAudioFormatXiphFLAC, mkvID: "A_FLAC"),
	.init(cType: kVideoFormatVP8, mkvID: "V_VP8"),
	.init(cType: "VP9", mkvID: "V_VP9"),
	.init(cType: "HEVC", mkvID: "V_MPEGH/ISO/HEVC"),
	.init(cType: kSubFormatSSA, mkvID: "S_TEXT/SSA"),
	.init(cType: kSubFormatASS, mkvID: "S_TEXT/ASS"),
	.init(cType: kSubFormatSSA, mkvID: "S_SSA"),
	.init(cType: kSubFormatASS, mkvID: "S_ASS"),
	.init(cType: "Opus", mkvID: "A_OPUS"),
	.init(cType: kAudioFormatMPEGLayer3, mkvID: "A_MPEG/L3"),
	.init(cType: kAudioFormatAC3, mkvID: "A_AC3"),
	.init(cType: kAudioFormatEAC3, mkvID: "A_EAC3"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC"),
	.init(cType: kAudioFormatDTS, mkvID: "A_DTS"),
	.init(cType: kSubFormatVobSub, mkvID: "S_VOBSUB"),
	.init(cType: "AV1", mkvID: "V_AV1"),
	
	// uncommon video codecs:
	.init(cType: "Raw Video", mkvID: "V_UNCOMPRESSED"),
	.init(cType: kMPEG4VisualCodecType, mkvID: "V_MPEG4/ISO/ASP"),
	.init(cType: kMPEG4VisualCodecType, mkvID: "V_MPEG4/ISO/SP"),
	.init(cType: kMPEG4VisualCodecType, mkvID: "V_MPEG4/ISO/AP"),
	//{ kH264CodecType, "V_MPEG4/ISO/AVC" },
	//{ "HEVC", "V_MPEGH/ISO/HEVC" },
		.init(cType: kVideoFormatMSMPEG4v3, mkvID: "V_MPEG4/MS/V3"),
//	.init(cType: kVideoFormatMSMPEG4v2, mkvID: "V_MPEG4/MS/V2"),
//	.init(cType: kVideoFormatMSMPEG4v1, mkvID: "V_MPEG4/MS/V1"),
		.init(cType: kMPEG1VisualCodecType, mkvID: "V_MPEG1"),
	.init(cType: kMPEG2VisualCodecType, mkvID: "V_MPEG2"),
	.init(cType: "RealVideo 1.0", mkvID: "V_REAL/RV10"),
	.init(cType: "RealVideo G2", mkvID: "V_REAL/RV20"),
	.init(cType: "RealVideo 8", mkvID: "V_REAL/RV30"),
	.init(cType: "RealVideo 9", mkvID: "V_REAL/RV40"),
	.init(cType: "Theora", mkvID: "V_THEORA"),
	.init(cType: "Snow", mkvID: "V_SNOW"),
	//{ kVideoFormatVP8, "V_VP8" },
	//{ "VP9", "V_VP9" },
	.init(cType: "ProRes", mkvID: "V_PRORES"),
	.init(cType: "Motion JPEG", mkvID: "V_MJPEG"),

	// uncommon audio codecs:
	//{ kAudioFormatMPEG4AAC, "A_AAC" },
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG4/LC"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG4/MAIN"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG4/LC/SBR"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG4/SSR"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG4/LTP"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG2/LC"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG2/MAIN"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG2/LC/SBR"),
	.init(cType: kAudioFormatMPEG4AAC, mkvID: "A_AAC/MPEG2/SSR"),
	.init(cType: kAudioFormatMPEGLayer1, mkvID: "A_MPEG/L1"),
	.init(cType: kAudioFormatMPEGLayer2, mkvID: "A_MPEG/L2"),
	//{ kAudioFormatMPEGLayer3, "A_MPEG/L3" },
	//{ kAudioFormatAC3, "A_AC3" },
	// anything special for these two?
		.init(cType: kAudioFormatAC3, mkvID: "A_AC3/BSID9"),
	.init(cType: kAudioFormatAC3, mkvID: "A_AC3/BSID10"),
	//{ kAudioFormatXiphVorbis, "A_VORBIS" },
	//{ kAudioFormatXiphFLAC, "A_FLAC" },
		.init(cType: kAudioFormatLinearPCM, mkvID: "A_PCM/INT/LIT"),
	.init(cType: kAudioFormatLinearPCM, mkvID: "A_PCM/INT/BIG"),
	.init(cType: kAudioFormatLinearPCM, mkvID: "A_PCM/FLOAT/IEEE"),
	//{ kAudioFormatDTS, "A_DTS" },
	.init(cType: "DTS Lossless", mkvID: "A_DTS/LOSSLESS"),
	.init(cType: "DTS Express", mkvID: "A_DTS/EXPRESS"),
	.init(cType: "The True Audio", mkvID: "A_TTA1"),
	.init(cType: "WavPack", mkvID: "A_WAVPACK4"),
	.init(cType: "RealAudio 1", mkvID: "A_REAL/14_4"),
	.init(cType: "RealAudio 2", mkvID: "A_REAL/28_8"),
	.init(cType: "RealAudio Cook", mkvID: "A_REAL/COOK"),
	.init(cType: "Sipro Voice", mkvID: "A_REAL/SIPR"),
	.init(cType: "RealAudio Lossless", mkvID: "A_REAL/RALF"),
	.init(cType: "Atrac3", mkvID: "A_REAL/ATRC"),
	//{ "Opus", "A_OPUS" },
		.init(cType: "Apple Lossless", mkvID: "A_ALAC"),
	
	// uncommon subtitles:
	.init(cType: "Universal Subtitles", mkvID: "S_TEXT/USF"),
	//{ kSubFormatSSA, "S_TEXT/SSA" },
	//{ kSubFormatSSA, "S_SSA" },
	//{ kSubFormatASS, "S_TEXT/ASS" },
	//{ kSubFormatASS, "S_ASS" },
		.init(cType: kSubFormatSubRip, mkvID: "S_TEXT/UTF8"),
	.init(cType: kSubFormatSubRip, mkvID: "S_TEXT/ASCII"),
	//{ kSubFormatVobSub, "S_VOBSUB" },
	.init(cType: "DVB Subtitles", mkvID: "S_DVBSUB"),
	.init(cType: "Karaoke And Text Encapsulation", mkvID: "S_KATE"),
	.init(cType: "WebVTT", mkvID: "S_TEXT/WEBVTT"),
	.init(cType: "HDMV PGS", mkvID: "S_HDMV/PGS"),
	.init(cType: "HDMV Text", mkvID: "S_HDMV/TEXTST"),
	
	/*
	 #ifdef UNSUPPORTEDCODECS
		 // Currently unsupported codecs:
		 { "WMV", "V_MSWMV" }, // Video, Microsoft Video
		 { kVideoCodecIndeo5, "V_INDEO5" }, // Video, Indeo 5; transmuxed from AVI or created using VfW codec
		 { "Motion JPEG2000", "V_MJPEG2000" }, // Video, MJpeg 2000
		 { "Motion JPEG2000 Lossless", "V_MJPEG2000LL" }, // Video, MJpeg Lossless
		 { "DV Video", "V_DV" }, // Video, DV Video, type 1 (audio and video mixed)
		 { "Ogg Tarkin", "V_TARKIN" }, // Video, Ogg Tarkin
		 { "VP4", "V_ON2VP4" }, // Video, ON2, VP4
		 { "VP5", "V_ON2VP5" }, // Video, ON2, VP5
		 { "3ivx", "V_3IVX" }, // Video, 3ivX (is D4 decoder downwards compatible?)
		 { "HuffYuv", "V_HUFFYUV" }, // Video, HuffYuv, lossless; auch als VfW möglich
		 { "CoreYuv", "V_COREYUV" }, // Video, CoreYuv, lossless; auch als VfW möglich
		 { "Rududu Wavelet", "V_RUDUDU" }, // Nicola's Rududu Wavelet codec
	 #endif
	 */
	
		.init(cType: "QDesign Music", mkvID: "A_QUICKTIME/QDMC"),
	.init(cType: "QDesign Music 2", mkvID: "A_QUICKTIME/QDM2"),
]

// these CodecIDs need special handling since they correspond to many fourccs

let MKV_V_MS = "V_MS/VFW/FOURCC"
let MKV_A_MS = "A_MS/ACM"
let MKV_V_QT = "V_QUICKTIME"
let MKV_A_QT = "A_QUICKTIME"


private let osTypeCodecMap: [OSType: String] = {
	var osTypeCodecMap2: [OSType: String] = [:]
	
	let bundle = Bundle(for: ImportExtension.self)
	guard let osTypeMapURL = bundle.url(forResource: "OSTypeMap", withExtension: "plist"),
		  let plistData = try? Data(contentsOf: osTypeMapURL),
	let mapDict = try? PropertyListSerialization.propertyList(from: plistData, options: 0, format: nil) as? [String: [Any]] else {
		return [:]
	}
	for (key, ourArr) in mapDict {
		for entry in ourArr {
			if let entry = entry as? OSType {
				osTypeCodecMap2[entry] = key
			} else /* NSString */ {
				let preproperOSType = entry as! String
				let properOSType = UTGetOSTypeFromString(preproperOSType as CFString)
				osTypeCodecMap2[properOSType] = key
			}
		}
	}
	
	return osTypeCodecMap2
}()

func osType2CodecName(_ codec: OSType, macEncoding: Bool = true) -> String? {
	if let codecName = osTypeCodecMap[codec] {
		return codecName
	}
	
	return nil
}
/*

static NSString *osType2CodecName(OSType codec, bool macEncoding = true)
{
	static NSDictionary<NSNumber*, NSString*> *osTypeCodecMap;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableDictionary<NSNumber*, NSString*> *osTypeCodecMap2 = [[NSMutableDictionary alloc] init];
		@autoreleasepool {
		NSBundle *ourBundle = [NSBundle bundleForClass:[MKVOnlyClassForGettingBackToOurBundle class]];
		NSURL *osTypeMapURL = [ourBundle URLForResource:@"OSTypeMap" withExtension:@"plist"];
		if (!osTypeMapURL) {
			//Just use the four-char code instead, I guess
			postError(mkvErrorLevelTrivial, CFSTR("Unable to load OSType mapping for AVI/QT codecs. They will appear as their raw four characters."));
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
		return CFBridgingRelease(::CFStringCreateWithBytes(kCFAllocatorDefault, (const unsigned char*)ourCodec.cStr, 4, kCFStringEncodingDOSLatinUS, false));
	}
}
*/

func codecShortener(tr_entry: libmatroska.KaxTrackEntry) -> String? {
	var tr_codec: libmatroska.KaxCodecID? = nil
	return nil
}

/*
NSString *mkvCodecShortener(KaxTrackEntry &tr_entry)
{
	KaxCodecID *tr_codec = FindChild<KaxCodecID>(tr_entry);
	KaxCodecName *codecName = FindChild<KaxCodecName>(tr_entry);
	if (tr_codec == NULL)
		return nil;
	
	if (codecName && codecName->GetSize() != 0) {
		return @(codecName->GetValueUTF8().c_str());
	}
	
	const string &codecString(*tr_codec);
	
	if (codecString == MKV_V_MS) {
		// avi compatibility mode, 4cc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= (16+3))
			return nil;
		
		// offset to biCompression in BITMAPINFO
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer() + 16;
		return osType2CodecName((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3], false);
		
	} else if (codecString == MKV_A_MS) {
		// acm compatibility mode, twocc is in private info
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
		if (codecPrivate == NULL || codecPrivate->GetSize() <= 2)
			return nil;
		
		unsigned char *p = (unsigned char *) codecPrivate->GetBuffer();
		unsigned short twocc = p[0] | (p[1] << 8);
		
		for (int i = 0; kWavCodecIDs[i].cType; i++) {
			if (kWavCodecIDs[i].twocc == twocc)
				return @(kWavCodecIDs[i].cType);
		}
		return osType2CodecName('ms\0\0' | twocc, false);
		
	} else if (codecString == MKV_V_QT || codecString == MKV_A_QT) {
		// QT compatibility mode, private info is the ImageDescription structure, big endian
		KaxCodecPrivate *codecPrivate = FindChild<KaxCodecPrivate>(tr_entry);
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
	postError(mkvErrorLevelWarn, CFSTR("Unknown codec type %s"), codecString.c_str());

	return nil;
}
*/
