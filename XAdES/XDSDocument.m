//
//  XDSDocument.m
//  XAdES
//
//  Created by Olivier Michiels on 05/10/12.
//  Copyright (c) 2012 Olivier Michiels. All rights reserved.
//

#import "XDSDocument.h"
#import "XDSElement.h"
#import "XDSAttribute.h"
#import "NSData+CommonDigest.h"
#import "NSString+B64.h"
#include <openSSL/x509.h>

#define LOG_ELEMENT NSLog(@"%@", [element description]);

@interface XDSDocument()
@property(nonatomic, strong) XDSElement *root;
@property(nonatomic, strong) NSMutableArray *datas;
@property(nonatomic, strong) NSMutableDictionary *references;
@end

@implementation XDSDocument
@synthesize root = _root;
@synthesize digestAlgorithm = _digestAlgorithm;
@synthesize signatureAlgorithm = _signatureAlgorithm;
@synthesize datas = _datas;
@synthesize references = _references;

-(id)init {
    self = [super init];
    if (self) {
        self.root = [[XDSElement alloc] initWithName:@"SignedDoc" andNamespace:@"just"];
        [self.root addAttribute:[[XDSAttribute alloc] initWithName:@"xmlns:just" andValue:@"http://signinfo.eda.just.fgov.be/XSignInfo/2008/07/just#"]];
    }
    return self;
}

-(NSMutableArray*)datas {
    if (!_datas) _datas = [NSMutableArray array];
    
    return _datas;
}

-(NSMutableDictionary*)references {
    if (!_references) _references = [NSMutableDictionary dictionary];
    
    return _references;
}

-(void)addData:(NSDictionary *)data {
    NSString *identifier = [NSString stringWithFormat:@"D%d", self.datas.count];
    NSMutableDictionary *tmp = [data mutableCopy];
    [tmp setValue:identifier forKey:DateIdentifierKey];
    [self.datas addObject:tmp];
}

-(NSString*)description {
    NSMutableString *document = [[NSMutableString alloc] initWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [document appendString:[self.root description]];
    
    return document;
}

-(XDSElement*)createDigestMethod {
    return [self createDigestMethod:nil];
}

-(XDSElement*)createDigestMethod:(NSString*)namespace expanded:(BOOL)expanded {
    XDSElement *element = [[XDSElement alloc] initWithName:@"DigestMethod" andNamespace:namespace];
    element.expanded = expanded;
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"Algorithm" andValue:self.digestAlgorithm];
    [element addAttribute:attr];
    
    LOG_ELEMENT
    
    return element;
}

-(XDSElement*)createDigestMethod:(NSString*)namespace {
    return [self createDigestMethod:namespace expanded:YES];
}

