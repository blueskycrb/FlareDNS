//
//  CFRulesetRule.m
//  FlareDNS
//

#import "CFRulesetRule.h"

@implementation CFRulesetRule

+ (instancetype)ruleFromDictionary:(NSDictionary *)dict phase:(CFRulesetPhase)phase {
    CFRulesetRule *rule = [[CFRulesetRule alloc] init];
    rule.phase = phase;
    rule.ruleID = [dict[@"id"] isKindOfClass:[NSString class]] ? dict[@"id"] : @"";
    rule.descriptionText = [dict[@"description"] isKindOfClass:[NSString class]] ? dict[@"description"] : @"Untitled Rule";
    rule.expression = [dict[@"expression"] isKindOfClass:[NSString class]] ? dict[@"expression"] : @"";
    rule.action = [dict[@"action"] isKindOfClass:[NSString class]] ? dict[@"action"] : @"";
    rule.enabled = dict[@"enabled"] ? [dict[@"enabled"] boolValue] : YES;
    rule.rawDictionary = dict ?: @{};

    NSDictionary *actionParameters = [dict[@"action_parameters"] isKindOfClass:[NSDictionary class]] ? dict[@"action_parameters"] : nil;
    NSDictionary *fromValue = [actionParameters[@"from_value"] isKindOfClass:[NSDictionary class]] ? actionParameters[@"from_value"] : nil;
    NSDictionary *targetURL = [fromValue[@"target_url"] isKindOfClass:[NSDictionary class]] ? fromValue[@"target_url"] : nil;
    rule.targetURL = [targetURL[@"value"] isKindOfClass:[NSString class]] ? targetURL[@"value"] : nil;
    rule.statusCode = [fromValue[@"status_code"] respondsToSelector:@selector(integerValue)] ? [fromValue[@"status_code"] integerValue] : 0;
    rule.preserveQueryString = fromValue[@"preserve_query_string"] ? [fromValue[@"preserve_query_string"] boolValue] : NO;

    return rule;
}

+ (NSString *)apiPhaseFromPhase:(CFRulesetPhase)phase {
    switch (phase) {
        case CFRulesetPhaseDynamicRedirect: return @"http_request_dynamic_redirect";
        case CFRulesetPhaseCacheSettings: return @"http_request_cache_settings";
    }
}

+ (NSString *)displayNameForPhase:(CFRulesetPhase)phase {
    switch (phase) {
        case CFRulesetPhaseDynamicRedirect: return @"Redirect Rules";
        case CFRulesetPhaseCacheSettings: return @"Cache Rules";
    }
}

+ (NSString *)shortNameForPhase:(CFRulesetPhase)phase {
    switch (phase) {
        case CFRulesetPhaseDynamicRedirect: return @"Redirect";
        case CFRulesetPhaseCacheSettings: return @"Cache";
    }
}

@end
