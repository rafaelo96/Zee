import SwiftUI

extension View {
    /// Adds Zee chrome to a `TextField` or `SecureField` while preserving the
    /// native field, keyboard, cursor, selection, autofill, submit behavior,
    /// and accessibility role.
    func zeeTextField() -> some View {
        textFieldStyle(.plain)
            .modifier(ZeeFieldSurface())
    }

    /// Applies the field surface to a field-like row, such as a glyph beside a
    /// plain field, whose field's focus the caller tracks.
    func zeeFieldSurface(isFocused: Bool) -> some View {
        modifier(ZeeFieldSurface(rowFocus: isFocused))
    }

    /// Tells the fields under this view which surface they sit on.
    func zeeFieldSurfaceRole(_ role: ZeeFieldSurfaceRole) -> some View {
        environment(\.zeeFieldSurfaceRole, role)
    }
}
