//
//  SearchField.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/04/2021.
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

struct SearchField: View {
  @State var showNext: Bool = false
  @State var searchText: String = ""
  @State var lastSearchText: String = ""
  @Binding var showCancel: Bool
  let search: (String) -> Bool
  
  var body: some View {
    HStack {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("Search", text: $searchText, onEditingChanged: { isEditing in
          self.showCancel = true
        }, onCommit: {
          if !self.searchText.isEmpty {
            let more = self.search(self.searchText)
            withAnimation(.default) {
              self.lastSearchText = searchText
              self.showNext = more
            }
          }
        })
        .foregroundColor(.primary)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        Button(action: {
          withAnimation(.default) {
            self.searchText = ""
            self.lastSearchText = ""
            self.showNext = false
          }
        }) {
          Image(systemName: "xmark.circle.fill")
            .opacity(self.searchText == "" ? 0 : 1)
        }
      }
      .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
      .foregroundColor(.secondary)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(12)
      if showNext && showCancel && self.searchText == self.lastSearchText {
        Button("Next") {
          UIApplication.shared.endEditing(true)
          if !self.searchText.isEmpty {
            let more = self.search(self.searchText)
            withAnimation(.default) {
              self.showNext = more
            }
          }
        }
        .foregroundColor(Color(.systemBlue))
      }
      if showCancel  {
        Button("Cancel") {
          UIApplication.shared.endEditing(true)
          withAnimation(.default) {
            self.searchText = ""
            self.showCancel = false
            self.showNext = false
          }
        }
        .foregroundColor(Color(.systemBlue))
      }
    }
    .padding(EdgeInsets(top: 8, leading: 8, bottom: -1, trailing: 8))
    .animation(.default)
  }
}

struct SearchField_Previews: PreviewProvider {
  @State static var showCancel = true
  static var previews: some View {
    SearchField(showCancel: $showCancel) { str in
       return true
    }
  }
}
