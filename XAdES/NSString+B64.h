//
//  NSString+B64.h
//  eIDDemo
//
//  Created by Olivier Michiels on 04/10/12.
//
//

#import <Foundation/Foundation.h>

@interface NSString(B64)
+(NSString*)base64Encode:(NSData*)data;
@end
