---
title: Set up 1Password in Zee
description: Install the 1Password Chrome extension in Zee for Mac and authorize Zee in the 1Password app.
slug: /onepassword
sidebar_label: 1Password setup
sidebar_position: 10
keywords: [1Password, native messaging, trusted browser, Add Browser, authorize Zee, Zee for Mac]
---

# Set up 1Password in Zee

The 1Password Chrome Web Store extension runs on Chromium pages in Zee for Mac. To unlock and fill through the 1Password app, the app must trust Zee as a browser.

:::caution Use the signed Zee release
1Password checks the browser's code signature. Use the Developer ID signed and notarized Zee release installed in `/Applications`. A development build carries a different signature, and 1Password rejects it.
:::

## Before you begin

- Install and unlock **1Password for Mac**.
- Switch to the Zee Space that should own the extension. Installations do not copy to another Space or device on their own.

## Install the extension

1. In Zee for Mac, open the 1Password page in the Chrome Web Store.
2. Select **Add to Zee**.
3. Review the package, its permissions and the destination Space in Zee's review sheet.
4. Select **Add Extension**, then **Done**.

## Authorize Zee in 1Password

1. Open and unlock **1Password for Mac**.
2. Select your account or collection at the top of the sidebar, then select **Settings**.
3. Select **Browser** in the sidebar.
4. Select **Add Browser**.
5. Choose **Zee** in `/Applications`.
6. Review 1Password's access prompt and select **Authorize**.

1Password warns that an additional browser can reach your saved information while 1Password is unlocked, so it can save and fill logins. Only authorize a Zee build you trust.

## If it does not connect

Touch ID unlock comes from the 1Password app, so the extension offers it only after you authorize Zee there. Until then, the extension unlocks with your account password.

Reinstalling the extension does not change the signature 1Password checks. Confirm that you added the Zee app in `/Applications`, then see [Native companions](./native-companion-limits.md) and [Troubleshoot an extension](./troubleshoot-partial-compatibility.md).

## Official references

- [Connect additional browsers to the 1Password app](https://support.1password.com/additional-browsers/)
- [1Password browser code-signature requirements](https://support.1password.com/code-signature/)
