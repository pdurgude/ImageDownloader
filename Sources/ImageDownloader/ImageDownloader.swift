import UIKit

public struct ImageDownloader {
  let imageCache: ImageCache
  let inflightRequestsManager: InflightRequestManager
  let imageDownsampler: ImageDownsampler
  
  public init() {
    self.init(imageCache: .shared, inflightRequestManager: .shared, imageDownsampler: .shared)
  }
  
  private init(
    imageCache: ImageCache,
    inflightRequestManager: InflightRequestManager,
    imageDownsampler: ImageDownsampler
  ) {
    self.imageCache = imageCache
    self.inflightRequestsManager = inflightRequestManager
    self.imageDownsampler = imageDownsampler
  }
  
  public func downloadImage(for url: URL, size: CGSize = .zero) async throws -> UIImage? {
    defer {
      Task {
        await inflightRequestsManager.removeInflightRequest(for: url)
      }
    }
    
    await inflightRequestsManager.waitForInflightRequest(for: url)
    
    if let cachedImage = await cachedImage(for: url, size: size) {
      return cachedImage
    }
    
    let (imageData, _) = try await URLSession.shared.data(from: url)
    var image = UIImage(data: imageData)
    if let image = image {
      await imageCache.cache(image: image, for: url.absoluteString)
      
      // If Image needs to be downsampled to specified size then downsample it and store separate copy of image in cache for downsampled size.
      if size != .zero, let downsampledImage = await imageDownsampler.prepareThumbnail(from: image, of: size) {
        await imageCache.cache(image: downsampledImage, for: url.absoluteString, size: size)
        return downsampledImage
      }
    }
    
    return image
  }
  
  
}

// MARK: - Private methods

extension ImageDownloader {
  private func cachedImage(for url: URL, size: CGSize) async -> UIImage? {
    if let cachedImage = await imageCache.cachedImage(
      for: url.absoluteString,
      size: size
    ) {
      return cachedImage
    } else if size != .zero,
              let cachedImage = await imageCache.cachedImage(
                for: url.absoluteString,
                size: .zero
              ) {
      // If Original image is present in cache then downsample it to required size and cache it.
      if let downsampledImage = await imageDownsampler.prepareThumbnail(
        from: cachedImage,
        of: size
      ) {
        await imageCache.cache(
          image: downsampledImage,
          for: url.absoluteString,
          size: size
        )
        return downsampledImage
      }
    }
    return nil
  }
}
