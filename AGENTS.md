# Agent Instructions

## Versioning
- Before each commit or push, bump the app version/build in `pubspec.yaml`.
- Prefer incrementing only the build number (`x.y.z+N -> x.y.z+N+1`) unless a release warrants a semver change.
- If a commit doesn’t change the app package (docs-only or tooling-only), you may skip the bump.
