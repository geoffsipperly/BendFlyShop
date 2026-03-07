# Epic Waters (Fly Fishing Platform) — Current State Feature Inventory

## Architecture Overview

- **Platform:** Native iOS (Swift/SwiftUI), ~230,000 LOC across ~800 Swift files
- **Backend:** Supabase (PostgreSQL + 32 Edge Functions in TypeScript/Deno)
- **ML:** 3 CoreML models (YOLOv8 fish detection, ViT species classification, ViT sex classification)
- **Auth:** Supabase Auth + Apple Sign In + Biometric (Face ID/Touch ID)
- **Local Storage:** Core Data (7 entities) + JSON file persistence + UserDefaults caching
- **Roles:** Two distinct user experiences — Guide and Angler

---

## 1. ENGAGEMENT CHANNELS

### 1.1 Guide Mobile App (iOS)

- Guide Landing/Dashboard — Primary hub with "Record a Catch" and "Current Conditions" feature tiles; hamburger menu for Manage Trips, Catch History, Community Forum
- One-time Camera/Location Onboarding — First-launch permission request flow for camera + GPS
- Dark Mode UI — Consistent dark theme across all screens with blue accent color
- Branded Experience — Epic Waters logo, "Intelligent Conservation" tagline, "Powered by Mad Thinker" footer
- Toast Notifications — In-app feedback for save/upload/error events
- Splash Video — Onboarding/branding video with configurable display frequency

### 1.2 Angler Mobile App (iOS)

- Angler Landing/Dashboard — Catch history display (thumbnails + river + date), action buttons for Current Conditions, Trip Prep, Community Forum
- Catch History Feed — Most recent catches with expandable list (show more/less), tap to detail
- Trip Preparation Panel — Slide-in panel with trip planning features

### 1.3 Community Forum

- Category Browsing — Forum categories with descriptions, sorted by display order
- Thread Listing — Threads per category with author names (via Supabase views)
- Thread Creation — Title (20-word limit) + body (500-word limit) with word count display
- Post/Reply — Reply composer in thread detail view
- Media Attachments — Image uploads with local caching (5 files / 50MB max per post)
- Edit/Delete Own Posts — Swipe actions on posts authored by current user (JWT-based ownership check)
- Real-time Data — Uses Supabase PostgREST for forum_categories, forum_threads, forum_posts

> **Partially Implemented:** "Record a Field Note" menu item exists in Guide Landing but is commented out/disabled

---

## 2. ORCHESTRATION & WORKFLOW MANAGEMENT

### 2.1 AI-Assisted Catch Recording (Chat Flow)

- Conversational UI — Step-by-step guided catch entry: select trip → select angler → select license → open chat
- Photo-First Workflow — Upload photo → AI analyzes (species, sex, length, river) → user reviews/corrects → optional voice memo → confirm
- Natural Language Corrections — Parses edits like "length is 32", "male", "species: steelhead" from chat messages
- Initial Analysis Snapshot — Captures AI's first guess before user edits for model improvement tracking
- Key Components: `ReportChatView`, `CatchChatView`, `CatchChatViewModel`

### 2.2 Trip Lifecycle Management

- Trip Status Machine — Not Started → In Progress → Completed (based on start/end dates vs. current date)
- Bi-directional Trip Sync — Timestamp-based conflict resolution (server-wins when server is newer) between local Core Data and server
- Background Hydration — `TripSyncService` auto-syncs trips on app launch so they're available for catch recording
- Auto-Archive — Uploaded catch reports automatically archived after 14 days
- Key Components: `SynchTrips`, `TripSyncService`, `TripListView`

### 2.3 Catch Report Upload Pipeline

- Batch Upload — Upload all locally-saved reports with progress bar
- Two Upload Formats:
  - V1: Core Data `CatchReport` → JSON DTO with base64 photo (`UploadCatchReport`)
  - V2 (PicMemo): JSON-based `CatchReportPicMemo` → JSON with base64 photo + voice memo (`UploadCatchPicMemo`)
- Multi-Source Photo Resolution — PhotoStore → absolute path → Documents/Caches → Photos library (PHAsset)
- Voice Memo Embedding — Base64-encoded M4A audio + transcript + metadata (language, sample rate, on-device flag)
- Status Tracking — Saved Locally → Uploaded → Archived (with color-coded status pills)
- Retry on Auth Error — Automatic token refresh and retry on 400/401/403
- Backend Enrichment — After successful upload, the server automatically triggers environmental data enrichment (water conditions, weather, tides, moon phase)

