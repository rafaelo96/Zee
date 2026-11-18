import SwiftUI

struct BrowserBadgeStudioComposition: View {
    let context: BrowserBadgeStudioContext
    let symbol: String
    private var preview: SpaceBranding? { context.compact ? context.value : nil }

    var body: some View {
        BrowserBadgeStudioGroup(step: .shape, preview: preview, symbol: symbol) {
            gallery("Plate", \.backplate, BadgeBackplate.all)
            if context.value.badge.backplate.hasTeeth {
                context.count("Teeth", \.sealTeeth, range: BadgeMeasure.sealTeeth.countRange)
            }
            context.slider("Edge weight", \.edgeWidth, range: BadgeMeasure.edgeWidth.range)
            BrowserBadgeStudioColorRow(context: context, title: "Edge & outline", path: \.edgeColorIndex)
            context.slider("Plate size", \.plateScale, range: BadgeMeasure.plateScale.range)
        }
        BrowserBadgeStudioGroup(step: .field, preview: preview, symbol: symbol) {
            gallery("Division", \.fieldDivision, BadgeFieldDivision.all)
            BrowserBadgeStudioColorRow(context: context, title: "Field color", path: \.backplateColorIndex)
            if context.value.badge.fieldDivision != .plain {
                BrowserBadgeStudioColorRow(context: context, title: "Second field", path: \.secondaryFieldColorIndex)
            }
            if context.value.badge.fieldDivision.isCounted {
                context.count("Repeats", \.divisionCount, range: BadgeMeasure.divisionCount.countRange)
            }
            context.picker("Finish", \.finish, options: BadgeFinish.all)
            if context.value.badge.finish.hasAngle {
                context.slider(
                    "Sheen angle", \.sheenAngle, range: BadgeMeasure.sheenAngle.range, readout: .init { "\(Int($0))°" })
            }
        }
    }

    private func gallery<Option: Hashable & BrowserSpaceHeraldicTerm>(
        _ title: LocalizedStringKey, _ path: WritableKeyPath<SpaceBadge, Option>, _ options: [Option]
    ) -> some View {
        BrowserBadgeStudioGallery(context: context, title: title, path: path, options: options)
    }
}

struct BrowserBadgeStudioOrnaments: View {
    let context: BrowserBadgeStudioContext
    let symbol: String
    private var preview: SpaceBranding? { context.compact ? context.value : nil }

    var body: some View {
        BrowserBadgeStudioGroup(step: .band, preview: preview, symbol: symbol) {
            BrowserBadgeStudioGallery(
                context: context, title: "Design", path: \.ordinary, options: BadgeOrdinary.all)
            if context.value.badge.ordinary != .none {
                BrowserBadgeStudioColorRow(context: context, title: "Band color", path: \.ordinaryColorIndex)
                context.slider("Width", \.ordinaryWidth, range: BadgeMeasure.ordinaryWidth.range)
            }
        }
        BrowserBadgeStudioGroup(step: .border, preview: preview, symbol: symbol) {
            BrowserBadgeStudioGallery(
                context: context, title: "Design", path: \.trim, options: BadgeTrim.all)
            if context.value.badge.trim != .none {
                BrowserBadgeStudioColorRow(context: context, title: "Border color", path: \.trimColorIndex)
                context.slider("Weight", \.trimWeight, range: BadgeMeasure.trimWeight.range)
            }
            if context.value.badge.trim.isCounted {
                context.count("Details", \.trimDetail, range: BadgeMeasure.trimDetail.countRange)
            }
        }
        BrowserBadgeStudioGroup(title: "Depth", systemImage: "square.3.layers.3d", preview: preview, symbol: symbol) {
            context.picker("Shadow", \.depth, options: BadgeDepth.all)
            let outline = context.badge(\.showsOutline)
            ZeeSettingRow("Outline", setting: outline.resettable("Outline")) {
                Toggle("Outline", isOn: outline.binding).labelsHidden()
            }
            if outline.wrappedValue {
                BrowserBadgeStudioColorRow(context: context, title: "Edge & outline", path: \.edgeColorIndex)
            }
        }
    }
}

#if DEBUG
    #Preview("Interactive badge controls") {
        @Previewable @State var branding = BrowserSpaceBrandingPreviewFixture.badgeBranding
        Form {
            BrowserBadgeStudioComposition(
                context: BrowserBadgeStudioContext(
                    branding: $branding, defaults: BrowserSpaceBrandingPreviewFixture.badgeBranding, compact: false),
                symbol: "crown.fill")
        }.zeeSettingsForm().frame(width: 480, height: 650)
    }
#endif
