#!/usr/bin/env python3
"""Validate the guide's structure, local Markdown links, JSON, and shell syntax."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parent.parent
REQUIRED = [
    "README.md",
    "AGENTS.md",
    "RELEASE_STATUS.md",
    "guide-manifest.json",
    "docs/QUICKSTART.md",
    "docs/IOS_SIMULATOR.md",
    "docs/CREDENTIALS.md",
    "docs/TROUBLESHOOTING.md",
    "docs/VERIFICATION.md",
    "docs/RELEASE_CHECKLIST.md",
    "scripts/preflight.sh",
    "scripts/bootstrap-ios.sh",
    "scripts/shims/pnpm",
    "scripts/start-ios.sh",
    "scripts/verify-ios.sh",
]
LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
SECRET_PATTERNS = {
    "GitHub token": re.compile(r"gh[opsu]_[A-Za-z0-9]{20,}"),
    "OpenAI-style secret": re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    "Google API key": re.compile(r"AIza[A-Za-z0-9_-]{20,}"),
    "private key": re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
}


def error(message: str) -> None:
    print(f"ERROR {message}")


def validate_required() -> int:
    failures = 0
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            error(f"missing required file: {relative}")
            failures += 1
    return failures


def validate_manifest() -> int:
    try:
        manifest = json.loads((ROOT / "guide-manifest.json").read_text())
    except (OSError, json.JSONDecodeError) as exc:
        error(f"invalid guide-manifest.json: {exc}")
        return 1
    failures = 0
    if manifest.get("schema_version") != 1:
        error("guide-manifest.json schema_version must be 1")
        failures += 1

    for section in ("entrypoints", "progressive_docs"):
        entries = manifest.get(section)
        if not isinstance(entries, dict) or not entries:
            error(f"guide-manifest.json {section} must be a non-empty object")
            failures += 1
            continue
        for name, relative in entries.items():
            if not isinstance(relative, str) or not (ROOT / relative).is_file():
                error(f"guide-manifest.json {section}.{name} is not an existing file: {relative}")
                failures += 1

    exit_codes = manifest.get("verification_exit_codes", {})
    if set(exit_codes) != {"0", "1", "2"}:
        error("guide-manifest.json verification_exit_codes must define 0, 1, and 2")
        failures += 1

    release_control = manifest.get("release_control", {})
    if release_control.get("state") not in {"FROZEN", "REOPENED"}:
        error("guide-manifest.json release_control.state must be FROZEN or REOPENED")
        failures += 1
    for name in ("status", "checklist"):
        relative = release_control.get(name)
        if not isinstance(relative, str) or not (ROOT / relative).is_file():
            error(f"guide-manifest.json release_control.{name} is not an existing file: {relative}")
            failures += 1

    try:
        release_status = (ROOT / "RELEASE_STATUS.md").read_text(encoding="utf-8")
    except OSError as exc:
        error(f"cannot read RELEASE_STATUS.md: {exc}")
        failures += 1
    else:
        expected_state = release_control.get("state")
        if f"**State:** `{expected_state}`" not in release_status:
            error("RELEASE_STATUS.md state does not match guide-manifest.json")
            failures += 1
        upstream = manifest.get("verified_upstream", {}).get("commit")
        if not isinstance(upstream, str) or upstream not in release_status:
            error("RELEASE_STATUS.md does not contain the verified upstream commit")
            failures += 1
        checklist_ids = set(re.findall(r"RC-(\d{2})", (ROOT / "docs/RELEASE_CHECKLIST.md").read_text()))
        expected_ids = {f"{number:02d}" for number in range(1, 28)}
        if checklist_ids != expected_ids:
            error("release checklist must define exactly RC-01 through RC-27")
            failures += 1

    return failures


def validate_links() -> int:
    failures = 0
    for markdown in ROOT.rglob("*.md"):
        text = markdown.read_text(encoding="utf-8")
        for raw_target in LINK_RE.findall(text):
            target = raw_target.strip().strip("<>")
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            relative = unquote(target.split("#", 1)[0])
            if not relative:
                continue
            resolved = (markdown.parent / relative).resolve()
            if not resolved.exists():
                error(f"broken local link in {markdown.relative_to(ROOT)}: {target}")
                failures += 1
    return failures


def validate_secrets() -> int:
    failures = 0
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                error(f"possible {label} in {path.relative_to(ROOT)}")
                failures += 1
    return failures


def validate_shell() -> int:
    scripts = sorted((ROOT / "scripts").glob("*.sh")) + sorted(
        (ROOT / "scripts" / "lib").glob("*.sh")
    ) + [ROOT / "scripts" / "shims" / "pnpm"]
    result = subprocess.run(["bash", "-n", *map(str, scripts)], check=False)
    if result.returncode:
        error("bash syntax validation failed")
        return 1
    failures = 0
    for script in scripts:
        if not os.access(script, os.X_OK):
            error(f"script is not executable: {script.relative_to(ROOT)}")
            failures += 1
    return failures


def main() -> int:
    failures = sum(
        (
            validate_required(),
            validate_manifest(),
            validate_links(),
            validate_secrets(),
            validate_shell(),
        )
    )
    if failures:
        print(f"Guide validation failed with {failures} issue(s).")
        return 1
    print("Guide validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
