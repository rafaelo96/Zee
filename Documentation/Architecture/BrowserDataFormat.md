# Browser data format

**Settings › Advanced › Export Browser Data…** writes everything Zee keeps of your Spaces to one file, `Zee Browser Data.json`. It is plain JSON, documented here so that any person or program can read it without Zee, and so that your browsing never depends on Zee continuing to exist. **Import Browser Data…** reads it back, on any Mac, iPhone or iPad.

The core writes and reads it (`BrowserDataFile`, `BrowserDataSpace` and their record types in `ZeeCore/src/ZeeCore/Application/Portability`). Keys are written sorted and indented. A reader of this version accepts every earlier schema version, and fields this document marks as optional may be absent.

## What stays out

The file holds no secret and nothing tied to one device: no passwords, no credential preferences, no Space locks, no browser profiles, cookies or website data, no favicons, and no window layout. An import gives every Space, folder, tab, split and Boost a new identity, so a file can be imported more than once and beside the Spaces it came from.

## Document

| Key | Type | Meaning |
| --- | --- | --- |
| `format` | string | Always `dev.zee.browser.browser-data`. |
| `schemaVersion` | integer | The version of this layout, now `5`. |
| `exportedAt` | number | When the file was written, in milliseconds since 1970-01-01 UTC. |
| `spaces` | array of Space | At most 64 Spaces, in sidebar order. |

The file is at most 50 MB.

Identities are UUIDs in uppercase (`"6F1C…"`). Colors are objects of `red`, `green`, `blue` and `alpha`, each from 0 to 1. Times are milliseconds since 1970-01-01 UTC unless a field says otherwise.

## Space

| Key | Type | Meaning |
| --- | --- | --- |
| `name` | string | The Space's name. |
| `symbol` | string | An SF Symbol name, or `zee.emoji:` followed by an emoji. |
| `accent` | string | The accent color's name, such as `indigo`, `teal` or `orange`. |
| `branding` | object, optional | The Space's look: banner colors and pattern, theme and badge, as Zee stores them. |
| `folders` | array of Folder | The Space's folders, in sidebar order. |
| `tabs` | array of Tab | Pinned, saved and open tabs, in sidebar order. |
| `splitGroups` | array of Split, optional | The split views the tabs form. |
| `archivedTabs` | array of Archived tab | The Space's archive. |
| `history` | array of Visit | The Space's history. |
| `browsingPreferences` | object | Search engine, suggestions, when open tabs archive, content blocking and how long history and the archive are kept. |
| `boosts` | array of Boost, optional | The sites the Space restyles. |

A Space holds at most 5,000 open and 5,000 archived tabs.

## Folder

| Key | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | The folder's identity within the file. |
| `title` | string | Its name. |
| `symbol` | string | Its SF Symbol. |
| `location` | string, optional | `saved` (default) for a saved folder, `current` for a group of open tabs. |
| `parentID` | UUID, optional | The folder it sits in. Folders nest up to 16 levels. |
| `color` | color, optional | Its color. |
| `isCollapsed` | boolean, optional | Whether it is collapsed. |
| `isGroup` | boolean, optional | Whether it is a group of open tabs rather than a folder. |
| `orderAnchorTabID` | UUID, optional | The tab it sits after among its siblings. |

## Tab

| Key | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | The tab's identity within the file. |
| `title` | string | Its title. |
| `url` | string, optional | The address it shows. |
| `savedURL` | string, optional | The address a pinned or saved tab returns to. |
| `placement` | string | `pinned`, `saved` or `current` (an open tab). |
| `symbol` | string | Its icon: an SF Symbol name, or `zee.emoji:` and an emoji. |
| `folderID` | UUID, optional | The folder it sits in. |
| `splitGroupID` | UUID, optional | The split view it is part of. |
| `lastActivatedAt` | number | When it was last shown. |
| `nativeContent` | object, optional | For one of Zee's own pages: its `kind` and an optional `resourceID`. |

## Split

| Key | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | The split's identity, which its tabs name. |
| `customTitle`, `customIconSymbol` | string, optional | The name and icon the person gave it. |
| `tint` | color, optional | Its color. |
| `isCollapsed` | boolean, optional | Whether it is collapsed in the sidebar. |
| `titleModifiedAt`, `iconModifiedAt`, `tintModifiedAt`, `collapseModifiedAt` | number, optional | When each was last changed. |

## Archived tab

| Key | Type | Meaning |
| --- | --- | --- |
| `tab` | Tab | The tab as it was. |
| `archivedAt` | number | When it was archived. |
| `reason` | string | Why: `autoCleanup`, `closed`, `deleted`, `deletedOnAnotherDevice`, `quickWindow` or `synced`. |

## Visit

| Key | Type | Meaning |
| --- | --- | --- |
| `url` | string | The address visited. |
| `title` | string | Its title. |
| `firstVisitedAt`, `lastVisitedAt` | number | The first and the latest visit. |
| `visitCount` | integer | How many times it was visited. |

## Boost

| Key | Type | Meaning |
| --- | --- | --- |
| `id` | UUID (lowercase) | The Boost's identity. |
| `domain` | string | The site it restyles, which also covers every subdomain. |
| `isOn` | boolean | Whether it applies. |
| `allSpaces` | boolean | Whether it applies in every Space rather than its own. |
| `look` | object | `background`, `text` and `accent` colors (each optional), `font` (`site`, `system`, `serif`, `rounded` or `mono`) and `textScale` (0.5 to 2). |
| `css` | string | The person's own stylesheet, at most 64 KB. |
| `script` | string | The person's own script, at most 64 KB. |
| `hidden` | array of string | CSS selectors of the elements it hides, at most 200. |
| `modifiedAt` | number | When it was last changed, in seconds since 2001-01-01 UTC. |

## Bookmarks

**Export Bookmarks as HTML…** writes `Zee Bookmarks.html` instead: every Space's pinned and saved tabs and saved folders as a standard Netscape bookmark file, which every major browser imports.
