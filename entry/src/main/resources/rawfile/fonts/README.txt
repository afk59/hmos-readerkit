Place a real .ttf, .otf, or .woff2 font file in this folder to enable the
"Custom Serif" option in the Reader Kit showcase page.

Expected file name (see ReaderConstants.CUSTOM_FONT_RAWFILE_PATH):
  fonts/CustomFont.ttf

If you rename or replace the file, update CUSTOM_FONT_RAWFILE_PATH in
entry/src/main/ets/common/ReaderConstants.ets to match.

Until a font is added here, the resourceRequest callback in Index.ets will
catch the missing-file error and fall back gracefully (the page keeps using
the system font instead of crashing).
