// Adapted from Mori (MIT), commit b5b29c2e29061f9b2009e8cc0b2756c6ad62bb20.
// Copyright (c) 2026 Mori contributors. See ZeeEngines/Chromium/ThirdParty/Mori-LICENSE.
// Zee BrowserWindow: mostly inert (SwiftUI owns the chrome); window-level
// queries answer against the assigned native Zee NSWindow.

#include "chrome/browser/ui/zee/zee_browser_window.h"
#include <type_traits>
static_assert(!std::is_abstract_v<ZeeBrowserWindow>);

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "ZeeChromiumHost.h"

#include "base/functional/bind.h"
#include "base/location.h"
#include "base/strings/sys_string_conversions.h"
#include "chrome/browser/share/share_attempt.h"
#include "chrome/browser/ui/browser.h"
#include "chrome/browser/ui/autofill/autofill_bubble_handler.h"
#include "chrome/browser/ui/autofill/save_address_bubble_controller.h"
#include "chrome/browser/ui/autofill/update_address_bubble_controller.h"
#include "chrome/browser/ui/zee/zee_chrome_hooks.h"
#include "chrome/browser/ui/tabs/tab_strip_model.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/browser/ui/exclusive_access/exclusive_access_bubble.h"
#include "chrome/browser/ui/exclusive_access/exclusive_access_bubble_type.h"
#include "chrome/browser/ui/exclusive_access/exclusive_access_manager.h"
#include "chrome/browser/ui/exclusive_access/fullscreen_controller.h"
#include "chrome/browser/ui/browser_window/public/browser_window_features.h"
#include "chrome/browser/ui/unload_controller.h"
#include "chrome/browser/ui/views/bubble_anchor_util_views.h"
#include "components/input/native_web_keyboard_event.h"
#include "components/sharing_message/sharing_dialog_data.h"
#include "components/web_modal/modal_dialog_host.h"
#include "content/public/browser/keyboard_event_processing_result.h"
#include "ui/base/mojom/window_show_state.mojom.h"
#include "ui/gfx/range/range.h"
#include "ui/gfx/mac/coordinate_conversion.h"
#include "chrome/browser/themes/theme_service.h"
#include "ui/native_theme/native_theme.h"
#include "ui/color/color_provider_manager.h"


namespace {

// How long after a page leaves the fullscreen window it showed alone in the
// window keeps its fullscreen against a held Escape: longer than Chromium waits
// for a held Escape before it ends the browser's fullscreen.
constexpr base::TimeDelta kPageEscapeHoldGuard = base::Milliseconds(2000);

// Zee's chrome shortcuts (⌘S toggle sidebar, ⌘T toggle omnibox, …) belong to
// the SwiftUI registry. Claim them here — in the browser's keyboard pre-handler
// — so they win *before* the focused web page or Chromium's own commands
// (Save Page As on ⌘S, New Tab on ⌘T) can act. This is what makes the
// shortcuts fire reliably while web content has focus, instead of racing the
// app-level NSEvent monitor and Chromium's native accelerators (the
// intermittent "needs two presses" behavior).
bool HandleZeeShortcut(const input::NativeWebKeyboardEvent& event) {
  // Only fire on the raw key-down; ignore synthesized char and key-up events.
  if (event.GetType() != input::NativeWebKeyboardEvent::Type::kRawKeyDown) {
    return false;
  }
  NSEvent* ns_event = event.os_event.Get();
  if (!ns_event || ns_event.type != NSEventTypeKeyDown) {
    return false;
  }
  return [badge::MacUI() handleShortcutEvent:ns_event] == YES;
}

NSString* OriginDisclosureLabel(const url::Origin& origin) {
  const std::string serialized_origin = origin.Serialize();
  if (serialized_origin.empty() || serialized_origin == "null") {
    return @"Zee Browser";
  }
  return base::SysUTF8ToNSString(serialized_origin);
}

void ConfigureDisclosureLabel(NSTextField* label,
                              NSFont* font,
                              NSColor* color) {
  label.font = font;
  label.textColor = color;
  label.backgroundColor = NSColor.clearColor;
  label.bordered = NO;
  label.editable = NO;
  label.selectable = NO;
  label.lineBreakMode = NSLineBreakByTruncatingMiddle;
}

class ZeeAutofillBubbleHandler final : public autofill::AutofillBubbleHandler {
 public:
  ZeeAutofillBubbleHandler() = default;
  ~ZeeAutofillBubbleHandler() override = default;

