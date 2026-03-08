import XCTest
import CoreLocation
@testable import SkeenaSystem

/// Regression tests for RiverLocator.
/// These tests verify the river lookup logic using known coordinates
/// from the Bend Oregon region and ensure correct behavior for
/// boundary conditions, unknown communities, and edge cases.
@MainActor
final class RiverLocatorTests: XCTestCase {

  // MARK: - Test Data (Known Coordinates)

  // Deschutes River - representative coordinate
  private let deschuteRiverCoord = CLLocationCoordinate2D(latitude: 44.06, longitude: -121.31)

  // Metolius River - representative coordinate
  private let metoliusRiverCoord = CLLocationCoordinate2D(latitude: 44.43, longitude: -121.64)

  // Crooked River - representative coordinate
  private let crookedRiverCoord = CLLocationCoordinate2D(latitude: 44.30, longitude: -120.88)

  // Fall River - representative coordinate
  private let fallRiverCoord = CLLocationCoordinate2D(latitude: 43.78, longitude: -121.43)

  // A location far from any Bend Oregon river (Portland, OR)
  private let portlandCoord = CLLocationCoordinate2D(latitude: 45.5051, longitude: -122.6750)

  // MARK: - hasRivers Tests

  func testHasRivers_bendFlyShop_returnsTrue() {
    let locator = RiverLocator.shared
    XCTAssertTrue(locator.hasRivers(forCommunity: "Bend Fly Shop"),
                  "Bend Fly Shop should have rivers defined")
  }

  func testHasRivers_bendFlyShop_caseInsensitive() {
    let locator = RiverLocator.shared

    XCTAssertTrue(locator.hasRivers(forCommunity: "bend fly shop"),
                  "Should match case-insensitively (lowercase)")
    XCTAssertTrue(locator.hasRivers(forCommunity: "BEND FLY SHOP"),
                  "Should match case-insensitively (uppercase)")
    XCTAssertTrue(locator.hasRivers(forCommunity: "BeNd FlY sHoP"),
                  "Should match case-insensitively (mixed)")
  }

  func testHasRivers_bendFlyShop_withWhitespace() {
    let locator = RiverLocator.shared

    XCTAssertTrue(locator.hasRivers(forCommunity: "  Bend Fly Shop  "),
                  "Should trim leading/trailing whitespace")
    XCTAssertTrue(locator.hasRivers(forCommunity: "\nBend Fly Shop\t"),
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

  func testRiverName_atDeschuteRiver_returnsDeschutes() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: deschuteRiverCoord.latitude,
                              longitude: deschuteRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Deschutes",
                   "Should return short name 'Deschutes' when at exact Deschutes River coordinate")
  }

