//
//  XDSAttribute.m
//  XAdES
//
//  Created by Olivier Michiels on 05/10/12.
//  Copyright (c) 2012 Olivier Michiels. All rights reserved.
//

#import "XDSAttribute.h"

@interface XDSAttribute()
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *value;
@end

@implementation XDSAttribute
@synthesize name = _name;
@synthesize value = _value;

-(id)initWithName:(NSString *)name andValue:(NSString *)value {
    self = [super init];
    if (self) {
        self.name = name;
        self.value = value;
    }
    
    return self;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"%@=\"%@\"", self.name, self.value];
}
@end
