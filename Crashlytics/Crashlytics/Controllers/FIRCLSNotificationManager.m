// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "Crashlytics/Crashlytics/Controllers/FIRCLSNotificationManager.h"

#import "Crashlytics/Crashlytics/Components/FIRCLSApplication.h"
#import "Crashlytics/Crashlytics/Components/FIRCLSGlobals.h"
#import "Crashlytics/Crashlytics/Components/FIRCLSUserLogging.h"
#include "Crashlytics/Crashlytics/Helpers/FIRCLSDefines.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@implementation FIRCLSNotificationManager

- (void)registerNotificationListener {
  [self captureInitialNotificationStates];

#if TARGET_OS_IOS
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willBecomeActive:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeInactive:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
#if !CLS_TARGET_OS_XR
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didChangeOrientation:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(didChangeUIOrientation:)
             name:UIApplicationDidChangeStatusBarOrientationNotification
           object:nil];
#pragma clang diagnostic pop
#endif  // !CLS_TARGET_OS_XR

#elif CLS_TARGET_OS_OSX
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(willBecomeActive:)
                                               name:@"NSApplicationWillBecomeActiveNotification"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didBecomeInactive:)
                                               name:@"NSApplicationDidResignActiveNotification"
                                             object:nil];
#endif
}

- (void)captureInitialNotificationStates {
#if TARGET_OS_IOS && (!CLS_TARGET_OS_XR)
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  UIInterfaceOrientation statusBarOrientation =
      [FIRCLSApplicationSharedInstance() statusBarOrientation];
#endif  // TARGET_OS_IOS && (!CLS_TARGET_OS_XR)

  // It's nice to do this async, so we don't hold up the main thread while doing three
  // consecutive IOs here.
  dispatch_async(FIRCLSGetLoggingQueue(), ^{
    FIRCLSUserLoggingWriteInternalKeyValue(FIRCLSInBackgroundKey, @"0");
#if TARGET_OS_IOS && (!CLS_TARGET_OS_XR)
    FIRCLSUserLoggingWriteInternalKeyValue(FIRCLSDeviceOrientationKey,
                                           [@(orientation) description]);
    FIRCLSUserLoggingWriteInternalKeyValue(FIRCLSUIOrientationKey,
                                           [@(statusBarOrientation) description]);
#endif  // TARGET_OS_IOS && (!CLS_TARGET_OS_XR)
  });
}

- (void)willBecomeActive:(NSNotification *)notification {
  FIRCLSUserLoggingRecordInternalKeyValue(FIRCLSInBackgroundKey, @NO);
}

- (void)didBecomeInactive:(NSNotification *)notification {
  FIRCLSUserLoggingRecordInternalKeyValue(FIRCLSInBackgroundKey, @YES);
}

#if TARGET_OS_IOS && (!CLS_TARGET_OS_XR)
- (void)didChangeOrientation:(NSNotification *)notification {
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

  FIRCLSUserLoggingRecordInternalKeyValue(FIRCLSDeviceOrientationKey, @(orientation));
}

- (void)didChangeUIOrientation:(NSNotification *)notification {
  UIInterfaceOrientation statusBarOrientation =
      [FIRCLSApplicationSharedInstance() statusBarOrientation];

  FIRCLSUserLoggingRecordInternalKeyValue(FIRCLSUIOrientationKey, @(statusBarOrientation));
}
#endif  // TARGET_OS_IOS && (!CLS_TARGET_OS_XR)

@end
