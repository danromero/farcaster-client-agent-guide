# Credentials and placeholders

The public snapshot can be compiled locally, but it intentionally omits private
service configuration. Separate these milestones:

1. **Build:** native and JavaScript compilation succeed.
2. **Credential-free launch:** onboarding renders with expected integration
   warnings.
3. **Fully functional client:** sign-in, integrity-protected APIs, wallets,
   notifications, telemetry, and deployment services have valid configuration.

Never invent replacement values. Obtain them from the service/project owner.

## Required for credential-free launch

No Apple Developer credential is required for an iOS Simulator.

The committed `GoogleService-Info.plist` contains placeholders. Without a guard,
Firebase native initialization can terminate the process. Use the opt-in guard
for UI-only development, or supply a real plist for the app’s bundle identifier.

## Required for production-backed behavior

| Integration | Public placeholder | Needed for |
| --- | --- | --- |
| Firebase iOS | `apps/farcaster-mobile/ios/Farcaster/GoogleService-Info.plist` | Firebase initialization and App Check |
| Firebase App Check | `EXPO_PUBLIC_FIREBASE_APP_CHECK_DEBUG_TOKEN` | Simulator requests accepted by protected APIs |
| Primary Privy | `PRIMARY_PRIVY_APP_ID`, `PRIMARY_PRIVY_CLIENT_ID` | Primary embedded wallet |
| Secondary Privy | `SECONDARY_PRIVY_APP_ID`, `SECONDARY_PRIVY_CLIENT_ID` | Private/secondary embedded wallet |
| Alchemy | Base mainnet URL ending in `REPLACE_ME` | Alchemy-backed wallet/pay-user queries |

The App Check debug token must be registered with the corresponding Firebase
project. Merely placing an arbitrary value in `.env` does not work.

Expected warnings in credential-free mode include:

```text
No Firebase App '[DEFAULT]' has been created
Secondary Privy client init failed
Invalid Privy app ID
```

These warnings identify unavailable features. They are not proof that the
native build or Metro failed if onboarding is visible and the process remains
alive.

## Optional or workflow-specific configuration

| Integration | Placeholder | Required when |
| --- | --- | --- |
| Expo access | `EXPO_ACCESS_TOKEN` | EAS/cloud build, update, or project access |
| Expo Updates | project ID and update URL containing `REPLACE_ME` | OTA updates |
| Datadog | client token and application ID | Production telemetry |
| Apple team/app groups | `DEVELOPMENT_TEAM` and entitlement prefixes | Physical device signing, extensions, notifications |
| Android Firebase | `google-services.json` | Android builds using Firebase |

None of these are required to prove an iOS Simulator native build can render
the credential-free onboarding UI.

## Safe provisioning

- Store local Expo variables in `apps/farcaster-mobile/.env`; confirm it is
  ignored before writing it.
- Replace the Firebase plist only with a file downloaded for the exact Firebase
  project and bundle identifier.
- Prefer environment injection or untracked local configuration for service
  IDs when the upstream code supports it.
- Run `git status --short` before every commit.
- Do not include credential file contents in issue reports or `doctor.sh`
  output. The diagnostic scripts report only whether placeholders remain.
