using System.Text;

namespace ZeeCore.Contracts;

#region Types

/// A note names one the Space does not hold.
public sealed record UnknownNote(Guid NoteId) : Rejection;

/// A note holds more than a note keeps, or a Space's notes together hold
/// more than a Space keeps of them.
public sealed record NoteTooLarge(int MaximumBytes, int MaximumSpaceBytes) : Rejection;

/// A Space holds as many notes as it keeps.
public sealed record NotesFull(int Maximum) : Rejection;

#endregion

/// A person's note, written in a tab of the Space it belongs to: its title and
/// its text. A note travels with the Space's settings, as Boosts do, so it
/// syncs, exports and goes with the Space. A tab shows it as the native view
/// `NativeView.Note`, naming it by its identity as the view's resource.
///
/// An easel, `IsEasel`, is a note whose text is the document of a free canvas
/// the platform draws, which a tab shows as `NativeView.Easel`; the core keeps
/// it, syncs it and holds it to a note's limits as it does any note's text.
public sealed record Note(Guid Id, string Title, string Body, DateTimeOffset ModifiedAt, bool IsEasel = false) {
    #region Static Variables

    /// The longest title a note keeps.
    public const int MaximumTitleLength = 200;
    /// The most bytes a note's text holds.
    public const int MaximumBodyBytes = 64 * 1024;
    /// The most bytes a Space's notes hold together, so the Space's synced
    /// record stays well within what one record carries.
    public const int MaximumSpaceBytes = 384 * 1024;
    /// The most notes a Space holds.
    public const int MaximumPerSpace = 100;

    #endregion

    #region Variables

    /// The bytes the note's title and text take.
    internal int Bytes => Encoding.UTF8.GetByteCount(Title) + Encoding.UTF8.GetByteCount(Body);

    #endregion

    #region Initializers

    /// An empty note, or an empty easel, made now.
    public static Note Empty(Guid id, DateTimeOffset now, bool isEasel = false) => new(id, "", "", now, isEasel);

    #endregion

    #region Actions - Validation

    /// The note as a Space keeps it: its title on one line, trimmed and no
    /// longer than a title keeps. Refused with `NoteTooLarge` for text past
    /// what a note holds.
    public Note Validated() {
        var title = string.Join(' ', Title.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)).Trim();
        if (title.Length > MaximumTitleLength) title = title[..MaximumTitleLength];
        if (Encoding.UTF8.GetByteCount(Body) > MaximumBodyBytes)
            throw new Rejected(new NoteTooLarge(MaximumBodyBytes, MaximumSpaceBytes));
        return this with { Title = title };
    }

    /// The name a tab showing the note wears: its title, or its text's first
    /// line when it has none, or nothing for an empty note, which the tab
    /// then names by the view's own title. An easel is named by its title
    /// alone.
    internal string? TabTitle {
        get {
            if (!string.IsNullOrWhiteSpace(Title)) return Title;
            // An easel's text is its canvas, which names nothing.
            if (IsEasel) return null;
            var line = Body.Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(text => text.Trim().TrimStart('#', '-', '*', ' '))
                .FirstOrDefault(text => text.Length > 0);
            return line is null ? null : line.Length > MaximumTitleLength ? line[..MaximumTitleLength] : line;
        }
    }

    #endregion
}
