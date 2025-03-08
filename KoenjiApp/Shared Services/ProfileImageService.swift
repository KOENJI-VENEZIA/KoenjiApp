import Foundation
import UIKit
import FirebaseStorage
import OSLog

/// A service for managing profile images in Google Cloud Storage
///
/// This service handles uploading, retrieving, and deleting profile images from Google Cloud Storage.
/// It provides methods for uploading images, getting download URLs, and deleting images.
class ProfileImageService {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    nonisolated(unsafe) static let shared = ProfileImageService()
    
    /// Storage reference for Firebase Storage
    private let storage = Storage.storage().reference()
    
    /// Logger for tracking image operations
    private let logger = Logger(subsystem: "com.koenjiapp", category: "ProfileImageService")
    
    /// Image cache to avoid repeated downloads
    private var imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Configure cache
        imageCache.countLimit = 100 // Maximum number of images to cache
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB cache limit
    }
    
    // MARK: - Public Methods
    
    /// Uploads a profile image to Google Cloud Storage
    ///
    /// This method uploads a profile image to Google Cloud Storage and returns the download URL.
    ///
    /// - Parameters:
    ///   - image: The image to upload
    ///   - profileID: The ID of the profile to associate with the image
    ///   - completion: A closure that is called when the upload is complete
    func uploadProfileImage(_ image: UIImage, for profileID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            logger.error("Failed to convert image to JPEG data")
            completion(.failure(NSError(domain: "com.koenjiapp", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
            return
        }
        
        // Create a storage reference for this profile image
        let imagePath = "profile_images/\(profileID).jpg"
        let imageRef = storage.child(imagePath)
        
        // Upload the image data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Failed to upload image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get the download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    self.logger.error("Failed to get download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    self.logger.error("Download URL is nil")
                    completion(.failure(NSError(domain: "com.koenjiapp", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"])))
                    return
                }
                
                // Cache the image
                self.imageCache.setObject(image, forKey: downloadURL.absoluteString as NSString)
                
                self.logger.info("Image uploaded successfully: \(downloadURL.absoluteString)")
                completion(.success(downloadURL))
            }
        }
    }
    
    /// Deletes a profile image from Google Cloud Storage
    ///
    /// This method deletes a profile image from Google Cloud Storage.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile whose image should be deleted
    ///   - completion: A closure that is called when the deletion is complete
    func deleteProfileImage(for profileID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imagePath = "profile_images/\(profileID).jpg"
        let imageRef = storage.child(imagePath)
        
        imageRef.delete { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Failed to delete image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            self.logger.info("Image deleted successfully for profile: \(profileID)")
            completion(.success(()))
        }
    }
    
    /// Loads a profile image from Google Cloud Storage or cache
    ///
    /// This method loads a profile image from Google Cloud Storage or the local cache.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load
    ///   - completion: A closure that is called when the image is loaded
    func loadProfileImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let urlString = url.absoluteString
        
        // Check if the image is in the cache
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            logger.debug("Image loaded from cache: \(urlString)")
            completion(cachedImage)
            return
        }
        
        // Download the image
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Failed to download image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                self.logger.error("Failed to create image from data")
                completion(nil)
                return
            }
            
            // Cache the image
            self.imageCache.setObject(image, forKey: urlString as NSString)
            
            self.logger.debug("Image downloaded successfully: \(urlString)")
            completion(image)
        }.resume()
    }
} 
