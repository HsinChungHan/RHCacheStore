//
//  ActorCodableCacheStoreUseCaseTests.swift
//
//
//  Created by Chung Han Hsin on 2024/1/30.
//

import XCTest
@testable import RHCacheStore

class ActorCodableCacheStoreUseCaseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        undoSideEffects()
    }
    
    // MARK: - Retrieve
    func test_retrieve_deliversEmptyOnEmptyCache() async {
        let sut = makeSUT()
        await retrivalExpect(sut, with: anyID, retrieve: .failure(CacheStoreError.failureLoadCache))
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() async {
        let sut = makeSUT()
        await retrivalExpect(sut, with: anyID, retrieve: .failure(CacheStoreError.failureLoadCache))
        await retrivalExpect(sut, with: anyID, retrieve: .failure(CacheStoreError.failureLoadCache))
    }
    
    func test_retrieve_deliversInsertedDataOnNonEmptyCache() async {
        let sut = makeSUT()
        let cache = (id: anyRates1.id, json: anyRates1.json)

        await insert(cache, to: sut)
        await retrivalExpect(sut, with: anyRates1.id, retrieve: .found(anyRates1.json))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() async {
        let sut = makeSUT()
        let cache = (id: anyRates1.id, json: anyRates1.json)
        await insert(cache, to: sut)
        await retrivalExpect(sut, with: anyRates1.id, retrieve: .found(anyRates1.json))
        await retrivalExpect(sut, with: anyRates1.id, retrieve: .found(anyRates1.json))
    }
    
    // MARK: - Insert
    func test_insert_overridesPreviousInsertedCacheValues() async {
        let sut = makeSUT()
        let cache1 = (id: anyRates1.id, json: anyRates1.json)
        let cache2 = (id: anyRates2.id, json: anyRates2.json)
        await insert(cache1, to: sut)
        await insert(cache2, to: sut)
        await retrivalExpect(sut, with: anyRates1.id, retrieve: .found(anyRates1.json))
        await retrivalExpect(sut, with: anyRates2.id, retrieve: .found(anyRates2.json))
    }
    
    // MARK: - Delete
    func test_delete_hasNoSideEffectOnEmptyCache() async {
        let sut = makeSUT()
        let cache1 = (id: anyRates1.id, json: anyRates1.json)
        await delete(with: cache1.id, from: sut)
    }
    
    func test_delete_deliversEmptyCacheOnInsertedCache() async {
        let sut = makeSUT()
        let cache1 = (id: anyRates1.id, json: anyRates1.json)
        await insert(cache1, to: sut)
        await delete(with: cache1.id, from: sut)
        await retrivalExpect(sut, with: anyRates1.id, retrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() async {
        var operationResults = [String]()
        let sut = makeSUT()

        // Operation 1: Insertion
        let op1 = "Operation 1: Insertion"
        let cache1 = (id: anyRates1.id, json: anyRates1.json)
        if await insert(cache1, to: sut) == nil {
            operationResults.append(op1)
        }

        // Operation 2: Deletion
        let op2 = "Operation 2: Deletion"
        if await delete(with: cache1.id, from: sut) == nil {
            operationResults.append(op2)
        }

        // Operation 3: Insertion
        let op3 = "Operation 3: Insertion"
        let cache2 = (id: anyRates2.id, json: anyRates2.json)
        if await insert(cache2, to: sut) == nil {
            operationResults.append(op3)
        }
        
        XCTAssertEqual(operationResults, [op1, op2, op3])
    }
}

private extension ActorCodableCacheStoreUseCaseTests {
    var anyID: String { "anyID" }
    var cacheDirectoryURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    var anyTestSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    var anyRates1: (id: String, json: [String: Double]) {
        let id = "anyRates1ID"
        let json = [
            "AED": 1.0,
            "AUD": 2.0,
            "TWD": 3.0
        ]
        return (id, json)
    }
    
    var anyRates2: (id: String, json: [String: Double]) {
        let id = "anyRates2ID"
        let json = [
            "USD": 3.0,
            "JPD": 2.0,
            "BIC": 1.0
        ]
        return (id, json)
    }
    
    
    func makeSUT(storeURL: URL?=nil, file: StaticString=#file, line: UInt=#line) -> ActorCacheStore {
        let sut = ActorCodableCacheStore.init(storeURL: storeURL ?? anyTestSpecificStoreURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

private extension ActorCodableCacheStoreUseCaseTests {
    func toData(with json: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: json, options: [])
    }
    
    func toJson(with data: Data) -> [String: Any] {
        try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
    
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: anyTestSpecificStoreURL)
    }
    
    func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    func undoSideEffects() {
        deleteStoreArtifacts()
    }
    
    func retrivalExpect(_ sut: ActorCacheStore, with id: String, retrieve expectedResult: RetriveCacheResult, file: StaticString=#file, line: UInt=#line) async {
        let result = await sut.retrieve(with: id)
        switch (result, expectedResult) {
        case (.empty, .empty):
            break
        case (.failure(_), .failure(_)):
            break
        case let (.found(json), .found(expectedJson)):
            XCTAssertEqual(json as? [String: Double], expectedJson as? [String: Double], file: file, line: line)
        default:
            XCTFail("Expect \(expectedResult), but get \(result) instead", file: file, line: line)
        }
    }
    
    @discardableResult
    func insert(_ cache: (id: String, json: Any), to sut: ActorCacheStore, file: StaticString=#file, line: UInt=#line) async -> Error? {
        var receivedError: Error? = nil
        do {
            try await sut.insert(with: cache.id, json: cache.json)
        } catch let error {
            receivedError = error
        }
        return receivedError
    }
    
    @discardableResult
    func delete(with id: String, from sut: ActorCacheStore, file: StaticString=#file, line: UInt=#line) async -> Error? {
        var receivedError: Error? = nil
        do {
            try await sut.delete(with: id)
        } catch let error {
            receivedError = error
        }
        return receivedError
    }
}

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString=#file, line: UInt=#line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Protential memory leak.", file: file, line: line)
        }
    }
}
