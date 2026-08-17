# huhphilgoo.github.io

Root site for the developer domain. It exists so that files which **must** live at a
domain root can be served — chiefly `app-ads.txt`.

## app-ads.txt

AdMob verifies app ownership by reading the developer website declared in the app's
store listing and fetching `<that domain>/app-ads.txt`. The path is fixed by the IAB
spec: root only, lowercase, plain text. A subpath (e.g. `/paintboard-site/app-ads.txt`)
is not read, and a blog that redirects unknown paths to its homepage returns HTML and
fails the format check — that was the original problem with `goodgods.com`.

Current entry covers every app under AdMob publisher `pub-4185693428426764`
(PaintBoard / 그림판 on both stores, and any future app on the same publisher ID):

    google.com, pub-4185693428426764, DIRECT, f08c47fec0942fa0

For this to work, the store listing's website field must point at
`https://huhphilgoo.github.io` — Play Console → 스토어 설정 → 스토어 등록정보 연락처
세부정보 → 웹사이트, and App Store Connect → 앱 정보 → 마케팅 URL.

Adding another ad network later means adding one more line; do not remove this one.

## Apps

- PaintBoard (그림판) — landing page: https://huhphilgoo.github.io/paintboard-site/
