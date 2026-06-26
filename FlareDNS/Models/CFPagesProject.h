//
//  CFPagesProject.h
//  FlareDNS
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CFPagesProject : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *subdomain;
@property (nonatomic, copy) NSArray<NSString *> *domains;
@property (nonatomic, copy, nullable) NSString *latestDeploymentURL;
@property (nonatomic, copy, nullable) NSString *productionBranch;
@property (nonatomic, copy, nullable) NSString *latestCommitHash;
@property (nonatomic, copy, nullable) NSString *latestCommitMessage;

+ (instancetype)projectFromDictionary:(NSDictionary *)dict;
- (nullable NSString *)primaryURLString;
- (nullable NSString *)displayURLString;

@end

NS_ASSUME_NONNULL_END