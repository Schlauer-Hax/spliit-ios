import XCTest

final class ExpenseCalculationTests: SpliitUITestCase {
    @MainActor
    func testCalculationsResolveOnBlurAndSaveWhileFocused() async throws {
        func formatted(_ amount: Decimal) -> String {
            amount.formatted(.number.precision(.fractionLength(2)).grouping(.never))
        }
        let group = try await api.createGroup(name: "Calculations", participants: ["Ana", "Bruno"])
        let app = launchApp(
            recentGroups: SpliitTestAPI.recentGroupsJSON([(group.id, "Calculations")])
        )
        let ana = try XCTUnwrap(group.participants["Ana"])
        let bruno = try XCTUnwrap(group.participants["Bruno"])
        app.staticTexts[AccessibilityID.GroupsList.rowTitle(group.id)].tap()
        app.buttons[AccessibilityID.ExpenseList.emptyAddButton].tap()

        let amount = app.textFields[AccessibilityID.ExpenseForm.amountField]
        replaceText(in: amount, with: "11,4+7,3")
        XCTAssertEqual(amount.value as? String, "11,4+7,3")
        capture(app, "expense-calculation-keyboard")
        replaceText(in: app.textFields[AccessibilityID.ExpenseForm.titleField], with: "Dinner")
        XCTAssertEqual(amount.value as? String, formatted(18.7))

        scrollUntilHittable(app.buttons["Amount"], in: app)
        app.buttons["Amount"].tap()
        let first = app.textFields[AccessibilityID.ExpenseForm.participantValue(ana)]
        let second = app.textFields[AccessibilityID.ExpenseForm.participantValue(bruno)]
        scrollUntilHittable(second, in: app)
        replaceText(in: first, with: "5+6,4")
        replaceText(in: second, with: "7/0")
        XCTAssertEqual(first.value as? String, formatted(11.4))
        first.tap()
        XCTAssertEqual(second.value as? String, "7/0")
        app.buttons[AccessibilityID.ExpenseForm.saveButton].tap()
        assertExists(app.staticTexts[AccessibilityID.ExpenseForm.error], "Division by zero must not save.")

        replaceText(in: second, with: "14,6/2")
        // Saving must also work before the active field has lost focus.
        app.buttons[AccessibilityID.ExpenseForm.saveButton].tap()
        assertExists(app.staticTexts["Dinner"], "The calculated expense should save.")
        app.staticTexts["Dinner"].tap()
        assertExists(amount, "The saved expense should reopen.")
        XCTAssertEqual(amount.value as? String, formatted(18.7))
        scrollUntilHittable(second, in: app)
        XCTAssertEqual(first.value as? String, formatted(11.4))
        XCTAssertEqual(second.value as? String, formatted(7.3))
        capture(app, "expense-calculated-shares")
    }
}
