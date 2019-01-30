#import "RNPermissionHandlerBluetoothPeripheral.h"

@import CoreBluetooth;

@interface RNPermissionHandlerBluetoothPeripheral() <CBPeripheralManagerDelegate>

@property (nonatomic) CBPeripheralManager* peripheralManager;
@property (nonatomic, copy) void (^resolve)(RNPermissionStatus status);
@property (nonatomic, copy) void (^reject)(NSError *error);

@end

@implementation RNPermissionHandlerBluetoothPeripheral

+ (NSArray<NSString *> * _Nullable)usageDescriptionKeys {
  return [RNPermissionsManager hasBackgroundModeEnabled:@"bluetooth-peripheral"] ? @[@"NSBluetoothPeripheralUsageDescription"] : nil;
}

- (void)checkWithResolver:(void (^)(RNPermissionStatus status))resolve
             withRejecter:(void (__unused ^)(NSError *error))reject {
  switch ([CBPeripheralManager authorizationStatus]) {
    case CBPeripheralManagerAuthorizationStatusNotDetermined:
      return resolve(RNPermissionStatusNotDetermined);
    case CBPeripheralManagerAuthorizationStatusRestricted:
      return resolve(RNPermissionStatusRestricted);
    case CBPeripheralManagerAuthorizationStatusDenied:
      return resolve(RNPermissionStatusDenied);
    case CBPeripheralManagerAuthorizationStatusAuthorized:
      return resolve(RNPermissionStatusAuthorized);
  }
}

- (void)requestWithOptions:(__unused NSDictionary * _Nullable)options
              withResolver:(void (^)(RNPermissionStatus status))resolve
              withRejecter:(void (^)(NSError *error))reject {
  _resolve = resolve;
  _reject = reject;
  
  _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:@{
    CBPeripheralManagerOptionShowPowerAlertKey: @false,
  }];
  
  [_peripheralManager startAdvertising:@{}];
}

- (void)peripheralManagerDidUpdateState:(nonnull CBPeripheralManager *)peripheral {
  CBManagerState state = peripheral.state;
  
  [_peripheralManager stopAdvertising];
  _peripheralManager = nil;
  
  switch (state) {
    case CBManagerStatePoweredOn:
      return [self checkWithResolver:_resolve withRejecter:_reject];
    case CBManagerStatePoweredOff:
    case CBManagerStateResetting:
    case CBManagerStateUnsupported:
      return _resolve(RNPermissionStatusNotAvailable);
    case CBManagerStateUnknown:
      return _resolve(RNPermissionStatusNotDetermined);
    case CBManagerStateUnauthorized:
      return _resolve(RNPermissionStatusDenied);
  }
}

@end
