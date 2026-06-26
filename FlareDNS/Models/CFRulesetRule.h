//
//  CFRulesetRule.h
//  FlareDNS
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CFRulesetPhase) {
    CFRulesetPhaseDynamicRedirect,
    CFRulesetPhaseCacheSettings
};

@interface CFRulesetRule : NSObject

@property (nonatomic, copy) NSString *ruleID;
@property (nonatomic, assign) CFRulesetPhase phase;
@property (nonatomic, copy) NSString *descriptionText;
@property (nonatomic, copy) NSString *expression;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy, nullable) NSString *targetURL;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) BOOL preserveQueryString;
@property (nonatomic, copy) NSDictionary *rawDictionary;

+ (instancetype)ruleFromDictionary:(NSDictionary *)dict phase:(CFRulesetPhase)phase;
+ (NSString *)apiPhaseFromPhase:(CFRulesetPhase)phase;
+ (NSString *)displayNameForPhase:(CFRulesetPhase)phase;
+ (NSString *)shortNameForPhase:(CFRulesetPhase)phase;

@end

NS_ASSUME_NONNULL_END
