//
//  Entity.swift
//  LoCo
//
//  Created by Drew McCormack on 17/01/2019.
//  Copyright © 2019 The Mental Faculty B.V. All rights reserved.
//

import Foundation
import LLVS

fileprivate var encoder: JSONEncoder = .init()
fileprivate var decoder: JSONDecoder = .init()

class PropertyLoader<KeyType: StoreKey> {
    let store: Store
    let reference: Value.Reference
    
    init(store: Store, reference: Value.Reference) {
        self.store = store
        self.reference = reference
    }
    
    func load<PropertyType: Codable>(_ storeKey: KeyType) throws -> PropertyType? {
        let key = storeKey.key(forIdentifier: reference.identifier)
        let value = try store.value(.init(key), prevailingAt: reference.version)!
        return try decoder.decode(PropertyType.self, from: value.data)
    }
}

class PropertyChangeGenerator<KeyType: StoreKey> {
    let store: Store
    let valueIdentifier: Value.Identifier
    var propertyChanges: [Value.Change] = []
    
    init(store: Store, valueIdentifier: Value.Identifier) {
        self.store = store
        self.valueIdentifier = valueIdentifier
    }
    
    func generate<PropertyType: Codable & Equatable>(_ storeKey: KeyType, propertyValue: PropertyType?, originalPropertyValue: PropertyType?) throws {
        let key = storeKey.key(forIdentifier: valueIdentifier)
        guard propertyValue != originalPropertyValue else { return }
        if let propertyValue = propertyValue {
            let data = try encoder.encode(propertyValue)
            let value = Value(identifier: .init(key), version: nil, data: data)
            let change: Value.Change = originalPropertyValue == nil ? .insert(value) : .update(value)
            propertyChanges.append(change)
        } else if originalPropertyValue != nil {
            let change: Value.Change = .remove(.init(key))
            propertyChanges.append(change)
        }
    }
}

protocol StoreKey {
    func key(forIdentifier identifier: Value.Identifier) -> String
}

extension Store {
    func valueContainer<KeyType: StoreKey>(_ reference: Value.Reference) -> PropertyLoader<KeyType> {
        return PropertyLoader(store: self, reference: reference)
    }
}
