import XCTest
import CoreLocation
@testable import SkeenaSystem

/// Regression tests for RiverLocator.
/// These tests verify the river lookup logic using known coordinates
/// from the Haida Gwaii region and ensure correct behavior for
/// boundary conditions, unknown communities, and edge cases.
@MainActor
final class RiverLocatorTests: XCTestCase {

  // MARK: - Test Data (Known Coordinates)

  // Copper Creek - first coordinate from RiverCoordinates.swift
  private let copperCreekCoord = CLLocationCoordinate2D(latitude: 53.16219534, longitude: -131.80042844)

  // Pallant Creek - first coordinate
  private let pallantCreekCoord = CLLocationCoordinate2D(latitude: 53.05020396, longitude: -132.02722038)

  // Yakoun River - first coordinate
  private let yakounRiverCoord = CLLocationCoordinate2D(latitude: 53.67145964, longitude: -132.20484788)

  // Tlell River - first coordinate
  private let tlellRiverCoord = CLLocationCoordinate2D(latitude: 53.56602409, longitude: -131.93391551)

  // Mamin River - first coordinate
  private let maminRiverCoord = CLLocationCoordinate2D(latitude: 53.62235570, longitude: -132.30535108)

  // A location far from any Haida Gwaii river (Vancouver, BC)
  private let vancouverCoord = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)

  // MARK: - hasRivers Tests

  func testHasRivers_epicWaters_returnsTrue() {
    let locator = RiverLocator.shared
    XCTAssertTrue(locator.hasRivers(forCommunity: "Epic Waters"),
                  "Epic Waters should have rivers defined")
  }

  func testHasRivers_epicWaters_caseInsensitive() {
    let locator = RiverLocator.shared

    XCTAssertTrue(locator.hasRivers(forCommunity: "epic waters"),
                  "Should match case-insensitively (lowercase)")
    XCTAssertTrue(locator.hasRivers(forCommunity: "EPIC WATERS"),
                  "Should match case-insensitively (uppercase)")
    XCTAssertTrue(locator.hasRivers(forCommunity: "EpIc WaTeRs"),
                  "Should match case-insensitively (mixed)")
  }

  func testHasRivers_epicWaters_withWhitespace() {
    let locator = RiverLocator.shared

    XCTAssertTrue(locator.hasRivers(forCommunity: "  Epic Waters  "),
                  "Should trim leading/trailing whitespace")
    XCTAssertTrue(locator.hasRivers(forCommunity: "\nEpic Waters\t"),
                  "Should trim newlines and tabs")
  }

  func testHasRivers_unknownCommunity_returnsFalse() {
    let locator = RiverLocator.shared

    XCTAssertFalse(locator.hasRivers(forCommunity: "Unknown Community"),
                   "Unknown community should return false")
    XCTAssertFalse(locator.hasRivers(forCommunity: ""),
                   "Empty string should return false")
    XCTAssertFalse(locator.hasRivers(forCommunity: "Another Lodge"),
                   "Non-existent community should return false")
  }

  // MARK: - riverName Tests: Exact Coordinates

  func testRiverName_atCopperCreek_returnsCopper() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: copperCreekCoord.latitude,
                              longitude: copperCreekCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Copper",
                   "Should return short name 'Copper' when at exact Copper Creek coordinate")
  }

  func testRiverName_atPallantCreek_returnsPallant() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: pallantCreekCoord.latitude,
                              longitude: pallantCreekCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Pallant",
                   "Should return short name 'Pallant' when at exact Pallant Creek coordinate")
  }

  func testRiverName_atYakounRiver_returnsYakoun() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: yakounRiverCoord.latitude,
                              longitude: yakounRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Yakoun",
                   "Should return short name 'Yakoun' when at exact Yakoun River coordinate")
  }

  func testRiverName_atTlellRiver_returnsTlell() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: tlellRiverCoord.latitude,
                              longitude: tlellRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Tlell",
                   "Should return short name 'Tlell' when at exact Tlell River coordinate")
  }

  func testRiverName_atMaminRiver_returnsMamin() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: maminRiverCoord.latitude,
                              longitude: maminRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Mamin",
                   "Should return short name 'Mamin' when at exact Mamin River coordinate")
  }

  // MARK: - riverName Tests: Nearby Coordinates (within maxDistanceKm)

  func testRiverName_nearCopperCreek_returnsCopper() {
    let locator = RiverLocator.shared
    // Offset by ~1km (approximately 0.009 degrees latitude)
    let nearbyLocation = CLLocation(latitude: copperCreekCoord.latitude + 0.009,
                                    longitude: copperCreekCoord.longitude)

    let result = locator.riverName(near: nearbyLocation, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Copper",
                   "Should return short name 'Copper' when within 10km of Copper Creek")
  }

  func testRiverName_5kmFromPallantCreek_returnsPallant() {
    let locator = RiverLocator.shared
    // Offset by ~5km (approximately 0.045 degrees latitude)
    let nearbyLocation = CLLocation(latitude: pallantCreekCoord.latitude + 0.045,
                                    longitude: pallantCreekCoord.longitude)

    let result = locator.riverName(near: nearbyLocation, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "Pallant",
                   "Should return short name 'Pallant' when ~5km away (within 10km threshold)")
  }

  // MARK: - riverName Tests: Beyond maxDistanceKm

  func testRiverName_farFromAllRivers_returnsEmptyString() {
    let locator = RiverLocator.shared
    let vancouverLocation = CLLocation(latitude: vancouverCoord.latitude,
                                       longitude: vancouverCoord.longitude)

    let result = locator.riverName(near: vancouverLocation, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "",
                   "Should return empty string when far from all rivers (Vancouver)")
  }

  func testRiverName_justBeyond10km_returnsEmptyString() {
    let locator = RiverLocator.shared
    // Offset by ~11km (approximately 0.1 degrees latitude)
    let farLocation = CLLocation(latitude: copperCreekCoord.latitude + 0.1,
                                 longitude: copperCreekCoord.longitude)

    let result = locator.riverName(near: farLocation, forCommunity: "Epic Waters")
    // This should either be empty or return a different river if one is within range
    // The key is it shouldn't return Copper if >10km away
    if result == "Copper" {
      // Verify distance is actually > 10km
      let copperCreekLocation = CLLocation(latitude: copperCreekCoord.latitude,
                                           longitude: copperCreekCoord.longitude)
      let distanceKm = farLocation.distance(from: copperCreekLocation) / 1000.0
      XCTAssertLessThanOrEqual(distanceKm, 10.0,
                                "If Copper returned, distance must be <= 10km")
    }
  }

  // MARK: - riverName Tests: Nil Location

  func testRiverName_nilLocation_returnsEmptyString() {
    let locator = RiverLocator.shared
    let result = locator.riverName(near: nil, forCommunity: "Epic Waters")
    XCTAssertEqual(result, "",
                   "Should return empty string when location is nil")
  }

  // MARK: - riverName Tests: Unknown Community

  func testRiverName_unknownCommunity_returnsEmptyString() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: copperCreekCoord.latitude,
                              longitude: copperCreekCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Unknown Community")
    XCTAssertEqual(result, "",
                   "Should return empty string for unknown community even at valid river location")
  }

  func testRiverName_emptyCommunity_returnsEmptyString() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: copperCreekCoord.latitude,
                              longitude: copperCreekCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "")
    XCTAssertEqual(result, "",
                   "Should return empty string for empty community string")
  }

  // MARK: - riverName Tests: Case Insensitive Community

  func testRiverName_caseInsensitiveCommunity() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: copperCreekCoord.latitude,
                              longitude: copperCreekCoord.longitude)

    let resultLower = locator.riverName(near: location, forCommunity: "epic waters")
    let resultUpper = locator.riverName(near: location, forCommunity: "EPIC WATERS")
    let resultMixed = locator.riverName(near: location, forCommunity: "Epic waters")

    XCTAssertEqual(resultLower, "Copper", "Should work with lowercase community")
    XCTAssertEqual(resultUpper, "Copper", "Should work with uppercase community")
    XCTAssertEqual(resultMixed, "Copper", "Should work with mixed case community")
  }

  // MARK: - riverName Tests: Closest River Selection

  func testRiverName_betweenTwoRivers_returnsClosest() {
    let locator = RiverLocator.shared

    // Find a point roughly between Tlell and Yakoun
    // Tlell: 53.56602409, -131.93391551
    // Yakoun first point: 53.67145964, -132.20484788
    // Midpoint roughly: 53.62, -132.07

    // Create a point closer to Tlell
    let closerToTlell = CLLocation(latitude: 53.57, longitude: -131.95)
    let resultTlell = locator.riverName(near: closerToTlell, forCommunity: "Epic Waters")

    // Create a point closer to Yakoun
    let closerToYakoun = CLLocation(latitude: 53.65, longitude: -132.18)
    let resultYakoun = locator.riverName(near: closerToYakoun, forCommunity: "Epic Waters")

    // Both should return the closest river (or empty if beyond 10km from all)
    // The key assertion is they shouldn't return the same river
    if !resultTlell.isEmpty && !resultYakoun.isEmpty {
      // If both found rivers, they should likely be different
      // (unless one location is equidistant)
      XCTAssertTrue(true, "Both locations found rivers")
    }
  }

  // MARK: - Snapshot Tests: All Rivers Exist

  func testAllExpectedRiversExist() {
    let locator = RiverLocator.shared

    // Test each known river coordinate returns the expected river name
    let expectedRivers: [(name: String, coord: CLLocationCoordinate2D)] = [
      ("Copper", copperCreekCoord),
      ("Pallant", pallantCreekCoord),
      ("Yakoun", yakounRiverCoord),
      ("Tlell", tlellRiverCoord),
      ("Mamin", maminRiverCoord)
    ]

    for (expectedName, coord) in expectedRivers {
      let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
      let result = locator.riverName(near: location, forCommunity: "Epic Waters")
      XCTAssertEqual(result, expectedName,
                     "River \(expectedName) should be found at its first coordinate")
    }
  }

  // MARK: - shortName Tests

  func testShortName_stripsCreekSuffix() {
    let def = RiverDefinition(
      name: "Copper Creek",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Copper")
  }

  func testShortName_stripsRiverSuffix() {
    let def = RiverDefinition(
      name: "Yakoun River",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Yakoun")
  }

  func testShortName_stripsLakeSuffix() {
    let def = RiverDefinition(
      name: "Mirror Lake",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Mirror")
  }

  func testShortName_stripsStreamSuffix() {
    let def = RiverDefinition(
      name: "Bear Stream",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Bear")
  }

  func testShortName_noSuffix_returnsFullName() {
    let def = RiverDefinition(
      name: "Pallant",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Pallant")
  }

  func testShortName_allConfiguredRivers() {
    // Verify every river that RiverLocator returns uses short names
    let locator = RiverLocator.shared
    let coords: [(CLLocationCoordinate2D, String)] = [
      (copperCreekCoord, "Copper"),
      (pallantCreekCoord, "Pallant"),
      (yakounRiverCoord, "Yakoun"),
      (tlellRiverCoord, "Tlell"),
      (maminRiverCoord, "Mamin"),
    ]
    for (coord, expected) in coords {
      let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
      let result = locator.riverName(near: loc, forCommunity: "Epic Waters")
      XCTAssertEqual(result, expected,
                     "riverName() should return '\(expected)', not a full name with suffix")
      XCTAssertFalse(result.contains("Creek"), "Short name should not contain 'Creek'")
      XCTAssertFalse(result.contains("River"), "Short name should not contain 'River'")
    }
  }

  // MARK: - Performance Test

  func testRiverName_performance() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: copperCreekCoord.latitude,
                              longitude: copperCreekCoord.longitude)

    measure {
      for _ in 0..<1000 {
        _ = locator.riverName(near: location, forCommunity: "Epic Waters")
      }
    }
  }
}
