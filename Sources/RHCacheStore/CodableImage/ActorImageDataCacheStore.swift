//
//  ActorImageDataCacheStore.swift
//  
//
//  Created by Chung Han Hsin on 2024/1/31.
//

import Foundation

public enum RetrieveImageDataCacheResult {
    case empty
    case found(Data)
    case failure(Error)
}

public protocol ActorImageDataCacheStore {
    func insert(with id: String, imageData: Data) async throws
    func retrieve(with id: String) async -> RetrieveImageDataCacheResult
    func delete(with id: String) async throws
    func saveCache() async throws
    func loadCache() async throws
}
