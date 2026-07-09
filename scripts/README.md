# Release automation

One command builds the split-per-abi APKs, publishes a GitHub release, and
points Firebase Remote Config at it. The app then auto-updates each device to
the APK matching its ABI, comparing versions by semver name (immune to the
split-per-abi versionCode offsets).

## One-time setup

1. **GitHub CLI**
   ```bash
   gh auth login
   ```

2. **Firebase service account** (free)
   Firebase Console → Project Settings → Service Accounts → *Generate new
   private key*. Save it as:
   ```
   scripts/.firebase-sa.json        # gitignored — never commit
   ```
   (or set `FIREBASE_SA_JSON=/path/to/key.json`)

3. **Python deps**
   ```bash
   pip install -r scripts/requirements.txt
   ```

## Cutting a release

```bash
scripts/release.sh <versionName> <versionCode> "<changelog>" [--forced]

# example
scripts/release.sh 1.6.0 8 "Perbaikan download YouTube & auto-update"
```

What it does:
1. Bumps `version:` in `pubspec.yaml` to `1.6.0+8`.
2. `flutter build apk --release --obfuscate --split-debug-info --split-per-abi`.
3. Creates GitHub release `v1.6.0` and uploads the 3 APKs.
4. Sets Remote Config: `latest_version_name`, `latest_version_code`,
   `download_url_base` (the release folder), `changelog`, `is_forced`.

`--forced` marks the update mandatory (blocks the app until updated).

## How the app picks the APK

`download_url_base` = `…/releases/download/v1.6.0`. The app appends the
per-abi filename it needs:
- `arm64-v8a`   → `app-arm64-v8a-release.apk`
- `armeabi-v7a` → `app-armeabi-v7a-release.apk`
- `x86_64`      → `app-x86_64-release.apk`

Legacy `download_url` (single URL) is still honored if `download_url_base`
is empty.

## Keystore reminder

Release signing uses `android/app/upload-keystore.jks` + `android/key.properties`
(both gitignored). Losing them means you can't ship updates that install over
an existing install. Back them up somewhere safe.
