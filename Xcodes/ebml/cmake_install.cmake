# Install script for directory: /Users/cwbetts/makestuff/MKVImporter/Vendor/libebml

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
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Debug/libebml.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/Release/libebml.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/MinSizeRel/libebml.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
    endif()
  elseif("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/RelWithDebInfo/libebml.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
      execute_process(COMMAND "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libebml.a")
    endif()
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ebml" TYPE FILE FILES
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/Debug.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlBinary.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlConfig.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlContexts.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlCrc32.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlDate.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlDummy.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlElement.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlEndian.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlFloat.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlHead.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlId.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlMaster.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlSInteger.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlStream.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlString.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlSubHead.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlTypes.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlUInteger.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlUnicodeString.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlVersion.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/EbmlVoid.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/IOCallback.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/MemIOCallback.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/MemReadIOCallback.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/SafeReadIOCallback.h"
    "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/StdIOCallback.h"
    )
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ebml/c" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Vendor/libebml/ebml/c/libebml_t.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/ebml" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/ebml_export.h")
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML/EBMLTargets.cmake")
    file(DIFFERENT EXPORT_FILE_CHANGED FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML/EBMLTargets.cmake"
         "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets.cmake")
    if(EXPORT_FILE_CHANGED)
      file(GLOB OLD_CONFIG_FILES "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML/EBMLTargets-*.cmake")
      if(OLD_CONFIG_FILES)
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML/EBMLTargets.cmake\" will be replaced.  Removing files [${OLD_CONFIG_FILES}].")
        file(REMOVE ${OLD_CONFIG_FILES})
      endif()
    endif()
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets.cmake")
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets-debug.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets-minsizerel.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets-relwithdebinfo.cmake")
  endif()
  if("${CMAKE_INSTALL_CONFIG_NAME}" MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/CMakeFiles/Export/lib/cmake/EBML/EBMLTargets-release.cmake")
  endif()
endif()

if("x${CMAKE_INSTALL_COMPONENT}x" STREQUAL "xUnspecifiedx" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/EBML" TYPE FILE FILES
    "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/EBMLConfig.cmake"
    "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/EBMLConfigVersion.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/cwbetts/makestuff/MKVImporter/Xcodes/ebml/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
