//
//  XDSElement.h
//  XAdES
//
//  Created by Olivier Michiels on 05/10/12.
//  Copyright (c) 2012 Olivier Michiels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XDSAttribute;
@interface XDSElement : NSObject
@property(nonatomic, strong) NSString *content;
@property(nonatomic, readonly, getter = isParent) BOOL parent;
@property(nonatomic, readonly, getter = isLeaf) BOOL leaf;
@property(nonatomic) BOOL expanded;

-(id)initWithName:(NSString*)name;
-(id)initWithName:(NSString*)name andNamespace:(NSString*)namespace;

-(void)addElement:(XDSElement*)element;
-(void)addAttribute:(XDSAttribute*)attribute;
@end
