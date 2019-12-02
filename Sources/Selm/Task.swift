//
//  Task.swift
//  Selm
//
//  Created by Kyle Kirkland on 11/29/19.
//

import Foundation
import Combine

class CancellablesHolder {
    
    var cancellables = Set<AnyCancellable>()
    
}

public struct Task<Value, ErrorType: Swift.Error> {
    
    public typealias Observer = (Result<Value, ErrorType>) -> Void
    public typealias Work = (@escaping Observer) -> Void

    let work: Work
    let cancellablesHolder = CancellablesHolder()
    
    public init(work: @escaping  Work) {
        self.work = work
    }
    
    public init(workWithCancellables: @escaping (@escaping Observer, inout Set<AnyCancellable>) -> Void) {
        let holder = self.cancellablesHolder
        self.work = { fulfill in
            workWithCancellables(fulfill, &holder.cancellables)
        }
    }
    
    public init(result: Result<Value, ErrorType>) {
        self.init { fulfill in
            fulfill(result)
        }
    }
    
    public init(value: Value) {
        self.init(result: .success(value))
    }
    
    public static func attempt<Msg>(
        mapResult: @escaping (Result<Value, ErrorType>) -> Msg,
        task: Task<Value, ErrorType>) -> Cmd<Msg>
    {
        return .ofTask(mapResult: mapResult, task: task)
    }
    
    public func flatMap<NewValue>(
        mapTask: @escaping (Value) -> Task<NewValue, ErrorType>) -> Task<NewValue, ErrorType> {
        return Task<NewValue, ErrorType> { fulfill in
            self.work { (oldResult: Result<Value, ErrorType>) in
                switch oldResult {
                case .success(let oldValue):
                    let mappedTask = mapTask(oldValue)
                    mappedTask.work(fulfill)
                case .failure(let error):
                    fulfill(.failure(error))
                }
            }
        }
    }
    
    public func map<NewValue>(transform: @escaping (Value) -> NewValue) -> Task<NewValue, ErrorType> {
        return flatMap { value in
            return Task<NewValue, ErrorType>(value: transform(value))
        }
    }
    
}
