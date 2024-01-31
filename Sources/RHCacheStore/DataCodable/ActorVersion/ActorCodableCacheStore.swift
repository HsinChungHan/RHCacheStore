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
            }
        } catch {
            throw CacheStoreError.failureLoadCache
        }
    }
}