-(XDSElement*)createDigestValue:(NSData*)value {
    XDSElement *element = [[XDSElement alloc] initWithName:@"DigestValue"];
    NSString *b64Hash = [NSString base64Encode:value];
    element.content = b64Hash;
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createCanonicalizationMethod {
    XDSElement *element = [[XDSElement alloc] initWithName:@"CanonicalizationMethod"];
    element.expanded = YES;
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"Algorithm" andValue:@"http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments"];
    [element addAttribute:attr];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSignatureMethod {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SignatureMethod"];
    element.expanded = YES;
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"Algorithm" andValue:self.signatureAlgorithm];
    [element addAttribute:attr];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createReference:(NSString*)identifier {
    XDSElement *element = [[XDSElement alloc] initWithName:@"Reference"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"URI" andValue:[NSString stringWithFormat:@"#%@", identifier]];
    [element addAttribute:attr];
    [element addElement:[self createDigestMethod]];
    NSData *hash = [[self.references valueForKey:identifier] SHA1Hash];
    [element addElement:[self createDigestValue:hash]];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createDataFile:(NSDictionary*)data {
    XDSElement *element = [[XDSElement alloc] initWithName:@"DataFile" andNamespace:@"just"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"xmlns:just" andValue:@"http://signinfo.eda.just.fgov.be/XSignInfo/2008/07/just#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"ContentType" andValue:@"EMBEDDED_BASE64"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"FileName" andValue:[data valueForKey:DataNameKey]];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:[data valueForKey:DateIdentifierKey]];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"MimeType" andValue:@"pdf"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Size" andValue:[NSString stringWithFormat:@"%d", [[data valueForKey:DataSizeKey] intValue]]];
    [element addAttribute:attr];
    
    element.content = [NSString base64Encode:[data valueForKey:DataContentKey]];

    [self.references setValue:[[element description] dataUsingEncoding:NSUTF8StringEncoding] forKey:[data valueForKey:DateIdentifierKey]];
    
    return element;
}

-(XDSElement*)createSignedInfo {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SignedInfo"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"xmlns" andValue:@"http://www.w3.org/2000/09/xmldsig#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"xmlns:just" andValue:@"http://signinfo.eda.just.fgov.be/XSignInfo/2008/07/just#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"SignedInfo0"];
    [element addAttribute:attr];
    [element addElement:[self createCanonicalizationMethod]];
    [element addElement:[self createSignatureMethod]];

    for (NSString *key in self.references.allKeys) {
        XDSElement *ref = [self createReference:key];
        [element addElement:ref];
    }
/*
    for (NSDictionary *data in self.datas) {
        XDSElement *ref = [self createReference:[data valueForKey:DateIdentifierKey]];
        [element addElement:ref];
    }
 */ 
    LOG_ELEMENT
    return element;
}

-(NSString*)bytes2String:(const unsigned char*)bytes length:(NSInteger)length {
    NSMutableString *ret = [NSMutableString string];
    for (int i = 0; i < length; i++)
        [ret appendFormat:@"%02.2hhx", bytes[i]];
    return ret;
}

-(NSString*)bytes2integer:(const unsigned char*)bytes length:(NSInteger)length {
    NSMutableString *ret = [NSMutableString string];
    for (int i = 0; i < length; i++)
        [ret appendFormat:@"%d", bytes[i]];
    return ret;
}

-(NSString*)X509IntegerToNSString:(ASN1_INTEGER*)integer
{
	BIO *bio = BIO_new(BIO_s_mem());
	NSString *result = nil;
	char *data;
	int length;
	
	if(i2a_ASN1_INTEGER(bio, integer)) {
		length = BIO_get_mem_data(bio, &data);
		result = [self bytes2integer:data length:length];
	}
	
	BIO_free(bio);
	
	return result;
}

-(XDSElement*)createSigningCertificate:(NSData*)cert {
    const unsigned char* certData = (const unsigned char*)[cert bytes];
    X509 *x509 = d2i_X509(NULL, &certData, cert.length);
    
    XDSElement *element = [[XDSElement alloc] initWithName:@"SigningCertificate" andNamespace:@"xades"];
    XDSElement *certElement = [[XDSElement alloc] initWithName:@"Cert" andNamespace:@"xades"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"URI" andValue:@"."];
    [certElement addAttribute:attr];
    XDSElement *certDigest = [[XDSElement alloc] initWithName:@"CertDigest" andNamespace:@"xades"];
    [certDigest addElement:[self createDigestMethod:@"ds" expanded:YES]];
    NSString *certHash = [NSString base64Encode:[cert SHA1Hash]];
    XDSElement *digestValue = [[XDSElement alloc] initWithName:@"DigestValue" andNamespace:@"ds"];
    digestValue.content = certHash;
    [certDigest addElement:digestValue];
    //[certDigest addElement:[self createDigestValue:[certHash dataUsingEncoding:NSUTF8StringEncoding]]];
    [certElement addElement:certDigest];
    XDSElement *issuerElement = [[XDSElement alloc] initWithName:@"IssuerSerial" andNamespace:@"xades"];
    XDSElement *issuerName = [[XDSElement alloc] initWithName:@"X509IssuerName" andNamespace:@"ds"];
    X509_NAME *name = X509_get_issuer_name(x509);
    char* x509Name = X509_NAME_oneline(name, NULL, 0);
    issuerName.content = [NSString stringWithFormat:@"%s", x509Name];
    [issuerElement addElement:issuerName];
    XDSElement *issuerSerial = [[XDSElement alloc] initWithName:@"X509SerialNumber" andNamespace:@"ds"];
    ASN1_INTEGER *serial = x509->cert_info->serialNumber;
    NSString *serialNumber = [self X509IntegerToNSString:serial];
    NSLog(@"%@", serialNumber);
    issuerSerial.content = serialNumber;
  //  issuerSerial.content = @"21267647932559534548729785088889419001";
    [issuerElement addElement:issuerSerial];
    [certElement addElement:issuerElement];
    [element addElement:certElement];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSignaturePolicyIdentifier {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SignaturePolicyIdentifier" andNamespace:@"xades"];
    XDSElement *signaturePolicyId = [[XDSElement alloc] initWithName:@"SignaturePolicyId" andNamespace:@"xades"];
    XDSElement *sigPolicyId = [[XDSElement alloc] initWithName:@"SigPolicyId" andNamespace:@"xades"];
    XDSElement *identifier = [[XDSElement alloc] initWithName:@"Identifier" andNamespace:@"xades"];
    identifier.content = @"http://signinfo.eda.just.fgov.be/SignaturePolicy/pdf/PrivateSeal/BE_Justice_Signature_Policy_PrivateSeal_Hum_v0.4a_201109_Fr.pdf";
    [sigPolicyId addElement:identifier];
    XDSElement *description = [[XDSElement alloc] initWithName:@"Description" andNamespace:@"xades"];
    description.content = @"Belgian Ministry of Justice Signature Policy";
    [sigPolicyId addElement:description];
    [signaturePolicyId addElement:sigPolicyId];
    XDSElement *sigPolicyHash = [[XDSElement alloc] initWithName:@"SigPolicyHash" andNamespace:@"xades"];
    [sigPolicyHash addElement:[self createDigestMethod:@"ds" expanded:YES]];
    XDSElement *digestValue = [[XDSElement alloc] initWithName:@"DigestValue" andNamespace:@"ds"];
    digestValue.content = @"+xMNMCSKHxZNu5dzgso0hzAwkxmDgLdNo0J0YEoX3H3aItTNdrHAt17l9cUFBRQuiNn29OVOPcFy2QKbL9iGzw==";
    [sigPolicyHash addElement:digestValue];
    [signaturePolicyId addElement:sigPolicyHash];
    XDSElement *sigPolicyQualifiers = [[XDSElement alloc] initWithName:@"SigPolicyQualifiers" andNamespace:@"xades"];
    XDSElement *sigPolicyQualifier = [[XDSElement alloc] initWithName:@"SigPolicyQualifier" andNamespace:@"xades"];
    XDSElement *spUserNotice = [[XDSElement alloc] initWithName:@"SPUserNotice" andNamespace:@"xades"];
    XDSElement *explicitText = [[XDSElement alloc] initWithName:@"ExplicitText" andNamespace:@"xades"];
    explicitText.content = @"Signe par bmjconcopy : 2012-10-04T11:51:45";
    [spUserNotice addElement:explicitText];
    [sigPolicyQualifier addElement:spUserNotice];
    [sigPolicyQualifiers addElement:sigPolicyQualifier];
    [signaturePolicyId addElement:sigPolicyQualifiers];
    [element addElement:signaturePolicyId];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSigningTime {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SigningTime" andNamespace:@"xades"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd";
    NSDate *today = [NSDate date];
    NSString *date = [dateFormat stringFromDate:today];
    dateFormat.dateFormat = @"hh:mm:ss";
    NSString *time = [dateFormat stringFromDate:today];
    
    element.content = [NSString stringWithFormat:@"%@T%@+02:00", date, time];
  //  element.content = @"2012-10-04T11:51:45+02:00";
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSignedSignatureProperties:(NSData*)cert {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SignedSignatureProperties" andNamespace:@"xades"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"SignedSignatureProperties0"];
    [element addAttribute:attr];
    [element addElement:[self createSigningTime]];
    [element addElement:[self createSigningCertificate:cert]];
    [element addElement:[self createSignaturePolicyIdentifier]];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSignedProperties:(NSData*)cert {
    XDSElement *element = [[XDSElement alloc] initWithName:@"SignedProperties" andNamespace:@"xades"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"xmlns" andValue:@"http://www.w3.org/2000/09/xmldsig#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"xmlns:ds" andValue:@"http://www.w3.org/2000/09/xmldsig#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"xmlns:just" andValue:@"http://signinfo.eda.just.fgov.be/XSignInfo/2008/07/just#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"xmlns:xades" andValue:@"http://uri.etsi.org/01903/v1.3.2#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"prop0"];
    [element addAttribute:attr];
    [element addElement:[self createSignedSignatureProperties:cert]];
    
    NSString *reference = [element description];
    [self.references setValue:[reference dataUsingEncoding:NSUTF8StringEncoding] forKey:@"prop0"];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createQualifyingProperties:(NSData*)cert {
    XDSElement *element = [[XDSElement alloc] initWithName:@"QualifyingProperties" andNamespace:@"xades"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"xmlns:xades" andValue:@"http://uri.etsi.org/01903/v1.3.2#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"xmlns:ds" andValue:@"http://www.w3.org/2000/09/xmldsig#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Target" andValue:@"#S0"];
    [element addAttribute:attr];
    
    [element addElement:[self createSignedProperties:cert]];
    
    LOG_ELEMENT
    return element;
}


-(XDSElement*)createObject:(NSData*)cert {
    XDSElement *element = [[XDSElement alloc] initWithName:@"Object"];
    [element addElement:[self createQualifyingProperties:cert]];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createKeyInfo:(NSArray*)certs {
    XDSElement *element = [[XDSElement alloc] initWithName:@"KeyInfo"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"KeyInfo0"];
    [element addAttribute:attr];
    XDSElement *x509Data = [[XDSElement alloc] initWithName:@"X509Data"];
    for (NSData *cert in certs) {
        XDSElement *x509Certificate = [[XDSElement alloc] initWithName:@"X509Certificate"];
        x509Certificate.content = [NSString base64Encode:cert];
        [x509Data addElement:x509Certificate];
    }
    [element addElement:x509Data];
    
    LOG_ELEMENT
    return element;
}

-(XDSElement*)createSignature:(NSArray*)certs {
    XDSElement *element = [[XDSElement alloc] initWithName:@"Signature"];
    XDSAttribute *attr = [[XDSAttribute alloc] initWithName:@"xmlns" andValue:@"http://www.w3.org/2000/09/xmldsig#"];
    [element addAttribute:attr];
    attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"S0"];
    [element addAttribute:attr];
    
    NSData *cert = [certs objectAtIndex:0];
    XDSElement *object = [self createObject:cert];
    XDSElement *signedInfo = [self createSignedInfo];
    NSData *hash = [[[signedInfo description] dataUsingEncoding:NSUTF8StringEncoding] SHA1Hash];
    NSLog(@"signed info hash %@", hash);
    NSData *signature = [self.delegate sign:hash];
    NSString *signatureValue = [NSString base64Encode:signature];

    [element addElement:signedInfo];
    XDSElement *signatureValueElement = [[XDSElement alloc] initWithName:@"SignatureValue"];
    attr = [[XDSAttribute alloc] initWithName:@"Id" andValue:@"SignatureValue0"];
    signatureValueElement.content = signatureValue;
    
    [element addElement:signatureValueElement];
    [element addElement:[self createKeyInfo:certs]];
    [element addElement:object];
    
 //   LOG_ELEMENT
    return element;
}

-(void)sign:(NSArray*)certs {
    for (NSDictionary *data in self.datas) {
        XDSElement *dataElement = [self createDataFile:data];
        [self.root addElement:dataElement];
    }
    
    [self.root addElement:[self createSignature:certs]];
 //   NSLog(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>%@", [self.root description]);
}
@end
