# Status Bar Presets for KOReader

## TL;DR

> **Quick Summary**: Add status bar preset system to KOReader patches with "Kindle UI" and "Default KOReader" presets, persistent selection, and Status Bar menu integration.
>
> **Deliverables**:
> - Modified `src/presets.lua` with safety checks and preset application logic
> - New menu integration for preset selection
> - Modified `src/main.lua` with startup auto-apply
> - Updated `2-kindle-time-left.lua` built patch file
>
> **Estimated Effort**: Medium
> **Parallel Execution**: NO - Sequential (each task builds on previous)
> **Critical Path**: Task 1 → Task 2 → Task 3 → Task 4

---

## Context

### Original Request
User wants to implement status bar presets for KOReader with the following requirements:
1. Create "Kindle UI" preset alongside "Default KOReader" preset
2. Check if presets exist before creating (avoid overwriting user modifications)
3. Persistency - remember which preset was selected
4. Add UI for selecting presets in Status Bar menu
5. Apply presets immediately when selected
6. Auto-apply last selected preset on startup

### Interview Summary
**Key Discussions**:
- **UI Location**: Status Bar Menu (most discoverable, follows KOReader conventions)
- **Application Behavior**: Apply Immediately when selected
- **Creation Safety**: Check Before Creating (don't overwrite existing presets)
- **Startup Behavior**: Auto-apply on Startup (remember last selection)

**Research Findings**:
- KOReader uses `G_reader_settings` for persistence (`readSetting`/`saveSetting`)
- Status Bar (ReaderFooter) has settings like `all_at_once`, `order`, `disable_progress_bar`, etc.
- Existing `createPresets()` function in `src/presets.lua` creates presets every time (unsafe)
- Menu integration requires hooking into `ReaderFooter` menu
- Build system concatenates `src/` files into `2-kindle-time-left.lua`

### Metis Review
**Identified Gaps** (addressed):
- **Preset versioning**: Added version tracking for schema updates
- **Error handling**: Added fallback to default preset on failure
- **User feedback**: Added notification when preset is applied
- **Guardrails**: Prevent deleting built-in presets

---

## Work Objectives

### Core Objective
Implement a complete status bar preset system with safe creation, menu-based selection, persistent storage, and automatic application.

### Concrete Deliverables
- `src/presets.lua` - Modified with `createPresetsSafely()`, `applyPreset()`, `getPresets()` functions
- Menu integration code in main flow - Adds "Select Preset" submenu to Status Bar settings
- `src/main.lua` - Modified with startup auto-apply logic
- `2-kindle-time-left.lua` - Updated combined patch file via `build.sh`

### Definition of Done
- [x] Presets are created only on first run (not overwritten)
- [x] Status Bar menu has "Presets" submenu with available options
- [x] Selecting a preset applies it immediately to status bar
- [x] Last selected preset is remembered and auto-applied on startup
- [x] Build script runs successfully creating updated patch file
- [ ] Manual testing on KOReader device confirms functionality (requires device)

### Must Have
- Safety check before creating presets (don't overwrite)
- "Kindle UI" preset with specific configuration
- "Default KOReader" preset for reverting
- Menu integration in Status Bar settings
- Persistent storage of selected preset
- Auto-apply on startup

### Must NOT Have (Guardrails)
- Custom preset creation (save current as new preset) - OUT OF SCOPE
- Preset deletion UI - OUT OF SCOPE
- Preset editing UI - OUT OF SCOPE
- Overwriting existing presets on load - PREVENT THIS

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: NO (KOReader patches don't have unit test infrastructure)
- **Automated tests**: None
- **Verification method**: Manual testing on KOReader device + Code review

### Agent-Executed QA Scenarios (MANDATORY)

> **KOReader patches require manual device testing.** The following scenarios describe how to verify on a real KOReader device.

#### Scenario 1: First Install - Presets Created
**Tool**: Manual testing on KOReader device
**Preconditions**: Fresh KOReader install or settings cleared, patch installed
**Steps**:
1. Install patch file to KOReader patches directory
2. Open any book in KOReader
3. Open Status Bar menu → Check for "Presets" option
4. Tap "Presets" → Verify "Kindle UI" and "Default KOReader" appear
5. Check `G_reader_settings` manually or via file inspection
**Expected Result**: Two presets exist, "Kindle UI" is active by default
**Evidence**: Screenshot of Presets menu, settings file inspection

#### Scenario 2: Preset Selection and Application
**Tool**: Manual testing on KOReader device
**Preconditions**: Patch installed, book open, status bar visible
**Steps**:
1. Note current status bar appearance
2. Open Status Bar → Presets
3. Select "Default KOReader"
4. Observe status bar immediately
5. Select "Kindle UI"
6. Observe status bar changes immediately
**Expected Result**: Status bar appearance changes immediately when preset selected
**Evidence**: Before/after screenshots of status bar

#### Scenario 3: Persistence - Remember Selection
**Tool**: Manual testing on KOReader device
**Preconditions**: Patch installed, user selected "Default KOReader" in previous session
**Steps**:
1. Select "Default KOReader" preset
2. Close KOReader completely
3. Reopen KOReader
4. Open a book
5. Check status bar appearance
**Expected Result**: Status bar shows "Default KOReader" configuration (not Kindle UI)
**Evidence**: Settings file shows `footer_active_preset = "Default KOReader"`

#### Scenario 4: Safety - No Overwrite on Reload
**Tool**: Manual testing on KOReader device + code inspection
**Preconditions**: Patch installed, user modified "Kindle UI" preset settings
**Steps**:
1. Install patch, let it create presets
2. Manually modify "Kindle UI" preset in settings
3. Close and reopen KOReader (patch reloads)
4. Check if modifications persist
**Expected Result**: User modifications remain (presets not recreated/replaced)
**Evidence**: Settings file comparison before/after reload

---

## Execution Strategy

### Sequential Execution (NO Parallel)

```
Wave 1 (Sequential):
├── Task 1: Modify presets.lua - Safety checks & application logic
├── Task 2: Add preset selection menu integration
├── Task 3: Modify main.lua - Startup auto-apply
└── Task 4: Build and verify patch file

Critical Path: Task 1 → Task 2 → Task 3 → Task 4
No parallel execution - each task depends on previous
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2, 3, 4 | None |
| 2 | 1 | 3, 4 | None |
| 3 | 1, 2 | 4 | None |
| 4 | 1, 2, 3 | None | None (final) |

---

## TODOs

- [x] 1. Modify presets.lua - Add Safety Checks and Application Logic

  **What to do**:
  - Add `presets_initialized` check before creating presets
  - Add `applyPreset(presetName, footer)` function that:
    - Reads preset from settings
    - Copies settings to footer
    - Refreshes footer display
  - Add `getPresets()` helper function
  - Add version tracking to presets for future compatibility
  - Add `getActivePreset()` and `setActivePreset()` functions for persistence

  **Must NOT do**:
  - Don't overwrite existing presets (check `presets_initialized` flag)
  - Don't delete any existing preset creation code (extend it)
  - Don't add UI code here (keep in main flow)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain` (Lua/KOReader domain requires understanding of KOReader internals)
    - Reason: KOReader patching requires deep understanding of ReaderFooter internals and settings API
  - **Skills**: None specifically (KOReader patching is specialized)
  - **Skills Evaluated but Omitted**: N/A

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Tasks 2, 3, 4
  - **Blocked By**: None (can start immediately)

  **References**:
  - `src/presets.lua:1-54` - Current createPresets() implementation
  - `src/footer.lua:67-72` - Footer refresh pattern: `footer:updateFooterTextGenerator()` and `footer:onUpdateFooter(true)`
  - Explore research: "footerTextGeneratorMap" pattern for understanding footer structure
  - KOReader docs: G_reader_settings API (readSetting/saveSetting)

  **Acceptance Criteria**:
  - [ ] `createPresetsSafely(footer)` function exists that checks `presets_initialized` before creating
  - [ ] `applyPreset(presetName, footer)` function exists that applies preset settings
  - [ ] `getActivePreset()` returns currently selected preset name from settings
  - [ ] `setActivePreset(presetName)` saves selected preset to settings
  - [ ] Existing `createPresets()` logic preserved but wrapped in safety check
  - [ ] Code compiles without Lua syntax errors

  **Agent-Executed QA Scenario**:
  ```
  Scenario: Verify presets.lua modifications compile
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run: lua -c src/presets.lua (or luac -p src/presets.lua)
      2. Assert: No syntax errors reported
      3. Review code: Check all new functions exist with correct signatures
    Expected Result: Lua syntax check passes
  ```

  **Commit**: YES
  - Message: `feat(presets): add safety checks and preset application logic`
  - Files: `src/presets.lua`

---

- [x] 2. Add Preset Selection Menu Integration

  **What to do**:
  - Hook into KOReader's ReaderFooter menu system
  - Add "Presets" submenu to Status Bar settings
  - Menu should show available presets ("Kindle UI", "Default KOReader")
  - On selection, call `applyPreset()` and show notification
  - Add checkmark/indicator for currently active preset

  **Must NOT do**:
  - Don't create separate plugin (keep integrated)
  - Don't modify KOReader core files (work within patch system)
  - Don't add complex UI (submenu is sufficient)

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain` (requires understanding KOReader menu system)
    - Reason: Menu integration requires knowledge of KOReader's UIManager and menu patterns
  - **Skills**: None specifically

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Tasks 3, 4
  - **Blocked By**: Task 1 (needs applyPreset function)

  **References**:
  - KOReader source: `frontend/apps/reader/modules/readerfooter.lua` - Menu structure pattern
  - KOReader source: `frontend/ui/widget/menu.lua` - Menu widget patterns
  - Explore research: "UIManager:show()" pattern for notifications
  - `src/main.lua:1-21` - Current hooking pattern

  **Acceptance Criteria**:
  - [ ] "Presets" submenu appears in Status Bar settings menu
  - [ ] Submenu shows both "Kindle UI" and "Default KOReader" options
  - [ ] Selecting a preset immediately applies it
  - [ ] Notification/toast shows when preset is applied
  - [ ] Currently active preset has visual indicator (checkmark)

  **Agent-Executed QA Scenario**:
  ```
  Scenario: Menu integration code compiles
    Tool: Bash
    Preconditions: Task 1 completed
    Steps:
      1. Review modified main.lua or separate menu file
      2. Run: lua -c on the file
      3. Assert: No syntax errors
    Expected Result: Lua syntax check passes
  ```

  **Commit**: YES
  - Message: `feat(menu): add preset selection submenu to status bar`
  - Files: `src/main.lua` (or new menu file)

---

- [x] 3. Modify main.lua - Add Startup Auto-Apply

  **What to do**:
  - In `addKindleUIpreset()` function:
    - After creating presets, read `footer_active_preset` from settings
    - If preset exists, call `applyPreset()` with the saved name
    - If no active preset saved, default to "Kindle UI"
  - Ensure this runs after presets are created

  **Must NOT do**:
  - Don't apply preset if user hasn't selected one yet (use default)
  - Don't fail if preset doesn't exist (fallback to default)

  **Recommended Agent Profile**:
  - **Category**: `quick` (simple modification to existing flow)
    - Reason: Just needs to add applyPreset call to existing startup flow
  - **Skills**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential
  - **Blocks**: Task 4
  - **Blocked By**: Tasks 1, 2 (needs applyPreset and presets to exist)

  **References**:
  - `src/main.lua:1-21` - Current startup flow
  - Task 1 output: `applyPreset()` and `getActivePreset()` functions

  **Acceptance Criteria**:
  - [ ] `addKindleUIpreset()` reads active preset on startup
  - [ ] If active preset exists, it's applied automatically
  - [ ] If no active preset, "Kindle UI" is applied as default
  - [ ] Footer refreshes correctly after auto-apply

  **Agent-Executed QA Scenario**:
  ```
  Scenario: Startup auto-apply code compiles
    Tool: Bash
    Preconditions: Tasks 1, 2 completed
    Steps:
      1. Review modified main.lua
      2. Run: lua -c src/main.lua
      3. Assert: No syntax errors
    Expected Result: Lua syntax check passes
  ```

  **Commit**: YES
  - Message: `feat(startup): auto-apply last selected preset on startup`
  - Files: `src/main.lua`

---

- [x] 4. Build Patch File and Verify

  **What to do**:
  - Run `build.sh` to concatenate src/ files into `2-kindle-time-left.lua`
  - Verify the built file contains all modifications
  - Check that build completes without errors
  - Document any manual testing steps needed

  **Must NOT do**:
  - Don't skip the build step (user needs the .lua patch file)
  - Don't commit build artifacts if they shouldn't be tracked

  **Recommended Agent Profile**:
  - **Category**: `quick` (just running build script)
    - Reason: Simple execution of existing build process
  - **Skills**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (final task)
  - **Blocks**: None
  - **Blocked By**: Tasks 1, 2, 3 (needs all source modifications)

  **References**:
  - `build.sh` - Build script to run
  - `2-kindle-time-left.lua` - Output file to verify

  **Acceptance Criteria**:
  - [ ] `./build.sh` runs successfully
  - [ ] `2-kindle-time-left.lua` is created/updated
  - [ ] Built file contains preset safety checks
  - [ ] Built file contains applyPreset logic
  - [ ] Built file contains menu integration
  - [ ] Built file contains startup auto-apply

  **Agent-Executed QA Scenario**:
  ```
  Scenario: Build script runs successfully
    Tool: Bash
    Preconditions: Tasks 1, 2, 3 completed
    Steps:
      1. Run: chmod +x build.sh && ./build.sh
      2. Assert: Script exits with code 0
      3. Assert: 2-kindle-time-left.lua exists and is newer than src/ files
      4. Assert: File contains "createPresetsSafely" or similar new function
    Expected Result: Build succeeds and output contains new code
  ```

  **Commit**: YES
  - Message: `build: regenerate patch file with preset system`
  - Files: `2-kindle-time-left.lua`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(presets): add safety checks and preset application logic` | src/presets.lua | lua -c src/presets.lua |
| 2 | `feat(menu): add preset selection submenu to status bar` | src/main.lua | lua -c src/main.lua |
| 3 | `feat(startup): auto-apply last selected preset on startup` | src/main.lua | lua -c src/main.lua |
| 4 | `build: regenerate patch file with preset system` | 2-kindle-time-left.lua | ./build.sh succeeds |

---

## Success Criteria

### Verification Commands
```bash
# Syntax check all Lua files
lua -c src/presets.lua
lua -c src/main.lua

# Build the patch
./build.sh

# Verify output exists and contains new code
grep -q "applyPreset" 2-kindle-time-left.lua && echo "SUCCESS: applyPreset found"
grep -q "presets_initialized" 2-kindle-time-left.lua && echo "SUCCESS: safety check found"
```

### Final Checklist
- [x] All "Must Have" present: Safety checks, both presets, menu integration, persistence, auto-apply
- [x] All "Must NOT Have" absent: No preset overwrites, no out-of-scope features
- [x] Build succeeds without errors
- [x] Manual testing guide provided for device verification

### Manual Testing Guide (for device)
1. Install `2-kindle-time-left.lua` to KOReader patches directory
2. Open a book
3. Test: Status Bar → Presets → Select each preset → Verify immediate change
4. Test: Close KOReader → Reopen → Verify last preset is active
5. Test: Clear settings → Reinstall → Verify presets created safely

---

## Technical Notes

### KOReader Settings API
```lua
-- Read setting (with default)
local value = G_reader_settings:readSetting("key", default_value)

-- Save setting
G_reader_settings:saveSetting("key", value)
```

### Footer Refresh Pattern
```lua
-- After changing footer settings:
footer:updateFooterTextGenerator()
footer:onUpdateFooter(true)
```

### Menu Integration Pattern
```lua
-- Hook into ReaderFooter menu (simplified)
local ReaderFooter = require("apps/reader/modules/readerfooter")
local original_init = ReaderFooter.init

function ReaderFooter:init()
    original_init(self)
    -- Add menu items here
end
```

### Preset Structure
```lua
presets["Kindle UI"] = {
    footer = { -- footer settings
        all_at_once = true,
        order = {"chapter_time_to_read", ...},
        ...
    },
    reader_footer_mode = 3, -- mode constant
    reader_footer_custom_text = "KOReader",
    reader_footer_custom_text_repetitions = 1,
}
```
