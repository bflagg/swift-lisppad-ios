//
//  InterpreterState.swift
//  LispPad
//
//  Created by Matthias Zenger on 02/11/2023.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SwiftUI
import MarkdownKit

class InterpreterState: ObservableObject {
  @Published var consoleInput = ""
  @Published var consoleInputRange = NSRange(location: 0, length: 0)
  @Published var focused: Bool = false
  @Published var consoleTab: Int = 1
  @Published var selectedPreferencesTab = 0
  @Published var showProgressView: String? = nil
}
