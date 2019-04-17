import XCTest
import Foundation
@testable import Selm

final class RunnerTests: XCTestCase {
    func testCreate() {
        let exp = expectation(description: #function)
        exp.expectedFulfillmentCount = 3
        exp.assertForOverFulfill = true

        var firstDispatched  = false
        var secondDispatched = false
        var thirdDispatched  = false
        let dispatch = Runner<Model, Msg>.create(initialize: { return (Model(string: "test"), Cmd.ofMsg(.first)) },
                                                 update: { msg, model in
                                                     defer { exp.fulfill() }

                                                     var model = model
                                                     model.string = "test updated"

                                                     switch msg {
                                                     case .first:
                                                         firstDispatched = true
                                                         return (model, Cmd.ofMsg(.second))
                                                     case .second:
                                                         secondDispatched = true
                                                         return (model, Cmd.none)
                                                     case .third:
                                                         thirdDispatched = true
                                                         return (model, Cmd.none)
                                                     }
                                                 },
                                                 view: { model, dispatch in
                                                     XCTAssertEqual(model.string, "test updated")
                                                 })
        dispatch(.third)

        waitForExpectations(timeout: 100.0)

        XCTAssertTrue(firstDispatched)
        XCTAssertTrue(secondDispatched)
        XCTAssertTrue(thirdDispatched)
    }

    func testAsync() {
        let exp = expectation(description: #function)
        exp.assertForOverFulfill = false
        exp.expectedFulfillmentCount = 3
        let dispatch = Runner<Model, Msg>.create(initialize: { (Model(string: "test"), .none) },
                                                 update: { msg, model in
                                                     var model = model
                                                     defer { exp.fulfill() }

                                                     switch msg {
                                                     case .first:
                                                         model.string = "first"
                                                         return (model,
                                                                 Cmd.ofAsyncMsg { fulfill in
                                                                     DispatchQueue
                                                                         .global()
                                                                         .asyncAfter(deadline: .now() + .seconds(1)) {
                                                                             fulfill(.second)
                                                                         }
                                                                 })
                                                     case .second:
                                                         model.string = "second"
                                                         return (model, .none)
                                                     case .third:
                                                         model.string = "third"
                                                         return (model, .none)
                                                     }
                                                 },
                                                 view: { model, dispatch in print(model.string) })
        dispatch(.first)
        dispatch(.third)

        waitForExpectations(timeout: 2.0)
    }


    struct Model {
        var string: String
    }

    enum Msg {
        case first
        case second
        case third
    }
}
