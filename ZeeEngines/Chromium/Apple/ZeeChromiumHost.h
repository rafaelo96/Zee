#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// Chromium's event and accessibility integration, attached only when its
// runtime starts. The application and its delegate remain Zee's own.
NS_SWIFT_UI_ACTOR
@protocol ZeeEngineApplicationEvents <NSObject>
- (void)processEvent:(NSEvent *)event forwarding:(void (NS_NOESCAPE ^)(void))forwarding;
- (void)addObserver:(void *)observer NS_SWIFT_NAME(add(observer:));
- (void)removeObserver:(void *)observer NS_SWIFT_NAME(remove(observer:));
- (BOOL)observeKey:(nullable NSString *)key value:(nullable id)value context:(nullable void *)context;
- (void)prepareAccessibility;
- (void)setEnhancedAccessibility:(BOOL)enabled;
- (nullable id)focusedAccessibilityElement;
@end

NS_SWIFT_UI_ACTOR
@protocol ZeeEngineApplicationHosting <NSObject>
- (void)attachApplicationEvents:(id<ZeeEngineApplicationEvents>)events;
@end

// A Chromium feature whose own UI this build never shows. Zee says so in a
// notice instead, in its own words.
typedef NS_ENUM(NSInteger, ZeeUnavailableFeature) {
  ZeeUnavailableFeatureAutofill,
  ZeeUnavailableFeatureAddressAutofill,
  ZeeUnavailableFeatureAddressAutofillSignIn,
  ZeeUnavailableFeatureAutofillAI,
  ZeeUnavailableFeatureAutofillOffers,
  ZeeUnavailableFeatureAutofillReauthentication,
  ZeeUnavailableFeaturePaymentAutofill,
  ZeeUnavailableFeatureVirtualCardEnrollment,
  ZeeUnavailableFeatureProfiles,
  ZeeUnavailableFeatureEyeDropper,
  ZeeUnavailableFeatureCaretBrowsing,
  ZeeUnavailableFeaturePrivateBrowsing,
  ZeeUnavailableFeatureChromeLabs,
} NS_SWIFT_NAME(UnavailableEngineFeature);

// What one of Chromium's own toasts is about. The message is Chromium's own.
typedef NS_ENUM(NSInteger, ZeeEngineNoticeKind) {
  ZeeEngineNoticeKindLinkCopied,
  ZeeEngineNoticeKindConfirmation,
} NS_SWIFT_NAME(EngineNoticeKind);

// The Zee window a Browser the engine created for itself belongs in, and the
// Space its tabs join.
@protocol ZeeEngineWindowPlacement <NSObject>
@property(nonatomic, readonly) NSUUID *window;
@property(nonatomic, readonly) NSUUID *space;
@end

// Where an extension's popup opens: a view in a Zee window, and the rect in
// that view's coordinates the popup hangs from.
@protocol ZeeExtensionPopupAnchor <NSObject>
@property(nonatomic, readonly) NSView *view;
@property(nonatomic, readonly) NSRect rect;
@end

// Zee's own UI, which the Mac shell asks on the main thread for what only
// Zee's windows can answer. The UI framework attaches it when it starts.
NS_SWIFT_UI_ACTOR
@protocol ZeeMacUI <NSObject>
// The Zee window named `windowID`, or with none, the window an engine
// surface with no window of its own is shown in.
- (nullable NSWindow *)windowWithID:(nullable NSUUID *)windowID NS_SWIFT_NAME(window(id:));
// The native shell keeps the frame and state a zoomed or fullscreen window
// returns to. Coordinates stay in AppKit's screen space at this boundary.
- (NSRect)restoredFrameForWindow:(NSWindow *)window NS_SWIFT_NAME(restoredFrame(for:));
- (BOOL)wasWindowZoomedBeforeFullScreen:(NSWindow *)window NS_SWIFT_NAME(wasZoomedBeforeFullScreen(_:));
// Reserves the Zee window for a Browser the engine created for itself and
// names the Space its tabs belong to. Zee is one window: the Browser joins
// the window the person is using, and only a window `chrome.windows.create`
// asked for (`ownWindow`) opens another. None when no Space can host the
// profile's tabs.
- (nullable id<ZeeEngineWindowPlacement>)reserveEngineWindowForProfile:(NSUUID *)profileID
                                                              ownWindow:(BOOL)ownWindow
    NS_SWIFT_NAME(reserveEngineWindow(profile:ownWindow:));
// Opens the reserved window just before its first tab is offered.
- (void)presentEngineWindow:(NSUUID *)windowID space:(NSUUID *)spaceID focused:(BOOL)focused
    NS_SWIFT_NAME(presentEngineWindow(_:space:focused:));
// A quit the application asked for; true while Zee finishes it itself.
- (BOOL)deferQuit;
// A Dock click or `Open` with no Zee window.
- (BOOL)reopen;
// A link or document from another app.
- (BOOL)openExternalURLs:(NSArray<NSURL *> *)urls NS_SWIFT_NAME(openExternal(_:));
// The Dock icon's menu: Zee's window commands and Spaces, ahead of the
// window list and the items macOS adds itself.
- (nullable NSMenu *)dockMenu;
// An app's system sign-in, in the Quick Window named `windowID`, and its end.
- (BOOL)openAuthenticationSession:(NSURL *)url window:(NSUUID *)windowID
    NS_SWIFT_NAME(openAuthenticationSession(_:window:));
