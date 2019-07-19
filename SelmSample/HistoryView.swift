//
//  HistoryView.swift
//  SelmSample
//
//  Created by 和泉田 領一 on 2019/07/01.
//

import SwiftUI
import Combine
import Swiftx
import Operadics
import Selm

struct HistoryView : View {
    struct Model: Equatable {
        var history: [Step]
                
        init(history: [Step]) { self.history = history }
        
        static func ==(_ lhs: Model, _ rhs: Model) -> Bool {
            if lhs.history != rhs.history { return false }
            return true
        }
    }
    
    enum Msg {
        case add(Step)
        case onDisappear
    }
    
    enum ExternalMsg {
        case noOp
        case dismiss
    }
    
    static func initialize(history: [Step]) -> (Model, Cmd<Msg>) {
        (Model(history: history), .none)
    }
    
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>, ExternalMsg) {
        switch msg {
        case .add(let step):
            return (model |> set(\.history, model.history + [step]), .none, .noOp)
            
        case .onDisappear:
            return (model, .none, .dismiss)
        }
    }
    
    @ObjectBinding var driver: Driver<Msg, Model>
    
    var body: some View {
        VStack(spacing: 20.0) {
            List {
                ForEach(driver.model.history, id: \.self) { step in
                    Text(step.string)
                }
            }
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView(driver: .init(model: .init(history: []), dispatch: { _ in }))
    }
}
#endif
