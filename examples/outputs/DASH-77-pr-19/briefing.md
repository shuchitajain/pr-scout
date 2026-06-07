# PR Review Briefing — DASH-77 / PR #19

**Story:** DASH-77 — Add CSV export to the analytics dashboard  
**PR:** #19 — feat: csv export for analytics dashboard  
**Run:** 2026-06-05  
**Branch:** `feature/DASH-77-csv-export` → `main`

---

## Story Verdict

| Story | Verdict | Summary |
|---|---|---|
| DASH-77 | **Partial** | Export triggers and file download work. AC 3 (column selection) and AC 5 (export scoped to active date range) are not implemented. |

---

## PR Narrative Walkthrough

The change adds a CSV export button to `AnalyticsDashboardScreen` and wires it to a new `CsvExportService`. The service fetches all rows from `AnalyticsRepository.getEvents()`, serialises them to CSV using the `csv` package, and triggers a file download via `dart:html` on web and `path_provider` + `share_plus` on mobile.

The export button is correctly placed in the app bar and is gated behind the existing `FeatureFlags.csvExport` flag.

`CsvExportService.export()` fetches the full dataset regardless of the date range currently selected in the dashboard. The `DateRangeFilter` state is not passed to the repository call — the method signature accepts no parameters and calls `getEvents()` with no filter arguments.

Column selection is not present. All columns are always exported. The story required users to choose which columns to include before downloading.

A loading indicator is shown during export on mobile but not on web — the web path calls the download helper synchronously without any loading state.

---

## Story Compliance Matrix — DASH-77

| # | Acceptance Criterion | Status | Evidence |
|---|---|---|---|
| AC 1 | Export button visible on the analytics dashboard for users with the `csv_export` permission | ✅ Pass | Button rendered in `AnalyticsDashboardScreen` app bar, gated on `FeatureFlags.csvExport`. `lib/ui/screens/analytics_dashboard_screen.dart` lines 38–45 |
| AC 2 | Tapping export downloads a valid `.csv` file with correct headers | ✅ Pass | `CsvExportService.export()` serialises rows with headers derived from column keys. `lib/services/csv_export_service.dart` lines 22–41 |
| AC 3 | User can select which columns to include before downloading | ❌ Missing | No column selection UI or parameter in `CsvExportService.export()`. All columns always exported. |
| AC 4 | Export is not available to users without the `csv_export` permission | ✅ Pass | `FeatureFlags.csvExport` check present; button hidden and service call guarded. `lib/ui/screens/analytics_dashboard_screen.dart` line 38 |
| AC 5 | Exported data is scoped to the date range currently active in the dashboard | ❌ Missing | `CsvExportService.export()` calls `getEvents()` with no filter. Full dataset always exported. `lib/services/csv_export_service.dart` line 27 |
| AC 6 | A loading indicator is shown while the export is in progress | ⚠️ Partial | Loading state shown on mobile path. Web path downloads synchronously with no loading indicator. `lib/services/csv_export_service.dart` lines 44–59 |

---

## Findings

### Finding 1 — Export ignores active date range filter (High)

**Why it matters:** Users who have filtered the dashboard to a specific date range will receive a full-history export without any indication that filters were ignored. This is a data correctness issue and a likely support escalation.

**Evidence:** `lib/services/csv_export_service.dart` line 27. `getEvents()` is called with no arguments. `DateRangeFilter` is available in `DashboardState` but is never read by the export path.

**Reviewer question:** Should `export()` accept a `DateRangeFilter` parameter, or should it read directly from the state provider? Either way, this needs to be resolved before AC 5 can pass.

**Confidence:** High

---

### Finding 2 — No loading state on web export path (Medium)

**Why it matters:** Large datasets can take several seconds to serialise. On web, the button stays enabled and the UI is unresponsive during that time, with no feedback to the user.

**Evidence:** `lib/services/csv_export_service.dart` lines 44–59. The `kIsWeb` branch calls `_triggerWebDownload()` directly without setting `isExporting = true` or disabling the button.

**Reviewer question:** Should the web path share the same loading state wrapper as mobile, or is a separate web-specific approach preferred?

**Confidence:** Medium

---

### Finding 3 — Large exports not chunked or streamed (Low)

**Why it matters:** `getEvents()` fetches all rows into memory before serialisation. For accounts with large datasets this will cause memory spikes and potentially crash the tab on web.

**Evidence:** `lib/services/csv_export_service.dart` lines 22–28. No pagination or streaming is used.

**Reviewer question:** Is there a known row count ceiling for this endpoint, or should the export be chunked?

**Confidence:** Low
