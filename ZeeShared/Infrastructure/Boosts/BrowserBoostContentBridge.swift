import Foundation

/// The content bridge that applies a page's Boosts. It runs in the top
/// document only, in Zee's own world, on both engines: as the document starts
/// it tells the page's Boost session its address, and keeps the stylesheet
/// the session answers with in one style element of its own, which it moves
/// to the end of the head once the document has one, so the Boost's rules
/// come after the site's. The Boost's script runs separately, once per
/// document, through the engine's own evaluation, so a site's content policy
/// cannot refuse it.
@MainActor
enum BrowserBoostContentBridge {
    static let messageHandlerName = "zeeBoost"

    /// Keeps `sheet` as the document's Boost stylesheet.
    static let applyBody = "globalThis.__zeeBoost?.apply(sheet); return true;"

    static let source = """
        (() => {
          if (globalThis.__zeeBoost) return;
          const id = "zee-boost-style";
          let sheet = "";
          const place = () => {
            let style = document.getElementById(id);
            if (!sheet) { style?.remove(); return; }
            if (!style) {
              style = document.createElement("style");
              style.id = id;
            }
            const parent = document.head || document.documentElement;
            if (parent && (style.parentNode !== parent || style !== parent.lastElementChild)) parent.appendChild(style);
            if (style.textContent !== sheet) style.textContent = sheet;
          };
          globalThis.__zeeBoost = { apply(next) { sheet = String(next || ""); place(); } };
          document.addEventListener("DOMContentLoaded", place, { once: true });
          try { webkit.messageHandlers.\(messageHandlerName).postMessage({ url: location.href }); } catch {}
        })();
        """

    static var script: BrowserContentScript {
        BrowserContentScript(source: source, handlerName: messageHandlerName, mainFrameOnly: true)
    }
}
