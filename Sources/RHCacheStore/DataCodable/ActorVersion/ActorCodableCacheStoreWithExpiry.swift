//
//  ActorCodableCacheStoreWithExpiry.swift
//
//
//  Created by Chung Han Hsin on 2024/1/30.
//

import Foundation

public actor ActorCodableCacheStoreWithExpiry: ActorCacheStore {
    private var expiryDates: [String: Date] = [:]
    private let expiryTimeInterval: TimeInterval
    private let storeURL: URL
    private let codableCacheStore: ActorCodableCacheStore // Assuming CodableCacheStore is also refactored to conform to ActorCacheStore

    public init(expiryTimeInterval: TimeInterval, storeURL: URL) {
        self.expiryTimeInterval = expiryTimeInterval
        self.storeURL = storeURL
        self.codableCacheStore = ActorCodableCacheStore(storeURL: storeURL)
        Task {
            do {
               try await loadCache()
            } catch {
                print("🛑 Failed to load cache!")
            }
            
        }
    }
    
    public func delete(with id: String) async throws {
        do {
            expiryDates.removeValue(forKey: id)
            try await saveCache()
            try await codableCacheStore.delete(with: id)
        } catch {
            throw CacheStoreError.failureDeletion
        }
    }
    
    public func insert(with id: String, json: Any) async throws {
        do {
            expiryDates[id] = Date().addingTimeInterval(expiryTimeInterval)
            try await saveCache()
            try await codableCacheStore.insert(with: id, json: json)
        } catch {
            throw CacheStoreError.failureInsertion
        }
    }
    
    public func retrieve(with id: String) async -> RetriveCacheResult {
        guard
            let expiryDate = expiryDates[id],
            Date() >= expiryDate
        else {
            try? await delete(with: id)
            return .empty
        }
        return await codableCacheStore.retrieve(with: id)
    }
}

// MARK: - ActorCacheStorePrivateHelpers
extension ActorCodableCacheStoreWithExpiry: ActorCacheStorePrivateHelpers {
    func saveCache() async throws {
        do {
            let data = try JSONEncoder().encode(expiryDates)
            try data.write(to: expiryDatesStoreURL)
        } catch {
            throw CacheStoreError.failureSaveCache
        }
    }
    
    func loadCache() async throws {
        do {
            let data = try Data(contentsOf: expiryDatesStoreURL)
            self.expiryDates = try JSONDecoder().decode([String: Date].self, from: data)
        } catch {
            throw CacheStoreError.failureLoadCache
        }
    }
}

// MARK: - Computed Properties
private extension ActorCodableCacheStoreWithExpiry {
    var expiryDatesStoreURL: URL {
        storeURL.appendingPathExtension("expiry")
    }
}
