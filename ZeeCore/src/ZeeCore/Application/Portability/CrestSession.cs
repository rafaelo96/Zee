using ZeeCore.Contracts;
using ZeeCore.Domain;

namespace ZeeCore.Application;

/// Reads the browser Zee forked from: its session file is Zee's own layout,
/// a `checkpoint` table whose `core` part holds the Spaces and whose
/// `history.<id>` parts hold each Space's history. The file is copied before
/// it is opened, so a Crest that is still running keeps writing its own.
internal static class CrestSession {
    #region Static Variables

    /// The session file in Crest's data folder.
    public const string FileName = "session.sqlite";

    /// The files SQLite keeps beside a session in write-ahead mode, which
    /// hold its newest changes.
    private static readonly string[] Companions = ["-wal", "-shm"];

    #endregion

    #region Actions - Reading

    /// Every Space of the session at `path`, each with a new identity from
    /// `ids` for it and everything it holds, as an import of a browser-data
    /// file brings it: its tabs, folders, splits, archive, history and
    /// Boosts. Throws `Rejected` with `SessionUnrecognized` for a file that is
    /// no session or holds none, and `SessionTooLarge` for one too large.
    public static IReadOnlyList<SpaceState> Spaces(string path, IIdSource ids, DateTimeOffset now) {
        var parts = Parts(path);
        SessionState? session;
        try {
            // The sync journal says nothing an import brings, and one written
            // by a newer Crest would only stop it.
            parts.Remove(StoragePart.Journal.Name);
            session = StoredSession.Decode(parts).Session;
        } catch (Rejected) {
            throw new Rejected(new SessionUnrecognized());
        }
        if (session is null || session.Spaces.Count == 0) throw new Rejected(new SessionUnrecognized());
        try {
            return [.. session.Spaces.Select(space => BrowserDataSpace.From(space).Materialize(ids, now))];
        } catch (Rejected) {
            throw new Rejected(new SessionUnrecognized());
        }
    }

    /// The parts of a copy of the session at `path` and the files beside it.
    private static Dictionary<string, byte[]> Parts(string path) {
        var info = new FileInfo(path);
        if (!info.Exists) throw new Rejected(new SessionUnrecognized());
        if (info.Length > InstalledBrowser.MaximumSessionBytes) throw new Rejected(new SessionTooLarge());
        string copy = Path.Combine(Path.GetTempPath(), "zee-crest-import-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(copy);
        try {
            string file = Path.Combine(copy, FileName);
            File.Copy(path, file);
            foreach (string companion in Companions) {
                if (File.Exists(path + companion)) File.Copy(path + companion, file + companion);
            }
            using var connection = SqliteConnection.Open(file, Sqlite.OpenReadWrite);
            return connection.Parts().ToDictionary(part => part, part => connection.Read(part)!, StringComparer.Ordinal);
        } catch (Exception error) when (error is IOException or UnauthorizedAccessException or StorageException) {
            throw new Rejected(new SessionUnrecognized());
        } finally {
            try {
                Directory.Delete(copy, recursive: true);
            } catch (Exception error) when (error is IOException or UnauthorizedAccessException) {
            }
        }
    }

    #endregion
}
