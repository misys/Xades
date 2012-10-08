//
//  XDSDocument.h
//  XAdES
//
//  Created by Olivier Michiels on 05/10/12.
//  Copyright (c) 2012 Olivier Michiels. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *DataContentKey = @"contentKey";
static NSString *DataNameKey = @"nameKey";
static NSString *DataSizeKey = @"sizeKey";
static NSString *DateIdentifierKey = @"identifierKey";

@protocol XDSDocumentDelegate;
@interface XDSDocument : NSObject
@property(nonatomic, strong) NSString *digestAlgorithm;
@property(nonatomic, strong) NSString *signatureAlgorithm;
@property(nonatomic, assign) id<XDSDocumentDelegate> delegate;


-(void)addData:(NSDictionary*)data;
-(void)sign:(NSArray*)certs;

@end

@protocol XDSDocumentDelegate <NSObject>

-(NSData*)sign:(NSData*)toSign;

@end
