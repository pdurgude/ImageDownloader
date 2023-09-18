//
//  File.swift
//  
//
//  Created by Prathamesh Durgude on 04/09/23.
//

import Foundation
import UIKit

struct ImageDownsampler {
  
  static let shared = ImageDownsampler()
  
  private let downsampleQueue = DispatchQueue(label: "com.ImageDownloader.ImageDownsampleQueue")
  
  private init() { }
  
  func prepareThumbnail(from image: UIImage, of size: CGSize) async -> UIImage? {
    if #available(iOS 15.0, *) {
      return await image.byPreparingThumbnail(ofSize: size)
    } else {
      return await withCheckedContinuation { continuation in
        downsample(image: image, to: size) { image in
          continuation.resume(returning: image)
        }
      }
    }
  }
  
  private func downsample(image: UIImage, to size: CGSize, completion: @escaping (UIImage?) -> Void) {
    downsampleQueue.async {
      let imageSourceOption = [
        kCGImageSourceShouldCache : kCFBooleanFalse
      ] as CFDictionary
      
      let thumbnailOptions = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
      ] as [CFString : Any] as CFDictionary
      
      guard let imageData = image.jpegData(compressionQuality: 1.0) else {
        completion(nil)
        return
      }
      guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOption),
            let thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions)
      else {
        completion(nil)
        return
      }
      
      completion(UIImage(cgImage: thumbnailImage))
    }
  }
}
