# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.ebml.Debug:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Debug/libebml.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Debug/libebml.a


PostBuild.ebml.Release:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Release/libebml.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Release/libebml.a


PostBuild.ebml.MinSizeRel:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/MinSizeRel/libebml.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/MinSizeRel/libebml.a


PostBuild.ebml.RelWithDebInfo:
/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/RelWithDebInfo/libebml.a:
	/bin/rm -f /Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/RelWithDebInfo/libebml.a




# For each target create a dummy ruleso the target does not have to exist
