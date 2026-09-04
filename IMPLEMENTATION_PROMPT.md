# TASK: Fix Google Sign-In for Flutter Web Without Breaking Android

## Context

Project ini adalah Flutter mobile app dengan target utama Android.

Selama development, project juga dijalankan melalui Chrome untuk testing UI, routing, dan fitur lainnya.

Current situation:

- Google Sign-In BERHASIL di Android.
- Google Sign-In GAGAL ketika aplikasi dijalankan di Chrome/Web.
- Jangan merusak atau mengganti flow Android yang saat ini sudah berhasil.
- Backend authentication menggunakan Supabase Auth.
- Google OAuth provider menggunakan Google Cloud.
- Project menggunakan `supabase_flutter`.
- Project juga menggunakan `google_sign_in` untuk native Google authentication.

The goal is:

1. Keep Android Google Sign-In working exactly as before.
2. Make Google Sign-In work correctly when running Flutter Web in Chrome.
3. Use the correct authentication architecture for each platform.
4. Use the latest official Supabase documentation and current package APIs.
5. Avoid unnecessary architectural changes or overengineering.

---

# IMPORTANT: USE CURRENT DOCUMENTATION

Before modifying code, MUST consult current documentation.

Use:

1. Context7 MCP for the latest documentation of:
   - `supabase_flutter`
   - Supabase Auth
   - `google_sign_in`
   - Flutter Web authentication
   - relevant OAuth APIs

2. Supabase MCP for the actual Supabase project configuration when available:
   - Google Auth provider configuration
   - Auth URL Configuration
   - Redirect URLs
   - relevant Auth configuration

3. Prefer official Supabase documentation and official package documentation over assumptions or outdated knowledge.

DO NOT rely on deprecated examples if current documentation provides a newer approach.

If Context7 or Supabase MCP is unavailable, continue using the official documentation available to you, but clearly identify that limitation in the final report.

---

# CURRENT ERROR / DEBUG INFORMATION

When running the project on Chrome, the console reports:

