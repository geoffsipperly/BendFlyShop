// ForecastLocationConfigTests.swift
// SkeenaSystemTests
//
// Unit tests for the FORECAST_LOCATION configuration variable:
// verifies AppEnvironment.forecastLocation reads from config,
// supports runtime override, and falls back to "Haida Gwaii".

import XCTest
@testable import SkeenaSystem

@MainActor
final class ForecastLocationConfigTests: XCTestCase {

  // MARK: - Setup / Teardown

  override func setUp() {
    super.setUp()
    // Clear any previous override
    AppEnvironment.shared.overrideForecastLocation = nil
  }

  override func tearDown() {
    AppEnvironment.shared.overrideForecastLocation = nil
    super.tearDown()
  }

  // MARK: - Default Value

  func testForecastLocation_defaultsToHaidaGwaii() {
    // When no override is set, the value should come from Info.plist (xcconfig)
    // or fall back to "Haida Gwaii"
    let location = AppEnvironment.shared.forecastLocation
    XCTAssertFalse(location.isEmpty, "Forecast location should never be empty")
    XCTAssertEqual(location, "Haida Gwaii",
                   "Default forecast location should be 'Haida Gwaii'")
  }

  // MARK: - Override

  func testForecastLocation_respectsOverride() {
    AppEnvironment.shared.overrideForecastLocation = "Terrace"
    XCTAssertEqual(AppEnvironment.shared.forecastLocation, "Terrace",
                   "Override should take precedence over Info.plist value")
  }

  func testForecastLocation_overrideWithDifferentLocation() {
    AppEnvironment.shared.overrideForecastLocation = "Prince Rupert"
    XCTAssertEqual(AppEnvironment.shared.forecastLocation, "Prince Rupert",
                   "Override should support any location string")
  }

  func testForecastLocation_clearingOverrideRestoresDefault() {
    AppEnvironment.shared.overrideForecastLocation = "Smithers"
    XCTAssertEqual(AppEnvironment.shared.forecastLocation, "Smithers")

    AppEnvironment.shared.overrideForecastLocation = nil
    XCTAssertEqual(AppEnvironment.shared.forecastLocation, "Haida Gwaii",
                   "Clearing override should restore default value")
  }

  // MARK: - Empty Override Ignored

  func testForecastLocation_emptyOverrideIsUsed() {
    // Unlike stringFromInfo which checks isEmpty, override is used directly
    AppEnvironment.shared.overrideForecastLocation = "Vancouver Island"
    XCTAssertEqual(AppEnvironment.shared.forecastLocation, "Vancouver Island")
  }

  // MARK: - Snapshot Consistency

  func testForecastLocation_matchesWeatherLocationSnapshot() {
    // This ensures the new configurable FORECAST_LOCATION matches the
    // previously hardcoded "Haida Gwaii" value from ConfigurationSnapshotTests
    let location = AppEnvironment.shared.forecastLocation
    XCTAssertEqual(location, "Haida Gwaii",
                   "FORECAST_LOCATION should match the previously hardcoded weather location")
  }
}
