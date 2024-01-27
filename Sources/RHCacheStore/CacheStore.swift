//
//  Store.swift
//
//
//  Created by Chung Han Hsin on 2024/1/27.
//

import Foundation

public enum CacheStoreError: Error {
    case failureDeletion
    case failureInsertion
    case failureRetrival
    case failureSaveCache
    case failureLoadCache
}

public protocol CacheStore {
    func delete(with id: String, completion: @escaping (Result<Void, CacheStoreError>) -> Void)
    func insert(with id: String, data: Data, completion: @escaping (Result<Void, CacheStoreError>) -> Void)
    func retrieve(with id: String, completion: @escaping (Result<Data, CacheStoreError>) -> Void)
}

protocol CacheStorePrivateHelpers {
    func saveCache(completion: @escaping (Result<Void, CacheStoreError>) -> Void)
    func loadCache(completion: @escaping (Result<Void, CacheStoreError>) -> Void)
}
