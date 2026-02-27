//
//  CFDomainExpiryService.h
//  FlareDNS
//
//  Created by Vincent Yang on 2/28/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CFDomainExpiryService : NSObject

+ (instancetype)shared;

- (void)fetchExpiryForDomain:(NSString *)domain completion:(void(^)(NSString * _Nullable registeredAt, NSString * _Nullable expiresAt, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
