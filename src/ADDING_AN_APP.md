# 다른 앱을 이 사이트에 추가하기 — 에이전트용 프롬프트

아래 블록을 **그 앱의 프로젝트 디렉터리에서** 실행 중인 에이전트 세션에 그대로 붙여넣는다.
대화 이력이 0인 모델도 바로 수행할 수 있도록 절대 경로와 정확한 명령으로 쓰여 있다.

기준 표본은 `paintboard` 항목이다. 새 앱은 그 구조를 그대로 따라간다.

⚠️ **동시에 두 앱을 작업하지 말 것.** 같은 저장소에 푸시하므로 한 앱씩 끝내고 다음으로 넘어간다.

---

## 붙여넣을 프롬프트

````
이 앱을 개발자 통합 사이트(https://huhphilgoo.github.io)에 추가해줘.
개인정보처리방침 페이지는 필수, 랜딩 페이지는 내가 원할 때만 만든다.

## 하드 룰
- **이 앱의 소스 코드는 절대 수정하지 마라.** 읽기만 한다. 커밋은 사이트 저장소에만 한다.
- 값을 추측하지 마라. 아래 명령으로 실제 파일에서 확인한 값만 쓴다.
- 스토어 등록명은 파일에서 알 수 없다. 반드시 나에게 물어라 (Google이 방침과 스토어
  등록정보의 앱·개발자 이름 불일치를 리젝 사유로 삼는다. 실제로 그림판이 이걸로 걸렸다).

## 1단계 — 이 저장소에서 사실 수집

다음을 실행하고 결과를 보고해라. 없는 항목은 "없음"으로 표시한다.

```bash
# 패키지명 / 번들 ID
grep -rn "applicationId" android/app/build.gradle.kts android/app/build.gradle 2>/dev/null
grep -rn "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj 2>/dev/null | head -3

# 앱 표시 이름 (en / ko)
find android -name "strings.xml" -exec grep -H "app_name" {} \;
grep -A1 "CFBundleDisplayName" ios/Runner/Info.plist 2>/dev/null
grep -h '"appTitle"' lib/l10n/*.arb 2>/dev/null

# 광고·분석 SDK
grep -A2 "com.google.android.gms.ads.APPLICATION_ID" android/app/src/main/AndroidManifest.xml 2>/dev/null
grep -nE "google_mobile_ads|firebase_analytics|firebase_core" pubspec.yaml 2>/dev/null

# 안드로이드 권한
grep -o 'android:name="android.permission.[A-Z_]*"' android/app/src/main/AndroidManifest.xml 2>/dev/null | sort -u

# iOS 권한 사용 설명 (권한이 실제로 무엇에 쓰이는지 알려준다)
grep -B0 -A1 "UsageDescription" ios/Runner/Info.plist 2>/dev/null

# 지원 언어
ls lib/l10n/*.arb 2>/dev/null
```

수집 후 나에게 **다음 항목을 확인**해라. 파일로는 알 수 없는 것들이다.
- Google Play 스토어 등록정보의 **앱 이름** (한 글자도 다르지 않게)
- App Store의 **앱 이름**
- 두 스토어 링크 (미출시면 "미출시")
- 랜딩 페이지도 만들지 여부
- 타겟 연령 (Play Console에 신고한 값. 그림판은 만 18세 이상)

## 2단계 — 사이트 저장소 클론

```bash
cd /tmp && rm -rf site && git clone https://github.com/huhphilgoo/huhphilgoo.github.io.git site
cd /tmp/site && cat README.md && python3 -c "import json;d=json.load(open('src/apps.json'));print(json.dumps(d['apps'][0],ensure_ascii=False,indent=2))"
```

마지막 명령이 출력하는 **paintboard 항목이 표본**이다. 구조를 그대로 따른다.

## 3단계 — src/apps.json 에 항목 추가

`apps` 배열 끝에 새 객체를 추가한다. 채울 것:

- `slug` — URL에 쓰일 소문자 영문 (예: `bshort`). 최종 주소가 `/<slug>/privacy/` 가 된다
- `name` / `nameKo` — 영문명 / 한글명
- `package` — 1단계에서 확인한 applicationId
- `storeNames.play` / `storeNames.appStore` — **내가 알려준 스토어 등록명 그대로**
- `links.play` / `links.appStore` — 미출시면 해당 키를 넣지 마라
- `summary` / `summaryKo` — 한 문장 소개
- `policyUpdated` — 오늘 날짜
- `privacy.storage` — 사용자 데이터가 어디에 저장되는지 (ko/en)
- `privacy.services` — 실제로 쓰는 것만. 가능한 값: `admob`, `firebaseAnalytics`
  (다른 SDK를 쓴다면 `src/build.py` 의 `SERVICES` 딕셔너리에 항목을 먼저 추가해라)
- `privacy.consent` — `ump`/`att` 사용 여부 (광고가 없으면 둘 다 false)
- `privacy.permissions` — 1단계에서 확인한 **실제 권한만**. 각 항목은 ko/en 각각
  `[권한 이름, 사용 목적, 비고]` 3개 문자열
- `privacy.minAge` — 타겟 연령
- `landing` — 랜딩 페이지를 안 만들면 `null`. 만들면 paintboard 의 `landing` 구조를 따르되
  `en` 과 `ko` 두 블록을 모두 채운다 (섹션 제목까지 전부 언어별로 들어간다)

**없는 권한이나 안 쓰는 SDK를 적지 마라.** 방침에 과잉 신고를 하면 데이터 보안 신고와
어긋나서 그것 자체가 문제가 된다.

## 4단계 — 스크린샷 (랜딩 페이지를 만드는 경우만)

`/tmp/site/<slug>/assets/` 에 넣는다. 가로 1400px 내외 JPEG:

```bash
mkdir -p /tmp/site/<slug>/assets
sips -Z 1400 -s format jpeg -s formatOptions 85 <원본> --out /tmp/site/<slug>/assets/<이름>.jpg
```

⚠️ **실제 기기에서 손으로 조작해 찍은 캡처를 써라.** 통합 테스트로 생성한 스크린샷은
완벽한 원과 정확한 사인 곡선이 나와서 목업처럼 보이고 신뢰를 깎는다.

## 5단계 — 빌드·검증

```bash
cd /tmp/site && python3 src/build.py
```

생성된 방침 페이지에 식별자가 들어갔는지 확인해라. 0이면 안 된다:

```bash
grep -c "<앱 한글명>" /tmp/site/<slug>/privacy/index.html
grep -c "허필구" /tmp/site/<slug>/privacy/index.html
grep -c "<패키지명>" /tmp/site/<slug>/privacy/index.html
```

브라우저로 `/tmp/site/<slug>/privacy/index.html` 을 열어 한/영 양쪽을 눈으로 확인해라.

## 6단계 — 커밋·푸시

다른 앱 작업과 충돌하지 않도록 **반드시 pull 먼저**:

```bash
cd /tmp/site && git pull --rebase origin main
git add -A && git commit -m "Add <앱 이름>" && git push origin main
```

배포는 GitHub Pages 가 자동으로 한다 (보통 1분). 확인:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://huhphilgoo.github.io/<slug>/privacy/
```

## 7단계 — 나에게 보고

다음을 알려줘라. 내가 스토어 콘솔에 직접 입력해야 하는 값들이다.

- 개인정보처리방침 URL: `https://huhphilgoo.github.io/<slug>/privacy/`
- 랜딩 페이지 URL (만든 경우): `https://huhphilgoo.github.io/<slug>/`
- 내가 할 일:
  - Play Console → 앱 콘텐츠 → 개인정보처리방침 → 위 URL → 저장 → 게시 개요에서 검토 전송
  - App Store Connect → 앱 정보 → 개인정보 보호 정책 URL → 같은 값
- 이 앱의 `app-ads.txt` 는 손댈 필요 없다. 같은 AdMob 게시자 ID
  (`pub-4185693428426764`) 를 쓰는 한 도메인 루트의 파일 하나가 전부 커버한다.
  다른 게시자 ID를 쓴다면 그 사실을 보고해라 — `src/apps.json` 의 `adNetworks` 에
  줄을 추가해야 한다.

마지막으로, 이 앱 저장소의 문서(CLAUDE.md / CURRENT.md / WORKLOG.md 같은 것이 있다면)에
"개인정보처리방침 URL이 바뀌었다"는 사실과 새 URL을 기록해라.
````

---

## 이 프롬프트가 방지하는 것

- **스토어 등록명 불일치** — 파일에서 추측하지 말고 오너에게 묻게 한다. 그림판이 실제로
  이것 때문에 Play 정책 플래그를 맞았다.
- **권한 과잉 신고** — 실제 매니페스트에 있는 권한만 쓰게 한다.
- **앱 소스 오염** — 읽기만 하고 커밋은 사이트 저장소에만 한다.
- **동시 푸시 충돌** — 한 번에 한 앱, push 전 rebase.
