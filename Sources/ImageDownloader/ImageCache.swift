//
//  ImageCache.swift
//
//  Created by Prathamesh Durgude on 04/09/23.
//

import Foundation
import UIKit

actor ImageCache {
  
  private struct ImageCacheKey: Hashable {
    let urlString: String
    let size: CGSize
    
    static func == (lhs: ImageCacheKey, rhs: ImageCacheKey) -> Bool {
      return lhs.urlString == rhs.urlString && lhs.size == rhs.size
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(urlString)
      hasher.combine(size.width)
      hasher.combine(size.height)
    }
  }
  
  static let shared = ImageCache()
  
  private var imageCache = [ImageCacheKey: UIImage]()
  
  private init() {
    Task {
      await MainActor.run {
        NotificationCenter.default.addObserver(
          self,
          selector: Selector(("didRecieveMemoryWarning:")),
          name: UIApplication.didReceiveMemoryWarningNotification,
          object: nil
        )
      }
    }
  }
  
  private func didRecieveMemoryWarning(notification: Notification) {
    imageCache.removeAll()
  }

  
  func cachedImage(for url: String, size: CGSize = .zero) -> UIImage? {
    var key = ImageCacheKey(urlString: url, size: size)
    return imageCache[key]
  }
  
  func cache(image: UIImage, for url: String, size: CGSize = .zero) {
    let key = ImageCacheKey(urlString: url, size: size)
    imageCache[key] = image
  }
}
