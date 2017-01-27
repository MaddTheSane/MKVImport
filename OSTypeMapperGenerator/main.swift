//
//  main.swift
//  OSTypeMapperGenerator
//
//  Created by C.W. Betts on 1/18/17.
//  Copyright © 2017 C.W. Betts. All rights reserved.
//

import Foundation

struct FourCharCodec {
	enum Code {
		case string(String)
		case osType(OSType)
	}
	var cType: String
	var fourocc: Code
}

private let kVideoCodecIndeo2 = "Indeo 2"
private let kVideoCodecIndeo3 = "Indeo 3"
private let kVideoCodecIndeo4 = "Indeo 4"
private let kVideoCodecIndeo5 = "Indeo 5"
private let kMPEG4VisualCodecType = "MPEG 4"
//let kMPEG4VisualCodecType = "MPEG 4"
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
private let kVideoFormatH261 = "H.261"
private let kVideoFormatH263 = "H.263"
private let kH264CodecType = "H.264"
private let kVideoFormatHEVC = "H.265"
private let kVideoFormatRAW = "Raw Video"
private let kVideoFormatProRes = "ProRes"
private let kVideoFormatMJPEG = "Motion JPEG"
private let kVideoFormatSorenson = "Sorenson Video"
private let kVideoFormatWMV = "WMV"
private let kVideoFormatJPEG2000 = "JPEG 2000"

private let kAudioFormatMPEGLayer1 = "mp1"
private let kAudioFormatMPEGLayer2 = "mp2"
private let kAudioFormatMPEGLayer3 = "mp3"
private let kAudioFormatDTS = "DTS"
private let kAudioFormatMPEG4AAC = "AAC"
private let kAudioFormatDV = "DV Audio"
private let kAudioFormatAC3 = "ac3"
private let kAudioFormatXiphFLAC = "FLAC"
private let kAudioFormatXiphVorbis = "Vorbis"
private let kAudioFormatLinearPCM = "Linear PCM"
private let kAudioFormatSpeex = "Speex"

private let kSubtitleFormatText = "Raw Text"

