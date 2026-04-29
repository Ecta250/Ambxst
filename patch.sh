#!/usr/bin/env bash
# patch.sh — idempotent local ambxst overrides, re-runnable after every upstream update.
#
# Changes applied:
#   1. Wallpaper.qml      — export current wallpaper as ~/bg.png on every change.
#   2. GlobalStates.qml   — add `launcherCategoryFilter` global property.
#   3. LauncherView.qml   — filter launcher results by category when filter is set.
#   4. GlobalShortcuts.qml — IPC `launcher-category:<Name>` opens launcher filtered.
#
# Each patch is wrapped in `// AMBXST_*_PATCH START` / `END` markers so re-running
# refreshes the embedded payload in place even if the script's content evolves.
#
# Usage: ./patch.sh            (from the ambxst project root)

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d "$here/modules" ]]; then
    echo "patch.sh: $here doesn't look like the ambxst project root." >&2
    exit 1
fi

python3 - "$here" <<'PY'
import pathlib, sys

here = pathlib.Path(sys.argv[1])

PATCHES = [
    {
        "file": "modules/widgets/dashboard/wallpapers/Wallpaper.qml",
        "marker": "AMBXST_BGPNG_PATCH",
        "original": (
            "    onCurrentWallpaperChanged:\n"
            "    // Matugen se ejecuta manualmente en las funciones de cambio\n"
            "    {}"
        ),
        "patched": (
            "    // AMBXST_BGPNG_PATCH START — exports current wallpaper as ~/bg.png\n"
            "    onCurrentWallpaperChanged: {\n"
            "        if (currentWallpaper && GlobalStates.wallpaperManager === wallpaper) {\n"
            '            exportBgPngProcess.command = ["bash", "-c", '
            '"ffmpeg -y -loglevel error -i \\"$1\\" -frames:v 1 \\"$HOME/bg.png\\" </dev/null", '
            '"_", currentWallpaper];\n'
            "            exportBgPngProcess.running = true;\n"
            "        }\n"
            "    }\n"
            "\n"
            "    Process {\n"
            "        id: exportBgPngProcess\n"
            "        running: false\n"
            "    }\n"
            "    // AMBXST_BGPNG_PATCH END"
        ),
    },
    {
        "file": "modules/globals/GlobalStates.qml",
        "marker": "AMBXST_CAT_STATE_PATCH",
        "original": (
            '    property string launcherSearchText: ""\n'
            '    property int launcherSelectedIndex: -1\n'
            '    property int launcherCurrentTab: 0'
        ),
        "patched": (
            '    property string launcherSearchText: ""\n'
            '    property int launcherSelectedIndex: -1\n'
            '    property int launcherCurrentTab: 0\n'
            '\n'
            '    // AMBXST_CAT_STATE_PATCH START — category filter for launcher\n'
            '    property string launcherCategoryFilter: ""\n'
            '    // AMBXST_CAT_STATE_PATCH END'
        ),
    },
    {
        "file": "modules/widgets/launcher/LauncherView.qml",
        "marker": "AMBXST_CAT_PROP_PATCH",
        "original": (
            "        // Animated model for smooth filtering\n"
            "        property var filteredApps: []\n"
            "        property var appsById: ({})"
        ),
        "patched": (
            "        // Animated model for smooth filtering\n"
            "        property var filteredApps: []\n"
            "        property var appsById: ({})\n"
            "\n"
            "        // AMBXST_CAT_PROP_PATCH START — category-filter state + auto-clear on close\n"
            "        property string categoryFilter: GlobalStates.launcherCategoryFilter\n"
            "        onCategoryFilterChanged: updateFilteredApps()\n"
            "\n"
            "        Connections {\n"
            "            target: Visibilities\n"
            "            function onCurrentActiveModuleChanged() {\n"
            '                if (Visibilities.currentActiveModule !== "launcher") {\n'
            '                    GlobalStates.launcherCategoryFilter = "";\n'
            "                }\n"
            "            }\n"
            "        }\n"
            "        // AMBXST_CAT_PROP_PATCH END"
        ),
    },
    {
        "file": "modules/widgets/launcher/LauncherView.qml",
        "marker": "AMBXST_CAT_FILTER_PATCH",
        "original": (
            "        function updateFilteredApps() {\n"
            "            if (searchText.length > 0) {\n"
            "                filteredApps = AppSearch.fuzzyQuery(searchText);\n"
            "            } else {\n"
            "                filteredApps = AppSearch.getAllApps();\n"
            "            }\n"
            "        }"
        ),
        "patched": (
            "        // AMBXST_CAT_FILTER_PATCH START — applies categoryFilter to results\n"
            "        function updateFilteredApps() {\n"
            "            let apps;\n"
            "            if (searchText.length > 0) {\n"
            "                apps = AppSearch.fuzzyQuery(searchText);\n"
            "            } else {\n"
            "                apps = AppSearch.getAllApps();\n"
            "            }\n"
            "            if (categoryFilter && categoryFilter.length > 0) {\n"
            "                apps = apps.filter(function (a) { return a.categories && a.categories.indexOf(categoryFilter) !== -1; });\n"
            "            }\n"
            "            filteredApps = apps;\n"
            "        }\n"
            "        // AMBXST_CAT_FILTER_PATCH END"
        ),
    },
    {
        "file": "modules/services/GlobalShortcuts.qml",
        "marker": "AMBXST_CAT_RUN_PATCH",
        "original": (
            '    function run(command) {\n'
            '        console.log("IPC run command received:", command);\n'
            '        switch (command) {'
        ),
        "patched": (
            '    function run(command) {\n'
            '        console.log("IPC run command received:", command);\n'
            '        // AMBXST_CAT_RUN_PATCH START — launcher-category:<Name> IPC\n'
            '        if (command && command.indexOf("launcher-category:") === 0) {\n'
            '            toggleLauncherWithCategory(command.substring("launcher-category:".length));\n'
            '            return;\n'
            '        }\n'
            '        // AMBXST_CAT_RUN_PATCH END\n'
            '        switch (command) {'
        ),
    },
    {
        "file": "modules/services/GlobalShortcuts.qml",
        "marker": "AMBXST_CAT_FN_PATCH",
        "original": (
            '    function toggleLauncherWithPrefix(tabIndex, prefix) {\n'
            '        const isActive = Visibilities.currentActiveModule === "launcher";\n'
            '        const currentTab = GlobalStates.widgetsTabCurrentIndex;\n'
            '        const currentText = GlobalStates.launcherSearchText;\n'
            '\n'
            '        if (isActive && currentTab === tabIndex && (currentText === prefix || currentText === "")) {\n'
            '            Visibilities.setActiveModule("");\n'
            '            GlobalStates.clearLauncherState();\n'
            '            return;\n'
            '        }\n'
            '\n'
            '        GlobalStates.widgetsTabCurrentIndex = tabIndex;\n'
            '        GlobalStates.launcherSearchText = prefix;\n'
            '        \n'
            '        if (!isActive) {\n'
            '            Visibilities.setActiveModule("launcher");\n'
            '        }\n'
            '    }'
        ),
        "patched": (
            '    function toggleLauncherWithPrefix(tabIndex, prefix) {\n'
            '        const isActive = Visibilities.currentActiveModule === "launcher";\n'
            '        const currentTab = GlobalStates.widgetsTabCurrentIndex;\n'
            '        const currentText = GlobalStates.launcherSearchText;\n'
            '\n'
            '        if (isActive && currentTab === tabIndex && (currentText === prefix || currentText === "")) {\n'
            '            Visibilities.setActiveModule("");\n'
            '            GlobalStates.clearLauncherState();\n'
            '            return;\n'
            '        }\n'
            '\n'
            '        GlobalStates.widgetsTabCurrentIndex = tabIndex;\n'
            '        GlobalStates.launcherSearchText = prefix;\n'
            '        \n'
            '        if (!isActive) {\n'
            '            Visibilities.setActiveModule("launcher");\n'
            '        }\n'
            '    }\n'
            '\n'
            '    // AMBXST_CAT_FN_PATCH START — open launcher filtered to a category\n'
            '    function toggleLauncherWithCategory(category) {\n'
            '        const isActive = Visibilities.currentActiveModule === "launcher";\n'
            '        const currentCategory = GlobalStates.launcherCategoryFilter;\n'
            '        if (isActive && currentCategory === category && GlobalStates.widgetsTabCurrentIndex === 0 && GlobalStates.launcherSearchText === "") {\n'
            '            Visibilities.setActiveModule("");\n'
            '            return;\n'
            '        }\n'
            '        GlobalStates.widgetsTabCurrentIndex = 0;\n'
            '        GlobalStates.launcherSearchText = "";\n'
            '        GlobalStates.launcherSelectedIndex = -1;\n'
            '        GlobalStates.launcherCategoryFilter = category;\n'
            '        if (!isActive) {\n'
            '            Visibilities.setActiveModule("launcher");\n'
            '        }\n'
            '    }\n'
            '    // AMBXST_CAT_FN_PATCH END'
        ),
    },
]


def apply_patch(root, patch):
    path = root / patch["file"]
    if not path.exists():
        raise SystemExit(f"patch.sh: {path} not found")
    text = path.read_text()
    marker = patch["marker"]
    start = f"// {marker} START"
    end = f"// {marker} END"
    # The marker block as it should appear in the desired output.
    p_s = patch["patched"].index(start)
    p_e = patch["patched"].index(end, p_s) + len(end)
    desired_block = patch["patched"][p_s:p_e]
    if start in text and end in text:
        s = text.index(start)
        e = text.index(end, s) + len(end)
        if text[s:e] == desired_block:
            return "unchanged"
        text = text[:s] + desired_block + text[e:]
        path.write_text(text)
        return "refreshed"
    if patch["original"] in text:
        text = text.replace(patch["original"], patch["patched"], 1)
        path.write_text(text)
        return "applied"
    raise SystemExit(
        f"patch.sh: neither marker nor upstream anchor found in {patch['file']} "
        f"for {marker}. Upstream may have changed."
    )


for patch in PATCHES:
    status = apply_patch(here, patch)
    print(f"patch.sh: [{status:9}] {patch['marker']:25} {patch['file']}")
PY
