
#define MATROSKA_DLL_API
#define MATROSKA_NO_EXPORT

#ifndef MATROSKA_DEPRECATED
#  define MATROSKA_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef MATROSKA_DEPRECATED_EXPORT
#  define MATROSKA_DEPRECATED_EXPORT MATROSKA_DLL_API MATROSKA_DEPRECATED
#endif

#ifndef EBML_DEPRECATED_NO_EXPORT
#  define MATROSKA_DEPRECATED_NO_EXPORT MATROSKA_NO_EXPORT MATROSKA_DEPRECATED
#endif