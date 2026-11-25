"""Sanity checks for the generated Xcode project and the Swift sources.

    python3 scripts/validate.py
"""
from __future__ import annotations

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, "MoodWatch.xcodeproj", "project.pbxproj")
ID_RE = re.compile(r"\b[0-9A-F]{24}\b")
DEF_RE = re.compile(r"^\t\t([0-9A-F]{24})(?: /\*.*?\*/)? = \{", re.M)

errors: list[str] = []
warnings: list[str] = []


def check_pbxproj() -> None:
    text = open(PBX, encoding="utf-8").read()
    if text.count("{") != text.count("}"):
        errors.append(f"pbxproj braces unbalanced: {text.count('{')} vs {text.count('}')}")
    if text.count("(") != text.count(")"):
        errors.append(f"pbxproj parens unbalanced: {text.count('(')} vs {text.count(')')}")

    defined = set(DEF_RE.findall(text))
    used = set(ID_RE.findall(text))
    missing = used - defined
    if missing:
        errors.append(f"pbxproj references undefined ids: {sorted(missing)}")

    # every id must appear at least twice (definition + one reference)
    for i in defined:
        if text.count(i) < 2:
            warnings.append(f"id {i} defined but never referenced")

    for section in [
        "PBXBuildFile", "PBXFileReference", "PBXFrameworksBuildPhase", "PBXGroup",
        "PBXNativeTarget", "PBXProject", "PBXResourcesBuildPhase", "PBXSourcesBuildPhase",
        "XCBuildConfiguration", "XCConfigurationList",
    ]:
        if f"/* Begin {section} section */" not in text:
            errors.append(f"missing section {section}")

    if "rootObject = " not in text:
        errors.append("missing rootObject")

    # the app group must contain every swift file ref
    for base, _dirs, files in os.walk(os.path.join(ROOT, "MoodWatch")):
        for name in files:
            if name.endswith(".swift"):
                if f"/* {name} */" not in text:
                    errors.append(f"swift file not referenced in project: {name}")


def strip_swift(source: str) -> str:
    """Crude removal of strings and comments so brace counting is meaningful."""
    out = []
    i = 0
    n = len(source)
    while i < n:
        ch = source[i]
        if ch == "/" and i + 1 < n and source[i + 1] == "/":
            j = source.find("\n", i)
            i = n if j == -1 else j
        elif ch == "/" and i + 1 < n and source[i + 1] == "*":
            j = source.find("*/", i)
            i = n if j == -1 else j + 2
        elif ch == '"':
            # triple-quoted or single-line string
            if source.startswith('"""', i):
                j = source.find('"""', i + 3)
                i = n if j == -1 else j + 3
            else:
                i += 1
                while i < n:
                    if source[i] == "\\":
                        i += 2
                        continue
                    if source[i] == '"' or source[i] == "\n":
                        i += 1
                        break
                    i += 1
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def check_swift() -> None:
    app = os.path.join(ROOT, "MoodWatch")
    count = 0
    for base, _dirs, files in os.walk(app):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            count += 1
            path = os.path.join(base, name)
            src = open(path, encoding="utf-8").read()
            clean = strip_swift(src)
            if clean.count("{") != clean.count("}"):
                errors.append(f"{name}: braces {clean.count('{')} vs {clean.count('}')}")
            if clean.count("(") != clean.count(")"):
                errors.append(f"{name}: parens {clean.count('(')} vs {clean.count(')')}")
            if "import SwiftUI" not in src and "import Foundation" not in src:
                warnings.append(f"{name}: no SwiftUI/Foundation import")
    print(f"scanned {count} Swift files")


def check_assets() -> None:
    for rel in ["Assets.xcassets/Contents.json", "Assets.xcassets/AppIcon.appiconset/Contents.json",
                "Assets.xcassets/AppIcon.appiconset/AppIcon.png",
                "Assets.xcassets/AccentColor.colorset/Contents.json"]:
        if not os.path.exists(os.path.join(ROOT, "MoodWatch", rel)):
            errors.append(f"missing asset: {rel}")


def main() -> int:
    check_pbxproj()
    check_swift()
    check_assets()
    for w in warnings:
        print("WARN:", w)
    for e in errors:
        print("ERROR:", e)
    if errors:
        print(f"\n{len(errors)} error(s)")
        return 1
    print("\nall checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
