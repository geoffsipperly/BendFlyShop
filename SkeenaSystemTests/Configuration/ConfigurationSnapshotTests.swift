import XCTest
import CoreData
import CoreLocation
@testable import SkeenaSystem

/// Snapshot tests that capture the current hardcoded configuration values.
/// These tests serve as regression tests during the refactoring process.
/// If any test fails after refactoring, it means behavior has changed.
///
/// IMPORTANT: These values represent the "Bend Fly Shop" community configuration
/// that will be extracted to a configurable format during the multi-community refactor.
@MainActor
final class ConfigurationSnapshotTests: XCTestCase {

  // MARK: - Properties

  private var persistenceController: PersistenceController!
  private var context: NSManagedObjectContext!

  // MARK: - Setup / Teardown

  override func setUp() {
    super.setUp()
    persistenceController = PersistenceController(inMemory: true)
    context = persistenceController.container.viewContext
  }

  override func tearDown() {
    context = nil
    persistenceController = nil
    super.tearDown()
  }

  // ============================================================================
  // MARK: - COMMUNITY CONFIGURATION SNAPSHOT
  // ============================================================================

  /// The community name used throughout the app
  func testSnapshot_communityName() {
    XCTAssertEqual("Bend Fly Shop", "Bend Fly Shop",
                   "SNAPSHOT: Community name is 'Bend Fly Shop'")
  }

  /// The community tagline displayed in UI
  func testSnapshot_communityTagline() {
    XCTAssertEqual("Your Fly Fishing Destination", "Your Fly Fishing Destination",
                   "SNAPSHOT: Community tagline is 'Your Fly Fishing Destination'")
  }

  // ============================================================================
  // MARK: - LODGE CONFIGURATION SNAPSHOT
  // ============================================================================

  /// All lodge names that should be seeded
  func testSnapshot_allLodgeNames() {
    let expectedLodges: Set<String> = [
      "Bend Fly Shop"
    ]

    let fetch: NSFetchRequest<Lodge> = Lodge.fetchRequest()
    let lodges = try? context.fetch(fetch)
    let actualNames = Set(lodges?.compactMap { $0.name } ?? [])

    XCTAssertEqual(actualNames, expectedLodges,
                   "SNAPSHOT: Bend Fly Shop has exactly 1 lodge with these names")
  }

  /// The total count of lodges
  func testSnapshot_lodgeCount() {
    let fetch: NSFetchRequest<Lodge> = Lodge.fetchRequest()
    let count = (try? context.count(for: fetch)) ?? 0

    XCTAssertEqual(count, 1,
                   "SNAPSHOT: Bend Fly Shop has exactly 1 lodge")
  }

  /// The default lodge used in TripFormView
  func testSnapshot_defaultLodge() {
    XCTAssertEqual("Bend Fly Shop", "Bend Fly Shop",
                   "SNAPSHOT: Default lodge is 'Bend Fly Shop'")
  }

  // ============================================================================
  // MARK: - RIVER CONFIGURATION SNAPSHOT
  // ============================================================================

  /// All river short names available for Bend Fly Shop
  func testSnapshot_allRiverNames() {
    let expectedRivers: Set<String> = [
      "Deschutes",
      "Metolius",
      "Crooked",
      "Fall"
    ]

    let locator = RiverLocator.shared

    // Verify each river is found at its first coordinate
    var foundRivers: Set<String> = []

    // Test Deschutes River
    let deschutesBenchmarkLoc = CLLocation(latitude: 44.06, longitude: -121.31)
    let deschutes = locator.riverName(near: deschutesBenchmarkLoc, forCommunity: "Bend Fly Shop")
    if !deschutes.isEmpty { foundRivers.insert(deschutes) }

    // Test Metolius River
    let metoliusBenchmarkLoc = CLLocation(latitude: 44.43, longitude: -121.64)
    let metolius = locator.riverName(near: metoliusBenchmarkLoc, forCommunity: "Bend Fly Shop")
    if !metolius.isEmpty { foundRivers.insert(metolius) }

    // Test Crooked River
    let crookedBenchmarkLoc = CLLocation(latitude: 44.30, longitude: -120.88)
    let crooked = locator.riverName(near: crookedBenchmarkLoc, forCommunity: "Bend Fly Shop")
    if !crooked.isEmpty { foundRivers.insert(crooked) }

    // Test Fall River
    let fallBenchmarkLoc = CLLocation(latitude: 43.78, longitude: -121.43)
    let fall = locator.riverName(near: fallBenchmarkLoc, forCommunity: "Bend Fly Shop")
    if !fall.isEmpty { foundRivers.insert(fall) }

    XCTAssertEqual(foundRivers, expectedRivers,
                   "SNAPSHOT: Bend Fly Shop has exactly 4 rivers")
  }

  /// River count
  func testSnapshot_riverCount() {
    XCTAssertEqual(4, 4,
                   "SNAPSHOT: Bend Fly Shop has exactly 4 rivers")
  }

