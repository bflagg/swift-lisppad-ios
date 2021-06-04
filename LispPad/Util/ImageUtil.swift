//
//  ImageManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 03/06/2021.
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

import UIKit
import LispKit

class ImageManager: NSObject {
  let condition = NSCondition()
  var completed = false
  var error: Error? = nil
  
  func writeImageToLibrary(_ image: UIImage, async: Bool = false) throws {
    UIImageWriteToSavedPhotosAlbum(image,
                                   self,
                                   #selector(image(_:didFinishSavingWithError:contextInfo:)),
                                   nil)
    if !async {
      self.condition.lock()
      defer {
        self.condition.unlock()
      }
      while !self.completed {
        self.condition.wait()
      }
      if let error = self.error {
        throw error
      }
    }
  }
  
  @objc func image(_ image: UIImage,
                   didFinishSavingWithError error: Error?,
                   contextInfo: UnsafeRawPointer) {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    self.error = error
    self.completed = true
    self.condition.signal()
  }
}

func iconImage(for drawing: Drawing,
               width: CGFloat = 720.0,
               height: CGFloat = 720.0,
               scale: CGFloat = 2.0,
               renderingWidth: CGFloat = 1000.0,
               renderingHeight: CGFloat = 1000.0) -> UIImage? {
  guard let context = CGContext(data: nil,
                                width: Int(renderingWidth * scale),
                                height: Int(renderingHeight * scale),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: Color.colorSpaceName,
                                bitmapInfo: CGBitmapInfo(rawValue:
                                              CGImageAlphaInfo.premultipliedFirst.rawValue)
                                            .union(.byteOrder32Little).rawValue) else {
    return nil
  }
  context.translateBy(x: 0.0, y: CGFloat(renderingHeight * scale))
  context.scaleBy(x: CGFloat(scale), y: CGFloat(-scale))
  UIGraphicsPushContext(context)
  defer {
    UIGraphicsPopContext()
  }
  drawing.draw()
  guard let cgImage = context.makeImage() else {
    return nil
  }
  let image = UIImage(cgImage: cgImage, scale: CGFloat(scale), orientation: .up)
  guard let box = contentBox(image: image),
        let res = crop(image: image,
                       rect: box,
                       size: fit(size: box.size, maxWidth: width, maxHeight: height)) else {
    return nil
  }
  return res
}

private func fit(size: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
  var scale: CGFloat = maxWidth / size.width
  if size.height * scale > maxHeight {
    scale = maxHeight / size.height
  }
  return CGSize(width: size.width * scale, height: size.height * scale)
}

private func contentBox(image: UIImage) -> CGRect? {
  guard let cgImage = image.cgImage,
        let imageData = cgImage.dataProvider?.data else {
    return nil
  }
  let scale = image.scale
  let width = cgImage.width
  let height = cgImage.height
  let pixels: UnsafePointer<UInt8> = CFDataGetBytePtr(imageData)
  var left = CGPoint(x: 0, y: 0)
  loop: for x in 0..<width {
    for y in 0..<height {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        left = CGPoint(x: x, y: y)
        break loop
      }
    }
  }
  var top = CGPoint(x: 0, y: 0)
  loop: for y in 0..<height {
    for x in 0..<width {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        top = CGPoint(x: x, y: y)
        break loop
      }
    }
  }
  var bottom = CGPoint(x: width - 1, y: height - 1)
  loop: for y in stride(from: height - 1, through: 0, by: -1) {
    for x in stride(from: width - 1, through: 0, by: -1) {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        bottom = CGPoint(x: x, y: y)
        break loop
      }
    }
  }
  var right = CGPoint(x: width - 1, y: height - 1)
  loop: for x in stride(from: width - 1, through: 0, by: -1) {
    for y in stride(from: height - 1, through: 0, by: -1) {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        right = CGPoint(x: x, y: y)
        break loop
      }
    }
  }
  return CGRect(x: left.x / scale,
                y: top.y / scale,
                width: (right.x - left.x) / scale,
                height: (bottom.y - top.y) / scale)
}

private func crop(image: UIImage, rect: CGRect, size: CGSize?) -> UIImage? {
  let imageSize = size ?? image.size
  let imageScale = image.scale
  // Create a new bitmap
  guard let context = CGContext(data: nil,
                                width: Int(imageSize.width * imageScale),
                                height: Int(imageSize.height * imageScale),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: Color.colorSpaceName,
                                bitmapInfo: CGBitmapInfo(rawValue:
                                              CGImageAlphaInfo.premultipliedFirst.rawValue)
                                            .union(.byteOrder32Little).rawValue) else {
    return nil
  }
  // Flip the coordinate system
  context.translateBy(x: 0.0, y: imageSize.height * imageScale)
  context.scaleBy(x: imageScale, y: -imageScale)
  // Scale to match the required size
  context.scaleBy(x: imageSize.width / rect.width, y: imageSize.height / rect.height)
  UIGraphicsPushContext(context)
  defer {
    UIGraphicsPopContext()
  }
  // Draw image into the bitmap
  image.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y),
             blendMode: .copy,
             alpha: 1.0)
  // Create a new image from the bitmap
  guard let cgImage = context.makeImage() else {
    return nil
  }
  let image = UIImage(cgImage: cgImage, scale: imageScale, orientation: .up)
  return image
}