  autofill::AutofillBubbleBase* ShowSaveCreditCardBubble(
      content::WebContents* web_contents,
      autofill::SaveCardBubbleController* controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowIbanBubble(
      content::WebContents* web_contents,
      autofill::IbanBubbleController* controller,
      bool is_user_gesture,
      autofill::IbanBubbleType bubble_type) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowOfferNotificationBubble(
      content::WebContents* web_contents,
      autofill::OfferNotificationBubbleController* controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeatureAutofillOffers);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowSaveAutofillAiDataBubble(
      content::WebContents* web_contents,
      autofill::AutofillAiImportDataController* controller) override {
    Unavailable(ZeeUnavailableFeatureAutofillAI);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowAutofillAiLocalSaveNotification(
      content::WebContents* web_contents,
      autofill::AutofillAiImportDataController* controller) override {
    Unavailable(ZeeUnavailableFeatureAutofillAI);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowSaveAddressProfileBubble(
      content::WebContents* web_contents,
      std::unique_ptr<autofill::SaveAddressBubbleController> controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeatureAddressAutofill);
    return nullptr;
  }

#if BUILDFLAG(ENABLE_DICE_SUPPORT)
  autofill::AutofillBubbleBase* ShowAddressSignInPromo(
      content::WebContents* web_contents,
      const autofill::AutofillProfile& autofill_profile) override {
    Unavailable(ZeeUnavailableFeatureAddressAutofillSignIn);
    return nullptr;
  }
#endif

  autofill::AutofillBubbleBase* ShowUpdateAddressProfileBubble(
      content::WebContents* web_contents,
      std::unique_ptr<autofill::UpdateAddressBubbleController> controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeatureAddressAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowFilledCardInformationBubble(
      content::WebContents* web_contents,
      autofill::FilledCardInformationBubbleController* controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowVirtualCardEnrollBubble(
      content::WebContents* web_contents,
      autofill::VirtualCardEnrollBubbleController* controller,
      bool is_user_gesture) override {
    Unavailable(ZeeUnavailableFeatureVirtualCardEnrollment);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowVirtualCardEnrollConfirmationBubble(
      content::WebContents* web_contents,
      autofill::VirtualCardEnrollBubbleController* controller) override {
    Unavailable(ZeeUnavailableFeatureVirtualCardEnrollment);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowMandatoryReauthBubble(
      content::WebContents* web_contents,
      autofill::MandatoryReauthBubbleController* controller,
      bool is_user_gesture,
      autofill::MandatoryReauthBubbleType bubble_type) override {
    Unavailable(ZeeUnavailableFeatureAutofillReauthentication);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowSaveCardConfirmationBubble(
      content::WebContents* web_contents,
      autofill::SaveCardBubbleController* controller) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowSaveIbanConfirmationBubble(
      content::WebContents* web_contents,
      autofill::IbanBubbleController* controller) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowOmniboxAutofillBubble(
      content::WebContents*, autofill::OmniboxAutofillBubbleController*) override {
    Unavailable(ZeeUnavailableFeatureAutofill);
    return nullptr;
  }
  autofill::AutofillBubbleBase* ShowPaymentsChurnedUsersBubble(
      content::WebContents*, autofill::PaymentsChurnedUsersBubbleController*, bool) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowPaymentsChurnedUsersConfirmationBubble(
      content::WebContents*, autofill::PaymentsChurnedUsersBubbleController*) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }

  autofill::AutofillBubbleBase* ShowWalletReminderNoticeBubble(
      content::WebContents*, autofill::WalletReminderNoticeBubbleController*, bool) override {
    Unavailable(ZeeUnavailableFeaturePaymentAutofill);
    return nullptr;
  }
 private:
  static void Unavailable(ZeeUnavailableFeature feature) {
    [badge::MacUI() showUnavailableFeature:feature];
  }
};

}  // namespace

ZeeBrowserWindow::ZeeBrowserWindow(Browser* browser)
    : browser_(browser),
      modal_dialog_host_(browser),
      exclusive_access_context_(browser),
      location_bar_(browser) {
  badge::OnBrowserWindowCreated(browser);
}

// --- ZeeFindBar --------------------------------------------------------------

FindBarController* ZeeFindBar::GetFindBarController() const {
  return controller_;
}

void ZeeFindBar::SetFindBarController(FindBarController* find_bar_controller) { controller_ = find_bar_controller; }

void ZeeFindBar::Show(bool animate, bool focus) {}

void ZeeFindBar::Hide(bool animate) {}

void ZeeFindBar::SetFocusAndSelection() {}

void ZeeFindBar::ClearResults( const find_in_page::FindNotificationDetails& results) {}

void ZeeFindBar::StopAnimation() {}

void ZeeFindBar::MoveWindowIfNecessary() {}

void ZeeFindBar::SetFindTextAndSelectedRange( const std::u16string& find_text, const gfx::Range& selected_range) {}

std::u16string_view ZeeFindBar::GetFindText() const {
  return {};
}

gfx::Range ZeeFindBar::GetSelectedRange() const {
  return {};
}

void ZeeFindBar::UpdateUIForFindResult( const find_in_page::FindNotificationDetails& result, const std::u16string& find_text) {}

void ZeeFindBar::AudibleAlert() {}

bool ZeeFindBar::IsFindBarVisible() const {
  return false;
}

void ZeeFindBar::RestoreSavedFocus() {}

bool ZeeFindBar::HasGlobalFindPasteboard() const {
  return false;
}

void ZeeFindBar::UpdateFindBarForChangedWebContents() {}

bool ZeeFindBar::CanPopulateFromSelectedText() {
  return false;
}

const FindBarTesting* ZeeFindBar::GetFindBarTesting() const {
  return nullptr;
}

bool ZeeFindBar::HasFocus() const {
  return false;
}

void ZeeFindBar::CloseOverlappingBubbles() {}

views::Widget* ZeeFindBar::GetHostWidget() {
  return nullptr;
}

// --- ZeeLocationBar ---------------------------------------------------------

void ZeeLocationBar::FocusLocation(bool is_user_initiated, bool clear_focus_if_failed) {}

void ZeeLocationBar::FocusSearch() {}

// Chromium announces omnibox changes through its own location bar, which Zee
// never shows; Zee's address field speaks for itself.
void ZeeLocationBar::AnnounceAlert(const std::u16string& announcement) {}

void ZeeLocationBar::UpdateFocusBehavior(bool toolbar_visible) {}

void ZeeLocationBar::UpdateContentSettingsIcons() {
  // Chromium reports a page's site state here — a blocked pop-up among it.
  // Zee draws that state in its own Site Controls.
  badge::UpdateSiteIndicators(browser_->tab_strip_model()->GetActiveWebContents());
}

void ZeeLocationBar::SaveStateToContents(content::WebContents* contents) {}

void ZeeLocationBar::Revert() {}

OmniboxView* ZeeLocationBar::GetOmniboxView() {
  return nullptr;
}

OmniboxPopupView* ZeeLocationBar::GetOmniboxPopupView() {
  return nullptr;
}

OmniboxController* ZeeLocationBar::GetOmniboxController() {
  return nullptr;
}

bool ZeeLocationBar::ShouldCloseOmniboxPopup(ui::MouseEvent* event) {
  return false;
}

content::WebContents* ZeeLocationBar::GetWebContents() {
  return nullptr;
}

LocationBarModel* ZeeLocationBar::GetLocationBarModel() {
  return nullptr;
}

std::optional<bubble_anchor_util::AnchorConfiguration> ZeeLocationBar::GetChipAnchor() {
  return {};
}

ChipController* ZeeLocationBar::GetChipController() {
  return nullptr;
}

void ZeeLocationBar::OnChanged() {}

void ZeeLocationBar::UpdateWithoutTabRestore() {}

ui::TrackedElement* ZeeLocationBar::GetAnchorOrNull() {
  return nullptr;
}

Browser* ZeeLocationBar::GetBrowser() {
  return browser_;
}

Profile* ZeeLocationBar::GetProfile() {
  return browser_ ? browser_->GetProfile() : nullptr;
}

bool ZeeLocationBar::IsInitialized() const {
  return false;
}

bool ZeeLocationBar::IsVisible() const {
  return false;
}

bool ZeeLocationBar::IsDrawn() const {
  return false;
}

bool ZeeLocationBar::IsFullscreen() const {
  return false;
}

bool ZeeLocationBar::IsEditingOrEmpty() const {
  return false;
}

void ZeeLocationBar::InvalidateLayout() {}

gfx::Rect ZeeLocationBar::Bounds() const {
  return {};
}

gfx::Rect ZeeLocationBar::BoundsInScreen() const {
  return {};
}

gfx::Size ZeeLocationBar::MinimumSize() const {
  return {};
}

gfx::Size ZeeLocationBar::PreferredSize() const {
  return {};
}

void ZeeLocationBar::Update(content::WebContents* contents) {}

void ZeeLocationBar::ResetTabState(content::WebContents* contents) {}

bool ZeeLocationBar::HasSecurityStateChanged() {
  return false;
}

LocationBarTesting* ZeeLocationBar::GetLocationBarForTesting() {
  return nullptr;
}

// --- ZeeExclusiveAccessContext ---------------------------------------------

ZeeExclusiveAccessContext::ZeeExclusiveAccessContext(Browser* browser)
    : browser_(browser) {
  // A Zee window holds a Browser for each profile it shows, and each hears
  // the window it answers for.
  NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
  NSMutableArray* observers = [NSMutableArray array];
  for (NSNotificationName name in @[ NSWindowDidEnterFullScreenNotification,
                                      NSWindowDidExitFullScreenNotification ]) {
    const bool entered = [name isEqualToString:NSWindowDidEnterFullScreenNotification];
    [observers addObject:[center addObserverForName:name
                                              object:nil
                                               queue:nil
                                          usingBlock:^(NSNotification* notification) {
                                            if (notification.object == badge::WindowForBrowser(browser_)) {
                                              WindowFullscreenChanged(entered);
                                            }
                                          }]];
  }
  window_fullscreen_observers_ = (__bridge_retained void*)observers;
}

ZeeExclusiveAccessContext::~ZeeExclusiveAccessContext() {
  NSArray* observers = (__bridge_transfer NSArray*)window_fullscreen_observers_;
  window_fullscreen_observers_ = nullptr;
  for (id observer in observers) {
    [NSNotificationCenter.defaultCenter removeObserver:observer];
  }
  HideFullscreenDisclosure(ExclusiveAccessBubbleHideReason::kInterrupted);
}

Profile* ZeeExclusiveAccessContext::GetProfile() {
  return browser_->GetProfile();
}

bool ZeeExclusiveAccessContext::IsFullscreen() const {
  NSWindow* window = badge::WindowForBrowser(browser_);
  return window && (window.styleMask & NSWindowStyleMaskFullScreen);
}

void ZeeExclusiveAccessContext::EnterFullscreen(
    const url::Origin& origin,
    ExclusiveAccessBubbleType bubble_type,
    FullscreenTabParams fullscreen_tab_params) {
  // Only a page's own request shows the page alone. The browser's or an
  // extension's fullscreen keeps Zee's chrome around the page.
  content::WebContents* contents = GetWebContentsForExclusiveAccess();
  if (contents && !exclusive_access_bubble::IsExclusiveAccessModeBrowserFullscreen(bubble_type)) {
    content_fullscreen_ = contents->GetWeakPtr();
    badge::ReportContentFullscreen(contents, true);
  }
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (window && !(window.styleMask & NSWindowStyleMaskFullScreen)) {
    // The disclosure shows once the window is fullscreen, where it belongs.
    [window toggleFullScreen:nil];
    return;
  }
  UpdateExclusiveAccessBubble({.origin = origin, .type = bubble_type}, {});
}

void ZeeExclusiveAccessContext::ExitFullscreen() {
  EndContentFullscreen();
  HideFullscreenDisclosure(ExclusiveAccessBubbleHideReason::kInterrupted);
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (window && (window.styleMask & NSWindowStyleMaskFullScreen)) {
    [window toggleFullScreen:nil];
  }
}

void ZeeExclusiveAccessContext::WindowFullscreenChanged(bool entered) {
  // Chromium's own windows report every transition, as the fullscreen
  // controller expects: entering shows its disclosure, and leaving ends the
  // page's fullscreen however the window left.
  ExclusiveAccessManager::From(browser_)
      ->fullscreen_controller()
      ->WindowFullscreenStateChanged();
  if (!entered) {
    EndContentFullscreen();
  }
}

void ZeeExclusiveAccessContext::UpdateUIForTabFullscreen() {
  // A page's fullscreen in a window that is already fullscreen neither enters
  // nor leaves the window's fullscreen: Chromium only updates the window's UI,
  // as its own windows hide their toolbar. The page shows alone while it holds
  // the window's exclusive access, and goes back among Zee's chrome when it
  // lets go, leaving the window fullscreen as it was.
  content::WebContents* contents = GetWebContentsForExclusiveAccess();
  FullscreenController* controller =
      ExclusiveAccessManager::From(browser_)->fullscreen_controller();
  if (contents && controller->exclusive_access_tab() == contents) {
    content_fullscreen_ = contents->GetWeakPtr();
    badge::ReportContentFullscreen(contents, true);
    return;
  }
  if (content_fullscreen_) {
    page_left_fullscreen_window_ = base::TimeTicks::Now();
  }
  EndContentFullscreen();
}

void ZeeExclusiveAccessContext::EndContentFullscreen() {
  content::WebContents* contents = content_fullscreen_.get();
  content_fullscreen_.reset();
  if (contents) {
    badge::ReportContentFullscreen(contents, false);
  }
}

void ZeeExclusiveAccessContext::UpdateExclusiveAccessBubble(
    const ExclusiveAccessBubbleParams& params,
    ExclusiveAccessBubbleHideCallback first_hide_callback) {
  // Zee discloses a page's fullscreen. The browser's or an extension's keeps
  // Zee's chrome and needs no instruction.
  const bool should_close_bubble =
      (!params.has_download &&
       params.type == EXCLUSIVE_ACCESS_BUBBLE_TYPE_NONE) ||
      exclusive_access_bubble::IsExclusiveAccessModeBrowserFullscreen(params.type);
  if (should_close_bubble) {
    if (first_hide_callback) {
      std::move(first_hide_callback)
          .Run(ExclusiveAccessBubbleHideReason::kNotShown);
    }
    HideFullscreenDisclosure(ExclusiveAccessBubbleHideReason::kInterrupted);
    return;
  }
  ShowFullscreenDisclosure(params.origin, std::move(first_hide_callback));
}

bool ZeeExclusiveAccessContext::IsExclusiveAccessBubbleDisplayed() const {
  return exclusive_access_bubble_visible_;
}

void ZeeExclusiveAccessContext::OnExclusiveAccessUserInput() {
  NSPanel* panel = (__bridge NSPanel*)fullscreen_disclosure_;
  if (panel) {
    [panel orderFront:nil];
  }
}

content::WebContents* ZeeExclusiveAccessContext::GetWebContentsForExclusiveAccess() {
  return browser_->tab_strip_model()->GetActiveWebContents();
}

bool ZeeExclusiveAccessContext::CanUserEnterFullscreen() const {
  return true;
}

bool ZeeExclusiveAccessContext::CanUserExitFullscreen() const {
  // The Escape that ends a page's fullscreen ends only the page's. Chromium
  // ends the browser's fullscreen when Escape is held, and a page going back
  // among Zee's chrome leaves the window for a moment, so the key's release
  // can reach the window instead of the page, and a tap would read as held.
  return base::TimeTicks::Now() - page_left_fullscreen_window_ > kPageEscapeHoldGuard;
}

void ZeeExclusiveAccessContext::ShowFullscreenDisclosure(
    const url::Origin& origin,
    ExclusiveAccessBubbleHideCallback first_hide_callback) {
  NSWindow* parent = badge::WindowForBrowser(browser_);
  if (!parent) {
    if (first_hide_callback) {
      std::move(first_hide_callback)
          .Run(ExclusiveAccessBubbleHideReason::kNotShown);
    }
    return;
  }

  HideFullscreenDisclosure(ExclusiveAccessBubbleHideReason::kInterrupted);

  const NSRect parent_frame = parent.frame;
  const CGFloat width = std::min<CGFloat>(
      520.0, std::max<CGFloat>(320.0, parent_frame.size.width - 48.0));
  const CGFloat height = 72.0;
  const NSRect frame = NSMakeRect(NSMidX(parent_frame) - width / 2.0,
                                  NSMaxY(parent_frame) - height - 28.0,
                                  width, height);

  NSPanel* panel =
      [[NSPanel alloc] initWithContentRect:frame
                                 styleMask:NSWindowStyleMaskBorderless |
                                           NSWindowStyleMaskNonactivatingPanel
                                   backing:NSBackingStoreBuffered
                                     defer:NO];
  panel.opaque = NO;
  panel.backgroundColor = NSColor.clearColor;
  panel.hasShadow = YES;
  panel.ignoresMouseEvents = YES;
  panel.level = parent.level + 1;
  panel.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary |
                             NSWindowCollectionBehaviorCanJoinAllSpaces |
                             NSWindowCollectionBehaviorTransient;

  NSView* container =
      [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
  container.wantsLayer = YES;
  container.layer.cornerRadius = 14.0;
  container.layer.masksToBounds = YES;
  container.layer.backgroundColor =
      [[NSColor colorWithCalibratedWhite:0.06 alpha:0.86] CGColor];

  NSTextField* title = [NSTextField labelWithString:@"Full screen"];
  title.frame = NSMakeRect(20.0, 45.0, width - 40.0, 18.0);
  ConfigureDisclosureLabel(
      title, [NSFont systemFontOfSize:13.0 weight:NSFontWeightSemibold],
      NSColor.whiteColor);

  NSTextField* origin_label =
      [NSTextField labelWithString:OriginDisclosureLabel(origin)];
  origin_label.frame = NSMakeRect(20.0, 26.0, width - 40.0, 16.0);
  ConfigureDisclosureLabel(origin_label,
                           [NSFont systemFontOfSize:12.0
                                             weight:NSFontWeightRegular],
                           [NSColor colorWithCalibratedWhite:1.0 alpha:0.78]);

  NSTextField* instruction =
      [NSTextField labelWithString:@"Press Esc to exit full screen"];
  instruction.frame = NSMakeRect(20.0, 10.0, width - 40.0, 15.0);
  ConfigureDisclosureLabel(instruction,
                           [NSFont systemFontOfSize:11.0
                                             weight:NSFontWeightRegular],
                           [NSColor colorWithCalibratedWhite:1.0 alpha:0.58]);

  [container addSubview:title];
  [container addSubview:origin_label];
  [container addSubview:instruction];
  panel.contentView = container;

  [parent addChildWindow:panel ordered:NSWindowAbove];
  [panel orderFront:nil];

  fullscreen_disclosure_ = (__bridge_retained void*)panel;
  fullscreen_disclosure_hide_callback_ = std::move(first_hide_callback);
  exclusive_access_bubble_visible_ = true;
  fullscreen_disclosure_timer_.Start(
      FROM_HERE, ExclusiveAccessBubble::kShowTime,
      base::BindOnce(&ZeeExclusiveAccessContext::HideFullscreenDisclosure,
                     base::Unretained(this),
                     ExclusiveAccessBubbleHideReason::kTimeout));
}

void ZeeExclusiveAccessContext::HideFullscreenDisclosure(
    ExclusiveAccessBubbleHideReason reason) {
  fullscreen_disclosure_timer_.Stop();
  NSPanel* panel = (__bridge_transfer NSPanel*)fullscreen_disclosure_;
  fullscreen_disclosure_ = nullptr;
  exclusive_access_bubble_visible_ = false;

  if (panel) {
    [panel.parentWindow removeChildWindow:panel];
    [panel orderOut:nil];
    [panel close];
  }

  if (fullscreen_disclosure_hide_callback_) {
    std::move(fullscreen_disclosure_hide_callback_).Run(reason);
  }
}

ZeeBrowserWindow::~ZeeBrowserWindow() {
  badge::OnBrowserWindowDestroyed(browser_);
}

// --- ZeeModalDialogHost ----------------------------------------------------

ZeeModalDialogHost::~ZeeModalDialogHost() {
  for (auto& observer : observers_) {
    observer.OnHostDestroying();
  }
}

gfx::NativeView ZeeModalDialogHost::GetHostView() const {
  return gfx::NativeView(badge::WindowForBrowser(browser_).contentView);
}

gfx::Point ZeeModalDialogHost::GetDialogPosition(const gfx::Size& size) {
  NSView* content = badge::WindowForBrowser(browser_).contentView;
  const int width = content ? NSWidth(content.bounds) : 1280;
  return gfx::Point(std::max(0, (width - size.width()) / 2), 64);
}

gfx::Size ZeeModalDialogHost::GetMaximumDialogSize() {
  NSView* content = badge::WindowForBrowser(browser_).contentView;
  if (!content) {
    return gfx::Size(1200, 760);
  }
  return gfx::Size(NSWidth(content.bounds), NSHeight(content.bounds));
}

void ZeeModalDialogHost::AddObserver(
    web_modal::ModalDialogHostObserver* observer) {
  observers_.AddObserver(observer);
}

void ZeeModalDialogHost::RemoveObserver(
    web_modal::ModalDialogHostObserver* observer) {
  observers_.RemoveObserver(observer);
}

bool ZeeBrowserWindow::IsMaximized() const {
  return badge::WindowForBrowser(browser_).isZoomed;
}

bool ZeeBrowserWindow::IsMinimized() const {
  return badge::WindowForBrowser(browser_).isMiniaturized;
}

bool ZeeBrowserWindow::IsFullscreen() const {
  return (badge::WindowForBrowser(browser_).styleMask & NSWindowStyleMaskFullScreen) != 0;
}

// An extension's popup that shows as a tab leaves the person's window alone.
void ZeeBrowserWindow::Hide() {
  if (badge::OwnsWindow(browser_)) [badge::WindowForBrowser(browser_) orderOut:nil];
}

void ZeeBrowserWindow::ShowInactive() {
  badge::OnEngineWindowShown(browser_, false);
  [badge::WindowForBrowser(browser_) orderFront:nil];
}

void ZeeBrowserWindow::Deactivate() {}

void ZeeBrowserWindow::Maximize() {
  if (badge::OwnsWindow(browser_) && !IsMaximized()) [badge::WindowForBrowser(browser_) zoom:nil];
}

void ZeeBrowserWindow::Minimize() {
  if (badge::OwnsWindow(browser_)) [badge::WindowForBrowser(browser_) miniaturize:nil];
}

void ZeeBrowserWindow::Restore() {
  if (!badge::OwnsWindow(browser_)) return;
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (window.isMiniaturized) [window deminiaturize:nil];
  if (window.isZoomed) [window zoom:nil];
}

void ZeeBrowserWindow::FlashFrame(bool flash) {}

ui::ZOrderLevel ZeeBrowserWindow::GetZOrderLevel() const {
  return ui::ZOrderLevel::kNormal;
}

void ZeeBrowserWindow::SetZOrderLevel(ui::ZOrderLevel order) {}

bool ZeeBrowserWindow::IsOnCurrentWorkspace() const {
  return badge::WindowForBrowser(browser_).isOnActiveSpace;
}

bool ZeeBrowserWindow::IsVisibleOnScreen() const {
  return (badge::WindowForBrowser(browser_).occlusionState & NSWindowOcclusionStateVisible) != 0;
}

void ZeeBrowserWindow::SetTopControlsShownRatio(content::WebContents* web_contents, float ratio) {}

bool ZeeBrowserWindow::DoBrowserControlsShrinkRendererSize( const content::WebContents* contents) const {
  return false;
}

ui::NativeTheme* ZeeBrowserWindow::GetNativeTheme() {
  return ui::NativeTheme::GetInstanceForNativeUi();
}

const ui::ThemeProvider* ZeeBrowserWindow::GetThemeProvider() const {
  return &ThemeService::GetThemeProviderForProfile(browser_->GetProfile());
}

const ui::ColorProvider* ZeeBrowserWindow::GetColorProvider() const {
  return ui::ColorProviderManager::Get().GetColorProviderFor(
      ui::NativeTheme::GetInstanceForNativeUi()->GetColorProviderKey(nullptr, false));
}

int ZeeBrowserWindow::GetTopControlsHeight() const {
  return {};
}

void ZeeBrowserWindow::SetTopControlsGestureScrollInProgress(bool in_progress) {}

std::vector<StatusBubble*> ZeeBrowserWindow::GetStatusBubbles() {
  return {};
}

void ZeeBrowserWindow::UpdateTitleBar() {}

void ZeeBrowserWindow::UpdateLoadingAnimations(bool is_visible) {}




void ZeeBrowserWindow::OnActiveTabChanged(content::WebContents* old_contents, content::WebContents* new_contents, int index, int reason) {}

void ZeeBrowserWindow::OnTabDetached(content::WebContents* contents, bool was_active) {}

gfx::Size ZeeBrowserWindow::GetContentsSize() const {
  return {};
}

void ZeeBrowserWindow::SetContentsSize(const gfx::Size& size) {}

autofill::AutofillBubbleHandler* ZeeBrowserWindow::GetAutofillBubbleHandler() {
  static ZeeAutofillBubbleHandler* handler = new ZeeAutofillBubbleHandler();
  return handler;
}

LocationBar* ZeeBrowserWindow::GetLocationBar() const {
  return const_cast<ZeeLocationBar*>(&location_bar_);
}

// Zee's menus are its own, so no Chromium menu asks this window for its
// command shortcuts.
ui::AcceleratorProvider* ZeeBrowserWindow::GetAcceleratorProvider() {
  return nullptr;
}

// Zee's toolbar is its own, so this window pins no Chromium toolbar actions.
PinnedToolbarActions* ZeeBrowserWindow::GetPinnedToolbarActions() {
  return nullptr;
}

void ZeeBrowserWindow::SetFocusToLocationBar(bool is_user_initiated) {
  [badge::MacUI() focusLocation];
}

void ZeeBrowserWindow::UpdateReloadStopState(bool is_loading, bool force) {}

void ZeeBrowserWindow::UpdateToolbar(content::WebContents* contents) {}

bool ZeeBrowserWindow::UpdateToolbarSecurityState() {
  return false;
}

void ZeeBrowserWindow::UpdateCustomTabBarVisibility(bool visible, bool animate) {}

// Chrome dims its contents view while a DevTools-owned modal dialog is up. The
// dialog is presented as a sheet on the Zee window, which draws its own
// dimming, so there is no separate scrim to show or hide.

void ZeeBrowserWindow::ResetToolbarTabState(content::WebContents* contents) {}

void ZeeBrowserWindow::FocusToolbar() {}

void ZeeBrowserWindow::ToolbarSizeChanged(bool is_animating) {}

void ZeeBrowserWindow::TabDraggingStatusChanged(bool is_dragging) {}

void ZeeBrowserWindow::LinkOpeningFromGesture(WindowOpenDisposition disposition) {}

void ZeeBrowserWindow::FocusAppMenu() {}

bool ZeeBrowserWindow::IsTabStripEditable() const {
  return true;
}

void ZeeBrowserWindow::DisableTabStripEditingForTesting() {}

bool ZeeBrowserWindow::IsToolbarVisible() const {
  return false;
}

bool ZeeBrowserWindow::IsToolbarShowing() const {
  return false;
}

bool ZeeBrowserWindow::IsLocationBarVisible() const {
  return false;
}

void ZeeBrowserWindow::ShowUpdateChromeDialog() {}

void ZeeBrowserWindow::ShowIntentPickerBubble( std::vector<apps::IntentPickerAppInfo> app_info, bool show_stay_in_chrome, bool show_remember_selection, apps::IntentPickerBubbleType bubble_type, const std::optional<url::Origin>& initiating_origin, IntentPickerResponse callback) {
  if (app_info.empty()) {
    std::move(callback).Run(std::string(), apps::PickerEntryType::kUnknown,
                            apps::IntentPickerCloseReason::STAY_IN_CHROME,
                            false);
    return;
  }

  NSAlert* alert = [[NSAlert alloc] init];
  alert.messageText = @"Open this link in another app?";
  alert.informativeText = @"Choose an app or keep browsing in Zee.";
  alert.alertStyle = NSAlertStyleInformational;
  for (const auto& app : app_info) {
    [alert addButtonWithTitle:base::SysUTF8ToNSString(app.display_name)];
  }
  [alert addButtonWithTitle:@"Stay in Zee"];

  NSModalResponse response = [alert runModal];
  NSInteger selected = response - NSAlertFirstButtonReturn;
  if (selected >= 0 && selected < static_cast<NSInteger>(app_info.size())) {
    const auto& app = app_info[static_cast<size_t>(selected)];
    std::move(callback).Run(app.launch_name, app.type,
                            apps::IntentPickerCloseReason::OPEN_APP,
                            false);
    return;
  }
  std::move(callback).Run(std::string(), apps::PickerEntryType::kUnknown,
                          apps::IntentPickerCloseReason::STAY_IN_CHROME,
                          false);
}

// Zee keeps a page by pinning its tab, so bookmarking is that.
void ZeeBrowserWindow::ShowBookmarkBubble(const GURL& url, bool already_bookmarked) {
  [badge::MacUI() bookmarkActivePage];
}

ShowTranslateBubbleResult ZeeBrowserWindow::ShowTranslateBubble( content::WebContents* contents, translate::TranslateStep step, const std::string& source_language, const std::string& target_language, translate::TranslateErrors error_type, bool is_user_gesture) {
  if (contents) {
    [badge::MacUI() translatePage];
  }
  return {};
}

DownloadBubbleUIController* ZeeBrowserWindow::GetDownloadBubbleUIController() {
  return nullptr;
}

void ZeeBrowserWindow::ConfirmBrowserCloseWithPendingDownloads( int download_count, DownloadCloseType dialog_type, base::OnceCallback<void(bool)> callback) {
  NSAlert* alert = [[NSAlert alloc] init];
  alert.messageText = download_count == 1
                          ? @"A download is still in progress."
                          : [NSString stringWithFormat:@"%d downloads are still in progress.",
                                                       download_count];
  alert.informativeText = @"Closing Zee now will cancel unfinished downloads.";
  alert.alertStyle = NSAlertStyleWarning;
  [alert addButtonWithTitle:@"Close Anyway"];
  [alert addButtonWithTitle:@"Keep Browsing"];
  NSModalResponse response = [alert runModal];
  std::move(callback).Run(response == NSAlertFirstButtonReturn);
}

void ZeeBrowserWindow::ShowAppMenu() {
  NSMenu* appMenu = [[NSApp.mainMenu itemAtIndex:0] submenu];
  if (!appMenu) {
    return;
  }
  NSWindow* window = badge::WindowForBrowser(browser_);
  NSPoint point = window ? NSMakePoint(NSMidX(window.frame), NSMaxY(window.frame) - 40)
                         : NSMakePoint(24, 24);
  [appMenu popUpMenuPositioningItem:nil atLocation:point inView:nil];
}

void ZeeBrowserWindow::PreHandleDragUpdate(const content::DropData& drop_data, const gfx::PointF& point) {}

void ZeeBrowserWindow::PreHandleDragExit() {}

void ZeeBrowserWindow::HandleDragEnded() {}

content::KeyboardEventProcessingResult ZeeBrowserWindow::PreHandleKeyboardEvent( const input::NativeWebKeyboardEvent& event) {
  if (HandleZeeShortcut(event)) {
    return content::KeyboardEventProcessingResult::HANDLED;
  }
  return content::KeyboardEventProcessingResult::NOT_HANDLED;
}

bool ZeeBrowserWindow::HandleKeyboardEvent( const input::NativeWebKeyboardEvent& event) {
  // Chromium offers shortcuts to the document first. Its Views window would
  // then dispatch unhandled equivalents to AppKit; Zee owns that last step.
  NSEvent* native_event = event.os_event.Get();
  if (event.GetType() != input::NativeWebKeyboardEvent::Type::kRawKeyDown ||
      !native_event || native_event.type != NSEventTypeKeyDown ||
      !badge::WindowForBrowser(browser_).isKeyWindow) return false;
  return [NSApp.mainMenu performKeyEquivalent:native_event];
}

std::unique_ptr<FindBar> ZeeBrowserWindow::CreateFindBar() {
  return std::make_unique<ZeeFindBar>();
}

web_modal::WebContentsModalDialogHost*
ZeeBrowserWindow::GetWebContentsModalDialogHost() {
  return &modal_dialog_host_;
}

web_modal::WebContentsModalDialogHost*
ZeeBrowserWindow::GetWebContentsModalDialogHostFor(
    content::WebContents* web_contents) {
  return &modal_dialog_host_;
}

void ZeeBrowserWindow::ShowAvatarBubbleFromAvatarButton(bool is_source_accelerator) {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeatureProfiles];
}

void ZeeBrowserWindow::ShowHatsDialog( const std::string& site_id, const std::optional<std::string>& hats_histogram_name, const std::optional<uint64_t> hats_survey_ukm_id, base::OnceClosure success_callback, base::OnceClosure failure_callback, const SurveyBitsData& product_specific_bits_data, const SurveyStringData& product_specific_string_data) {}

ExclusiveAccessContext* ZeeBrowserWindow::GetExclusiveAccessContext() {
  return &exclusive_access_context_;
}

std::string ZeeBrowserWindow::GetWorkspace() const {
  return {};
}

bool ZeeBrowserWindow::IsVisibleOnAllWorkspaces() const {
  return false;
}

void ZeeBrowserWindow::ShowEmojiPanel() {
  [NSApp orderFrontCharacterPalette:nil];
}

std::unique_ptr<content::EyeDropper> ZeeBrowserWindow::OpenEyeDropper( content::RenderFrameHost* frame, content::EyeDropperListener* listener) {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeatureEyeDropper];
  return {};
}

void ZeeBrowserWindow::ShowCaretBrowsingDialog() {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeatureCaretBrowsing];
}

void ZeeBrowserWindow::CreateTabSearchBubble() {
  [badge::MacUI() showTabSearch];
}

void ZeeBrowserWindow::CloseTabSearchBubble() {}

void ZeeBrowserWindow::ShowIncognitoClearBrowsingDataDialog() {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeaturePrivateBrowsing];
}

void ZeeBrowserWindow::ShowIncognitoHistoryDisclaimerDialog() {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeaturePrivateBrowsing];
}

bool ZeeBrowserWindow::IsUnframedModeEnabled() const {
  return false;
}

bool ZeeBrowserWindow::GetCanResize() {
  return (badge::WindowForBrowser(browser_).styleMask & NSWindowStyleMaskResizable) != 0;
}

ui::mojom::WindowShowState ZeeBrowserWindow::GetWindowShowState() const {
  if (IsFullscreen()) return ui::mojom::WindowShowState::kFullscreen;
  if (IsMinimized()) return ui::mojom::WindowShowState::kMinimized;
  if (IsMaximized()) return ui::mojom::WindowShowState::kMaximized;
  return ui::mojom::WindowShowState::kNormal;
}

void ZeeBrowserWindow::ShowChromeLabs() {
  [badge::MacUI() showUnavailableFeature:ZeeUnavailableFeatureChromeLabs];
}

BrowserView* ZeeBrowserWindow::AsBrowserView() {
  return nullptr;
}

void ZeeBrowserWindow::DeleteBrowserWindow() {
  delete this;
}

// --- Real implementations against the assigned native Zee window -------------------

void ZeeBrowserWindow::Show() {
  badge::EnsureZeeUIStarted(browser_);
  badge::OnEngineWindowShown(browser_, true);
}

void ZeeBrowserWindow::Close() {
  // The BrowserView/WebUIBrowserWindow close protocol, minus the OS window:
  // beforeunload gets a veto, then tabs close, and TabStripEmpty() re-enters
  // Close() for the empty Browser, which schedules its own deletion. It is
  // never deleted here: the unload and tab strip code that emptied it is
  // still on the stack, as it is when a page's unload finishes the close
  // `chrome.windows.remove` started.
  UnloadController::From(browser_)->OnWindowClosing();
}

bool ZeeBrowserWindow::IsActive() const {
  return badge::WindowForBrowser(browser_).isKeyWindow;
}

void ZeeBrowserWindow::Activate() {
  // Chromium brings a page forward by making it the Browser's active tab and
  // then asking for its window, as a Picture in Picture window's return
  // control does. Zee shows that page's own window, Space and tab instead.
  if (badge::ReturnFromPictureInPicture(browser_->tab_strip_model()->GetActiveWebContents())) {
    return;
  }
  [badge::WindowForBrowser(browser_) makeKeyAndOrderFront:nil];
}

gfx::NativeWindow ZeeBrowserWindow::GetNativeWindow() const {
  return gfx::NativeWindow(badge::WindowForBrowser(browser_));
}

gfx::Rect ZeeBrowserWindow::GetBounds() const {
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (!window) {
    return gfx::Rect(0, 0, 1280, 820);
  }
  return gfx::ScreenRectFromNSRect(window.frame);
}

gfx::Rect ZeeBrowserWindow::GetRestoredBounds() const {
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (!window) return GetBounds();
  return gfx::ScreenRectFromNSRect([badge::MacUI() restoredFrameForWindow:window]);
}

ui::mojom::WindowShowState ZeeBrowserWindow::GetRestoredState() const {
  NSWindow* window = badge::WindowForBrowser(browser_);
  const bool zoomed = IsFullscreen() ? [badge::MacUI() wasWindowZoomedBeforeFullScreen:window] : IsMaximized();
  return zoomed ? ui::mojom::WindowShowState::kMaximized : ui::mojom::WindowShowState::kNormal;
}

bool ZeeBrowserWindow::IsVisible() const {
  return badge::WindowForBrowser(browser_).isVisible;
}

void ZeeBrowserWindow::SetBounds(const gfx::Rect& bounds) {
  NSWindow* window = badge::WindowForBrowser(browser_);
  if (!window || IsFullscreen() || !badge::OwnsWindow(browser_)) return;
  // Chromium and extensions use the primary display's top-left origin, even
  // for windows on other displays. Use the inverse of GetBounds's conversion.
  [window setFrame:gfx::ScreenRectToNSRect(bounds) display:YES];
}

bool ZeeLocationBar::IsMouseHovered() const { return false; }
bool ZeeLocationBar::IsFocusWithin() const {
  NSResponder* responder = badge::WindowForBrowser(browser_).firstResponder;
  return [responder isKindOfClass:NSTextView.class] && ((NSTextView*)responder).isFieldEditor;
}