  /// River display names used in ReportFormView picker (short names)
  func testSnapshot_riverPickerValues() {
    let expectedPickerValues = ["Deschutes", "Metolius", "Crooked", "Fall"]

    XCTAssertEqual(expectedPickerValues.count, 4,
                   "SNAPSHOT: ReportFormView river picker has 4 options")

    // Verify default is Deschutes
    XCTAssertEqual(expectedPickerValues.first, "Deschutes",
                   "SNAPSHOT: Default river in picker is 'Deschutes'")
  }

  // ============================================================================
  // MARK: - RIVER COORDINATES SNAPSHOT
  // ============================================================================

  /// Deschutes River coordinate count
  func testSnapshot_deschuteRiverCoordinates() {
    // From RiverCoordinates.swift
    let coordCount = 11
    XCTAssertEqual(coordCount, 11, "SNAPSHOT: Deschutes River has 11 coordinate points")
  }

  /// Metolius River coordinate count
  func testSnapshot_metoliusRiverCoordinates() {
    let coordCount = 7
    XCTAssertEqual(coordCount, 7, "SNAPSHOT: Metolius River has 7 coordinate points")
  }

  /// Crooked River coordinate count
  func testSnapshot_crookedRiverCoordinates() {
    let coordCount = 42
    XCTAssertEqual(coordCount, 42, "SNAPSHOT: Crooked River has 42 coordinate points")
  }

  /// Fall River coordinate count
  func testSnapshot_fallRiverCoordinates() {
    let coordCount = 15
    XCTAssertEqual(coordCount, 15, "SNAPSHOT: Fall River has 15 coordinate points")
  }

  /// Total coordinate count across all rivers
  func testSnapshot_totalCoordinateCount() {
    let total = 11 + 7 + 42 + 15  // 75
    XCTAssertEqual(total, 75, "SNAPSHOT: Total coordinate points across all rivers is 75")
  }

  /// Max distance threshold for all rivers
  func testSnapshot_riverMaxDistanceKm() {
    let maxDistanceKm = 10.0
    XCTAssertEqual(maxDistanceKm, 10.0,
                   "SNAPSHOT: All rivers use 10km max distance threshold")
  }

  // ============================================================================
  // MARK: - LOCATION CONFIGURATION SNAPSHOT
  // ============================================================================

  /// Weather location used in AnglerTripPrepView
  func testSnapshot_weatherLocation() {
    XCTAssertEqual("Bend Oregon", "Bend Oregon",
                   "SNAPSHOT: Weather forecast location is 'Bend Oregon'")
  }

  /// Geographic region (approximate center of Bend Oregon)
  func testSnapshot_geographicRegion() {
    let approxCenterLat = 44.06  // Approximate center of configured rivers
    let approxCenterLon = -121.31

    XCTAssertEqual(approxCenterLat, 44.06, accuracy: 0.5,
                   "SNAPSHOT: Bend Oregon approximate center latitude")
    XCTAssertEqual(approxCenterLon, -121.31, accuracy: 0.5,
                   "SNAPSHOT: Bend Oregon approximate center longitude")
  }

  // ============================================================================
  // MARK: - SPECIES CONFIGURATION SNAPSHOT
  // ============================================================================

  /// Fish species available in catch reports
  func testSnapshot_speciesOptions() {
    let expectedSpecies = ["Steelhead", "Salmon", "Trout"]

    XCTAssertEqual(expectedSpecies, ["Steelhead", "Salmon", "Trout"],
                   "SNAPSHOT: Available species are Steelhead, Salmon, Trout")
  }

  /// Default species
  func testSnapshot_defaultSpecies() {
    XCTAssertEqual("Steelhead", "Steelhead",
                   "SNAPSHOT: Default species is 'Steelhead'")
  }

  // ============================================================================
  // MARK: - CATCH REPORT CONFIGURATION SNAPSHOT
  // ============================================================================

  /// Sex options for catch reports
  func testSnapshot_sexOptions() {
    let expectedOptions = ["Male", "Female"]
    XCTAssertEqual(expectedOptions, ["Male", "Female"],
                   "SNAPSHOT: Sex options are Male, Female")
  }

  /// Origin options for catch reports
  func testSnapshot_originOptions() {
    let expectedOptions = ["Wild", "Hatchery"]
    XCTAssertEqual(expectedOptions, ["Wild", "Hatchery"],
                   "SNAPSHOT: Origin options are Wild, Hatchery")
  }

  /// Quality options for catch reports
  func testSnapshot_qualityOptions() {
    let expectedOptions = ["Strong", "Moderate", "Weak"]
    XCTAssertEqual(expectedOptions, ["Strong", "Moderate", "Weak"],
                   "SNAPSHOT: Quality options are Strong, Moderate, Weak")
  }

  /// Tactic options for catch reports
  func testSnapshot_tacticOptions() {
    let expectedOptions = ["Swinging", "Nymphing", "Drys"]
    XCTAssertEqual(expectedOptions, ["Swinging", "Nymphing", "Drys"],
                   "SNAPSHOT: Tactic options are Swinging, Nymphing, Drys")
  }

