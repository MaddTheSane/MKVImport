# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.matroska.Debug:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Debug/libmatroska.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Debug/libmatroska.a


PostBuild.matroska.Release:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Release/libmatroska.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Release/libmatroska.a


PostBuild.matroska.MinSizeRel:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/MinSizeRel/libmatroska.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/MinSizeRel/libmatroska.a


PostBuild.matroska.RelWithDebInfo:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/RelWithDebInfo/libmatroska.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/RelWithDebInfo/libmatroska.a




# For each target create a dummy ruleso the target does not have to exist
