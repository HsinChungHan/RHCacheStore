//
//  CacheStoreError.swift
//
//
//  Created by Chung Han Hsin on 2024/1/30.
//

import Foundation

public enum CacheStoreError: Error {
    case failureDeletion
    case failureInsertion
    case failureRetrival
    case failureSaveCache
    case failureLoadCache
    case corruptFile
}
