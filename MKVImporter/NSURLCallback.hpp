//
//  NSURLCallback.hpp
//  MKVImporter
//
//  Created by C.W. Betts on 5/24/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

#ifndef NSURLCallback_hpp
#define NSURLCallback_hpp

#include <stdio.h>
#include <ebml/IOCallback.h>
#import <Foundation/Foundation.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden"))) extern
#endif


__private_extern LIBEBML_NAMESPACE::IOCallback *createCallbackForURL(NSURL *ourURL);


#endif /* NSURLCallback_hpp */
