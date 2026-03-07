//
//  RiverLocator.swift
//  River / Epic Waters
//
//  Uses coordinate arrays defined in RiverCoordinates.swift
//  (e.g. coppercreekCoordinates, maminCoordinates, etc.)
//

import Foundation
import CoreLocation

/// Represents a fishable river entry in our offline dataset.
///
/// Note: `coordinates` is a "spine" of points along the river.
/// We'll treat the river's coverage as the union of circles
/// around each of these points, with radius `maxDistanceKm`.
struct RiverDefinition {
  let name: String
  let communityID: String        // e.g. "Epic Waters"
  let coordinates: [CLLocationCoordinate2D]
  let maxDistanceKm: Double      // max distance from ANY point to count as on this river

  /// The river's base name with water-body suffixes stripped
  /// (e.g. "Copper Creek" → "Copper", "Yakoun River" → "Yakoun").
  var shortName: String {
    let suffixes = [" Creek", " River", " Lake", " Stream"]
    for suffix in suffixes where name.hasSuffix(suffix) {
      return String(name.dropLast(suffix.count))
    }
    return name
  }
}

/// Main entry point for river lookup. Designed to be community- and dataset-agnostic.
final class RiverLocator {

  static let shared = RiverLocator()

  // MARK: - Dataset

  /// For now we only have Epic Waters rivers near Haida Gwaii.
  /// Coordinate arrays are defined in RiverCoordinates.swift:
  /// - coppercreekCoordinates
  /// - pallantcreekCoordinates
  /// - maminCoordinates
  /// - tlellCoordinates
  /// - yakounCoordinates
  ///
  /// NOTE: maxDistanceKm values are inherited from the original centroid-based
  /// implementation and can be tuned as you test in the field.
  private let rivers: [RiverDefinition] = [
    // Epic Waters – Haida Gwaii, BC

    // Cooper Creek (also called Copper Creek in some sources).
    RiverDefinition(
      name: "Copper Creek",
      communityID: AppEnvironment.shared.communityName,
      coordinates: coppercreekCoordinates,
      maxDistanceKm: 10
    ),

    // Pallant Creek (Haida Gwaii)
    RiverDefinition(
      name: "Pallant Creek",
      communityID: AppEnvironment.shared.communityName,
      coordinates: pallantcreekCoordinates,
      maxDistanceKm: 10
    ),

    // Yakoun River (largest river on Haida Gwaii)
    RiverDefinition(
      name: "Yakoun River",
      communityID: AppEnvironment.shared.communityName,
      coordinates: yakounCoordinates,
      maxDistanceKm: 10
    ),

    // Tlell River
    RiverDefinition(
      name: "Tlell River",
      communityID: AppEnvironment.shared.communityName,
      coordinates: tlellCoordinates,
      maxDistanceKm: 10
    ),

    // Mamin River – approximate centroid path on Haida Gwaii (to be refined)
    RiverDefinition(
      name: "Mamin River",
      communityID: AppEnvironment.shared.communityName,
      coordinates: maminCoordinates,
      maxDistanceKm: 10
    )
  ]

  private init() {}

  // MARK: - Public API

  /// Returns true if we have at least one river for this community.
    func hasRivers(forCommunity communityID: String) -> Bool {
      let normalized = communityID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return rivers.contains { $0.communityID.lowercased() == normalized }
    }

  /// Returns the best-matching river name for this location & community.
  ///
  /// Semantics:
  /// - If `location` is nil → "" (no river)
  /// - If no rivers are defined for this community → "" (no river)
  /// - For each river in this community:
  ///   - Compute the minimum distance to ANY of that river's coordinates.
  ///   - If that minimum distance ≤ `maxDistanceKm`, the river is a candidate.
  /// - Return the name of the candidate river with the smallest distance.
  /// - If no river is within its `maxDistanceKm` → "" (no river)
  func riverName(near location: CLLocation?, forCommunity communityID: String) -> String {
    // If we don't have a valid location, we can't resolve a river.
    guard let location else {
      return ""
    }

    // Filter for this community.
      let normalized = communityID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      let communityRivers = rivers.filter { $0.communityID.lowercased() == normalized }

    guard !communityRivers.isEmpty else {
      return ""
    }

    var bestRiver: RiverDefinition?
    var bestDistanceKm = Double.greatestFiniteMagnitude

    // For each river in this community...
    for river in communityRivers {
      guard !river.coordinates.isEmpty else { continue }

      // Find the closest of this river's points.
      var bestDistanceForRiver = Double.greatestFiniteMagnitude

      for coord in river.coordinates {
        let riverLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let distanceKm = location.distance(from: riverLoc) / 1000.0

        if distanceKm < bestDistanceForRiver {
          bestDistanceForRiver = distanceKm
        }
      }

      // Enforce the per-river max distance.
      guard bestDistanceForRiver <= river.maxDistanceKm else {
        continue
      }

      // Keep track of the globally closest qualifying river.
      if bestDistanceForRiver < bestDistanceKm {
        bestDistanceKm = bestDistanceForRiver
        bestRiver = river
      }
    }

    // If nothing qualified within its own radius, return "" ("no river").
    return bestRiver?.shortName ?? ""
  }
}
