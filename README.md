# Farcaster Client Agent Guide

An independent, agent-first runbook for getting the public
[`farcasterxyz/client`](https://github.com/farcasterxyz/client) snapshot running
in an iOS Simulator.

This repository is deliberately separate from the client. It contains focused
documentation, diagnostics, and opt-in compatibility patches so a coding agent
can follow a reproducible path without loading one enormous setup document or
rediscovering known failure modes.

Use this guide when the immediate goal is narrow and concrete: take a public
client checkout on macOS from preflight to visibly running Farcaster onboarding
in an iOS Simulator. It is strongest at diagnosing host setup, keeping the
client's toolchain pinned, applying the credential-free launch guard safely,
and proving that the current checkout—not a stale app or another Metro
process—produced the screen in the simulator.

It does not turn the public snapshot into a fully configured production client.
Treat authenticated features and protected integrations as a separate,
credentialed milestone.

> [!IMPORTANT]
> This is a community guide, not an official Farcaster or Neynar repository.
> The upstream snapshot changes over time; always run the preflight checks before
> applying a documented workaround.

## Give this to an agent

Clone this guide next to the client checkout. The resulting layout matters:

```text
workspace/
├── client/                         # target application; agents may modify it
└── farcaster-client-agent-guide/  # control repo; start the agent here
```

Create that layout:

```bash
git clone https://github.com/farcasterxyz/client.git
git clone https://github.com/danromero/farcaster-client-agent-guide.git
cd farcaster-client-agent-guide
./scripts/preflight.sh ../client
```

Start the agent with `farcaster-client-agent-guide` as its project/current
directory, then give it this instruction:

```text
Get the Farcaster client at ../client running in an iOS Simulator. Follow the
AGENTS.md and guide-manifest.json in this repository. Run preflight first, load
only the relevant linked docs, do not invent credentials, and verify every
completion checkpoint. The target outcome is visible Farcaster onboarding from
the current checkout; expected missing-credential warnings are not themselves
launch failures.
```

Codex discovers [`AGENTS.md`](AGENTS.md) from the project root down to its current
directory. It will therefore load this guide automatically only when the agent
starts in this guide repository. If the agent is already running from the client
checkout, explicitly tell it to read the guide's `AGENTS.md`; a sibling repo is
not in its automatic instruction-discovery path. Other agents can use the same
file as their explicit entrypoint.

## Human quick start

The shortest supported path is in [`docs/QUICKSTART.md`](docs/QUICKSTART.md).
For a first setup, run preflight and bootstrap first:

```bash
./scripts/preflight.sh ../client
./scripts/bootstrap-ios.sh ../client --apply-placeholder-guard
```

Then use two terminals because the launch command normally keeps Metro in the
foreground:

```bash
# Terminal A — leave this running
./scripts/start-ios.sh ../client --build

# Terminal B — after an iOS bundle completes and the app renders
./scripts/verify-ios.sh ../client
```

The first verification captures a screenshot and exits `2` until a person or
vision-capable agent inspects it. If it shows Farcaster onboarding, rerun with
`--visual-status onboarding`; for an authenticated screen, use
`--visual-status authenticated`. Exit `0` completes runtime verification, but
the final handoff must also include the successful bootstrap, native-build, and
`iOS Bundled` evidence from this run; the verifier cannot reconstruct old
terminal output.

The placeholder guard is an explicit, reviewable source patch that allows the
public snapshot to launch without a real Firebase plist. It does not make
credential-gated features work.

## Documentation map

| Need | Load this file |
| --- | --- |
| Minimal first run | [`docs/QUICKSTART.md`](docs/QUICKSTART.md) |
| Full iOS procedure | [`docs/IOS_SIMULATOR.md`](docs/IOS_SIMULATOR.md) |
| Credential boundaries | [`docs/CREDENTIALS.md`](docs/CREDENTIALS.md) |
| Known failure signatures | [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) |
| Completion criteria | [`docs/VERIFICATION.md`](docs/VERIFICATION.md) |
| Agent execution policy | [`docs/AGENT_WORKFLOW.md`](docs/AGENT_WORKFLOW.md) |
| Updating this guide | [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md) |
| Finite release acceptance | [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md) |
| Current coverage and limitations | [`RELEASE_STATUS.md`](RELEASE_STATUS.md) |

## Design principles

- Derive versions from the target checkout instead of hardcoding them.
- Treat launch success and production-feature access as different milestones.
- Diagnose before modifying the client.
- Make compatibility patches opt-in and version-checked.
- Keep secrets out of logs, commits, and agent transcripts.
- Record expected output at expensive checkpoints so work is not repeated.

## Scope

The current guide covers macOS and the iOS Simulator. Physical devices,
production signing, Android, EAS builds, releases, and backend development are
outside the verified path.

The guide was last verified against upstream commit
`b6922e24036cac6f5e6d51904a59ff7cfcdd8483` from August 26, 2026. Scripts check
the target dynamically and should remain useful across later snapshots, while
the optional patch may need refreshing.

## License

Guide code and documentation are available under the [MIT License](LICENSE).
See [`NOTICE`](NOTICE) for upstream attribution.
