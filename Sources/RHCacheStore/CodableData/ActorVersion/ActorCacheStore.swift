//
//  ActorCacheStore.swift
//
//
//  Created by Chung Han Hsin on 2024/1/30.
//

import Foundation



public protocol ActorCacheStore {
    func delete(with id: String) async throws
    func insert(with id: String, json: Any) async throws
    func retrieve(with id: String) async -> RetriveCacheResult
    func saveCache() async throws
    func loadCache() async throws
}
