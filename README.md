# huhphilgoo.github.io

One site for every app: the hub, each app's landing page and privacy policy, and the
single `app-ads.txt` that AdMob reads. Served by GitHub Pages straight from `main`.

    https://huhphilgoo.github.io/                    hub
    https://huhphilgoo.github.io/app-ads.txt         AdMob verification
    https://huhphilgoo.github.io/paintboard/         landing page (English)
    https://huhphilgoo.github.io/paintboard/ko/      landing page (한국어)
    https://huhphilgoo.github.io/paintboard/privacy/ privacy policy (both languages)

## Everything here is generated

Do **not** hand-edit the HTML — it is overwritten on every build. Edit `src/apps.json`
(the data) or `src/build.py` (the templates and stylesheet), then:

    python3 src/build.py

Commit the result. There is no CI and no build step on GitHub's side; the generated
files in the repo *are* the site.

## Adding an app

1. Add an entry to `src/apps.json`.
2. Drop web-sized screenshots in `<slug>/assets/` if the app gets a landing page.
   Set `"landing": null` for apps that only need a privacy policy.
   A landing page needs an `en` and a `ko` block; English renders at `/<slug>/` and
   Korean at `/<slug>/ko/`, cross-linked by the EN/KO switcher and `hreflang` tags.
   Images and the palette are shared between the two, so they are declared once.
3. Run `python3 src/build.py`, review, commit, push.
4. Point the store listings at the new URL:
   - Play Console → 앱 콘텐츠 → 개인정보처리방침 → `…/<slug>/privacy/`
   - App Store Connect → 앱 정보 → 개인정보 보호 정책 URL → same

## Two rules that are easy to get wrong

**`app-ads.txt` must stay at the repo root.** The IAB spec reads it only from a domain
root — `/paintboard/app-ads.txt` would never be found. It is generated from the
`adNetworks` list, and one file covers every app sharing those publisher IDs. AdMob
locates it through the **website field of the store listing**, so that field must be
`https://huhphilgoo.github.io` (root, no path).

**Every app needs its own privacy page.** Google rejects a policy that does not identify
the app and developer exactly as the store listing does — a shared template page naming
no app is precisely what got PaintBoard flagged in August 2026. That is why the
identifiers live in `apps.json` and every page is rebuilt from them rather than copied.

## Why not a blog

The policies used to live on Tistory. A blog cannot serve `app-ads.txt` from a domain
root (unknown paths return the blog homepage as HTML, which fails the format check), it
gives no version history for a legal document, and one shared post cannot satisfy the
per-app identification requirement.