### 2.4 Farmed Report Upload Pipeline

- Batch Upload — Upload all locally-saved farmed reports
- GPS Validation — Requires valid GPS coordinates
- River Name Resolution — Automatic river lookup from GPS via `RiverLocator`
- Backend Enrichment — Server triggers environmental enrichment after upload (same pipeline as catch reports)
- Key Components: `UploadFarmedReports`

---

## 3. DISCIPLINE-SPECIFIC SERVICES (FLY FISHING)

### 3.1 Catch Reporting

- Manual Catch Form — River (segmented picker), species, sex, origin (wild/hatchery), tag ID (hatchery only), length (inches), quality, tactic, field notes, photo
- PicMemo Catch Reports — Alternative photo + voice memo workflow with AI analysis
- GPS Auto-Tagging — Automatic latitude/longitude capture via LocationManager
- River Auto-Detection — Offline GPS-to-river matching using pre-defined coordinate spines for 5 Haida Gwaii rivers (Copper, Pallant, Yakoun, Tlell, Mamin)
- Catch Detail View — View catch with photo, species, size, location, notes
- AI-Generated Catch Stories — Natural language narrative generated from catch data with 3 fetch modes (cache-first, server-only, fresh)
- Map Visualization — All catches displayed on Mapbox Maps with clustering and spiderfy-on-tap for overlapping pins (replaced Apple MapKit)
- Key Components: `ReportFormView`, `ReportsListViewPicMemo`, `CatchPhotoAnalyzer`, `RiverLocator`, `CatchStoryService`, `ClusteredMapView`, `AnglerCatchMapView`

### 3.2 Farmed Fish Reporting

- Farmed Report Recording — Records farmed (aquaculture) fish observations with guide name, optional angler number, GPS coordinates
- Automatic River Resolution — GPS-to-river lookup via `RiverLocator` spine dataset
- Offline Storage — JSON file persistence in Documents/FarmedReports/
- Status Tracking — savedLocally → uploaded
- Swipe-to-Delete — Individual reports can be swiped to delete
- 14-Day Auto-Purge — Uploaded reports automatically removed after 14 days
- Upload to Backend — Batch upload with automatic environmental enrichment
- Key Components: `FarmedReport`, `FarmedReportStore`, `FarmedReportsListView`, `UploadFarmedReports`

### 3.3 Observations (Guide Feature)

- Environmental Observations — Audio-based field observations with voice recording
- GPS Tagging — Auto-captures location on recording
- Transcript Support — On-device or uploaded transcription
- Idempotency — Client-side ID prevents duplicate uploads
- Key Components: `Observation`, `ObservationStore`, `ObservationsListView`, `RecordObservationSheet`, `UploadObservations`

### 3.4 Species & Catch Analysis (On-Device ML)

- Fish Detection — YOLOv8 object detector (`best.mlpackage`) at 640x640 resolution; handles dual output layouts; geometry filtering (aspect ratio, height/area fraction)
- Species Classification — Vision Transformer (`ViTFishSpecies.mlpackage`) at 224x224; 9 species labels; lifecycle stage parsing (e.g., "Steelhead Traveler" → species + stage)
- Sex Classification — Vision Transformer (`ViTFishSex.mlpackage`, iOS 16+ only); male/female determination
- Length Estimation — Heuristic from YOLOv8 bounding box (pixels → inches with 0.59 scale factor for training bias); clamped 10-47 inches with +/-7% range
- EXIF Metadata Extraction — Prefers photo date/location over device GPS for catch context

### 3.5 Classified Waters License Management

- Full CRUD — Create, read, update, delete licenses via API
- Three Input Methods: Manual entry, camera scan (OCR), photo library scan
- OCR Extraction — Vision framework (`VNRecognizeTextRequest`) specialized for BC Non-Tidal licenses; extracts license number, river, dates, name, angler number, DOB, telephone, residency
- Classified Waters Table Parsing — Dedicated `BCClassifiedWaters` parser for license table rows
- Fuzzy Label Matching — Handles OCR typos in label fields (e.g., "Licencee" variants)
- License Grouping — Active/Future/Expired sections with exclusive end-date logic
- Batch Save — Pending creates + edits + deletes saved in single operation
- Purchase Link — Embedded WebView to government license purchase page
- Key Components: `AnglerClassifiedWatersLicenseUpload`, `LicenseTextRecognizer`, `ClassifiedWatersExtractor`, `FSELicense_BCFuzzyLabels`

