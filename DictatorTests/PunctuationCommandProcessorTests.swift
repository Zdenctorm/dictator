import XCTest
@testable import Dictator

final class PunctuationCommandProcessorTests: XCTestCase {
    func testTeckaToPeriod() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Dnes je hezky tečka"),
            "Dnes je hezky ."
        )
    }

    func testCarkaToComma() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Ahoj čárka jak se máš"),
            "Ahoj , jak se máš"
        )
    }

    func testOtaznikVariants() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Co děláš otázník"),
            "Co děláš ?"
        )
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Co děláš otaznik"),
            "Co děláš ?"
        )
    }

    func testVykricnikToExclamation() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Pozor vykřičník"),
            "Pozor !"
        )
    }

    func testNovyRadekToNewline() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "První nový řádek druhý"),
            "První \ndruhý"
        )
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "První novy radek druhý"),
            "První \ndruhý"
        )
    }

    func testNovyOdstavecToDoubleNewline() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Úvod nový odstavec pokračování"),
            "Úvod \n\npokračování"
        )
    }

    func testCaseInsensitive() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Konec TEČKA"),
            "Konec ."
        )
    }

    func testDoesNotReplaceInsideWords() {
        let unchanged = "Tečkovaný text zůstane beze změny"
        XCTAssertEqual(PunctuationCommandProcessor.apply(to: unchanged), unchanged)
    }

    func testMultipleCommandsInOneString() {
        XCTAssertEqual(
            PunctuationCommandProcessor.apply(to: "Ahoj čárka světe tečka nový řádek Další věta"),
            "Ahoj , světe . \nDalší věta"
        )
    }

    func testEmptyStringUnchanged() {
        XCTAssertEqual(PunctuationCommandProcessor.apply(to: ""), "")
    }
}