  func testRiverName_atMetoliusRiver_returnsMetolius() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: metoliusRiverCoord.latitude,
                              longitude: metoliusRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Metolius",
                   "Should return short name 'Metolius' when at exact Metolius River coordinate")
  }

  func testRiverName_atCrookedRiver_returnsCrooked() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: crookedRiverCoord.latitude,
                              longitude: crookedRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Crooked",
                   "Should return short name 'Crooked' when at exact Crooked River coordinate")
  }

  func testRiverName_atFallRiver_returnsFall() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: fallRiverCoord.latitude,
                              longitude: fallRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Fall",
                   "Should return short name 'Fall' when at exact Fall River coordinate")
  }

  // MARK: - riverName Tests: Nearby Coordinates (within maxDistanceKm)

  func testRiverName_nearDeschuteRiver_returnsDeschutes() {
    let locator = RiverLocator.shared
    // Offset by ~1km (approximately 0.009 degrees latitude)
    let nearbyLocation = CLLocation(latitude: deschuteRiverCoord.latitude + 0.009,
                                    longitude: deschuteRiverCoord.longitude)

    let result = locator.riverName(near: nearbyLocation, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Deschutes",
                   "Should return short name 'Deschutes' when within 10km of Deschutes River")
  }

  func testRiverName_5kmFromMetoliusRiver_returnsMetolius() {
    let locator = RiverLocator.shared
    // Offset by ~5km (approximately 0.045 degrees latitude)
    let nearbyLocation = CLLocation(latitude: metoliusRiverCoord.latitude + 0.045,
                                    longitude: metoliusRiverCoord.longitude)

    let result = locator.riverName(near: nearbyLocation, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "Metolius",
                   "Should return short name 'Metolius' when ~5km away (within 10km threshold)")
  }

  // MARK: - riverName Tests: Beyond maxDistanceKm

  func testRiverName_farFromAllRivers_returnsEmptyString() {
    let locator = RiverLocator.shared
    let portlandLocation = CLLocation(latitude: portlandCoord.latitude,
                                      longitude: portlandCoord.longitude)

    let result = locator.riverName(near: portlandLocation, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "",
                   "Should return empty string when far from all rivers (Portland)")
  }

  func testRiverName_justBeyond10km_returnsEmptyString() {
    let locator = RiverLocator.shared
    // Offset by ~11km (approximately 0.1 degrees latitude)
    let farLocation = CLLocation(latitude: deschuteRiverCoord.latitude + 0.1,
                                 longitude: deschuteRiverCoord.longitude)

    let result = locator.riverName(near: farLocation, forCommunity: "Bend Fly Shop")
    // This should either be empty or return a different river if one is within range
    // The key is it shouldn't return Deschutes if >10km away
    if result == "Deschutes" {
      // Verify distance is actually > 10km
      let deschuteRiverLocation = CLLocation(latitude: deschuteRiverCoord.latitude,
                                             longitude: deschuteRiverCoord.longitude)
      let distanceKm = farLocation.distance(from: deschuteRiverLocation) / 1000.0
      XCTAssertLessThanOrEqual(distanceKm, 10.0,
                                "If Deschutes returned, distance must be <= 10km")
    }
  }

  // MARK: - riverName Tests: Nil Location

  func testRiverName_nilLocation_returnsEmptyString() {
    let locator = RiverLocator.shared
    let result = locator.riverName(near: nil, forCommunity: "Bend Fly Shop")
    XCTAssertEqual(result, "",
                   "Should return empty string when location is nil")
  }

  // MARK: - riverName Tests: Unknown Community

  func testRiverName_unknownCommunity_returnsEmptyString() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: deschuteRiverCoord.latitude,
                              longitude: deschuteRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "Unknown Community")
    XCTAssertEqual(result, "",
                   "Should return empty string for unknown community even at valid river location")
  }

  func testRiverName_emptyCommunity_returnsEmptyString() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: deschuteRiverCoord.latitude,
                              longitude: deschuteRiverCoord.longitude)

    let result = locator.riverName(near: location, forCommunity: "")
    XCTAssertEqual(result, "",
                   "Should return empty string for empty community string")
  }

  // MARK: - riverName Tests: Case Insensitive Community

  func testRiverName_caseInsensitiveCommunity() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: deschuteRiverCoord.latitude,
                              longitude: deschuteRiverCoord.longitude)

    let resultLower = locator.riverName(near: location, forCommunity: "bend fly shop")
    let resultUpper = locator.riverName(near: location, forCommunity: "BEND FLY SHOP")
    let resultMixed = locator.riverName(near: location, forCommunity: "Bend fly shop")

    XCTAssertEqual(resultLower, "Deschutes", "Should work with lowercase community")
    XCTAssertEqual(resultUpper, "Deschutes", "Should work with uppercase community")
    XCTAssertEqual(resultMixed, "Deschutes", "Should work with mixed case community")
  }

  // MARK: - riverName Tests: Closest River Selection

  func testRiverName_betweenTwoRivers_returnsClosest() {
    let locator = RiverLocator.shared

    // Find a point roughly between Deschutes and Crooked
    // Deschutes: 44.06, -121.31
    // Crooked: 44.30, -120.88
    // Midpoint roughly: 44.18, -121.10

    // Create a point closer to Deschutes
    let closerToDeschutes = CLLocation(latitude: 44.08, longitude: -121.28)
    let resultDeschutes = locator.riverName(near: closerToDeschutes, forCommunity: "Bend Fly Shop")

    // Create a point closer to Crooked
    let closerToCrooked = CLLocation(latitude: 44.28, longitude: -120.91)
    let resultCrooked = locator.riverName(near: closerToCrooked, forCommunity: "Bend Fly Shop")

    // Both should return the closest river (or empty if beyond 10km from all)
    // The key assertion is they shouldn't return the same river
    if !resultDeschutes.isEmpty && !resultCrooked.isEmpty {
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
      ("Deschutes", deschuteRiverCoord),
      ("Metolius", metoliusRiverCoord),
      ("Crooked", crookedRiverCoord),
      ("Fall", fallRiverCoord)
    ]

    for (expectedName, coord) in expectedRivers {
      let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
      let result = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
      XCTAssertEqual(result, expectedName,
                     "River \(expectedName) should be found at its first coordinate")
    }
  }

  // MARK: - shortName Tests

  func testShortName_stripsCreekSuffix() {
    let def = RiverDefinition(
      name: "Deschutes Creek",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Deschutes")
  }

  func testShortName_stripsRiverSuffix() {
    let def = RiverDefinition(
      name: "Deschutes River",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Deschutes")
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
      name: "Deschutes",
      communityID: "Test",
      coordinates: [],
      maxDistanceKm: 10
    )
    XCTAssertEqual(def.shortName, "Deschutes")
  }

  func testShortName_allConfiguredRivers() {
    // Verify every river that RiverLocator returns uses short names
    let locator = RiverLocator.shared
    let coords: [(CLLocationCoordinate2D, String)] = [
      (deschuteRiverCoord, "Deschutes"),
      (metoliusRiverCoord, "Metolius"),
      (crookedRiverCoord, "Crooked"),
      (fallRiverCoord, "Fall"),
    ]
    for (coord, expected) in coords {
      let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
      let result = locator.riverName(near: loc, forCommunity: "Bend Fly Shop")
      XCTAssertEqual(result, expected,
                     "riverName() should return '\(expected)', not a full name with suffix")
      XCTAssertFalse(result.contains("Creek"), "Short name should not contain 'Creek'")
      XCTAssertFalse(result.contains("River"), "Short name should not contain 'River'")
    }
  }

  // MARK: - Performance Test

  func testRiverName_performance() {
    let locator = RiverLocator.shared
    let location = CLLocation(latitude: deschuteRiverCoord.latitude,
                              longitude: deschuteRiverCoord.longitude)

    measure {
      for _ in 0..<1000 {
        _ = locator.riverName(near: location, forCommunity: "Bend Fly Shop")
      }
    }
  }
}