```text
[GSI_LOGGER]: google.accounts.id.initialize() is called multiple times.
This could cause unexpected behavior and only the last initialized instance will be used.

The `signIn` method is discouraged on the web because it can't reliably provide an `idToken`.
Use `signInSilently` and `renderButton` to authenticate your users instead.

The google_sign_in plugin `signIn` method is deprecated on the web...

[GSI_LOGGER-TOKEN_CLIENT]: Starting popup flow.

[GSI_LOGGER-OAUTH2_CLIENT]: Starting popup timer.

[GSI_LOGGER-OAUTH2_CLIENT]: Checking popup closed.

[GSI_LOGGER-OAUTH2_CLIENT]: Popup window closed.

[google_sign_in_web] Error on TokenResponse: popup_closed

Previously, Google also showed:

Access blocked: Authorization Error

no registered origin

Error 401: invalid_client

This strongly indicates that the current Web implementation is using the google_sign_in Web implementation instead of using the Supabase OAuth browser flow.

IMPORTANT DISCOVERY FROM THE LOG

The current implementation appears to execute:

GoogleSignIn().signIn()

on Web.

This must be investigated.

For the final architecture, use platform-specific authentication:

Android / Native

Keep the existing native Google Sign-In flow if it is already working:

google_sign_in
        ↓
Google ID Token + Access Token
        ↓
supabase.auth.signInWithIdToken(...)
        ↓
Supabase Session

Supabase's current Flutter documentation supports native Google authentication using google_sign_in together with signInWithIdToken.

Web

Do NOT use:

GoogleSignIn().signIn()

for the Web flow.

Use the Supabase OAuth flow:

Flutter Web
    ↓
supabase.auth.signInWithOAuth(
    OAuthProvider.google
)
    ↓
Google OAuth
    ↓
Supabase Auth callback
    ↓
Flutter Web
    ↓
Supabase Session

Supabase's current documentation recommends signInWithOAuth for browser OAuth flows.

STEP 1 — AUDIT THE EXISTING AUTH IMPLEMENTATION

Before changing anything:

Search the entire project for:

GoogleSignIn
googleSignIn.signIn()
signInWithIdToken
signInWithOAuth
OAuthProvider.google
Provider.google
google.accounts.id
google.accounts.oauth2

Identify:

Where Google authentication is implemented.
Which widget/page triggers Google login.
Whether Google Sign-In is initialized globally.
Whether Google Sign-In is initialized more than once.
Whether google_sign_in is being executed on Web.
Whether there are platform-specific files.
Whether the project already has an authentication service/provider/controller.
Whether login state is handled through onAuthStateChange.
Whether routing depends on Supabase session state.

Do NOT immediately rewrite the authentication system.

First understand the existing architecture.

STEP 2 — PRESERVE ANDROID

Android currently works.

Therefore:

DO NOT:

remove google_sign_in
remove Android OAuth configuration
remove Android deep-link configuration
replace the native Android authentication flow with Web OAuth
change Android package configuration unnecessarily
change Android SHA-1/SHA-256 configuration unnecessarily
change existing Android redirect/deep-link configuration unless the audit proves it is incorrect

The existing Android flow should remain functionally equivalent.

Expected native architecture:

Android
   ↓
google_sign_in
   ↓
Google authentication
   ↓
idToken + accessToken
   ↓
Supabase signInWithIdToken
   ↓
Supabase session
STEP 3 — IMPLEMENT WEB-SPECIFIC GOOGLE AUTH

Use Flutter platform detection appropriately.

For example, the architecture may use:

if (kIsWeb) {
  // Supabase OAuth
} else {
  // Existing native Google Sign-In
}

However, do NOT blindly copy this example.

First inspect the current project and confirm the correct API signatures from current Context7 / Supabase documentation.

The Web branch should use:

supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  ...
)

The native branch should preserve the existing working implementation.

STEP 4 — WEB REDIRECT CONFIGURATION

The current Supabase URL Configuration contains mobile-oriented URLs:

io.supabase.flutter://callback/
com.example.skolaapp:call-back/

These are related to the native/mobile flow.

DO NOT remove them simply to make Web work.

Add a Web development redirect URL.

For development, use a fixed Flutter Web port:

http://localhost:3000

and allow:

http://localhost:3000/**

in:

Supabase
→ Authentication
→ URL Configuration
→ Redirect URLs

Keep the existing mobile redirect URLs unless the audit proves one is invalid or unused.

STEP 5 — DO NOT CONFUSE DART VM SERVICE PORT WITH WEB APP PORT

The current log contains:

A Dart VM Service on Chrome is available at:
http://127.0.0.1:52238/...

IMPORTANT:

That is the Dart VM / debugging service.

It is NOT necessarily the Flutter Web application origin.

Do NOT add:

http://127.0.0.1:52238

to Google OAuth configuration just because it appears in the log.

Instead, run the application with a fixed Web port:

flutter run -d chrome --web-port 3000

The actual application origin should then be:

http://localhost:3000

Use that URL consistently for development configuration.

STEP 6 — GOOGLE CLOUD CONFIGURATION

Inspect the Google Cloud OAuth configuration.

There must be a Web OAuth Client.

Expected:

OAuth Client Type:
Web application

For the Web OAuth Client:

Authorized JavaScript origins

Add:

http://localhost:3000
Authorized redirect URIs

Use the Supabase Auth callback URL for the project.

It should be obtained from the Supabase Google Provider configuration / official Supabase documentation.

Expected format:

https://<PROJECT-REF>.supabase.co/auth/v1/callback

DO NOT invent the project reference.

Obtain the actual value from the connected Supabase project.

DO NOT put:

io.supabase.flutter://callback/

as the Web OAuth callback URI.

That is a native/mobile redirect.

STEP 7 — SUPABASE GOOGLE PROVIDER

Inspect:

Supabase
→ Authentication
→ Providers
→ Google

Verify that the Google provider uses the correct Web OAuth credentials:

Client ID
Client Secret

from the Web OAuth Client in Google Cloud.

If multiple Google OAuth Client IDs are configured for different platforms, follow the current Supabase documentation regarding the ordering/format of multiple client IDs.

Do not expose secrets in source code, logs, or final output.

Never hardcode the Google Client Secret into Flutter code.

STEP 8 — SUPABASE URL CONFIGURATION

The project is primarily a mobile application.

Therefore, do not unnecessarily replace the existing mobile authentication configuration.

The current configuration includes:

io.supabase.flutter://callback/
com.example.skolaapp:call-back/

Preserve these if they are still required by Android.

Add the Web development redirect:

http://localhost:3000/**

If the Web implementation explicitly passes:

redirectTo: 'http://localhost:3000'

ensure that the exact redirect target is permitted by the Supabase Redirect URLs allow-list.

Follow the current Supabase documentation for the relationship between:

Site URL
Redirect URLs
redirectTo

Do not make assumptions.

STEP 9 — SITE URL

Do NOT automatically change the existing Site URL just because Web needs to work.

First inspect how the existing Android authentication flow works.

The project is mobile-first, and Android currently works.

Prefer an explicit Web redirect if that allows the existing mobile configuration to remain intact.

If changing Site URL is actually required by the current Supabase architecture, explain why before making the change and ensure Android authentication remains functional.

STEP 10 — REMOVE UNNECESSARY WEB google_sign_in USAGE

The current Web log contains:

google_sign_in_web
signIn
popup_closed

This means the native Google Sign-In package is being invoked in Web.

After the fix:

When running:

flutter run -d chrome --web-port 3000

the Google login button should NOT invoke:

GoogleSignIn().signIn()

on Web.

Instead it should invoke:

supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  ...
)

The Web authentication flow should therefore be handled by Supabase OAuth.

STEP 11 — HANDLE AUTH SESSION CORRECTLY

After Google authentication:

Verify that the existing Supabase session handling works on Web.

Inspect:

onAuthStateChange
currentSession
currentUser
routing/navigation after login

Do not create a second authentication state system if the project already has one.

The Web OAuth flow should ultimately produce a normal Supabase Auth session and use the existing session handling.

STEP 12 — HANDLE WEB REDIRECT CORRECTLY

After successful Google authentication:

Google
   ↓
Supabase Auth
   ↓
http://localhost:3000

The application should:

Receive the OAuth result.
Restore/read the Supabase session.
Trigger the existing authentication state handling.
Navigate to the correct authenticated page/dashboard.
Avoid requiring the user to manually restart the application.

Do not implement a custom token parser unless current Supabase Flutter behavior requires it.

Follow current Supabase documentation.

STEP 13 — AVOID GOOGLE GSI INITIALIZATION DUPLICATION

The current log says:

google.accounts.id.initialize() is called multiple times.

Find why this happens.

Possible causes include:

Google Sign-In Web being initialized multiple times.
Multiple widgets initializing the same Google service.
Login page being rebuilt and triggering initialization.
A combination of google_sign_in and another Google Identity Services implementation.

Fix the root cause.

Do NOT simply suppress the log.

If Web no longer uses google_sign_in.signIn(), determine whether the warning disappears naturally.

Do not add another Google Identity Services initialization just to silence the warning.

STEP 14 — DEPENDENCY AUDIT

Inspect:

pubspec.yaml
pubspec.lock

Determine:

Current supabase_flutter version.
Current google_sign_in version.
Whether google_sign_in_web is explicitly declared.
Whether another Google authentication package is installed.
Whether any dependency is outdated or incompatible.

Do NOT blindly upgrade every dependency.

Only change dependencies if required for the authentication fix or current API compatibility.

If a dependency upgrade is required, explain:

current version
required version
reason
compatibility implications
STEP 15 — SECURITY REQUIREMENTS

Do not:

put Google Client Secret in Flutter source code
put Supabase service-role key in Flutter source code
expose OAuth secrets in logs
commit secrets to Git
bypass OAuth validation
disable nonce/security checks just to make login work
disable SSL/TLS validation
implement insecure custom OAuth handling

Use Supabase Auth as the authentication authority.

STEP 16 — TESTING

After implementation, test BOTH platforms.

Test A — Android

Run the existing Android configuration.

Expected:

Google Login
    ↓
Google account selection
    ↓
Supabase authentication
    ↓
Authenticated session
    ↓
Dashboard

Android must continue to work.

Test B — Chrome

Run:

flutter run -d chrome --web-port 3000

Expected:

Google Login
    ↓
Supabase OAuth
    ↓
Google login/consent
    ↓
Supabase callback
    ↓
http://localhost:3000
    ↓
Authenticated session
    ↓
Dashboard

There should NOT be:

google_sign_in_web
signIn()
popup_closed

as the Web authentication mechanism.

STEP 17 — TEST LOGIN / LOGOUT / LOGIN AGAIN

Test:

Login with Google.
Confirm authenticated state.
Logout.
Login again.
Confirm the session is recreated correctly.
Refresh the Web page.
Confirm the authenticated session persists correctly.
Close and reopen Chrome if applicable and verify expected session behavior.

Do not introduce behavior that breaks the existing Android login/logout flow.

STEP 18 — VERIFY THE EXACT CONFIGURATION

Before declaring the task complete, verify:

Supabase
Authentication
└── Providers
    └── Google
        ├── Enabled
        ├── Correct Web Client ID
        └── Correct Client Secret

and:

Authentication
└── URL Configuration
    ├── Existing mobile redirect URLs preserved
    └── http://localhost:3000/** added
Google Cloud
OAuth Client
└── Web application
    ├── Authorized JavaScript origins
    │   └── http://localhost:3000
    │
    └── Authorized redirect URIs
        └── Supabase Auth callback URL
Flutter
Web
└── Supabase OAuth
    └── signInWithOAuth(OAuthProvider.google)

Android
└── Existing native Google Sign-In
    └── signInWithIdToken(...)
IMPORTANT IMPLEMENTATION RULE

Do not blindly implement the architecture described above.

First:

Inspect the existing code.
Inspect current package versions.
Consult Context7.
Consult Supabase MCP.
Compare the current implementation against the current official documentation.
Make the smallest correct change.
Preserve working Android behavior.

The goal is NOT to rewrite authentication.

The goal is:

FIX WEB GOOGLE SIGN-IN
+
PRESERVE ANDROID GOOGLE SIGN-IN
+
FOLLOW CURRENT SUPABASE API
+
FOLLOW CURRENT GOOGLE OAUTH CONFIGURATION
FINAL REPORT

After implementation, provide a concise report containing:

1. Root Cause

Explain exactly why Google Sign-In failed on Web.

2. Code Changes

List the files modified and what changed.

3. Authentication Architecture

Show:

Android → google_sign_in → signInWithIdToken → Supabase

Web → signInWithOAuth → Google → Supabase → Flutter Web

if that is confirmed to be the final implementation.

4. Configuration Changes

List exactly what must exist in:

Google Cloud
Supabase Authentication → Providers → Google
Supabase Authentication → URL Configuration

Do not expose any secrets.

5. Testing

Report:

Android Google Login: PASS / FAIL
Web Google Login: PASS / FAIL
Logout: PASS / FAIL
Login Again: PASS / FAIL
Session Persistence: PASS / FAIL
6. Remaining Issues

If anything could not be verified because credentials, MCP access, or external configuration was unavailable, state it explicitly.

Do not claim the issue is fixed unless the implementation was actually tested.