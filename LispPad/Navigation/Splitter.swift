//
//  Splitter.swift
//  SplitView
//
//  Created by Steven Harris on 8/18/21.
//

import SwiftUI

/// The Splitter that separates the `primary` from `secondary` views in a `Split` view.
/// The Splitter holds onto `styling`, which is accessed by Split to determine the
/// `visibleThickness` by which the `primary` and `secondary` views are separated. The
/// `styling` also publishes `previewHide`, which specifies whether we are previewing
/// what Split will look like when we hide a side. The Splitter uses `previewHide`
/// to change its `dividerColor` to `.clear` when being previewed, while Split uses it
/// to determine whether the spacing between views should be `visibleThickness` or zero.
public struct Splitter: View {
  
  @Binding private var orientation: SplitOrientation
  
  private let color: Color
  private let inset: CGFloat
  private let width: CGFloat
  private let invisibleWidth: CGFloat
  
  public var body: some View {
    ZStack {
      switch self.orientation {
        case .horizontal:
          Color.clear
            .frame(width: self.invisibleWidth)
            .padding(0)
          RoundedRectangle(cornerRadius: self.width / 2)
            .fill(self.color)
            .frame(width: self.width)
            .padding(EdgeInsets(top: inset, leading: 0, bottom: inset, trailing: 0))
        case .vertical:
          Color.clear
            .frame(height: self.invisibleWidth)
            .padding(0)
          RoundedRectangle(cornerRadius: self.width / 2)
            .fill(self.color)
            .frame(height: self.width)
            .padding(EdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset))
      }
    }
    .contentShape(Rectangle())
    // Change of cursor on hover on macOS
    .onHover { inside in
      #if targetEnvironment(macCatalyst) || os(macOS)
      // With nested split views, it's possible to transition from one Splitter to another,
      // so we always need to pop the current cursor (a no-op when it's the only one). We
      // may or may not push the hover cursor depending on whether it's inside or not.
      NSCursor.pop()
      if inside {
        self.layout == .horizontal ? NSCursor.resizeLeftRight.push()
                                   : NSCursor.resizeUpDown.push()
      }
      #endif
    }
  }
  
  public init(orientation: Binding<SplitOrientation>,
              color: Color = .gray,
              inset: CGFloat = 6,
              width: CGFloat = 2,
              invisibleWidth: CGFloat = 30) {
    self._orientation = orientation
    self.color = color
    self.inset = inset
    self.width = width
    self.invisibleWidth = invisibleWidth
  }
}

struct Splitter_Previews: PreviewProvider {
  static var previews: some View {
    Splitter(orientation: .constant(.horizontal))
    Splitter(orientation: .constant(.horizontal),
             color: .red,
             inset: 2,
             width: 8,
             invisibleWidth: 30)
    Splitter(orientation: .constant(.vertical))
    Splitter(orientation: .constant(.vertical),
             color: .red,
             inset: 2,
             width: 8,
             invisibleWidth: 30)
  }
}
