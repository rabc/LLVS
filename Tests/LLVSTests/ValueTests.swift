import XCTest
import Foundation
@testable import LLVS

final class ValueTests: XCTestCase {
    
    let fm = FileManager.default

    var store: Store!
    var rootURL: URL!
    var valuesURL: URL!
    var version: Version!
    var originalValue: Value!
    
    override func setUp() {
        super.setUp()
        rootURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        valuesURL = rootURL.appendingPathComponent("values")
        store = try! Store(rootDirectoryURL: rootURL)
        
        originalValue = Value(identifier: .init("ABCDEF"), version: nil, properties: ["name":"Bob"])
        var values = [originalValue!]
        version = try! store.addVersion(basedOn: nil, storing: &values)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: rootURL)
        super.tearDown()
    }
    
    func testSavingValueCreatesSubDirectoriesAndFile() {
        let v = version.identifier.identifierString
        let map = v.index(v.startIndex, offsetBy: 1)
        let versionSubDir = String(v[..<map])
        let versionFile = String(v[map...])
        XCTAssert(fm.fileExists(atPath: valuesURL.appendingPathComponent("AB").path))
        XCTAssert(fm.fileExists(atPath: valuesURL.appendingPathComponent("AB/CDEF").path))
        XCTAssert(fm.fileExists(atPath: valuesURL.appendingPathComponent("AB/CDEF/\(versionSubDir)").path))
        XCTAssert(fm.fileExists(atPath: valuesURL.appendingPathComponent("AB/CDEF/\(versionSubDir)/\(versionFile).json").path))
    }
    
    func testSavedFileContainsValue() {
        let v = version.identifier.identifierString
        let map = v.index(v.startIndex, offsetBy: 1)
        let versionSubDir = String(v[..<map])
        let versionFile = String(v[map...])
        let file = valuesURL.appendingPathComponent("AB/CDEF/\(versionSubDir)/\(versionFile).json")
        let decoder = JSONDecoder()
        let value = try! decoder.decode(Value.self, from: Data(contentsOf: file))
        XCTAssertEqual(value.identifier.identifierString, originalValue.identifier.identifierString)
        XCTAssertEqual(value.version!, version!)
        XCTAssertEqual(value.properties["name"]!, "Bob")
    }
    
    func testFetchingNonExistentVersionOfValueGivesNil() {
        let version = Version(identifier: .init(UUID().uuidString), predecessors: nil)
        let fetchedValue = try! store.value(originalValue.identifier, storedAt: version.identifier)
        XCTAssertNil(fetchedValue)
    }
    
    func testFetchingSavedVersionOfValue() {
        let value = try! store.value(originalValue.identifier, storedAt: version.identifier)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.identifier.identifierString, originalValue.identifier.identifierString)
        XCTAssertEqual(value!.version!, version!)
        XCTAssertEqual(value!.properties["name"]!, "Bob")
    }
    
    func testFetchingAllVersionOfValue() {
        let newValue = Value(identifier: .init("ABCDEF"), version: nil, properties: ["name":"Dave"])
        var values = [newValue]
        let predecessor = Version.Predecessors(identifierOfFirst: version.identifier, identifierOfSecond: nil)
        let newVersion = try! store.addVersion(basedOn: predecessor, storing: &values)

        let fetchedValues = try! store.values(newValue.identifier)
        
        XCTAssertEqual(fetchedValues.count, 2)
        
        let versions: Set<Version.Identifier> = [version!.identifier, newVersion.identifier]
        let fetchedVersions = Set(fetchedValues.map({ $0.version!.identifier }))
        XCTAssertEqual(versions, fetchedVersions)
    }
    
    func testAllVersionsOfValue() {
        let newValue = Value(identifier: .init("ABCDEF"), version: nil, properties: ["name":"Dave"])
        var values = [newValue]
        let newVersion = try! store.addVersion(basedOn: nil, storing: &values)
        
        let versionIdentifiers = try! store.versionIdentifiers(for: newValue.identifier)
        
        XCTAssertEqual(versionIdentifiers.count, 2)
        
        let versions: Set<Version.Identifier> = [version!.identifier, newVersion.identifier]
        let fetchedVersions = Set(versionIdentifiers)
        XCTAssertEqual(versions, fetchedVersions)
    }
    
    static var allTests = [
        ("testSavingValueCreatesSubDirectoriesAndFile", testSavingValueCreatesSubDirectoriesAndFile),
        ("testSavedFileContainsValue", testSavedFileContainsValue),
        ("testFetchingNonExistentVersionOfValueGivesNil", testFetchingNonExistentVersionOfValueGivesNil),
        ("testFetchingSavedVersionOfValue", testFetchingSavedVersionOfValue),
        ("testFetchingAllVersionOfValue", testFetchingAllVersionOfValue),
        ("testAllVersionsOfValue", testAllVersionsOfValue),
        ]
}