### 3.6 River Conditions & Fishing Forecast

- Guide Forecast — River-specific conditions (5 rivers: Copper, Pallant, Mamin, Yakoun, Tlell) with:
  - 3-day weather (yesterday/today/tomorrow) with high/low/precipitation
  - Tide wave graph (Catmull-Rom interpolated curve with high/low tide markers)
  - Water level trend sparkline (4 days)
  - Water temperature sparkline (when available)
- Angler Forecast — Location-based multi-day forecast with AI-generated interpretation (expandable summary), daily rows showing weather icon, temp range, precipitation, wind
- AI Tactics Recommendations — Generated from river conditions data: summary, optimal times, water approach, recommended flies (bulleted), detailed analysis
- Key Components: `FishingForecastRequestView`, `FishingForecastResultView`, `TacticsRecommendationsView`, `AnglerForecastView`

### 3.7 Voice Notes / Field Memos

- Audio Recording — M4A recording with AVAudioEngine, pause/resume, live mic level visualization (ripple effect)
- Live Speech-to-Text — Real-time transcription via SFSpeechRecognizer during recording
- GPS Tagging — Auto-captures location on recording start
- Local Persistence — JSON metadata + M4A audio files in Documents/VoiceNotes/
- Upload — Multipart form-data to Supabase Edge Function with Idempotency-Key header
- Status Tracking — savedPendingUpload → uploaded
- Playback — NoteAudioPlayer for voice note playback from history list
- Key Components: `VoiceNoteView`, `SpeechRecorder`, `VoiceNoteStore`, `NoteAudioPlayer`

### 3.8 Gear Management

- Interactive Gear Checklist — Mandatory items (waders, boots, jacket) + recommended items (switch rod, short spey) with square checkboxes
- Reel Hand Selection — Left/right picker persisted to server
- Collapsible Optional Gear — Detailed rod/reel/fly recommendations
- Lodge-Specific — Checklist keyed to lodge (currently "Copper Bay")
- Server + Local Cache Sync — Gear selections saved to API and cached in UserDefaults
- Static Gear Guide — Read-only recommended gear view for Haida Gwaii (spey rods, sink tips, flies, leaders, waders)
- Key Components: `GearChecklist`, `AnglerRecommendedGearView`

### 3.9 Fishing Tactics Education

- Learn Tactics View — Educational content for anglers about fishing techniques
- Key Components: `LearnTacticsView`

---

## 4. COMMON BUSINESS SERVICES

### 4.1 Authentication & Identity

- Email/Password Auth — Supabase Auth signup/signin with JWT tokens
- Apple Sign In — Via entitlements (`com.apple.developer.applesignin`)
- Token Management — JWT storage in Keychain, automatic refresh with 120s buffer, serialized refresh (prevents concurrent attempts), retry on 429/5xx
- Offline Login — Cached credentials in Keychain for offline authentication when network unavailable
- Biometric Auth — Face ID/Touch ID via LAContext, resumes session from tokens or offline credentials
- Remember Me — Role-based defaults (guides ON, anglers OFF); toggle persists offline credentials
- Password Reset — Via Supabase `/auth/v1/recover`
- Role-Based Routing — `AppRootView` routes to Guide or Angler landing based on `userType` from profile metadata
- Key Components: `AuthService`, `AuthStore`, `BiometricAuth`, `AppRootView`

### 4.2 User Profile Management

- Guide Registration — First/last name, email, password, community selection, terms acceptance
- Angler Registration — Same + angler number + OCR scan of license (auto-fills name, DOB, sex, residency, phone)
- Community Selection — Epic Waters, Rio Palena Lodge, Ted Carlin Fishing
- Self-Assessment (Angler) — Slider-based proficiency (1-100) for Learning Style, Casting, Wading, Hiking; dynamic context from server; hierarchical cache lookup
- Profile Management — Edit personal info, preferences
- Angler Context Upload — Sends angler preferences/context to server for AI personalization
- Key Components: `GuideRegistrationView`, `AnglerAboutYou`, `ManageProfileView`, `UploadAnglerContext`

### 4.3 Trip Management

