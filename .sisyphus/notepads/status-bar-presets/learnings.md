# Status Bar Presets - Learnings

## Completed: 2026-02-03

### What Was Built
A complete status bar preset system for KOReader with:
- Safety-checked preset creation (no overwrites)
- "Kindle UI" and "Default KOReader" presets
- Menu integration in Status Bar settings
- Persistent selection storage
- Auto-apply on startup

### Key Technical Decisions

1. **Safety First**: Used `presets_initialized` flag to prevent overwriting user modifications
2. **Menu Hook Pattern**: Overrode `ReaderFooter:getMenuItems()` to inject Presets submenu
3. **Settings API**: Leveraged `G_reader_settings:readSetting/saveSetting` for persistence
4. **Footer Refresh**: Always call `updateFooterTextGenerator()` + `onUpdateFooter(true)` after changes

### Code Patterns Used

**Preset Application:**
```lua
for key, value in pairs(preset.footer) do
    footer.settings[key] = value
end
footer:updateFooterTextGenerator()
footer:onUpdateFooter(true)
```

**Menu Integration:**
```lua
local orig_getMenuItems = ReaderFooter.getMenuItems
function ReaderFooter:getMenuItems()
    local items = orig_getMenuItems(self)
    table.insert(items, preset_menu)
    return items
end
```

**Notification:**
```lua
UIManager:show(NotificationWidget:new{
    text = "Preset applied: " .. presetName,
    timeout = 2,
})
```

### Files Modified
- `src/presets.lua` - Added 5 functions (57 lines)
- `src/main.lua` - Added menu hook + startup logic (62 lines)
- `build.sh` - Fixed trailing comma bug
- `2-kindle-time-left.lua` - Regenerated complete patch

### Commits
1. `a922368` - feat(presets): add safety checks and preset application logic
2. `4aa5f9f` - feat(menu): add preset selection submenu to status bar
3. `1b302d4` - feat(startup): auto-apply last selected preset on startup
4. `dffe937` - build: regenerate patch file with preset system

### Testing Status
- ✅ Code syntax verified
- ✅ Build script runs successfully
- ✅ All functions present in output
- ⏸️ Manual device testing pending (requires KOReader device)

### Manual Testing Guide
1. Install `2-kindle-time-left.lua` to KOReader patches directory
2. Open a book
3. Test: Status Bar → Presets → Select each preset → Verify immediate change
4. Test: Close KOReader → Reopen → Verify last preset is active
5. Test: Clear settings → Reinstall → Verify presets created safely
