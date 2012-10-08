//
//  NSData.m
//  eIDDemo
//
//  Created by Olivier Michiels on 04/10/12.
//
//

#import "NSData+CommonDigest.h"
#include <CommonCrypto/CommonDigest.h>

@implementation NSData(CommonDigest)
-(NSData *)SHA512Hash {
    unsigned char hash[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512_CTX context;
    CC_SHA512_Init(&context);
    CC_SHA512_Update(&context, [self bytes], (CC_LONG)[self length]);
    CC_SHA512_Final(hash, &context);
    return [NSData dataWithBytes:hash length:CC_SHA512_DIGEST_LENGTH];
}

-(NSData *)SHA1Hash {
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_CTX context;
    CC_SHA1_Init(&context);
    CC_SHA1_Update(&context, [self bytes], (CC_LONG)[self length]);
    CC_SHA1_Final(hash, &context);
    return [NSData dataWithBytes:hash length:CC_SHA1_DIGEST_LENGTH];
}
@end