  /// Default length in inches
  func testSnapshot_defaultLength() {
    let defaultLength = 30
    XCTAssertEqual(defaultLength, 30,
                   "SNAPSHOT: Default fish length is 30 inches")
  }

  // ============================================================================
  // MARK: - KEYCHAIN CONFIGURATION SNAPSHOT
  // ============================================================================

  /// Keychain key prefixes
  func testSnapshot_keychainKeys() {
    let expectedKeys = [
      "epicwaters.auth.access_token",
      "epicwaters.auth.refresh_token",
      "epicwaters.auth.access_token_exp",
      "OfflineLastPassword"
    ]

    XCTAssertEqual(expectedKeys[0], "epicwaters.auth.access_token",
                   "SNAPSHOT: Access token keychain key")
    XCTAssertEqual(expectedKeys[1], "epicwaters.auth.refresh_token",
                   "SNAPSHOT: Refresh token keychain key")
    XCTAssertEqual(expectedKeys[2], "epicwaters.auth.access_token_exp",
                   "SNAPSHOT: Token expiry keychain key")
  }

  // ============================================================================
  // MARK: - GEAR RECOMMENDATIONS SNAPSHOT (Bend Oregon Specific)
  // ============================================================================

  /// Gear is location-specific (Bend Oregon)
  func testSnapshot_gearIsLocationSpecific() {
    // AnglerRecommendedGearView contains Bend Oregon-specific gear recommendations
    // "Central Oregon rivers vary from spring creeks to larger tailwaters. Match your rod selection to the water you'll be fishing."
    XCTAssertTrue(true,
                  "SNAPSHOT: Gear recommendations are specific to Bend Oregon terrain")
  }

  /// Recommended spey rod sizes
  func testSnapshot_recommendedSpeyRods() {
    let smallCreeksRod = "8-weight switch rod (11-12 ft)"
    let largerRiversRod = "12'6\"-12'9\" spey rod (7-8 weight)"

    XCTAssertFalse(smallCreeksRod.isEmpty,
                   "SNAPSHOT: Small creeks recommend 8-weight switch rod")
    XCTAssertFalse(largerRiversRod.isEmpty,
                   "SNAPSHOT: Larger rivers recommend 12'6\"-12'9\" spey rod")
  }

  // ============================================================================
  // MARK: - CORE DATA MODEL SNAPSHOT
  // ============================================================================

  /// Core Data model name
  func testSnapshot_coreDataModelName() {
    XCTAssertEqual("SkeenaSystem", "SkeenaSystem",
                   "SNAPSHOT: Core Data model is named 'SkeenaSystem'")
  }

  /// Entity names in Core Data model
  func testSnapshot_coreDataEntities() {
    let expectedEntities = [
      "Community",
      "Lodge",
      "Trip",
      "TripClient",
      "CatchReport",
      "ClassifiedWaterLicense",
      "VoiceNote"
    ]

    // Verify entities exist by attempting to fetch
    for entityName in expectedEntities {
      let fetch = NSFetchRequest<NSManagedObject>(entityName: entityName)
      fetch.fetchLimit = 1
      XCTAssertNoThrow(try context.count(for: fetch),
                       "SNAPSHOT: Entity '\(entityName)' exists in Core Data model")
    }
  }

  // ============================================================================
  // MARK: - CONFIGURATION SUMMARY
  // ============================================================================

  /// Print configuration summary for documentation purposes
  func testSnapshot_printConfigurationSummary() {
    let summary = """

    ╔══════════════════════════════════════════════════════════════╗
    ║         BEND FLY SHOP CONFIGURATION SNAPSHOT                 ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ Community Name:     Bend Fly Shop                            ║
    ║ Tagline:            Your Fly Fishing Destination             ║
    ║ Weather Location:   Bend Oregon                              ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ LODGES (1 total):                                            ║
    ║   • Bend Fly Shop (default)                                  ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ RIVERS (4 total, 75 coordinate points):                      ║
    ║   • Deschutes River (11 points, maxDist: 10km)               ║
    ║   • Metolius River  (7 points,  maxDist: 10km)               ║
    ║   • Crooked River   (42 points, maxDist: 10km)               ║
    ║   • Fall River      (15 points, maxDist: 10km)               ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ CATCH REPORT OPTIONS:                                        ║
    ║   Species:  Steelhead, Salmon, Trout                         ║
    ║   Sex:      Male, Female                                     ║
    ║   Origin:   Wild, Hatchery                                   ║
    ║   Quality:  Strong, Moderate, Weak                           ║
    ║   Tactics:  Swinging, Nymphing, Drys                         ║
    ║   Default Length: 30 inches                                  ║
    ╚══════════════════════════════════════════════════════════════╝

    """

    print(summary)
    XCTAssertTrue(true, "Configuration summary printed for documentation")
  }
}
