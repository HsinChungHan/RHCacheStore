//
//  CodableCacheStore.swift
//
//
//  Created by Chung Han Hsin on 2024/1/27.
//

import Foundation


public final class CodableCacheStore: CacheStore {
    private(set) var cache: [String: Data] = [:]
    
    let storeURL: URL
    public init(storeURL: URL) {
        self.storeURL = storeURL
        loadCache { _ in }
    }
    
    public func delete(with id: String, completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        self.concurrentQueue.async(flags: .barrier) {
            self.cache.removeValue(forKey: id)
            self.saveCache { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(()):
                    self.loadCache(completion: completion)
                default:
                    return
                }
            }
        }
    }
    
    public func insert(with id: String, data: Data, completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        self.concurrentQueue.async(flags: .barrier) {
            self.cache[id] = data
            self.saveCache { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(()):
                    self.loadCache(completion: completion)
                default:
                    return
                }
            }
        }
    }
    
    public func retrieve(with id: String, completion: @escaping (Result<Data, CacheStoreError>) -> Void) {
        concurrentQueue.sync { [weak self] in
            guard let self else { return }
            guard let data = self.cache[id] else {
                completion(.failure(.failureRetrival))
                return
            }
            completion(.success(data))
        }
    }
}

// MARK: - Helpers
extension CodableCacheStore: CacheStorePrivateHelpers {
    func saveCache(completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            do {
                let data = try JSONSerialization.data(withJSONObject: self.cache, options: [])
                try data.write(to: self.storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(.failureSaveCache))
            }
        }
    }
    
    func loadCache(completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            do {
                let data = try Data.init(contentsOf: self.storeURL)
                let decodedCache = try JSONSerialization.jsonObject(with: data, options: [])
                if let cache = decodedCache as? [String: Data] {
                    self.cache = cache
                    completion(.success(()))
                }
            } catch {
                completion(.failure(.failureSaveCache))
            }
        }
    }
}

// MARK: - Computed Properties
private extension CodableCacheStore {
    var concurrentQueue: DispatchQueue {
        DispatchQueue(label: "CodableCacheStore.Queue", qos: .userInitiated, attributes: .concurrent)
    }
}

