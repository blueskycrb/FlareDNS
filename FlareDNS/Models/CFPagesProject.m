//
//  CFPagesProject.m
//  FlareDNS
//

#import "CFPagesProject.h"

@implementation CFPagesProject

+ (instancetype)projectFromDictionary:(NSDictionary *)dict {
    CFPagesProject *project = [[CFPagesProject alloc] init];
    project.name = [dict[@"name"] isKindOfClass:[NSString class]] ? dict[@"name"] : @"";
    project.subdomain = [dict[@"subdomain"] isKindOfClass:[NSString class]] ? dict[@"subdomain"] : nil;
    project.productionBranch = [dict[@"production_branch"] isKindOfClass:[NSString class]] ? dict[@"production_branch"] : nil;

    NSMutableArray<NSString *> *domains = [NSMutableArray array];
    NSArray *rawDomains = [dict[@"domains"] isKindOfClass:[NSArray class]] ? dict[@"domains"] : @[];
    for (id item in rawDomains) {
        if ([item isKindOfClass:[NSString class]] && [(NSString *)item length] > 0) {
            [domains addObject:item];
        }
    }
    if (project.subdomain.length > 0 && ![domains containsObject:project.subdomain]) {
        [domains addObject:project.subdomain];
    }
    if (domains.count == 0 && project.name.length > 0) {
        [domains addObject:[NSString stringWithFormat:@"%@.pages.dev", project.name]];
    }
    project.domains = domains;

    NSDictionary *latestDeployment = [dict[@"latest_deployment"] isKindOfClass:[NSDictionary class]] ? dict[@"latest_deployment"] : nil;
    if (!latestDeployment) {
        latestDeployment = [dict[@"canonical_deployment"] isKindOfClass:[NSDictionary class]] ? dict[@"canonical_deployment"] : nil;
    }
    project.latestDeploymentURL = [latestDeployment[@"url"] isKindOfClass:[NSString class]] ? latestDeployment[@"url"] : nil;

    NSDictionary *trigger = [latestDeployment[@"deployment_trigger"] isKindOfClass:[NSDictionary class]] ? latestDeployment[@"deployment_trigger"] : nil;
    NSDictionary *metadata = [trigger[@"metadata"] isKindOfClass:[NSDictionary class]] ? trigger[@"metadata"] : nil;
    project.latestCommitHash = [metadata[@"commit_hash"] isKindOfClass:[NSString class]] ? metadata[@"commit_hash"] : nil;
    project.latestCommitMessage = [metadata[@"commit_message"] isKindOfClass:[NSString class]] ? metadata[@"commit_message"] : nil;

    return project;
}

- (nullable NSString *)primaryURLString {
    NSString *domain = self.domains.firstObject;
    if (domain.length == 0) {
        return self.latestDeploymentURL;
    }
    if ([domain hasPrefix:@"http://"] || [domain hasPrefix:@"https://"]) {
        return domain;
    }
    return [@"https://" stringByAppendingString:domain];
}

- (nullable NSString *)displayURLString {
    NSString *primary = [self primaryURLString];
    if (primary.length > 0) {
        return primary;
    }
    return self.latestDeploymentURL;
}

@end