//
//  CFDomainExpiryService.m
//  FlareDNS
//
//  Created by Vincent Yang on 2/28/26.
//

#import "CFDomainExpiryService.h"

static NSTimeInterval const kCacheTTL = 24 * 60 * 60; // 24 hours

@interface CFDomainExpiryService ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *cache;
@end

@implementation CFDomainExpiryService

+ (instancetype)shared {
    static CFDomainExpiryService *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CFDomainExpiryService alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 15;
        _session = [NSURLSession sessionWithConfiguration:config];
        _cache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)fetchExpiryForDomain:(NSString *)domain completion:(void(^)(NSString * _Nullable registeredAt, NSString * _Nullable expiresAt, NSError * _Nullable error))completion {
    // Check cache
    NSDictionary *cached = self.cache[domain];
    if (cached) {
        NSDate *timestamp = cached[@"timestamp"];
        if ([[NSDate date] timeIntervalSinceDate:timestamp] < kCacheTTL) {
            completion(cached[@"registeredAt"], cached[@"expiresAt"], nil);
            return;
        }
        [self.cache removeObjectForKey:domain];
    }

    NSString *urlString = [NSString stringWithFormat:@"https://domexp.owo.nz/query?q=%@",
                           [domain stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSURL *url = [NSURL URLWithString:urlString];

    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, error);
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSError *statusError = [NSError errorWithDomain:@"CFDomainExpiryService"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Domain expiry information unavailable"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, statusError);
            });
            return;
        }

        NSError *parseError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError || ![json isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, parseError ?: [NSError errorWithDomain:@"CFDomainExpiryService"
                                                                      code:-1
                                                                  userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            });
            return;
        }

        NSString *registeredAt = json[@"registered_at"];
        NSString *expiresAt = json[@"expires_at"];

        if (!registeredAt || !expiresAt) {
            NSError *missingError = [NSError errorWithDomain:@"CFDomainExpiryService"
                                                        code:-2
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Missing date information"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, nil, missingError);
            });
            return;
        }

        // Cache the result
        self.cache[domain] = @{
            @"registeredAt": registeredAt,
            @"expiresAt": expiresAt,
            @"timestamp": [NSDate date]
        };

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(registeredAt, expiresAt, nil);
        });
    }];
    [task resume];
}

@end