- Trip Creation — Guide name, trip name, start/end dates, community/lodge selection, up to 8 anglers per trip
- Per-Angler Data — Name, license/angler number, classified waters licenses, optional demographics (DOB, residency, sex, address, phone)
- Angler Lookup — API search by name or license number with multi-result picker for disambiguation
- Trip Editing — Modify dates, add/remove anglers, add/remove classified waters licenses per angler
- Trip List — Grouped by status (In Progress / Not Started / Completed) with color-coded pills
- Trip Detail — Read-only view of trip summary, anglers, licenses (editable for non-completed trips)
- Trip-to-Core Data Sync — Server trips hydrated to local Core Data on app launch and on navigation
- Key Components: `TripFormView`, `TripListView`, `TripDetailView`, `TripAPI`, `ManageTripsView`

### 4.4 Staff Directory

- Staff Listing — Staff bios grouped by lodge with photo, name, role, short description
- Staff Detail — Full bio view for individual staff members
- Community-Scoped — Fetches staff for current community (e.g., "Epic Waters")
- Key Components: `MeetStaff`, `StaffDetailView`

### 4.5 Flight Tracking

- Flight Itinerary Management — CRUD for flight itineraries
- Two Input Methods — Document upload (PDF/image OCR via AI extraction) or manual entry (flight number, airports, dates/times)
- One-Way vs Round-Trip — Separate outbound/return segments
- Real-Time Flight Status — Fetches live status via AeroDataBox API with color-coded pills (green=scheduled/departed/arrived, yellow=delayed, red=cancelled)
- Local Caching — Itineraries cached to UserDefaults
- Feature Flagged — Controlled by `FF_FLIGHT_INFO` flag
- Key Components: `AnglerFlights`

### 4.6 Terms & Conditions

- Role-Specific Terms — Separate terms for guides (`guide_terms.md`) and anglers (`angler_terms.md`)
- Required Acceptance — Checkbox + view sheet during registration
- Terms Loading — TermsStore service for content retrieval
- Key Components: `TermsAndConditionsView`, `TermsStore`

### 4.7 Angler Roster (Guide View)

- Trip-Based Roster — Fetch anglers across trips for a lodge
- Detailed Angler Profiles — Self-assessment with color-coded proficiency meters (red 0-33 / yellow 34-75 / green 76+), preferences (drinks, food, health), gear checklist
- Learning Style Interpretation — Generates natural language sentence from proficiency data
- Key Components: `AnglerProfilesView`

---

## 5. AI & ML

### 5.1 On-Device Computer Vision

- YOLOv8 Fish Detection — `best.mlpackage`, 640x640 input, dual output layout support, confidence threshold 0.08 (0.01 fallback), geometry filtering
- ViT Species Classification — `ViTFishSpecies.mlpackage`, 224x224 RGB input, 9 species labels
- ViT Sex Classification — `ViTFishSex.mlpackage`, iOS 16+ only
- Length Estimation — Bounding box pixel-to-inches heuristic with training bias correction

### 5.2 On-Device Speech Processing

- Live Transcription — SFSpeechRecognizer for real-time speech-to-text during voice memo recording
- Multi-Language Support — Language metadata preserved for server-side processing

### 5.3 On-Device OCR

- Vision Framework OCR — `VNRecognizeTextRequest` (accurate mode, language correction)
- BC License Parser — Specialized two-column layout detection, fuzzy label matching, classified waters table extraction
- Name Parsing — Handles "LAST, FIRST" format, Scottish name prefixes (Mc/Mac)

### 5.4 Server-Side AI (via Supabase Edge Functions)

- Fishing Forecast AI — 14-day weather/tide/conditions interpretation via Lovable AI (Gemini)
- Tactics Recommendations — AI-generated fishing tactics based on river conditions and voice note transcripts
- Catch Story Generation — Natural language narrative from catch data + environmental enrichment + voice memo transcripts (Lovable AI / Gemini-2.5-pro)
- Flight Document Extraction — AI-powered extraction of flight details from uploaded PDF/image documents (Lovable AI)
- Transcript Insights — AI-derived structured insights from voice note transcripts

---

## 6. DATA / CONTENT MANAGEMENT

### 6.1 Core Data Schema (Local)

- **CatchReport** — Species, sex, origin, length, quality, river, tactic, GPS, photo, notes, tag ID, status, angler/guide/trip references
- **Trip** — Name, dates, guide, lodge reference, clients, catches
- **TripClient** — Name, license number, trip reference, catches, classified licenses
- **ClassifiedWaterLicense** — License number, water, vendor, valid dates, guide name
- **Community** — Name, lodges
- **Lodge** — Name, community reference, trips
- **VoiceNote** (CDVoiceNote) — Audio path, JSON path, transcript, duration, format, sample rate, language, GPS, status

