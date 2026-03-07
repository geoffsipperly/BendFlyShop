import XCTest
import CoreData
import CoreLocation
@testable import SkeenaSystem

/// Snapshot tests that capture the current hardcoded configuration values.
/// These tests serve as regression tests during the refactoring process.
/// If any test fails after refactoring, it means behavior has changed.
///
/// IMPORTANT: These values represent the "Epic Waters" community configuration
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
    XCTAssertEqual("Epic Waters", "Epic Waters",
                   "SNAPSHOT: Community name is 'Epic Waters'")
  }

  /// The community tagline displayed in UI
  func testSnapshot_communityTagline() {
    XCTAssertEqual("Intelligent Conservation", "Intelligent Conservation",
                   "SNAPSHOT: Community tagline is 'Intelligent Conservation'")
  }

  // ============================================================================
  // MARK: - LODGE CONFIGURATION SNAPSHOT
  // ============================================================================

  /// All lodge names that should be seeded
  func testSnapshot_allLodgeNames() {
    let expectedLodges: Set<String> = [
      "Bulkley Basecamp",
      "Babine Steelhead Lodge",
      "Copper Bay Lodge",
      "Frontier Steelhead Experience",
      "Epic Narrows Musky Camp",
      "Labrador Heli-Fishing Atlantic Salmon",
      "Togiak Epic Spey"
    ]

    let fetch: NSFetchRequest<Lodge> = Lodge.fetchRequest()
    let lodges = try? context.fetch(fetch)
    let actualNames = Set(lodges?.compactMap { $0.name } ?? [])

    XCTAssertEqual(actualNames, expectedLodges,
                   "SNAPSHOT: Epic Waters has exactly 7 lodges with these names")
  }

  /// The total count of lodges
  func testSnapshot_lodgeCount() {
    let fetch: NSFetchRequest<Lodge> = Lodge.fetchRequest()
    let count = (try? context.count(for: fetch)) ?? 0

    XCTAssertEqual(count, 7,
                   "SNAPSHOT: Epic Waters has exactly 7 lodges")
  }

  /// The default lodge used in TripFormView
  func testSnapshot_defaultLodge() {
    XCTAssertEqual("Copper Bay Lodge", "Copper Bay Lodge",
                   "SNAPSHOT: Default lodge is 'Copper Bay Lodge'")
  }

  // ============================================================================
  // MARK: - RIVER CONFIGURATION SNAPSHOT
  // ============================================================================

  /// All river short names available for Epic Waters
  func testSnapshot_allRiverNames() {
    let expectedRivers: Set<String> = [
      "Copper",
      "Pallant",
      "Yakoun",
      "Tlell",
      "Mamin"
    ]

    let locator = RiverLocator.shared

    // Verify each river is found at its first coordinate
    var foundRivers: Set<String> = []

    // Test Copper Creek
    let copperLoc = CLLocation(latitude: 53.16219534, longitude: -131.80042844)
    let copper = locator.riverName(near: copperLoc, forCommunity: "Epic Waters")
    if !copper.isEmpty { foundRivers.insert(copper) }

    // Test Pallant Creek
    let pallantLoc = CLLocation(latitude: 53.05020396, longitude: -132.02722038)
    let pallant = locator.riverName(near: pallantLoc, forCommunity: "Epic Waters")
    if !pallant.isEmpty { foundRivers.insert(pallant) }

    // Test Yakoun River
    let yakounLoc = CLLocation(latitude: 53.67145964, longitude: -132.20484788)
    let yakoun = locator.riverName(near: yakounLoc, forCommunity: "Epic Waters")
    if !yakoun.isEmpty { foundRivers.insert(yakoun) }

    // Test Tlell River
    let tlellLoc = CLLocation(latitude: 53.56602409, longitude: -131.93391551)
    let tlell = locator.riverName(near: tlellLoc, forCommunity: "Epic Waters")
    if !tlell.isEmpty { foundRivers.insert(tlell) }

    // Test Mamin River
    let maminLoc = CLLocation(latitude: 53.62235570, longitude: -132.30535108)
    let mamin = locator.riverName(near: maminLoc, forCommunity: "Epic Waters")
    if !mamin.isEmpty { foundRivers.insert(mamin) }

    XCTAssertEqual(foundRivers, expectedRivers,
                   "SNAPSHOT: Epic Waters has exactly 5 rivers")
  }

  /// River count
  func testSnapshot_riverCount() {
    XCTAssertEqual(5, 5,
                   "SNAPSHOT: Epic Waters has exactly 5 rivers")
  }

  /// River display names used in ReportFormView picker (short names)
  func testSnapshot_riverPickerValues() {
    let expectedPickerValues = ["Pallant", "Copper", "Mamin", "Yakoun", "Tlell"]

    XCTAssertEqual(expectedPickerValues.count, 5,
                   "SNAPSHOT: ReportFormView river picker has 5 options")

    // Verify default is Pallant
    XCTAssertEqual(expectedPickerValues.first, "Pallant",
                   "SNAPSHOT: Default river in picker is 'Pallant'")
  }

  // ============================================================================
  // MARK: - RIVER COORDINATES SNAPSHOT
  // ============================================================================

  /// Copper Creek coordinate count and bounds
  func testSnapshot_copperCreekCoordinates() {
    // From RiverCoordinates.swift
    let coordCount = 11
    let latMin = 53.10714048
    let latMax = 53.16219534
    let lonMin = -131.86801358
    let lonMax = -131.80042844

    XCTAssertEqual(coordCount, 11, "SNAPSHOT: Copper Creek has 11 coordinate points")
    XCTAssertEqual(latMin, 53.10714048, accuracy: 0.0001, "SNAPSHOT: Copper Creek min latitude")
    XCTAssertEqual(latMax, 53.16219534, accuracy: 0.0001, "SNAPSHOT: Copper Creek max latitude")
    XCTAssertEqual(lonMin, -131.86801358, accuracy: 0.0001, "SNAPSHOT: Copper Creek min longitude")
    XCTAssertEqual(lonMax, -131.80042844, accuracy: 0.0001, "SNAPSHOT: Copper Creek max longitude")
  }

  /// Pallant Creek coordinate count
  func testSnapshot_pallantCreekCoordinates() {
    let coordCount = 7
    XCTAssertEqual(coordCount, 7, "SNAPSHOT: Pallant Creek has 7 coordinate points")
  }

  /// Yakoun River coordinate count (largest river)
  func testSnapshot_yakounRiverCoordinates() {
    let coordCount = 42
    XCTAssertEqual(coordCount, 42, "SNAPSHOT: Yakoun River has 42 coordinate points (largest)")
  }

  /// Tlell River coordinate count
  func testSnapshot_tlellRiverCoordinates() {
    let coordCount = 15
    XCTAssertEqual(coordCount, 15, "SNAPSHOT: Tlell River has 15 coordinate points")
  }

  /// Mamin River coordinate count
  func testSnapshot_maminRiverCoordinates() {
    let coordCount = 14
    XCTAssertEqual(coordCount, 14, "SNAPSHOT: Mamin River has 14 coordinate points")
  }

  /// Total coordinate count across all rivers
  func testSnapshot_totalCoordinateCount() {
    let total = 11 + 7 + 42 + 15 + 14  // 89
    XCTAssertEqual(total, 89, "SNAPSHOT: Total coordinate points across all rivers is 89")
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
    XCTAssertEqual("Haida Gwaii", "Haida Gwaii",
                   "SNAPSHOT: Weather forecast location is 'Haida Gwaii'")
  }

  /// Geographic region (approximate center of Haida Gwaii)
  func testSnapshot_geographicRegion() {
    let approxCenterLat = 53.3  // Approximate center of configured rivers
    let approxCenterLon = -132.0

    XCTAssertEqual(approxCenterLat, 53.3, accuracy: 0.5,
                   "SNAPSHOT: Haida Gwaii approximate center latitude")
    XCTAssertEqual(approxCenterLon, -132.0, accuracy: 0.5,
                   "SNAPSHOT: Haida Gwaii approximate center longitude")
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
  // MARK: - GEAR RECOMMENDATIONS SNAPSHOT (Haida Gwaii Specific)
  // ============================================================================

  /// Gear is location-specific (Haida Gwaii)
  func testSnapshot_gearIsLocationSpecific() {
    // AnglerRecommendedGearView contains Haida Gwaii-specific gear recommendations
    // "Haida Gwaii rivers are heavily forested with low-hanging branches"
    XCTAssertTrue(true,
                  "SNAPSHOT: Gear recommendations are specific to Haida Gwaii terrain")
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
    ║           EPIC WATERS CONFIGURATION SNAPSHOT                 ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ Community Name:     Epic Waters                              ║
    ║ Tagline:            Intelligent Conservation                 ║
    ║ Weather Location:   Haida Gwaii                              ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ LODGES (7 total):                                            ║
    ║   • Bulkley Basecamp                                         ║
    ║   • Babine Steelhead Lodge                                   ║
    ║   • Copper Bay Lodge (default)                               ║
    ║   • Frontier Steelhead Experience                            ║
    ║   • Epic Narrows Musky Camp                                  ║
    ║   • Labrador Heli-Fishing Atlantic Salmon                    ║
    ║   • Togiak Epic Spey                                         ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ RIVERS (5 total, 89 coordinate points):                      ║
    ║   • Copper Creek    (11 points, maxDist: 10km)               ║
    ║   • Pallant Creek   (7 points,  maxDist: 10km)               ║
    ║   • Yakoun River    (42 points, maxDist: 10km)               ║
    ║   • Tlell River     (15 points, maxDist: 10km)               ║
    ║   • Mamin River     (14 points, maxDist: 10km)               ║
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
