import SwiftUI

/// A term in Zee's heraldic vocabulary, whose name the core declares with
/// the term, so the catalog extracts it from the generated contracts.
protocol BrowserSpaceHeraldicTerm {
    var title: LocalizedStringResource { get }
}

extension SpaceIconStyle: BrowserSpaceHeraldicTerm {}
extension SpaceBannerPattern: BrowserSpaceHeraldicTerm {}
extension SpaceTextColorMode: BrowserSpaceHeraldicTerm {}
extension SpaceThemeMode: BrowserSpaceHeraldicTerm {}
extension BadgeBackplate: BrowserSpaceHeraldicTerm {}
extension BadgeChargeKind: BrowserSpaceHeraldicTerm {}
extension BadgeChargeLayout: BrowserSpaceHeraldicTerm {}
extension BadgeChargeWeight: BrowserSpaceHeraldicTerm {}
extension BadgeDepth: BrowserSpaceHeraldicTerm {}
extension BadgeFieldDivision: BrowserSpaceHeraldicTerm {}
extension BadgeFinish: BrowserSpaceHeraldicTerm {}
extension BadgeMonogramStyle: BrowserSpaceHeraldicTerm {}
extension BadgeOrdinary: BrowserSpaceHeraldicTerm {}
extension BadgeSymbol: BrowserSpaceHeraldicTerm {}
extension BadgeTrim: BrowserSpaceHeraldicTerm {}
