# Contributing

Contributions should make the verified path shorter, safer, or easier to
diagnose across machines.

The guide may be frozen. Before proposing a change, read `RELEASE_STATUS.md` and
identify a valid reopen trigger from `docs/RELEASE_CHECKLIST.md`. Open-ended
polish without new evidence is intentionally deferred.

## Before opening a pull request

```bash
python3 scripts/validate-guide.py
bash -n scripts/*.sh scripts/lib/*.sh scripts/shims/*
shellcheck -x scripts/*.sh scripts/lib/*.sh scripts/shims/*
```

When changing a workaround, include:

- the upstream commit tested;
- the exact failure signature;
- a read-only diagnostic that identifies the condition;
- the smallest safe remedy; and
- evidence for the completion checkpoint.

Do not submit credentials, production identifiers, signing material, or logs
that may contain them.
