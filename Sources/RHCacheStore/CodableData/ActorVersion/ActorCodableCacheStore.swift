//
//  File.swift
//  
//
//  Created by Chung Han Hsin on 2024/1/30.
//

import Foundation

public actor ActorCodableCacheStore: ActorCacheStore {
    private var cache: [String: Any] = [:]
    private let storeURL: URL

    private var isCacheLoad = false
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func delete(with id: String) async throws {
        cache.removeValue(forKey: id)
        do {
            try await saveCache()
        } catch {
            throw CacheStoreError.failureDeletion
        }
    }
    
    public func insert(with id: String, json: Any) async throws {
        cache[id] = json
        do {
            try await saveCache()
        } catch {
            throw CacheStoreError.failureInsertion
        }
    }
    
    public func retrieve(with id: String) async -> RetriveCacheResult {
        if !isCacheLoad {
            do {
                try await loadCache()
            } catch let error {
                return .failure(error)
            }
        }
        
        guard let json = cache[id] else {
            return .empty
        }
        return .found(json)
    }
    
    public func saveCache() async throws {
        do {
            let data = try JSONSerialization.data(withJSONObject: cache, options: [])
            try data.write(to: storeURL)
        } catch {
            throw CacheStoreError.failureSaveCache
        }
    }
    
    public func loadCache() async throws {
        do {
            let data = try Data(contentsOf: storeURL)
            let decodedCache = try JSONSerialization.jsonObject(with: data, options: [])

            if let cache = decodedCache as? [String: Any] {
                self.cache = cache
                isCacheLoad = true
            }
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                // Create a new file if it's not existed
                try createEmptyCacheFile()
                self.cache = [:]
                isCacheLoad = true
            } else if error.domain == NSCocoaErrorDomain && error.code == NSFileReadCorruptFileError {
                throw CacheStoreError.corruptFile
            } else {
                throw CacheStoreError.failureLoadCache
            }
        }
    }

    private func createEmptyCacheFile() throws {
        let emptyData = "{}".data(using: .utf8) ?? Data()
        try emptyData.write(to: storeURL, options: .atomic)
    }
}
