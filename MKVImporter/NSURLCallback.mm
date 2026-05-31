//
//  NSURLCallback.cpp
//  MKVImporter
//
//  Created by C.W. Betts on 5/24/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#include "NSURLCallback.hpp"
#include <ebml/StdIOCallback.h>
#include <string>
#include "Debugging.h"

using namespace LIBEBML_NAMESPACE;
using std::string;

class NSURLCallback final: public IOCallback
{
private:
	NSFileHandle *file;
	
	virtual ~NSURLCallback();
	
protected:
	
	NSURLCallback(NSURL *theURL) {
		NSError *err = nil;
		file = [NSFileHandle fileHandleForReadingFromURL:theURL error:&err];
		if (!file) {
			throw CRTError(ENOENT, string(err.localizedDescription.UTF8String));
		}
	}
	
	// The read callback works like most other read functions. You specify the
	// file, the buffer and the size and the function returns the bytes read.
	// If an error occurs or the file pointer points to the end of the file 0 is returned.
	// Users are encouraged to throw a descriptive exception, when an error occurs.
	virtual uint32 read(void *buffer, size_t size) override;

	// Seek to the specified position. The mode can have either SEEK_SET, SEEK_CUR
	// or SEEK_END. The callback should return true(1) if the seek operation succeeded
	// or false (0), when the seek fails.
	virtual void setFilePointer(int64 offset, seek_mode mode=seek_beginning) override;

	// This callback just works like its read pendant. It returns the number of bytes written.
	virtual size_t write(const void *buffer, size_t size) override {
		throw CRTError(EROFS, "NSURLCallback can only read");
		return 0;
	}

	// Although the position is always positive, the return value of this callback is signed to
	// easily allow negative values for returning errors. When an error occurs, the implementor
	// should return -1 and the file pointer otherwise.
	//
	// If an error occurs, an exception should be thrown.
	virtual uint64 getFilePointer() override;

	// The close callback flushes the file buffers to disk and closes the file. When using the stdio
	// library, this is equivalent to calling fclose. When the close is not successful, an exception
	// should be thrown.
	virtual void close() override;
	
	
	friend libebml::IOCallback *createCallbackForURL(NSURL *ourURL);
};

uint32 NSURLCallback::read(void *buffer, size_t size) {
	NSData *dataRead;
	if (@available(macOS 10.15, *)) {
		NSError *anErr=nil;
		dataRead = [file readDataUpToLength:size error:&anErr];
		if (!dataRead) {
			throw CRTError(EIO, string(anErr.localizedDescription.UTF8String));
		}
	} else {
		// Fallback on earlier versions
		dataRead = [file readDataOfLength:size];
	}
	[dataRead getBytes:buffer length:size];
	return dataRead.length;
}

uint64 NSURLCallback::getFilePointer() {
	unsigned long long offset = 0;
	if (@available(macOS 10.15, *)) {
		NSError *err = nil;
		BOOL success = [file getOffset:&offset error:&err];
		
		if (success) {
			return offset;
		} else {
			CRTError(EIO, string(err.localizedDescription.UTF8String));
			return -1;
		}
	} else {
		// Fallback on earlier versions
		return [file offsetInFile];
	}
}

void NSURLCallback::setFilePointer(int64 offset, seek_mode mode) {
	unsigned long long currentPosition = 0;
	if (@available(macOS 10.15, *)) {
		BOOL success = NO;
		NSError *theErr = nil;
		switch (mode) {
			case seek_current:
				success = [file getOffset:&currentPosition error:&theErr];
				if (!success) {
					throw CRTError(EIO, theErr.localizedDescription.UTF8String);
				}
				currentPosition += offset;
				break;
				
			case seek_end:
				success = [file seekToEndReturningOffset:&currentPosition error:&theErr];
				if (!success) {
					throw CRTError(EIO, theErr.localizedDescription.UTF8String);
				}
				currentPosition += offset;
				break;
				
			case seek_beginning:
				currentPosition = offset;
				break;
		}
		
		success = [file seekToOffset:currentPosition error:&theErr];
		if (!success) {
			throw CRTError(EIO, theErr.localizedDescription.UTF8String);
		}
	} else {
		// Fallback on earlier versions
		switch (mode) {
			case seek_current:
				currentPosition = [file offsetInFile] + offset;
				break;
				
			case seek_end:
				currentPosition = [file seekToEndOfFile] + offset;
				break;
				
			case seek_beginning:
				currentPosition = offset;
				break;
		}

		[file seekToFileOffset:currentPosition];
	}
}

void NSURLCallback::close() {
	if (@available(macOS 10.15, *)) {
		NSError *theErr;
		BOOL success = [file closeAndReturnError:&theErr];
		if (!success) {
			throw CRTError(EIO, std::string(theErr.localizedDescription.UTF8String));
			return;
		}
	} else {
		[file closeFile];
	}
}

NSURLCallback::~NSURLCallback() {
	[file closeFile];
	file = nil;
}


#pragma mark - helper function

libebml::IOCallback *createCallbackForURL(NSURL *ourURL) {
	try {
		if (![ourURL isFileURL]) {
			return new NSURLCallback(ourURL);
		}
	} catch (CRTError &anErr) {
		// CRTError exceptions
		postError(mkvErrorLevelWarn, CFSTR("Encountered CRTError exception creating NSFileHandle for %@: %s"), ourURL, anErr.what());
	} catch (...) {
		// Any other exception
		postError(mkvErrorLevelSerious, CFSTR("Encountered UNKNOWN exception creating NSFileHandle for %@"), ourURL);
	}
	
	return new libebml::StdIOCallback(ourURL.fileSystemRepresentation, MODE_READ);
}