func mainFunc() {
	//TODO: remove codecs used natively by Matroskas.
	let kOSTypeCodecIDs: [FourCharCodec] = {
		var toRet = [FourCharCodec]()
		//Taken from libavformat/riff.c from ffmpeg
		toRet.append(FourCharCodec(cType: kVideoCodecIndeo2, fourocc: .string("RT21")));
		toRet.append(FourCharCodec(cType: kVideoCodecIndeo3, fourocc: .string("IV31")));
		toRet.append(FourCharCodec(cType: kVideoCodecIndeo3, fourocc: .string("IV32")));
		toRet.append(FourCharCodec(cType: kVideoCodecIndeo4, fourocc: .string("IV41")));
		toRet.append(FourCharCodec(cType: kVideoCodecIndeo5, fourocc: .string("IV50")));
		toRet.append(FourCharCodec(cType: kAudioFormatMPEGLayer2, fourocc: .osType(0x6D730050))) // 'ms\0\0' + 0x50
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("FMP4")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DIVX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DX50")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("XVID")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("MP4S")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("M4S2")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .osType(4 << 24))) /* some broken avi use this */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DIV1")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("BLZ0")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("mp4v")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("UMP4")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("WV1F")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("SEDG")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("RMP4")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("3IV2")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("WAWV"))); /* WaWv MPEG-4 Video Codec */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("FFDS")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("FVFW")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DCOD")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("MVXM")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("PM4V")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("SMP4")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DXGM")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("VIDM")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("M4T3")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("GEOX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("HDX4"))); /* flipped video */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DMK2")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DIGI")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("INMC")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("EPHV"))); /* Ephv MPEG-4 */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("EM4A")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("M4CC"))); /* Divio MPEG-4 */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("SN40")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("VSPX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("ULDX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("GEOV")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("SIPP"))); /* Samsung SHR-6040 */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("SM4V")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("XVIX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DreX")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("QMP4"))); /* QNAP Systems */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("PLV1"))); /* Pelco DVR MPEG-4 */
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("MP43")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("DIV3")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("MPG3")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("DIV5")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("DIV6")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("DIV4")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("DVX3")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("AP41")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("COL1")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("COL0")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v2, fourocc: .string("MP42")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v2, fourocc: .string("DIV2")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v1, fourocc: .string("MPG4")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v1, fourocc: .string("MP41")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvsd")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvhd")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh1")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvsl")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dv25")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dv50")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("cdvc"))); /* Canopus DV */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("CDVH"))); /* Canopus DV */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("CDV5"))); /* Canopus DV */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvc ")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvcs")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh1")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvis")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("pdvc")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("SL25")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("SLDV")));
		
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("mpg1")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("mpg2")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mpg2")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("MPEG")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("PIM1")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("PIM2")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("VCR2")));
		
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("DVR ")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("MMES")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("LMP2"))); /* Lead MPEG2 in avi */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("slif")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("EM2V")));
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("M701"))); /* Matrox MPEG2 intra-only */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mpgv")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("BW10")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("XMPG"))); /* Xing MPEG intra only */
		
		toRet.append(FourCharCodec(cType: kVideoFormatVP3, fourocc: .string("VP31")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP3, fourocc: .string("VP30")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP5, fourocc: .string("VP50")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP6, fourocc: .string("VP60")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP6, fourocc: .string("VP61")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP6, fourocc: .string("VP62")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP6, fourocc: .string("VP6F")));
		toRet.append(FourCharCodec(cType: kVideoFormatVP6, fourocc: .string("FLV4")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("MSVC")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("msvc")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("CRAM")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("cram")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("WHAM")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSVideo, fourocc: .string("wham")))
		toRet.append(FourCharCodec(cType: kVideoFormatMSRLE, fourocc: .string("mrle")))
		toRet.append(FourCharCodec(cType: kVideoFormatMSRLE, fourocc: .osType(1 << 24)))
		toRet.append(FourCharCodec(cType: kVideoFormatMSRLE, fourocc: .osType(2 << 24)))
		toRet.append(FourCharCodec(cType: "zlib", fourocc: .string("ZLIB")))
		toRet.append(FourCharCodec(cType: "Snow", fourocc: .string("SNOW")))
		
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .osType(1 << 24 | 16)))
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .osType(2 << 24 | 16)))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .osType(3 << 24 | 16)))
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .osType(4 << 24 | 16)))
		
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("I420")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YUY2")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y422")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("V422")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YUNV")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("UYNV")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("UYNY")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("uyv1")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("2Vu1")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("2vuy")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("yuvs")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("yuv2")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("P422")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YV12")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YV16")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YV24")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("UYVY")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("VYUY")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("IYUV")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y800")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y8  ")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("HDYC")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YVU9")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("VDTZ"))) /* SoftLab-NSK VideoTizer */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y411")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("NV12")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("NV21")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y41B")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y42B")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YUV9")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YVU9")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("auv2")))
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("YVYU")))

		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("mjp2")))
		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("MJ2C")))
		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("LJ2C")))
		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("LJ2K")))
		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("IPJ2")))

		//Code taken from libavformat/isom.c from ffmpeg
		toRet.append(FourCharCodec(cType: kVideoFormatVP8, fourocc: .string("VP80")));
		toRet.append(FourCharCodec(cType: kAudioFormatMPEGLayer1, fourocc: .string(".mp1")));
		toRet.append(FourCharCodec(cType: kAudioFormatMPEGLayer2, fourocc: .string(".mp2")));
		toRet.append(FourCharCodec(cType: kAudioFormatMPEGLayer3, fourocc: .string(".mp3")));
		toRet.append(FourCharCodec(cType: kAudioFormatMPEGLayer3, fourocc: .osType(0x6D730055)))
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvcp"))); /* DV PAL */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvc "))); /* DV NTSC */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvpp"))); /* DVCPRO PAL produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dv5p"))); /* DVCPRO50 PAL produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dv5n"))); /* DVCPRO50 NTSC produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("AVdv"))); /* AVID DV */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("AVd1"))); /* AVID DV100 */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvhq"))); /* DVCPRO HD 720p50 */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvhp"))); /* DVCPRO HD 720p60 */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh1")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh2")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh4")));
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh5"))); /* DVCPRO HD 50i produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh6"))); /* DVCPRO HD 60i produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatDV, fourocc: .string("dvh3"))); /* DVCPRO HD 30p produced by FCP */
		toRet.append(FourCharCodec(cType: kVideoFormatHEVC, fourocc: .string("hev1"))); /* HEVC/H.265 which indicates parameter sets may be in ES */
		toRet.append(FourCharCodec(cType: kVideoFormatHEVC, fourocc: .string("hvc1"))); /* HEVC/H.265 which indicates parameter sets shall not be in ES */
		
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("mp4v")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("DIVX"))); /* OpenDiVX *//* sample files at http://heroinewarrior.com/xmovie.php3 use this tag */
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("XVID")));
		toRet.append(FourCharCodec(cType: kMPEG4VisualCodecType, fourocc: .string("3IV2"))); /* experimental: 3IVX files before ivx D4 4.5.1 */
		
		toRet.append(FourCharCodec(cType: kVideoFormatH263, fourocc: .string("h263"))); /* H263 */
		toRet.append(FourCharCodec(cType: kVideoFormatH263, fourocc: .string("s263"))); /* H263 ?? works */
		
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("avc1"))); /* AVC-1/H.264 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai5p"))); /* AVC-Intra  50M 720p24/30/60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai5q"))); /* AVC-Intra  50M 720p25/50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai52"))); /* AVC-Intra  50M 1080p25/50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai53"))); /* AVC-Intra  50M 1080p24/30/60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai55"))); /* AVC-Intra  50M 1080i50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai56"))); /* AVC-Intra  50M 1080i60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai1p"))); /* AVC-Intra 100M 720p24/30/60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai1q"))); /* AVC-Intra 100M 720p25/50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai12"))); /* AVC-Intra 100M 1080p25/50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai13"))); /* AVC-Intra 100M 1080p24/30/60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai15"))); /* AVC-Intra 100M 1080i50 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("ai16"))); /* AVC-Intra 100M 1080i60 */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("AVin"))); /* AVC-Intra with implicit SPS/PPS */
		toRet.append(FourCharCodec(cType: kH264CodecType, fourocc: .string("aivx"))); /* XAVC 4:2:2 10bit */
		
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("m1v ")));
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("m1v1"))); /* Apple MPEG-1 Camcorder */
		toRet.append(FourCharCodec(cType: kMPEG1VisualCodecType, fourocc: .string("mpeg"))); /* MPEG */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("m2v1"))); /* Apple MPEG-2 Camcorder */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv1"))); /* MPEG2 HDV 720p30 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv2"))); /* MPEG2 HDV 1080i60 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv3"))); /* MPEG2 HDV 1080i50 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv4"))); /* MPEG2 HDV 720p24 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv5"))); /* MPEG2 HDV 720p25 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv6"))); /* MPEG2 HDV 1080p24 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv7"))); /* MPEG2 HDV 1080p25 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv8"))); /* MPEG2 HDV 1080p30 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdv9"))); /* MPEG2 HDV 720p60 JVC */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("hdva"))); /* MPEG2 HDV 720p50 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx5n"))); /* MPEG2 IMX NTSC 525/60 50mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx5p"))); /* MPEG2 IMX PAL 625/50 50mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx4n"))); /* MPEG2 IMX NTSC 525/60 40mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx4p"))); /* MPEG2 IMX PAL 625/50 40mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx3n"))); /* MPEG2 IMX NTSC 525/60 30mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mx3p"))); /* MPEG2 IMX PAL 625/50 30mb/s produced by FCP */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd51"))); /* XDCAM HD422 720p30 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd54"))); /* XDCAM HD422 720p24 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd55"))); /* XDCAM HD422 720p25 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd59"))); /* XDCAM HD422 720p60 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5a"))); /* XDCAM HD422 720p50 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5b"))); /* XDCAM HD422 1080i60 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5c"))); /* XDCAM HD422 1080i50 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5d"))); /* XDCAM HD422 1080p24 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5e"))); /* XDCAM HD422 1080p25 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xd5f"))); /* XDCAM HD422 1080p30 CBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv1"))); /* XDCAM EX 720p30 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv2"))); /* XDCAM HD 1080i60 */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv3"))); /* XDCAM HD 1080i50 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv4"))); /* XDCAM EX 720p24 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv5"))); /* XDCAM EX 720p25 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv6"))); /* XDCAM HD 1080p24 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv7"))); /* XDCAM HD 1080p25 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv8"))); /* XDCAM HD 1080p30 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdv9"))); /* XDCAM EX 720p60 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdva"))); /* XDCAM EX 720p50 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdvb"))); /* XDCAM EX 1080i60 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdvc"))); /* XDCAM EX 1080i50 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdvd"))); /* XDCAM EX 1080p24 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdve"))); /* XDCAM EX 1080p25 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdvf"))); /* XDCAM EX 1080p30 VBR */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdhd"))); /* XDCAM HD 540p */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("xdh2"))); /* XDCAM HD422 540p */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("AVmp"))); /* AVID IMX PAL */
		toRet.append(FourCharCodec(cType: kMPEG2VisualCodecType, fourocc: .string("mp2v"))); /* FCP5 */
		
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("3IVD"))); /* 3ivx DivX Doctor */
		
		toRet.append(FourCharCodec(cType: kVideoFormatH263, fourocc: .string("H263")));
		
		toRet.append(FourCharCodec(cType: kAudioFormatDTS, fourocc: .string("dtsc"))); /* DTS formats prior to DTS-HD */
		toRet.append(FourCharCodec(cType: kAudioFormatDTS, fourocc: .string("dtsh"))); /* DTS-HD audio formats */
		toRet.append(FourCharCodec(cType: kAudioFormatDTS, fourocc: .string("dtsl"))); /* DTS-HD Lossless formats */
		toRet.append(FourCharCodec(cType: kAudioFormatDTS, fourocc: .string("DTS "))); /* non-standard */
		
		toRet.append(FourCharCodec(cType: kAudioFormatDV, fourocc: .string("vdva")));
		toRet.append(FourCharCodec(cType: kAudioFormatDV, fourocc: .string("dvca")));
		
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("fl32")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("fl32")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("fl64")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("fl64")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("twos")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("sowt")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("lpcm")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("lpcm")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("in24")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("in24")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("in32")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("in32")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("sowt")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("raw ")));
		toRet.append(FourCharCodec(cType: kAudioFormatLinearPCM, fourocc: .string("NONE")));
		toRet.append(FourCharCodec(cType: kAudioFormatSpeex, fourocc: .string("spex"))); /* Flash Media Server */
		toRet.append(FourCharCodec(cType: kAudioFormatSpeex, fourocc: .string("SPXN"))); /* ZygoAudio (quality 10 mode) */
		
		toRet.append(FourCharCodec(cType: "WMA 2", fourocc: .string("WMA2")));
		
		toRet.append(FourCharCodec(cType: kAudioFormatMPEG4AAC, fourocc: .string("mp4a")));
		toRet.append(FourCharCodec(cType: kAudioFormatAC3, fourocc: .string("ac-3"))); /* ETSI TS 102 366 Annex F */
		toRet.append(FourCharCodec(cType: kAudioFormatAC3, fourocc: .string("sac3"))); /* Nero Recode */
		
		toRet.append(FourCharCodec(cType: "Apple Video", fourocc: .string("rpza"))); /* Apple Video (RPZA) */
		toRet.append(FourCharCodec(cType: "Cinepak", fourocc: .string("cvid"))); /* Cinepak */
		toRet.append(FourCharCodec(cType: "Planar RGB", fourocc: .string("8BPS"))); /* Planar RGB (8BPS) */
		toRet.append(FourCharCodec(cType: "Apple Graphics", fourocc: .string("smc "))); /* Apple Graphics (SMC) */
		toRet.append(FourCharCodec(cType: "Apple Animation", fourocc: .string("rle "))); /* Apple Animation (RLE) */
		toRet.append(FourCharCodec(cType: "SGI RLE", fourocc: .string("rle1"))); /* SGI RLE 8-bit */
		toRet.append(FourCharCodec(cType: "MS RLE", fourocc: .string("WRLE")));
		toRet.append(FourCharCodec(cType: "QuickDraw", fourocc: .string("qdrw"))); /* QuickDraw */
		

		toRet.append(FourCharCodec(cType: kVideoFormatH263, fourocc: .string("H263")));
		toRet.append(FourCharCodec(cType: kVideoFormatMSMPEG4v3, fourocc: .string("3IVD"))); /* 3ivx DivX Doctor */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("AV1x"))); /* AVID 1:1x */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("AVup")));
		toRet.append(FourCharCodec(cType: "SGI", fourocc: .string("sgi "))); /* SGI  */
		toRet.append(FourCharCodec(cType: "DPX", fourocc: .string("dpx "))); /* DPX */
		toRet.append(FourCharCodec(cType: "OpenEXR", fourocc: .string("exr "))); /* OpenEXR */
		
		toRet.append(FourCharCodec(cType: kVideoFormatProRes, fourocc: .string("apch"))); /* Apple ProRes 422 High Quality */
		toRet.append(FourCharCodec(cType: kVideoFormatProRes, fourocc: .string("apcn"))); /* Apple ProRes 422 Standard Definition */
		toRet.append(FourCharCodec(cType: kVideoFormatProRes, fourocc: .string("apcs"))); /* Apple ProRes 422 LT */
		toRet.append(FourCharCodec(cType: kVideoFormatProRes, fourocc: .string("apco"))); /* Apple ProRes 422 Proxy */
		toRet.append(FourCharCodec(cType: kVideoFormatProRes, fourocc: .string("ap4h"))); /* Apple ProRes 4444 */
		
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("raw "))); /* Uncompressed RGB */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("yuv2"))); /* Uncompressed YUV422 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("2vuy"))); /* UNCOMPRESSED 8BIT 4:2:2 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("yuvs"))); /* same as 2vuy but byte swapped */
		
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("L555")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("L565")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("B565")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("24BG")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("BGRA")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("RGBA")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("ABGR")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("b16g")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("b48r")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("bxbg"))); /* BOXX */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("bxrg")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("bxyv")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("NO16")));
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("DVOO"))); /* Digital Voodoo SD 8 Bit */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("R420"))); /* Radius DV YUV PAL */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("R411"))); /* Radius DV YUV NTSC */
		
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("R10k"))); /* UNCOMPRESSED 10BIT RGB */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("R10g"))); /* UNCOMPRESSED 10BIT RGB */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("r210"))); /* UNCOMPRESSED 10BIT RGB */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("AVUI"))); /* AVID Uncompressed deinterleaved UYVY422 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("AVrp"))); /* Avid 1:1 10-bit RGB Packer */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("SUDS"))); /* Avid DS Uncompressed */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("v210"))); /* UNCOMPRESSED 10BIT 4:2:2 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("bxy2"))); /* BOXX 10BIT 4:2:2 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("v308"))); /* UNCOMPRESSED  8BIT 4:4:4 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("v408"))); /* UNCOMPRESSED  8BIT 4:4:4:4 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("v410"))); /* UNCOMPRESSED 10BIT 4:4:4 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("Y41P"))); /* UNCOMPRESSED 12BIT 4:1:1 */
		toRet.append(FourCharCodec(cType: kVideoFormatRAW, fourocc: .string("yuv4"))); /* libquicktime packed yuv420p */
		
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("jpeg"))); /* PhotoJPEG */
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("mjpa"))); /* Motion-JPEG (format A) */
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("AVDJ"))); /* MJPEG with alpha-channel (AVID JFIF meridien compressed) */
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("AVRn"))); /* MJPEG with alpha-channel (AVID ABVB/Truevision NuVista) */
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("dmb1"))); /* Motion JPEG OpenDML */
		toRet.append(FourCharCodec(cType: kVideoFormatMJPEG, fourocc: .string("mjpb"))); /* Motion-JPEG (format B) */
		
		toRet.append(FourCharCodec(cType: kVideoFormatSorenson, fourocc: .string("SVQ1"))); /* Sorenson Video v1 */
		toRet.append(FourCharCodec(cType: kVideoFormatSorenson, fourocc: .string("svq1"))); /* Sorenson Video v1 */
		toRet.append(FourCharCodec(cType: kVideoFormatSorenson, fourocc: .string("svqi"))); /* Sorenson Video v1 (from QT specs)*/
		toRet.append(FourCharCodec(cType: kVideoFormatSorenson, fourocc: .string("SVQ3"))); /* Sorenson Video v3 */
		
		toRet.append(FourCharCodec(cType: kVideoFormatWMV, fourocc: .string("WMV1")))
		toRet.append(FourCharCodec(cType: kVideoFormatWMV, fourocc: .string("WMV2")))
		toRet.append(FourCharCodec(cType: kVideoFormatWMV, fourocc: .string("GXVE"))) //WMV 2
		toRet.append(FourCharCodec(cType: kVideoFormatWMV, fourocc: .string("WMV3")))
		toRet.append(FourCharCodec(cType: kVideoFormatJPEG2000, fourocc: .string("mjp2"))) /* JPEG 2000 produced by FCP */
		
		toRet.append(FourCharCodec(cType: kSubtitleFormatText, fourocc: .string("text")))
		toRet.append(FourCharCodec(cType: kSubtitleFormatText, fourocc: .string("tx3g")))
		toRet.append(FourCharCodec(cType: "CEA 608", fourocc: .string("c608")))
		
		return toRet
	}()
	
	var codecDict2 = [String: Set<NSObject>]()
	for obj in kOSTypeCodecIDs {
		if codecDict2[obj.cType] == nil {
			codecDict2[obj.cType] = []
		}
		let obj2: NSObject
		switch obj.fourocc {
		case .string(let aStr):
			obj2 = aStr as NSString
		case .osType(let aOSTy):
			obj2 = NSNumber(value: aOSTy)
		}
		
		codecDict2[obj.cType]!.insert(obj2)
	}
	
	let codecDict: [String: [NSObject]] = {
		var tmpDict = [String: [NSObject]]()
		for (key, aSet) in codecDict2 {
			tmpDict[key] = Array(aSet)
		}
		return tmpDict
	}()
	
	let aDat = try! PropertyListSerialization.data(fromPropertyList: codecDict, format: .xml, options: 0)
	
	let dest = URL(fileURLWithPath: CommandLine.arguments[1])
	do {
		try aDat.write(to: dest)
	} catch let error as NSError {
		print("Error: \(error.localizedDescription) (\(error))")
		exit(EXIT_FAILURE)
	}
}

if CommandLine.arguments.count != 2 {
	print("Usage: \(CommandLine.arguments[0]) outputFile")
	exit(EXIT_FAILURE)
}

mainFunc()
print("Done")