- (void)closeAuthenticationSession:(NSUUID *)windowID NS_SWIFT_NAME(closeAuthenticationSession(window:));
// What the engine's browser window asks of Zee's: a key equivalent web
// content did not take, the location field, a bookmark for the active page,
// translation and tab search.
- (BOOL)handleShortcutEvent:(NSEvent *)event NS_SWIFT_NAME(handleShortcut(_:));
- (void)focusLocation;
- (void)bookmarkActivePage;
- (void)translatePage;
- (void)translateText:(NSString *)text NS_SWIFT_NAME(translate(_:));
- (void)showTabSearch;
- (void)showUnavailableFeature:(ZeeUnavailableFeature)feature NS_SWIFT_NAME(showUnavailable(_:));
- (void)showEngineNotice:(NSString *)message kind:(ZeeEngineNoticeKind)kind NS_SWIFT_NAME(showEngineNotice(_:kind:));
// Zee's own rows for the link or the selected text a page's context menu
// was opened on, which Zee puts ahead of the engine's rows in `menu`.
- (void)addPageMenuItems:(NSMenu *)menu
                    page:(NSUUID *)pageID
                    link:(nullable NSURL *)link
               selection:(nullable NSString *)selection
    NS_SWIFT_NAME(addPageMenuItems(to:page:link:selection:));
// A person began dragging the link to `url`, titled `title`, out of a page.
// Answers whether Zee's own drag took it; otherwise the engine's goes on.
- (BOOL)beginLinkDrag:(NSURL *)url title:(NSString *)title page:(NSUUID *)pageID
    NS_SWIFT_NAME(beginLinkDrag(_:title:page:));
// Where the popup that `extensionID` opened itself, with
// `chrome.action.openPopup()`, shows over the page `pageID`: the control a
// click on the extension's own button would have opened it from. Nil when the
// page has no window.
- (nullable id<ZeeExtensionPopupAnchor>)extensionPopupAnchor:(NSString *)extensionID page:(NSUUID *)pageID
    NS_SWIFT_NAME(extensionPopupAnchor(_:page:));
@end

// What an extension's `chrome.commands` shortcut did. A named command has
// already been delivered to its extension. An `_execute_action` binding names
// the extension whose action Zee runs itself, so its popup keeps the anchor
// a click on the extension's own button would have used.
@protocol ZeeExtensionShortcut <NSObject>
@property(nonatomic, readonly, nullable) NSString *actionExtensionID;
@end

// Chromium's Mac shell: what only AppKit does for the engine. It hosts each
// page's view and the views an extension or the inspector puts beside it,
// shows extension popups, runs system sign-in and answers the close and quit
// preflight. Everything else a page asks goes to
// the engine binding as a PageRequest. In-process and main-thread only;
// objects and blocks never enter .NET.
@protocol ZeeMacShell <NSObject>
// Zee's own UI, which the shell keeps for as long as it runs.
- (void)attachUI:(id<ZeeMacUI>)ui NS_SWIFT_NAME(attach(ui:));
- (nullable NSView *)viewForPage:(NSUUID *)pageID;
- (BOOL)runExtension:(NSString *)extensionID page:(NSUUID *)pageID
         anchorView:(NSView *)anchorView anchorRect:(NSRect)anchorRect;
// Runs a pinned action with no page open. Only an action carrying its own
// popup document can run: there is no tab to activate, grant host access for or
// inject into. Returns NO for anything else, including a page action.
- (BOOL)runExtension:(NSString *)extensionID profile:(NSUUID *)profileID window:(NSUUID *)windowID
          anchorView:(NSView *)anchorView anchorRect:(NSRect)anchorRect
    NS_SWIFT_NAME(runExtension(_:profile:window:anchorView:anchorRect:));
// The extension whose action popup shows in the Zee window `windowID`, or
// nil when none does.
- (nullable NSString *)extensionPopupInWindow:(NSUUID *)windowID NS_SWIFT_NAME(extensionPopup(inWindow:));
// Closes the action popup showing in the Zee window `windowID`, if one does.
- (void)closeExtensionPopupInWindow:(NSUUID *)windowID NS_SWIFT_NAME(closeExtensionPopup(inWindow:));
// Extension side panels. A panel is hosted as a Zee split-row card beside
// the page it belongs to: it is not a tab, is never persisted and never syncs.
// `closed` runs when the panel document or its extension host goes away.
- (nullable NSView *)openSidePanel:(NSString *)extensionID page:(NSUUID *)pageID
                            closed:(void (^)(void))closed
    NS_SWIFT_NAME(openSidePanel(_:page:closed:));
- (void)closeSidePanelForPage:(NSUUID *)pageID NS_SWIFT_NAME(closeSidePanel(page:));
// Docked DevTools. A Zee window is the user's window, so a docked inspector
// is mounted inside the page card it inspects instead of opening a window of
// its own. The binding presents when the docked frontend changes and answers
// where it goes; this is the frontend's container while an inspector is
// docked on that page, and nil otherwise.
- (nullable NSView *)devToolsViewForPage:(NSUUID *)pageID NS_SWIFT_NAME(devToolsView(page:));
// chrome.commands: what the shortcut did in the active page's own profile, or
// nil when no enabled extension bound it.
- (nullable id<ZeeExtensionShortcut>)dispatchExtensionShortcut:(NSEvent *)event
    page:(NSUUID *)pageID NS_SWIFT_NAME(dispatchExtensionShortcut(_:page:));
- (NSString *)engineVersion;
- (void)disposePages;
- (void)disposePages:(NSArray<NSUUID *> *)pageIDs windows:(NSArray<NSUUID *> *)windowIDs
    releaseProfiles:(NSArray<NSUUID *> *)profileIDs;
- (void)completeQuit;
// Declines a system sign-in the core could not place, so the requesting app
// learns at once rather than waiting on a window that will never open.
- (void)cancelAuthenticationSessionForWindow:(NSUUID *)windowID NS_SWIFT_NAME(cancelAuthenticationSession(window:));
@end
NS_ASSUME_NONNULL_END
