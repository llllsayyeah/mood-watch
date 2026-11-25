"""Generates MoodWatch.xcodeproj (project.pbxproj + shared scheme) from the MoodWatch/ folder.

Deterministic: run it again after adding/removing Swift files.

    python3 scripts/gen_project.py

No dependencies; writes OpenStep-format plist exactly like Xcode does.
"""
from __future__ import annotations

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_DIR_NAME = "MoodWatch"
BUNDLE_ID = "com.moodwatch.app"
DISPLAY_NAME = "Mood Watch"
DEPLOYMENT_TARGET = "16.0"
MARKETING_VERSION = "1.0.0"

FILE, BUILD, GROUP, PHASE, TARGET, CONFIG, CONFIGLIST, PROJECT, PRODUCT = (
    "1", "2", "3", "4", "5", "6", "7", "8", "9",
)
_ids: dict[str, int] = {}


def uid(kind: str, key: str) -> str:
    """Stable 24-hex-character id derived from kind + key."""
    slot = _ids.setdefault(kind + "\x00" + key, len(_ids) + 1)
    return f"{kind}{slot:023X}"


SAFE = re.compile(r"^[A-Za-z0-9_./$]+$")


def q(value: str) -> str:
    if SAFE.match(value):
        return value
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
    return f'"{escaped}"'


def collect_swift_files() -> list[str]:
    app_root = os.path.join(ROOT, APP_DIR_NAME)
    found = []
    for base, _dirs, files in os.walk(app_root):
        for name in sorted(files):
            if name.endswith(".swift"):
                rel = os.path.relpath(os.path.join(base, name), app_root)
                found.append(rel.replace(os.sep, "/"))
    return sorted(found)


SOURCES = collect_swift_files()
ASSET_CATALOGS = ["Assets.xcassets"]


def build_tree() -> dict:
    """Nested dict of folders -> files for the app folder."""
    tree: dict = {}
    for rel in SOURCES + ASSET_CATALOGS:
        parts = rel.split("/")
        node = tree
        for part in parts[:-1]:
            node = node.setdefault(part, {})
        node.setdefault("__files__", []).append(parts[-1])
    return tree


def group_lines(path_prefix: str, node: dict) -> list[str]:
    """Emit PBXGroup entries (children first, then the group itself).

    `path_prefix` is relative to the app folder; file ref ids use exactly the same keys as
    `SOURCES`, so children and definitions line up.
    """
    pad = "\t\t"
    out: list[str] = []
    child_ids: list[str] = []

    for folder in sorted(k for k in node if k != "__files__"):
        sub_prefix = f"{path_prefix}/{folder}" if path_prefix else folder
        out += group_lines(sub_prefix, node[folder])
        child_ids.append(uid(GROUP, sub_prefix))

    for filename in sorted(node.get("__files__", [])):
        rel = f"{path_prefix}/{filename}" if path_prefix else filename
        child_ids.append(uid(FILE, rel))

    gid = uid(GROUP, path_prefix or "__app__")
    label = path_prefix or APP_DIR_NAME
    out.append(f"{pad}{gid} /* {label} */ = {{")
    out.append(f"{pad}\tisa = PBXGroup;")
    out.append(f"{pad}\tchildren = (")
    for cid in child_ids:
        out.append(f"{pad}\t\t{cid},")
    out.append(f"{pad}\t);")
    group_path = APP_DIR_NAME if not path_prefix else path_prefix.split("/")[-1]
    out.append(f"{pad}\tpath = {q(group_path)};")
    out.append(f'{pad}\tsourceTree = "<group>";')
    out.append(f"{pad}}};")
    return out


def file_ref_line(rel: str) -> str:
    name = rel.split("/")[-1]
    fid = uid(FILE, rel)
    if name.endswith(".swift"):
        return f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(name)}; sourceTree = "<group>"; }};'
    if name.endswith(".xcassets"):
        return f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {q(name)}; sourceTree = "<group>"; }};'
    return f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text; path = {q(name)}; sourceTree = "<group>"; }};'


def settings_block(settings: dict, indent: str = "\t\t\t") -> list[str]:
    lines = []
    for key in sorted(settings):
        value = settings[key]
        if isinstance(value, list):
            inner = " ".join(q(v) for v in value)
            lines.append(f"{indent}{key} = ({inner});")
        else:
            lines.append(f"{indent}{key} = {q(str(value))};")
    return lines


