# Security

Metadata Randomizer's entire point is privacy: photo/video processing (stripping and replacing GPS/device/timestamp metadata) happens **entirely on-device**, nothing is uploaded anywhere.

The only network activity is the built-in update checker (`UpdateChecker.swift`), which is worth understanding precisely:

- It calls the GitHub Releases API over HTTPS for this repo and downloads the `.zip` asset attached to the latest release.
- It does **not** verify a checksum or signature of the downloaded archive beyond the HTTPS connection.
- After unzipping, the app **removes the quarantine attribute and re-signs itself ad-hoc** (`ContentView.swift`) before relaunching — i.e. it deliberately bypasses Gatekeeper's "app downloaded from the internet" check for the replaced bundle.
- Practical consequence: whoever can push a release to this GitHub repo controls what runs on your Mac on the next update, with Gatekeeper's quarantine check intentionally bypassed. Keep the maintainer GitHub account's security (2FA, etc.) in mind as part of this app's trust chain.

## Reporting a vulnerability

If you find a security issue (e.g. a way for original metadata to leak instead of being replaced, or a flaw in the update mechanism above), please open a GitHub issue or contact the maintainer directly rather than disclosing it publicly first.
