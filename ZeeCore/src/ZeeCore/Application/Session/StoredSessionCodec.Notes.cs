using System.Text.Json.Nodes;

using ZeeCore.Contracts;

namespace ZeeCore.Application;

/// A Space's notes as the stored session, the sync record and a browser-data
/// file all keep them: one object each, its time in the stored form's seconds.
internal static partial class StoredSessionCodec {
    #region Actions - Notes

    /// The notes `node` holds, or null when it holds none. A note that does
    /// not read, or that a Space would not keep, is left out, so one a later
    /// build wrote never costs the others.
    internal static IReadOnlyList<Note>? DecodeNotes(JsonNode? node) {
        if (node is not JsonArray items) return null;
        List<Note> notes = [];
        foreach (var item in items.OfType<JsonObject>().Take(Note.MaximumPerSpace)) {
            try {
                if (DecodeNote(item) is { } note && notes.All(kept => kept.Id != note.Id)) notes.Add(note);
            } catch (Exception error) when (error is Rejected or InvalidOperationException or FormatException) {
                // Left out, as the summary says.
            }
        }
        return notes;
    }

    private static Note? DecodeNote(JsonObject value) {
        if (!Guid.TryParse(TolerantText(value[Key.Id]), out var id)) return null;
        return new Note(id, TolerantText(value[Key.Title]) ?? "", TolerantText(value[Key.Body]) ?? "",
            OptionalDate(value[Key.ModifiedAt]) ?? ReferenceEpoch, TolerantFlag(value[Key.Easel]) ?? false).Validated();
    }

    internal static JsonArray EncodeNotes(IReadOnlyList<Note> notes) => new([.. notes.Select(note => (JsonNode)Encode(note))]);

    private static JsonObject Encode(Note note) {
        var value = new JsonObject {
            [Key.Id] = note.Id.ToString("D"),
            [Key.Title] = note.Title,
            [Key.Body] = note.Body,
            [Key.ModifiedAt] = Seconds(note.ModifiedAt)
        };
        // Only an easel says so, so a note reads the same on a build before easels.
        if (note.IsEasel) value[Key.Easel] = true;
        return value;
    }

    #endregion
}