def main() -> None:
    proj_name = "MoodWatch"
    target_id = uid(TARGET, proj_name)
    project_id = uid(PROJECT, proj_name)
    product_ref = uid(PRODUCT, proj_name)
    main_group = uid(GROUP, "__main__")
    products_group = uid(GROUP, "__products__")
    app_group = uid(GROUP, "__app__")
    sources_phase = uid(PHASE, "sources")
    frameworks_phase = uid(PHASE, "frameworks")
    resources_phase = uid(PHASE, "resources")
    target_cfg_list = uid(CONFIGLIST, "target")
    project_cfg_list = uid(CONFIGLIST, "project")
    debug_target = uid(CONFIG, "target-debug")
    release_target = uid(CONFIG, "target-release")
    debug_project = uid(CONFIG, "project-debug")
    release_project = uid(CONFIG, "project-release")

    tree = build_tree()
    app_group_lines = group_lines("", tree)
    app_group_id = uid(GROUP, "__app__")

    out: list[str] = []
    out.append("// !$*UTF8*$!")
    out.append("{")
    out.append("\tarchiveVersion = 1;")
    out.append("\tclasses = {")
    out.append("\t};")
    out.append("\tobjectVersion = 56;")
    out.append("\tobjects = {")
    out.append("")
    out.append("/* Begin PBXBuildFile section */")
    for rel in SOURCES:
        name = rel.split("/")[-1]
        bid = uid(BUILD, rel)
        fid = uid(FILE, rel)
        out.append(
            f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};"
        )
    for rel in ASSET_CATALOGS:
        bid = uid(BUILD, rel)
        fid = uid(FILE, rel)
        out.append(
            f"\t\t{bid} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {fid} /* Assets.xcassets */; }};"
        )
    out.append("/* End PBXBuildFile section */")
    out.append("")

    out.append("/* Begin PBXFileReference section */")
    for rel in SOURCES + ASSET_CATALOGS:
        out.append(file_ref_line(rel))
    out.append(
        f'\t\t{product_ref} /* {proj_name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {proj_name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )
    out.append("/* End PBXFileReference section */")
    out.append("")

    out.append("/* Begin PBXFrameworksBuildPhase section */")
    out.append(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    out.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    out.append("\t\t\tbuildActionMask = 2147483647;")
    out.append("\t\t\tfiles = (")
    out.append("\t\t\t);")
    out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    out.append("\t\t};")
    out.append("/* End PBXFrameworksBuildPhase section */")
    out.append("")

    out.append("/* Begin PBXGroup section */")
    out.append(f"\t\t{main_group} = {{")
    out.append("\t\t\tisa = PBXGroup;")
    out.append("\t\t\tchildren = (")
    out.append(f"\t\t\t\t{app_group_id} /* {APP_DIR_NAME} */,")
    out.append(f"\t\t\t\t{products_group} /* Products */,")
    out.append("\t\t\t);")
    out.append('\t\t\tsourceTree = "<group>";')
    out.append("\t\t};")
    out.append("")
    for line in app_group_lines:
        out.append(line)
    out.append("")
    out.append(f"\t\t{products_group} /* Products */ = {{")
    out.append("\t\t\tisa = PBXGroup;")
    out.append("\t\t\tchildren = (")
    out.append(f"\t\t\t\t{product_ref} /* {proj_name}.app */,")
    out.append("\t\t\t);")
    out.append("\t\t\tname = Products;")
    out.append('\t\t\tsourceTree = "<group>";')
    out.append("\t\t};")
    out.append("/* End PBXGroup section */")
    out.append("")

    out.append("/* Begin PBXNativeTarget section */")
    out.append(f"\t\t{target_id} /* {proj_name} */ = {{")
    out.append("\t\t\tisa = PBXNativeTarget;")
    out.append(f"\t\t\tbuildConfigurationList = {target_cfg_list} /* Build configuration list for PBXNativeTarget \"{proj_name}\" */;")
    out.append("\t\t\tbuildPhases = (")
    out.append(f"\t\t\t\t{sources_phase} /* Sources */,")
    out.append(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    out.append(f"\t\t\t\t{resources_phase} /* Resources */,")
    out.append("\t\t\t);")
    out.append("\t\t\tbuildRules = (")
    out.append("\t\t\t);")
    out.append("\t\t\tdependencies = (")
    out.append("\t\t\t);")
    out.append(f"\t\t\tname = {proj_name};")
    out.append(f"\t\t\tproductName = {proj_name};")
    out.append(f"\t\t\tproductReference = {product_ref} /* {proj_name}.app */;")
    out.append('\t\t\tproductType = "com.apple.product-type.application";')
    out.append("\t\t};")
    out.append("/* End PBXNativeTarget section */")
    out.append("")

    out.append("/* Begin PBXProject section */")
    out.append(f"\t\t{project_id} /* Project object */ = {{")
    out.append("\t\t\tisa = PBXProject;")
    out.append("\t\t\tattributes = {")
    out.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    out.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    out.append("\t\t\t\tLastUpgradeCheck = 1500;")
    out.append("\t\t\t\tTargetAttributes = {")
    out.append(f"\t\t\t\t\t{target_id} = {{")
    out.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    out.append("\t\t\t\t\t};")
    out.append("\t\t\t\t};")
    out.append("\t\t\t};")
    out.append(f"\t\t\tbuildConfigurationList = {project_cfg_list} /* Build configuration list for PBXProject \"{proj_name}\" */;")
    out.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    out.append("\t\t\tdevelopmentRegion = en;")
    out.append("\t\t\thasScannedForEncodings = 0;")
    out.append("\t\t\tknownRegions = (")
    out.append("\t\t\t\ten,")
    out.append("\t\t\t\tBase,")
    out.append("\t\t\t\t\"zh-Hans\",")
    out.append("\t\t\t);")
    out.append(f"\t\t\tmainGroup = {main_group};")
    out.append(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    out.append('\t\t\tprojectDirPath = "";')
    out.append('\t\t\tprojectRoot = "";')
    out.append("\t\t\ttargets = (")
    out.append(f"\t\t\t\t{target_id} /* {proj_name} */,")
    out.append("\t\t\t);")
    out.append("\t\t};")
    out.append("/* End PBXProject section */")
    out.append("")

    out.append("/* Begin PBXResourcesBuildPhase section */")
    out.append(f"\t\t{resources_phase} /* Resources */ = {{")
    out.append("\t\t\tisa = PBXResourcesBuildPhase;")
    out.append("\t\t\tbuildActionMask = 2147483647;")
    out.append("\t\t\tfiles = (")
    for rel in ASSET_CATALOGS:
        bid = uid(BUILD, rel)
        out.append(f"\t\t\t\t{bid} /* Assets.xcassets in Resources */,")
    out.append("\t\t\t);")
    out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    out.append("\t\t};")
    out.append("/* End PBXResourcesBuildPhase section */")
    out.append("")

    out.append("/* Begin PBXSourcesBuildPhase section */")
    out.append(f"\t\t{sources_phase} /* Sources */ = {{")
    out.append("\t\t\tisa = PBXSourcesBuildPhase;")
    out.append("\t\t\tbuildActionMask = 2147483647;")
    out.append("\t\t\tfiles = (")
    for rel in SOURCES:
        bid = uid(BUILD, rel)
        name = rel.split("/")[-1]
        out.append(f"\t\t\t\t{bid} /* {name} in Sources */,")
    out.append("\t\t\t);")
    out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    out.append("\t\t};")
    out.append("/* End PBXSourcesBuildPhase section */")
    out.append("")

    project_common = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
    }

    target_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_CFBundleDisplayName": DISPLAY_NAME,
        "INFOPLIST_KEY_NSHealthShareUsageDescription": "Mood Watch 读取心率变异性与静息心率，用于计算你的每日压力状态。数据只保存在本机。",
        "INFOPLIST_KEY_NSHealthUpdateUsageDescription": "Mood Watch 不会写入健康数据，仅在授权后读取。",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
        "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
        "MARKETING_VERSION": MARKETING_VERSION,
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }

    out.append("/* Begin XCBuildConfiguration section */")
    for cid, name, settings in [
        (debug_project, "Debug", project_common),
        (release_project, "Release", project_common),
        (debug_target, "Debug", target_settings),
        (release_target, "Release", target_settings),
    ]:
        out.append(f"\t\t{cid} /* {name} */ = {{")
        out.append("\t\t\tisa = XCBuildConfiguration;")
        out.append("\t\t\tbuildSettings = {")
        out += settings_block(settings)
        out.append("\t\t\t};")
        out.append(f"\t\t\tname = {name};")
        out.append("\t\t};")
    out.append("/* End XCBuildConfiguration section */")
    out.append("")

    out.append("/* Begin XCConfigurationList section */")
    for lid, cfg_debug, cfg_release, label in [
        (project_cfg_list, debug_project, release_project, f'Build configuration list for PBXProject "{proj_name}"'),
        (target_cfg_list, debug_target, release_target, f'Build configuration list for PBXNativeTarget "{proj_name}"'),
    ]:
        out.append(f"\t\t{lid} /* {label} */ = {{")
        out.append("\t\t\tisa = XCConfigurationList;")
        out.append("\t\t\tbuildConfigurations = (")
        out.append(f"\t\t\t\t{cfg_debug} /* Debug */,")
        out.append(f"\t\t\t\t{cfg_release} /* Release */,")
        out.append("\t\t\t);")
        out.append("\t\t\tdefaultConfigurationIsVisible = 0;")
        out.append("\t\t\tdefaultConfigurationName = Release;")
        out.append("\t\t};")
    out.append("/* End XCConfigurationList section */")
    out.append("")
    out.append("\t};")
    out.append(f"\trootObject = {project_id} /* Project object */;")
    out.append("}")

    proj_dir = os.path.join(ROOT, "MoodWatch.xcodeproj")
    os.makedirs(os.path.join(proj_dir, "xcshareddata", "xcschemes"), exist_ok=True)
    with open(os.path.join(proj_dir, "project.pbxproj"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")

    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{proj_name}.app"
               BlueprintName = "{proj_name}"
               ReferencedContainer = "container:{proj_name}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{proj_name}.app"
            BlueprintName = "{proj_name}"
            ReferencedContainer = "container:{proj_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{proj_name}.app"
            BlueprintName = "{proj_name}"
            ReferencedContainer = "container:{proj_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    with open(os.path.join(proj_dir, "xcshareddata", "xcschemes", f"{proj_name}.xcscheme"), "w", encoding="utf-8", newline="\n") as f:
        f.write(scheme)

    print(f"wrote {proj_name}.xcodeproj with {len(SOURCES)} Swift files")


if __name__ == "__main__":
    main()
