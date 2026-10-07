# Release design

Extract bundle/ZIP creation into scripts/package_app.sh, leaving install_app.sh as an explicit installation wrapper. Embed version 1.7.1/build 47 and sign the complete bundle using the existing ad-hoc distribution model. Archive only VisualBarTimer.app using ditto. Publish bilingual release notes with the arm64 and notarization status stated. Download the published ZIP and verify its SHA-256 before publishing the cask update. Packaging only; Lazyweb does not apply.
