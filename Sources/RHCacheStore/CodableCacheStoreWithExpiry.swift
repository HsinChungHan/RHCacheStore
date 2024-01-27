//
//  CodableCacheStoreWithExpiry.swift
//
//
//  Created by Chung Han Hsin on 2024/1/27.
//

import Foundation

public class CodableCacheStoreWithExpiry: CacheStore {
    private(set) var expiryDates: [String: Date] = [:]
    
    let expiryTimeInterval: TimeInterval
    let storeURL: URL
    public init(expiryTimeInterval: TimeInterval, storeURL: URL) {
        self.expiryTimeInterval = expiryTimeInterval
        self.storeURL = storeURL
        loadCache { _ in }
    }
    
    public func delete(with id: String, completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        expiryDates.removeValue(forKey: id)
        saveCache { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(()):
                self.codableCacheStore.delete(with: id, completion: completion)
            default:
                completion(result)
            }
        }
    }
    
    public func insert(with id: String, data: Data, completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        expiryDates[id] = Date().addingTimeInterval(expiryTimeInterval)
        saveCache { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(()):
                self.codableCacheStore.insert(with: id, data: data, completion: completion)
            default:
                completion(result)
            }
        }
    }
    
    public func retrieve(with id: String, completion: @escaping (Result<Data, CacheStoreError>) -> Void) {
        guard
            let expiryDate = expiryDates[id],
            Date() <= expiryDate
        else {
            delete(with: id) { result in
                switch result {
                case let .failure(error):
                    completion(.failure(error))
                default:
                    return
                }
            }
            return
        }
        codableCacheStore.retrieve(with: id, completion: completion)
    }
}

// MARK: - Computed Properties
private extension CodableCacheStoreWithExpiry {
    var codableCacheStore: CodableCacheStore { .init(storeURL: storeURL) }
    var expiryDatesStoreURL: URL { storeURL.appendingPathExtension("expiry") }
    var concurrentQueue: DispatchQueue {
        DispatchQueue(label: "\(expiryDatesStoreURL).Queue", qos: .userInitiated, attributes: .concurrent)
    }
}

// MARK: - Helpers
extension CodableCacheStoreWithExpiry: CacheStorePrivateHelpers {
    func saveCache(completion: @escaping (Result<Void, CacheStoreError>) -> Void) {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            do {
                let data = try JSONEncoder().encode(self.expiryDates)
                try data.write(to: self.expiryDatesStoreURL)
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
                let data = try Data.init(contentsOf: self.expiryDatesStoreURL)
                let expiryDates = try JSONSerialization.jsonObject(with: data, options: [])
                guard
                    let expiryDates = expiryDates as? [String: Date]
                else {
                    return
                }
                self.expiryDates = expiryDates
                completion(.success(()))
            } catch {
                completion(.failure(.failureLoadCache))
            }
        }
    }
}
