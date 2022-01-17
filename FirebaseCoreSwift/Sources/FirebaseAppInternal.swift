// Copyright 2022 Google LLC
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

import FirebaseCore
import ObjectiveC

extension FirebaseApp {
  static var isDefaultAppConfigured: Bool {
    // First two arguments are the class (FirebaseApp) and the selector name.
    typealias VoidBoolFunc = @convention(c) (AnyClass, Selector) -> Bool
    let sel = NSSelectorFromString("isDefaultAppConfigured")
    let isDefaultAppConfigured = generatePrivateClassFunc(sel, from: self, type: VoidBoolFunc.self)
    return isDefaultAppConfigured(self, sel)
  }

  static func registerLibrary(name: String, version: String) {
    // First two arguments are the class (FirebaseApp) and the selector name.
    typealias StringStringVoidFunc = @convention(c) (AnyClass, Selector, NSString, NSString) -> Void
    let sel = NSSelectorFromString("registerLibrary:withVersion:")
    let registerLibFunc = generatePrivateClassFunc(sel, from: self, type: StringStringVoidFunc.self)
    registerLibFunc(self, sel, NSString(string: name), NSString(string: version))
  }

  /// A concatenated string representing all the third-party libraries and version numbers.
  /// Redirects to the Objective-C method of the same name.
  static func firebaseUserAgent() -> String {
    // First two arguments are the class (FirebaseApp) and the selector name.
    typealias VoidStringFunc = @convention(c) (AnyClass, Selector) -> NSString
    let sel = NSSelectorFromString("firebaseUserAgent")
    let userAgentFunc = generatePrivateClassFunc(sel, from: self, type: VoidStringFunc.self)
    return String(userAgentFunc(self, sel))
  }
}

/// Fetches a class function of the provided type using `NSStringFromSelector` and the given class.
/// This may crash if the selector doesn't exist, so use at your own risk.
private func generatePrivateClassFunc<T: NSObject, U>(_ selector: Selector,
                                                      from klass: T.Type,
                                                      type: U.Type) -> U {
  guard klass.responds(to: selector) else {
    fatalError("""
    Firebase tried to get a method named \(selector) from a class named \(klass) but it doesn't
    exist. It may have been changed recently. Please file an issue in the firebase-ios-sdk repo
    if you see this error, and mention the Swift products that you're using along with this
    message. Sorry about that!
    https://github.com/firebase/firebase-ios-sdk/issues/new/choose
    """)
  }
  let methodImp = klass.method(for: selector)
  return unsafeBitCast(methodImp, to: type)
}
