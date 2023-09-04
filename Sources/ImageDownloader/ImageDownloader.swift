import UIKit

public struct ImageDownloader {
  let imageCache: ImageCache
  let inflightRequestsManager: InflightRequestManager
  
  public init() {
    self.init(imageCache: .shared, inflightRequestManager: .shared)
  }
  
  private init(imageCache: ImageCache, inflightRequestManager: InflightRequestManager) {
    self.imageCache = imageCache
    self.inflightRequestsManager = inflightRequestManager
  }
  
  func downloadImage(for url: URL) async throws -> UIImage? {
    defer {
      Task {
        print("Defere - Will remove inflight requests for url \(url)")
        await inflightRequestsManager.removeInflightRequest(for: url)
      }
    }
    
    await inflightRequestsManager.waitForInflightRequest(for: url)
    
    if let cachedImage = await imageCache.cachedImage(for: url.absoluteString) {
      print("Found image in Cache for url: \(url)")
      return cachedImage
    }
    
    print("image not found in Cache for url: \(url)")
    let (imageData, _) = try await URLSession.shared.data(from: url)
    let image = UIImage(data: imageData)
    if let image = image {
      await imageCache.cache(image: image, for: url.absoluteString)
    }
    
    print("Downloaded and cached image for url \(url)")
    return image
  }
}
