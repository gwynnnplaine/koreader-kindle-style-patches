# KOReader Kindle-Style UI Patches

A collection of KOReader patches that bring a Kindle-inspired UI to your e-reader. These patches enhance the footer with chapter time information and add a centered clock header, creating a cohesive and elegant reading interface.

<p align="center">
  <img src="assets/example.png" alt="Example of Kindle-style footer and header" height="400" />
  <br />
</p>

### Prerequisites
- KOReader installed on your device
- Minimum KOReader version: 2025.08 or later

### Downloads

> Looking for the original version without the latest enhancements? Check out the [v1 branch](../../tree/v1) for the previous two-patch setup.

Download from [GitHub Releases](../../releases/latest):
- **`2-mimic-kindle-ui-patch.lua`** — Complete patch with both footer and header (Recommended)
- **`2-mimic-kindle-ui-patch-no-header.lua`** — Footer only (if you prefer no header)

## Installation instructions

#### 1. Download the Patch
Get the latest patch file from [GitHub Releases](../../releases/latest).

#### 2. Install the Patch
[Learn how to install userpatches in KOReader](https://koreader.rocks/user_guide/#L2-userpatches)

Copy the downloaded `.lua` file to your KOReader device's `koreader/patches/` directory.

## Configuration

Each component includes its own configuration block at the top of the patch file. Edit these values before installing or restart KOReader after changes to see effects.

### Header Configuration
Located in the patch file's `HEADER_CONFIG` table:
- `top_padding` — Top margin in pixels (default: 12)
- `font_face` — Font name (default: "ffont")
- `font_size` — Font size in pixels (default: 16)
- `font_bold` — Use bold font (default: true)
- `font_color` — Font color (default: black)
- `use_book_margins` — Use document margins (default: true)
- `margin` — Fallback margin in pixels (default: Size.padding.large)
- `max_width_pct` — Maximum width percentage before truncating (default: 100)
- `show_for_pdf` — Show header for PDF/CBZ files (default: false)

### Footer Configuration
Located in the patch file's `FOOTER_CONFIG` table:
- `CHAPTER_COMPLETED_TEXT` — Text shown when chapter is complete (default: "Chapter completed")
- `LABEL_TEXT` — Text displayed before reading time (default: "Time left in chapter:")
- `LABEL_MIN_WIDTH` — Minimum character width for alignment (default: 5)
- `FOOTER_LEFT_MARGIN` — Left padding in character spaces (default: 1)
- `FOOTER_RIGHT_MARGIN` — Right padding in character spaces (default: 2)

## Testing & Feedback

This patch has been tested on:
- **Kindle 11th Generation**
- **KOReader Emulator on macOS**

**Your feedback is valuable!** If you encounter any issues or have suggestions for improvements, please:
- Open an [issue](../../issues) on GitHub
- Share your experience and device information
- Report any compatibility problems with your KOReader version

## Credits

- Header patch inspiration: [joshuacant's reader-header-centered patch](https://github.com/joshuacant/KOReader.patches)
- Built for the KOReader community

## Development

### Project Structure

The patch is built from modular source files in the `src/` directory:
- `src/helpers.lua` — Helper functions for time calculations
- `src/footer.lua` — Footer customization and Kindle-style time display
- `src/header.lua` — Centered clock header implementation
- `src/main.lua` — Main initialization and status bar configuration

### Building from Source

To build the patch files from source:

```bash
./build.sh
```

This generates two patch files:
- `2-mimic-kindle-ui-patch.lua` — Complete version with header and footer
- `2-mimic-kindle-ui-patch-no-header.lua` — Footer-only version

### Making Changes

1. Edit the relevant source files in the `src/` directory
2. Run `./build.sh` to rebuild the patch files
3. Copy the generated `.lua` file to your KOReader `patches/` directory
4. Restart KOReader to test your changes

### Contributing

Contributions are welcome! Feel free to:
- Submit bug reports and feature requests via [GitHub Issues](../../issues)
- Fork the repository and submit pull requests
