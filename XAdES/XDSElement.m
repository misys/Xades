//
//  XDSElement.m
//  XAdES
//
//  Created by Olivier Michiels on 05/10/12.
//  Copyright (c) 2012 Olivier Michiels. All rights reserved.
//

#import "XDSElement.h"
#import "XDSAttribute.h"

@interface XDSElement()
@property(nonatomic, strong) NSMutableArray *children;
@property(nonatomic, strong) NSMutableArray *attributes;
@property(nonatomic, strong) NSString *namespace;
@property(nonatomic, strong) NSString *name;
@end

@implementation XDSElement
@synthesize children = _children;
@synthesize attributes = _attributes;
@synthesize namespace = _namespace;
@synthesize name = _name;
@synthesize content = _content;
@synthesize parent = _parent;
@synthesize leaf = _leaf;
@synthesize expanded = _expanded;

-(id)initWithName:(NSString *)name {
    return [self initWithName:name andNamespace:nil];
}

-(id)initWithName:(NSString *)name andNamespace:(NSString *)namespace {
    self = [super init];
    if (self) {
        self.name = name;
        self.namespace = namespace;
        self.children = [NSMutableArray array];
        self.attributes = [NSMutableArray array];
    }
    return self;
}

-(void)addElement:(XDSElement *)element {
    [self.children addObject:element];
}

-(void)addAttribute:(XDSAttribute *)attribute {
    [self.attributes addObject:attribute];
}

-(BOOL)isParent {
    return self.children.count > 0;
}

-(BOOL)isLeaf {
    return self.children.count == 0;
}

-(NSString*)elementName:(BOOL)close {
    NSMutableString *elementName = self.namespace ? [NSMutableString stringWithFormat:@"%@:%@", self.namespace, self.name] : [NSMutableString stringWithFormat:@"%@", self.name];
    if (!close && self.attributes.count) [elementName appendString:@" "];
    
    return elementName;
}

-(NSString*)description {
    NSMutableString *element = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"<%@", [self elementName:NO]]];

    for (XDSAttribute *attribute in self.attributes) {
        [element appendString:[attribute description]];
        [element appendString:@" "];
    }
    element = [[element stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    
    if (self.leaf) {
        if (self.content) {
            [element appendString:[NSString stringWithFormat:@">%@</%@>", self.content, [self elementName:YES]]];
        } else {
            if (!self.expanded) [element appendString:@"/>"];
            else [element appendString:[NSString stringWithFormat:@"></%@>", [self elementName:YES]]];
        }
    } else {
        [element appendString:@">"];
        for (XDSElement *child in self.children) {
            [element appendString:[child description]];
        }
        [element appendString:[NSString stringWithFormat:@"</%@>", [self elementName:YES]]];
    }
    
    return element;
}
@end
