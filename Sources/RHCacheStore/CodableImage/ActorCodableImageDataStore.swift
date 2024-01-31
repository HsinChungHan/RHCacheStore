//
//  ActorCodableImageDataStore.swift
//
//
//  Created by Chung Han Hsin on 2024/1/31.
//

import Foundation

public actor ActorCodableUIImageStore: ActorImageDataCacheStore {
    private var isCacheLoad = false
    private let storeURL: URL
    private var cache: [String: URL] = [:]
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func insert(with id: String, imageData: Data) async throws {
        let fileURL = makeImageFileURL(with: id)
        do {
            try imageData.write(to: fileURL)
            cache[id] = fileURL
        } catch {
            throw CacheStoreError.failureInsertion
        }
    }
    
    public func retrieve(with id: String) async -> RetrieveImageDataCacheResult {
        if !isCacheLoad {
            do {
                try await loadCache()
            } catch let error {
                return .failure(error)
            }
        }
        guard let fileURL = cache[id] else { return .empty }
        do {
            let imageData = try Data(contentsOf: fileURL)
            return .found(imageData)
        } catch {
            return .empty
        }
    }
    
    public func delete(with id: String) async throws {
        guard let fileURL = cache[id] else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
            cache.removeValue(forKey: id)
        } catch {
            throw CacheStoreError.failureDeletion
        }
    }
    
    public func saveCache() async throws {
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: imageURLsFileURL)
        } catch {
            throw CacheStoreError.failureSaveCache
        }
    }
    
    public func loadCache() async throws {
        do {
            let data = try Data(contentsOf: imageURLsFileURL)
            cache = try JSONDecoder().decode([String: URL].self, from: data)
        } catch {
            throw CacheStoreError.failureLoadCache
        }
    }
}

private extension ActorCodableUIImageStore {
    func makeImageFileURL(with id: String) -> URL {
        storeURL.appendingPathComponent(id)
    }
    
    var imageURLsFileURL: URL {
        storeURL.appendingPathComponent("imageCacheIndex.json")
    }
}