### 6.2 JSON File Storage

- **CatchReportPicMemo** — Individual JSON files in Documents/CatchReportsPicMemo/ (V2 catch format)
- **FarmedReport** — Individual JSON files in Documents/FarmedReports/
- **VoiceNotes** — M4A audio + JSON metadata in Documents/VoiceNotes/
- **Observations** — Individual JSON files managed by ObservationStore

### 6.3 Seed Data

- 7 Lodges: Bulkley Basecamp, Babine Steelhead Lodge, Copper Bay Lodge, Frontier Steelhead Experience, Epic Narrows Musky Camp, Labrador Heli-Fishing Atlantic Salmon, Togiak Epic Spey
- 1 Community: Epic Waters
- 5 River Coordinate Spines: Copper (11 pts), Pallant (7 pts), Yakoun (42 pts), Tlell (15 pts), Mamin (14 pts)

### 6.4 Caching Strategy

- **UserDefaults** — Flight itineraries, gear selections, proficiency scores, catch stories, angler context (all with user/lodge-scoped keys)
- **Keychain** — JWT tokens, refresh tokens, offline credentials
- **Core Data** — Trips, catches, clients, licenses (synced with server)

---

## 7. INFRASTRUCTURE

### 7.1 Backend (Supabase)

- **PostgreSQL Database** — Primary data store
- **32 Edge Functions** — TypeScript on Deno runtime (see inventory below)
- **PostgREST** — Forum CRUD via REST API with database views
- **Storage Buckets** — catch-photos (public), catch-media, voice-notes (private), forum-media, flight-uploads
- **Auth** — Email/password + JWT token management
- **Two Environments** — DevTEST (`rowytjuewalinlnlzysb`) and PROD (`paxslufnrjjvvflgciir`)

#### Edge Functions Inventory

| Function | Purpose | Methods |
|----------|---------|---------|
| **angler-context** | Retrieves angler proficiency/skill context by community with lodge/species/tactic filtering | GET |
| **angler-details** | Comprehensive angler profile with preferences, proficiencies, gear, and context | GET |
| **angler-forecast** | 14-day fishing forecast using Open-Meteo weather + NOAA tides + AI interpretation | POST |
| **angler-profile** | Angler lookup by number or name, returns classified waters licenses | GET |
| **catch-report-media** | CRUD for catch report media (photos/videos); enforces 5 files / 50MB per catch | GET, POST, PATCH, DELETE |
| **catch-story** | AI-generated narrative from catch data + enrichment + transcripts (Gemini-2.5-pro) | POST |
| **classified-licenses** | CRUD for classified waters fishing licenses with role-based access | GET, POST, PUT, DELETE |
| **delete-user** | Admin user deletion with cascade across 15+ tables; supports dry-run preview | POST |
| **download-catch-reports** | Download catch reports filtered by user type and community | GET |
| **enrich-catch-report** | Enriches catch reports with water temp/level/flow, weather, tides, moon phase, integrity score | POST |
| **enrich-farmed-report** | Same enrichment pipeline as above but for farmed fish reports | POST |
| **flight-details** | Flight itinerary CRUD with AI-powered document extraction (PDF/Word/text) | GET, POST, DELETE |
| **flight-status** | Real-time flight status via AeroDataBox API (through MagicAPI gateway) | POST |
| **forum-posts** | Forum thread/post CRUD with media attachments | GET, POST, PATCH, DELETE |
| **gear** | Angler gear management (waders, boots, jacket, rods, reel hand) by lodge | GET, POST, PUT |
| **import-archived-catches** | Bulk import of historical catch reports with deduplication | POST |
| **manage-trip** | Trip CRUD with angler roster and license management; community/lodge scoped | GET, POST |
| **my-profile** | Self-service profile endpoint for authenticated anglers | GET, PUT, PATCH |
| **observations** | Audio observation upload with transcript and location; idempotent | POST |
| **proficiency** | Angler proficiency levels (casting, wading, hiking, learning) by species/tactic/lodge | GET, POST |
| **river-conditions** | Current water conditions (level, temp) for specific rivers + weather + tides | GET |
| **river-conditions-batch** | Batch version — water level and temperature for multiple rivers in one call | GET |
| **staff-bio-detail** | Detailed staff biography by community and name | GET |
| **staff-bios** | Staff listing by community with optional lodge filter | GET |
| **tactics-recommendations** | AI-powered tactical recommendations from voice note transcripts (full-text search) | POST |
| **transcript-insights** | AI-derived structured insights from voice note transcripts | POST |
| **trip-roster** | Active trip roster by community/lodge with angler names and licenses | GET |
| **update-user-email** | Admin-only email/password update | POST |
| **upload-catch-reports** | V1 catch upload — creates trips/anglers, base64 photo | POST |
| **upload-catch-reports-v2** | V2 — adds voice memo support, lifecycle stage, initial AI analysis | POST |
| **upload-catch-reports-v3** | V3 (current) — tripId reference only, trip reconciliation, auto-enrichment trigger | POST |
| **upload-farmed-reports** | Farmed fish report upload with GPS, river name, auto-enrichment | POST |

