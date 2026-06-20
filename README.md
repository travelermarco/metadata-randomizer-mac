# Metadata Randomizer for Mac

A macOS app that **strips and replaces photo/video metadata with randomized fake data** — so your real GPS location, device identity, and timestamps never leave your Mac when you share a file.

## How it works

Drag any photo or video onto the app window. Metadata Randomizer processes the file in under a second and saves a clean copy alongside the original, ready to share however you like.

What gets replaced on every file:

| Field | What you get instead |
|-------|---------------------|
| GPS coordinates | Random location near a real city (London, Tokyo, Dubai…) |
| Device make/model | Random device from a pool of 30+ real models |
| Timestamps | Random date between 6 months and 3 years ago |
| Filename | Random `IMG_XXXXXXXX.jpg` / `VID_XXXXXXXX.mp4` |
| Software / firmware | Matching the fake device profile |
| Serial numbers, comments, copyright | Removed |

For videos, the file is exported without the metadata tracks — only the audio and video streams are kept.

After processing, the app shows a confirmation card with the exact fake values that were injected, and a **Reveal in Finder** button to locate the output file.

## Usage

1. Open **Metadata Randomizer**
2. Drag one or more photos/videos onto the window
3. Read the confirmation — see exactly what fake data was injected
4. Click **Reveal in Finder** to find the anonymized file
5. Share the output file however you like

No configuration needed. No accounts. No cloud upload.

## Supported formats

| Type | Formats |
|------|---------|
| Images | JPG, JPEG, HEIC, HEIF, PNG, TIFF, WebP |
| Videos | MP4, MOV, M4V |

## Installation

Download the latest `Metadata.Randomizer.app.zip` from the [Releases](../../releases) page, unzip it and move the app to your Applications folder.

> On first launch macOS may ask you to confirm opening an app from the internet — click **Open** in System Settings → Privacy & Security.

## Updates

The app checks for updates automatically at launch. If a new version is available, a banner appears at the top of the window with a **Download** link.

You can also trigger a manual check from the menu bar: **Metadata Randomizer → Check for Updates…**

## Build from source

Requirements: macOS 13+, Swift 6 (Xcode Command Line Tools or full Xcode)

```bash
git clone https://github.com/travelermarco/metadata-randomizer-mac.git
cd metadata-randomizer-mac
bash build.sh
# App → Metadata Randomizer.app
open "Metadata Randomizer.app"
```

## Technical details

- **Images**: decoded via `CIImage` with automatic EXIF orientation baking (all original metadata discarded), re-encoded as JPEG 92% via `CGImageDestination`, fake EXIF injected via ImageIO property dictionaries
- **Videos**: exported via `AVAssetExportSession` with `AVMetadataItemFilter.forSharing()` — strips GPS and user-identifying metadata from the container; passthrough preset used where possible to avoid re-encoding
- **Updates**: checks `api.github.com/repos/travelermarco/metadata-randomizer-mac/releases/latest`, compares semver tags — silent fail when offline
- Language: Swift · Minimum deployment: macOS 13 · No third-party dependencies

## See also

[Metadata Randomizer for Android](https://github.com/travelermarco/metadata-randomizer) — the companion app for the same workflow on Android.

## License

MIT
