//
//  CodeEditorView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
//  Copyright © 2021 Matthias Zenger. All rights reserved.
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

import SwiftUI

struct CodeEditorView: View {
  @State var text: String = "This is a test"
  
  var body: some View {
    CodeEditor(text: $text,
               onEditingChanged: {},
               onCommit: {},
               onTextChange: { str in })
      .defaultFont(.monospacedSystemFont(ofSize: 13, weight: .regular))
      .autocorrectionType(.no)
      .autocapitalizationType(.none)
      .multilineTextAlignment(.leading)
      .keyboardType(.default)
  }
}

struct CodeEditorView_Previews: PreviewProvider {
  static var previews: some View {
    CodeEditorView()
  }
}