#### Key Backend Patterns

- **Authentication:** JWT-based with service role fallback for elevated DB operations
- **Authorization:** Community and role-based access control (guides can access more than anglers)
- **Idempotency:** Client-generated IDs prevent duplicate uploads (catch reports, observations, voice notes)
- **Enrichment Pipeline:** Fire-and-forget enrichment triggered after catch/farmed report upload — pulls water conditions from Canadian Water Office or USGS, weather from Open-Meteo, tides from NOAA, calculates moon phase and integrity score
- **AI Integration:** Several functions use Lovable AI (backed by Gemini-2.5-pro) for natural language generation (catch stories, forecasts, tactics, flight extraction)
- **Media Storage:** Supabase Storage with public buckets for photos, private for voice notes

### 7.2 Environment Configuration

- xcconfig-Based — `DevTEST.xcconfig` and `PROD.xcconfig` with all API URLs
- Info.plist Variable Injection — 25+ endpoint URLs resolved at build time
- Feature Flags — `BETA_RELEASE`, `FF_FLIGHT_INFO`
- Logging — Configurable `LOG_LEVEL`, centralized `AppLogging` system with per-category enable/disable

### 7.3 Deep Linking

- Associated Domains — `applinks:super-api-buddy.lovable.app`

### 7.4 Code Quality

- **SwiftLint** — Line length 120, type body 300/500, file length 500/1200
- **SwiftFormat** — Swift 5.10, 2-space indent, 120 max width
- **Testing** — Unit tests (auth regression, guide landing, angler trip prep, OCR, farmed reports) + UI tests + mock URL protocol

### 7.5 Dependencies

**Third-Party Libraries (SPM):**

| Package | Version | Purpose |
|---------|---------|---------|
| Supabase Swift | 2.37.0 | Backend SDK (auth, database, storage, edge functions) |
| Mapbox Maps iOS | 11.18.1 | Map rendering for catch/angler map views |
| Turf Swift | 4.0.0 | Geospatial calculations (Mapbox dependency) |

**Transitive dependencies:** swift-crypto, swift-concurrency-extras, swift-clocks, swift-http-types, swift-asn1, xctest-dynamic-overlay (pulled in by Supabase/Mapbox)

**Apple Frameworks:** Vision, CoreML, Speech, MapKit, LocalAuthentication, AVFoundation, Photos

---

## 8. EXTERNAL SERVICE INTEGRATIONS

| Service | Purpose | Integration Point |
|---------|---------|-------------------|
| Supabase | Backend (DB, Auth, Storage, Functions) | All API calls |
| Apple Vision | OCR for fishing licenses | `LicenseTextRecognizer` |
| Apple CoreML | Fish detection/classification | `CatchPhotoAnalyzer` (3 models) |
| Apple Speech | Live transcription | `VoiceNoteView` / `SpeechRecorder` |
| Mapbox Maps iOS | Catch mapping with clusters (replaced Apple MapKit) | `ClusteredMapView`, `AnglerCatchMapView` |
| Apple Sign In | Authentication | Entitlements |
| Apple Photos | Photo library access | `ImagePicker`, `UploadCatchReport` |
| Open-Meteo | Weather forecasts | `river-conditions`, `angler-forecast`, `enrich-catch-report` Edge Functions |
| NOAA | Tide data | `river-conditions`, `angler-forecast`, `enrich-catch-report` Edge Functions |
| Canadian Water Office | Real-time water level/temperature (BC rivers) | `river-conditions`, `enrich-catch-report` Edge Functions |
| USGS | Real-time water data (US rivers) | `enrich-catch-report` Edge Function |
| Lovable AI (Gemini) | Natural language generation (stories, forecasts, tactics, flight extraction) | `catch-story`, `angler-forecast`, `tactics-recommendations`, `flight-details` Edge Functions |
| AeroDataBox (via MagicAPI) | Real-time flight status | `flight-status` Edge Function |
| sunrise-sunset.org | Sunrise/sunset times | `enrich-catch-report` Edge Function |
| BC Government | License purchase (WebView) | `AnglerClassifiedWatersLicenseUpload` |

