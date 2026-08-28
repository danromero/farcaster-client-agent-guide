# Maintaining the guide

The upstream client is a one-way generated snapshot whose `main` branch may be
replaced wholesale. Revalidate this guide whenever its snapshot commit changes.

## Frozen release policy

The current decision and limitations are recorded in
[`RELEASE_STATUS.md`](../RELEASE_STATUS.md). A `FROZEN` release is not reopened
for an unbounded request to review it again. Reopen only for a trigger enumerated
in [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md), change the status to
`REOPENED`, and record the evidence that triggered the work.

Every new release must run the entire finite checklist. Targeted testing is
useful during a fix but cannot refreeze the release by itself.

## Refresh procedure

1. Clone the new upstream snapshot into a clean, non-synced path.
2. Record the commit and commit date.
3. Run this guide’s preflight without applying patches.
4. Compare these contracts:
   - root `.node-version` and `packageManager`;
   - root scripts and `build:packages` behavior;
   - `Brewfile`;
   - mobile `package.json` scripts;
   - `Podfile` and deployment target;
   - Firebase AppDelegate initialization;
   - Expo scheme, bundle ID, runtime version, and EAS placeholders;
   - Privy, App Check, Alchemy, Datadog, and signing placeholders.
5. Execute a complete clean iOS Simulator build.
6. Refresh only workarounds whose failure signatures still reproduce.
7. Update `guide-manifest.json` and the README verification statement.
8. Run all guide validations.
9. Complete every item in `RELEASE_CHECKLIST.md` and replace the release-status
   record with the new evidence and known limitations.

## Patch maintenance

The bundled patch is intentionally narrow and context-checked. If `git apply
--check` fails:

- do not weaken the check or use `--reject`;
- inspect whether upstream already handles placeholder Firebase options;
- reproduce the launch failure on the new snapshot;
- create a new minimal patch only if still required; and
- retain the upstream MIT attribution in `NOTICE`.

## Compatibility policy

Documentation should describe durable invariants. Scripts should derive target
versions and identifiers where possible. Snapshot-specific facts belong in the
manifest and patch metadata, not in the generic happy path.
