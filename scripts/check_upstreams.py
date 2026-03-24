#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_core(root: Path) -> tuple[str, str, str]:
    text = read_text(root / "repo/packages/y/ygopro-core/xmake.lua")
    ver = re.search(r'add_versions\("([^"]+)",\s*"([0-9a-f]{40})"\)', text)
    url = re.search(r'add_urls\("([^"]+)"\)', text)
    if not ver or not url:
        raise RuntimeError("Could not parse ygopro-core pin")
    return url.group(1), ver.group(1), ver.group(2)


def parse_scripts(root: Path) -> tuple[str, str]:
    text = read_text(root / "Makefile")
    repo = re.search(r"^SCRIPTS_REPO\s*:=\s*(\S+)", text, re.MULTILINE)
    ref = re.search(r"^SCRIPTS_REF\s*:=\s*([0-9a-f]{40})", text, re.MULTILINE)
    if not repo or not ref:
        raise RuntimeError("Could not parse ygopro-scripts pin")
    return repo.group(1), ref.group(1)


def ls_remote_head(url: str) -> str:
    out = subprocess.check_output(
        ["git", "ls-remote", url, "HEAD"],
        text=True,
    ).strip()
    return out.split()[0]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Show pinned ygopro-core and ygopro-scripts revisions, optionally compare with upstream HEAD."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Adapter repo root (default: parent of this script).",
    )
    parser.add_argument(
        "--check-remote",
        action="store_true",
        help="Query upstream HEAD commits with git ls-remote.",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    core_url, core_ver, core_ref = parse_core(root)
    scripts_url, scripts_ref = parse_scripts(root)

    print(f"root: {root}")
    print(f"ygopro-core   version={core_ver} pinned={core_ref} repo={core_url}")
    print(f"ygopro-scripts pinned={scripts_ref} repo={scripts_url}")

    if not args.check_remote:
        return 0

    core_head = ls_remote_head(core_url)
    scripts_head = ls_remote_head(scripts_url)
    print(f"ygopro-core   upstream_head={core_head} status={'up-to-date' if core_head == core_ref else 'update-available'}")
    print(f"ygopro-scripts upstream_head={scripts_head} status={'up-to-date' if scripts_head == scripts_ref else 'update-available'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
