# Install script for directory: /Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "../local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Debug/libmatroska.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/Release/libmatroska.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/MinSizeRel/libmatroska.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/RelWithDebInfo/libmatroska.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libmatroska.a")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/matroska" TYPE FILE FILES
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/FileKax.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxAttached.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxAttachments.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxBlockData.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxBlock.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxChapters.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxClusterData.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxCluster.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxConfig.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxContentEncoding.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxContexts.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxCuesData.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxCues.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxDefines.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxInfoData.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxInfo.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxSeekHead.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxSegment.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxSemantic.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTag.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTags.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTrackAudio.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTrackEntryData.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTracks.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTrackVideo.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxTypes.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/KaxVersion.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/matroska/c" TYPE FILE FILES
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/c/libmatroska.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libmatroska/matroska/c/libmatroska_t.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska/MatroskaTargets.cmake")
    file(DIFFERENT EXPORT_FILE_CHANGED FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska/MatroskaTargets.cmake"
         "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets.cmake")
    if(EXPORT_FILE_CHANGED)
      file(GLOB OLD_CONFIG_FILES "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska/MatroskaTargets-*.cmake")
      if(OLD_CONFIG_FILES)
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska/MatroskaTargets.cmake\" will be replaced.  Removing files [${OLD_CONFIG_FILES}].")
        file(REMOVE ${OLD_CONFIG_FILES})
      endif()
    endif()
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets.cmake")
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets-debug.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets-minsizerel.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets-relwithdebinfo.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/CMakeFiles/Export/lib/cmake/Matroska/MatroskaTargets-release.cmake")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Matroska" TYPE FILE FILES
    "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/MatroskaConfig.cmake"
    "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/MatroskaConfigVersion.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/cwbetts/makestuff/MKVImporter/Xcodes/matroska/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
