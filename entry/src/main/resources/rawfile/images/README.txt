Place a real .jpg or .png image in this folder to enable the "Image"
background option in the Reader Kit showcase page.

Expected file name (see ReaderConstants.CUSTOM_BG_RAWFILE_PATH):
  images/paper_texture.jpg

If you rename or replace the file, update CUSTOM_BG_RAWFILE_PATH in
entry/src/main/ets/common/ReaderConstants.ets to match.

Until an image is added here, the resourceRequest callback in Index.ets will
catch the missing-file error and fall back gracefully (the page keeps using
the configured theme color instead of crashing).
