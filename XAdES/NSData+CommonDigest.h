//
//  NSData.h
//  eIDDemo
//
//  Created by Olivier Michiels on 04/10/12.
//
//

#import <Foundation/Foundation.h>

@interface NSData (CommonDigest)
-(NSData *)SHA512Hash;
-(NSData *)SHA1Hash;
@end
