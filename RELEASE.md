# CurseForge release (GearQuest Forever)

This repo is a **new CurseForge project**. Do not reuse the TBC Anniversary GearQuest project ID, GitHub secrets, or webhook.

Publishing uses **GitHub Actions**, not the CurseForge webhook. Keep any CurseForge GitHub webhook **inactive**.

## One-time setup

1. **Create a new CurseForge project** at [authors.curseforge.com](https://authors.curseforge.com/) named **GearQuest Forever** (WoW Forever / Classic+). Do not attach it to the existing TBC GearQuest project. **Done:** [project 1698950](https://authors.curseforge.com/#/projects/1698950).
2. Copy the **Project ID** from CurseForge → Overview → paste into `GearQuest/GearQuestForever.toc` as `## X-Curse-Project-ID:`. **Done:** `1698950` (not TBC `1669225`).
3. **API token:** [authors.curseforge.com → API tokens](https://authors.curseforge.com/#/settings/api-tokens) → create a token (or reuse your author token — it is account-level, not project-level).
4. **GitHub secret:** this repo → Settings → Secrets and variables → Actions → New repository secret:
   - Name: `CF_API_KEY`
   - Value: your CurseForge API token. **Done** on `gear-quest-forever` (do not copy the TBC repo secret).
5. **CurseForge Source (optional):** Link this GitHub repo for metadata only. Uploads come from Actions.
6. TOC `## Interface:` is **16001** for CurseForge **WoW Forever 1.60.1**. Confirm `lastAddonVersion` in `_forever_\WTF\Config.wtf` after first login. Local sync is only `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns`.

## Release steps

Only when explicitly publishing:

1. Bump `## Version:` in `GearQuest/GearQuestForever.toc` and `GearQuest/Core.lua` (`GQ.VERSION`) to **`X.Y.Z`** (the current release is `1.0.9`). A beta tag is `X.Y.Z-beta` only when that upload should stay on the beta channel. The log window header is **`GearQuest Forever v`** plus `GQ.VERSION` (`GearQuest/Log.lua`, `GearQuestWindowTitle`). It must stay that string — do not hardcode a different version in the header. Bumping `GQ.VERSION` is what updates the band on every release.
2. Add a `## vX.Y.Z` section at the top of `CHANGELOG.md` and demote the previous `## ` heading to `###`. `scripts/upload-curseforge-forever.py` sends markdown from that first `## ` line through the end of the file. Older versions stay as `###` so there is only one level-2 heading. Write the new section for players: a short lead, then a subsection per change, with the classes, specs, levels, and what they will see. A one-line summary is not enough.
3. Commit and push to `main`.
4. Tag and push: `git tag vX.Y.Z` then `git push origin vX.Y.Z`. CurseForge **Files** shows that tag (keep the `v`). A tag that does not end in `-beta` uploads on the **release** channel. A tag that ends in `-beta` uploads on the **beta** channel. `.github/workflows/release.yml` sets `CF_RELEASE_TYPE` from the tag name.
5. Verify **GitHub Actions → Release** succeeds.
6. Check CurseForge → **Files** — new file appears as Processing, then Approved.

## Rules

- **Never tag** unless explicitly publishing a release.
- **Do not** delete and re-push tags — bump the patch version instead.
- Pushing to `main` alone is **not** a release.
- **Never** copy `X-Curse-Project-ID` from the TBC GearQuest repo.

## Next upload

`v1.0.0` is the first file on the CurseForge **release** channel. The next version is the next `X.Y.Z` on that channel unless a beta was asked for.

After a tag exists, bump the version rather than deleting the tag.
