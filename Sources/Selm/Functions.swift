//
// Created by 和泉田 領一 on 2019-04-08.
//

import Foundation

struct Memoizations {
    class Key: Hashable {
        class Box: Equatable {
            var value:   Any
            let compare: (Any) -> Bool

            init<A: Equatable>(_ value: A) {
                self.value = value
                self.compare = { target in
                    guard let target = target as? A else { return false }
                    return value == target
                }
            }

            static func == (lhs: Box, rhs: Box) -> Bool {
                return lhs.compare(rhs.value)
            }
        }

        var keyPath: [AnyKeyPath]
        var value: [Box]
        var resultType: String

        init(keyPath: [AnyKeyPath], value: [Box], resultType: String) {
            self.keyPath = keyPath
            self.value = value
            self.resultType = resultType
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(keyPath)
            hasher.combine(resultType)
        }

        static func == (lhs: Key, rhs: Key) -> Bool {
            if lhs.resultType != rhs.resultType { return false }
            if lhs.keyPath != rhs.keyPath { return false }
            return true
        }

        static func compareDeep(lhs: Key, rhs: Key) -> Bool {
            if lhs.resultType != rhs.resultType { return false }
            if lhs.keyPath != rhs.keyPath { return false }
            if lhs.value != rhs.value { return false }
            return true
        }
    }

    class Value {
        var value: Any? { return anyObject ?? any }
        private var any: Any?
        private weak var anyObject: AnyObject?

        init<T>(_ value: T) {
            if Mirror(reflecting: value).displayStyle == .class {
                self.any = .none
                self.anyObject = value as AnyObject
            } else {
                self.any = value
                self.anyObject = .none
            }
        }
    }

    static var store = [Key: Value]()
    static func add(key: Key, value: Value) {
        if store.count > 50000 {
            store.removeAll()
        }
        store.removeValue(forKey: key)
        store[key] = value
    }
}

public func dependsOn<Root, Value: Equatable, R>(_ keyPath: KeyPath<Root, Value>, _ root: Root, _ f: (Value) -> R) -> R {
    let value = root[keyPath: keyPath]
    let key = Memoizations.Key(keyPath: [keyPath], value: [.init(value)], resultType: String(describing: R.self))

    let result: R
    if let stored = Memoizations.store.first(where: { storedKey, _ in
        Memoizations.Key.compareDeep(lhs: storedKey, rhs: key)
    }),
       let res = stored.value.value as? R {
        result = res
    } else {
        result = f(value)
    }

    let weakRef = Memoizations.Value(result)
    Memoizations.add(key: key, value: weakRef)
    return result
}

public func dependsOn<Root, Value1: Equatable, Value2: Equatable, R>(_ keyPath1: KeyPath<Root, Value1>, _ keyPath2: KeyPath<Root, Value2>, _ root: Root, _ f: ((Value1, Value2)) -> R) -> R {
    let value1 = root[keyPath: keyPath1]
    let value2 = root[keyPath: keyPath2]
    let key = Memoizations.Key(keyPath: [keyPath1, keyPath2], value: [.init(value1), .init(value2)], resultType: String(describing: R.self))

    let result: R
    if let stored = Memoizations.store.first(where: { storedKey, _ in
        Memoizations.Key.compareDeep(lhs: storedKey, rhs: key)
    }),
       let res = stored.value.value as? R {
        result = res
    } else {
        result = f((value1, value2))
    }

    let weakRef = Memoizations.Value(result)
    Memoizations.add(key: key, value: weakRef)
    return result
}

public func dependsOn<Root, Value1: Equatable, Value2: Equatable, Value3: Equatable, R>(_ keyPath1: KeyPath<Root, Value1>, _ keyPath2: KeyPath<Root, Value2>, _ keyPath3: KeyPath<Root, Value3>, _ root: Root, _ f: ((Value1, Value2, Value3)) -> R) -> R {
    let value1 = root[keyPath: keyPath1]
    let value2 = root[keyPath: keyPath2]
    let value3 = root[keyPath: keyPath3]
    let key = Memoizations.Key(keyPath: [keyPath1, keyPath2, keyPath3], value: [.init(value1), .init(value2), .init(value3)], resultType: String(describing: R.self))

    let result: R
    if let stored = Memoizations.store.first(where: { storedKey, _ in
        Memoizations.Key.compareDeep(lhs: storedKey, rhs: key)
    }),
       let res = stored.value.value as? R {
        result = res
    } else {
        result = f((value1, value2, value3))
    }

    let weakRef = Memoizations.Value(result)
    Memoizations.add(key: key, value: weakRef)
    return result
}
