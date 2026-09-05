import Foundation
import os

/// The backup destination Marco picks once with a document picker (iCloud Drive, "On My
/// iPhone", a Dropbox/Nextcloud provider …) plus the local folder WOQ always writes to.
///
/// ## Why a bookmark
/// A `UIDocumentPickerViewController` grants access to the chosen folder for this launch
/// only. Storing the `URL` string would be useless after a restart, so the URL is turned
/// into a bookmark (`UserDefaults` key `backupFolderBookmark`) and resolved again on the
/// next launch.
///
/// ## iOS bookmark specifics (differs from macOS)
/// - There is **no `.withSecurityScope`** option on iOS — neither when creating
///   (`url.bookmarkData(options: .minimalBookmark)`) nor when resolving
///   (`URL(resolvingBookmarkData:options: [], …)`). Passing the macOS option traps.
/// - A document-picker URL nevertheless stays reachable across launches: the bookmark keeps
///   the sandbox extension, and access is claimed with
///   `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`.
///   That pairing is exactly what `withAccess(_:)` does; every file operation on `url` must
///   go through it.
/// - `.minimalBookmark` keeps the blob small and avoids resolving the file's properties at
///   creation time (a not-yet-downloaded iCloud folder would otherwise stall).
/// - Bookmarks go stale (the folder moved, iCloud re-created it, the app was reinstalled and
///   restored). `resolve()` detects `bookmarkDataIsStale` and rewrites the bookmark in place.
///
/// ## Info.plist keys the wiring step must add (project.yml `info.properties`)
/// - `UIFileSharingEnabled = true` — the app's Documents folder shows up in Files under
///   "On My iPhone › WOQ", so `localDirectory` backups are reachable without any picker.
/// - `LSSupportsOpeningDocumentsInPlace = true` — files there open in place instead of being
///   copied, so Marco can drag `woq-backup.json` straight into iCloud Drive.
/// Neither key is needed for the picked external folder; they only expose the local copy.
@MainActor @Observable final class BackupFolder {

    /// `UserDefaults` key holding the bookmark blob.
    static let bookmarkKey = "backupFolderBookmark"

    /// The resolved external folder, or nil when none was picked (or the bookmark died).
    /// Read-only from outside: go through `set(_:)` and `clear()` so the bookmark and the
    /// URL can never disagree.
    private(set) var url: URL?

    /// Last bookmark problem, for the settings UI. nil when everything is fine.
    private(set) var lastError: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let logger = Logger(subsystem: "nl.feax.woq", category: "backup")

    /// Resolves the stored bookmark straight away, so `url` is valid by the time the first
    /// backup runs.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        resolve()
    }

    // MARK: - Choosing the folder

    /// Stores the folder the document picker returned.
    ///
    /// Call this with the URL from `.fileImporter` / `UIDocumentPickerViewController` while
    /// its grant is still live. Access is claimed around `bookmarkData` because a provider
    /// folder is not readable without it, and the bookmark would otherwise fail with
    /// `NSFileReadNoPermissionError`.
    func set(_ url: URL) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let bookmark = try url.bookmarkData(options: .minimalBookmark)
        defaults.set(bookmark, forKey: Self.bookmarkKey)
        self.url = url
        lastError = nil
        logger.notice("backup folder set")
    }

    /// Forgets the external folder. Local backups keep running.
    func clear() {
        defaults.removeObject(forKey: Self.bookmarkKey)
        url = nil
        lastError = nil
        logger.notice("backup folder cleared")
    }

    /// Re-resolves the stored bookmark into `url`, refreshing it when it went stale.
    /// Safe to call at any time; it never throws, it records into `lastError`.
    func resolve() {
        guard let bookmark = defaults.data(forKey: Self.bookmarkKey) else {
            url = nil
            return
        }
        do {
            var isStale = false
            // options must be [] on iOS: `.withSecurityScope` is macOS only.
            let resolved = try URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            url = resolved
            lastError = nil
            if isStale {
                refreshBookmark(for: resolved)
            }
        } catch {
            url = nil
            lastError = error.localizedDescription
            logger.error("backup folder bookmark unusable: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Rewrites a stale bookmark from the URL it just resolved to. A failure here is not
    /// fatal: the resolved URL still works for this launch.
    private func refreshBookmark(for url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let fresh = try url.bookmarkData(options: .minimalBookmark)
            defaults.set(fresh, forKey: Self.bookmarkKey)
            logger.notice("refreshed a stale backup folder bookmark")
        } catch {
            logger.error("could not refresh stale bookmark: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Using the folder

    /// Runs `body` with the external folder while its security scope is held.
    ///
    /// Returns nil when no folder is configured — that is the normal "local backups only"
    /// case, not an error. Errors thrown by `body` propagate to the caller.
    ///
    /// `startAccessingSecurityScopedResource()` returning false is not treated as fatal:
    /// for URLs that never needed a scope (a plain Documents subfolder, a test directory)
    /// it always returns false while the folder is perfectly writable. `stop…` is only
    /// called when `start…` succeeded, as Apple requires balanced calls.
    @discardableResult
    func withAccess<T>(_ body: (URL) throws -> T) throws -> T? {
        guard let url else { return nil }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try body(url)
    }

    // MARK: - The local copy

    /// `<app container>/Documents/Backups`, created on demand.
    ///
    /// Always written in addition to the external folder, so a backup exists even when no
    /// folder was picked, iCloud is signed out, or the provider is offline. It lives in
    /// Documents (not Application Support) so `UIFileSharingEnabled` can expose it in the
    /// Files app — but note it is inside the app container, so it does NOT survive deleting
    /// the app. Only the external folder does; that is the whole point of the picker.
    static var localDirectory: URL {
        let directory = URL.documentsDirectory.appending(path: "Backups")
        if !FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