---

## 9. PARTIALLY IMPLEMENTED / IN PROGRESS

| Feature | Evidence | Status |
|---------|----------|--------|
| Field Notes (Guide) | Menu button exists in `LandingView` but is commented out; `VoiceNoteView` is fully implemented and reachable via hidden NavigationLink | UI entry point disabled |
| Gear Recommendations | `AnglerRecommendedGearView` is hardcoded for Haida Gwaii only; no dynamic/API content | Static content only |
| Learn Tactics | `LearnTacticsView` exists in Angler views | Likely minimal implementation |
| Lodge-Specific Gear | Checklist hardcoded to "Copper Bay" lodge | Not generalized |
| River Coordinates | Only 5 Haida Gwaii rivers defined; no mechanism to load new rivers dynamically | Static data |
| Angler Forecast Location | Hardcoded to "Copper Bay" | Not dynamic |
| Species Labels | 9 species in ViT model | Fixed to current training set |
| Length Estimation | Uses 0.59 temp scale factor to counteract training bias (person+fish vs. fish-only) | Needs model retraining |
| Multi-Community Support | Registration allows 3 communities (Epic Waters, Rio Palena, Ted Carlin) but nearly all features are hardcoded to "Epic Waters" / "Copper Bay" | Scaffolded but not generalized |

---

## 10. REUSABILITY ANALYSIS (for Duck Hunting & Cycling)

### Directly Reusable Common Services

- **Authentication System** — Full auth flow (signup, signin, biometric, offline, token refresh) — discipline-agnostic
- **Forum/Community** — Category → Thread → Post structure — fully generic
- **Trip Management** — Trip lifecycle, angler/participant roster, date-based status — adaptable to any guided experience
- **Voice Notes** — Recording, transcription, upload — discipline-agnostic
- **Flight Tracking** — Itinerary management, status checking — discipline-agnostic
- **Staff Directory** — Lodge/venue-scoped staff bios — discipline-agnostic
- **Profile & Self-Assessment** — Slider-based proficiency, preferences — questions could be swapped per discipline
- **Terms & Conditions** — Role-based terms display and acceptance — generic
- **Upload Pipeline** — Photo + voice memo + metadata batch upload — generic
- **Caching Strategy** — UserDefaults + Keychain + Core Data patterns — generic

### Patterns to Replicate (Discipline-Specific Swap)

- **Catch Reporting → Harvest/Activity Reporting** — Same form/chat pattern, different fields (species → game type, river → blind/location)
- **ML Photo Analysis → Species ID** — Same pipeline, different trained models (fish → duck/bird, bike component)
- **OCR License Scanning → Permit Scanning** — Same Vision pipeline, different parsing rules (fishing license → hunting license → race registration)
- **River Locator → Location Identifier** — Same GPS proximity matching, different coordinate data (rivers → hunting zones → cycling routes)
- **Gear Checklist → Equipment Checklist** — Same toggle/save pattern, different items
- **Forecast/Conditions → Weather/Conditions** — Same display pattern, different data endpoints
- **Tactics Recommendations → Strategy/Tips** — Same AI generation pattern, different domain context

### Gaps to Fill for New Disciplines

- **Dynamic Configuration** — Most features hardcoded to Haida Gwaii/Copper Bay; need config-driven lodge/venue/route selection
- **Multi-Discipline Data Model** — Core Data schema is fishing-specific (CatchReport, ClassifiedWaterLicense); needs abstraction or parallel schemas
- **Dynamic River/Location Data** — Need API-driven coordinate loading instead of hardcoded arrays
- **Model Swapping** — ML pipeline exists but models are fish-specific; need model registry per discipline
- **Generalized Gear/Equipment** — Currently static lists; need API-driven gear catalogs per discipline/venue
