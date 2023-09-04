//
//  ImageCache.swift
//
//  Created by Prathamesh Durgude on 04/09/23.
//

import Foundation
import UIKit

actor ImageCache {
  static let shared = ImageCache()
  
  private var imageCache = [String: UIImage]()
  
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
  
  func cachedImage(for url: String) -> UIImage? {
    imageCache[url]
  }
  
  func cache(image: UIImage, for url: String) {
      imageCache[url] = image
  }
}
