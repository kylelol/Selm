//
//  ContentPage.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/08/24.
//

import Foundation
import Combine
import Swiftx
import Operadics
import Selm

struct ContentPage: SelmPage {
    struct Model: Equatable {
        var count: Int = 0
        var url: String = ""
        var historyPageModel: HistoryPage.Model
        var safariPageModel: SafariPage.Model?
        
        static func == (lhs: Model, rhs: Model) -> Bool {
            if lhs.count != rhs.count { return false }
            return true
        }
    }
    
    enum Msg {
        case historyPageMsg(HistoryPage.Msg)
        case safariPageMsg(SafariPage.Msg)
        case step(Step)
        case stepDelayed(Step)
        case stepDelayedTask(Step)
        case stepTimer(Step)
        case stepDelayedTaskFinished(Result<Step, Error>)
        case updateCount(Step)
        case showSafariPage
    }
    
    static func initialize() -> (Model, Cmd<Msg>) {
        let (m, c) = HistoryPage.initialize()
        return (Model(historyPageModel: m), c.map(Msg.historyPageMsg))
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .historyPageMsg(let hvMsg):
            switch HistoryPage.update(hvMsg, model.historyPageModel) {
            case (let m, let c, .noOp):
                return (model |> set(\.historyPageModel, m),
                        c.map(Msg.historyPageMsg))
                
            case (let m, let c, .updated(count: let count)):
                return (model |> set(\.historyPageModel, m) |> set(\.count, count),
                        c.map(Msg.historyPageMsg))
            }
            
        case .safariPageMsg(let sMsg):
            guard let sModel = model.safariPageModel else { return (model, .none) }
            switch SafariPage.update(sMsg, sModel) {
            case (let m, let c, .noOp):
                return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
            case (_, let c, .dismiss):
                return (model |> set(\.safariPageModel, .none), c.map(Msg.safariPageMsg))
            }
            
        case .step(let step):
            return (model,
                    .batch([.ofMsg(.updateCount(step)),
                            .ofMsg(.historyPageMsg(.add(step)))]))
            
        case .stepDelayed(let step):
            return (model,
                    .ofAsyncCmd { fulfill in
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            .batch([.ofMsg(.updateCount(step)),
                                    .ofMsg(.historyPageMsg(.add(step)))])
                            |> fulfill
                        }
                    })
            
        case .stepDelayedTask(let step):
            return (
                model,
                incrementTimer(step: step)
                    |> Task.attempt(toMsg: { .stepDelayedTaskFinished($0) })
            )
        case .stepDelayedTaskFinished(let result):
            switch result {
            case .success(let step):
                let newModel = model
                    |> set(\.count, step.step(count: model.count))
                    |> set(\.historyPageModel.history, model.historyPageModel.history + [step])
                return (newModel, .none)
            case .failure:
                return (model, .none)
            }
            
        case .updateCount(let step):
            return (model |> set(\.count, step.step(count: model.count)), .none)
            
        case .stepTimer(let step):
            return (
                model,
                incrementTimerCombine(step: step)
                    |> Task.attempt(toMsg: { .stepDelayedTaskFinished($0) })
            )
            
        case .showSafariPage:
            let (m, c) = SafariPage.initialize(url: URL(string: "https://www.google.com")!)
            return (model |> set(\.safariPageModel, m), c.map(Msg.safariPageMsg))
        }
    }
    
    static func incrementTimer(step: Step) -> Task<Step, Error> {
        return Task { fulfill in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                fulfill(.success(step))
            }
        }
    }
    
    static func incrementTimerCombine(step: Step) -> Task<Step, Error> {
        return Task { observer, set in
            Timer.publish(every: 2.0, on: RunLoop.main, in: .common)
                .autoconnect()
                .first()
                .sink { _ in
                    observer(.success(step))
                }.store(in: &set)
        }
    }
}
