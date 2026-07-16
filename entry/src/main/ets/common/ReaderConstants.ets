import { readerCore } from '@kit.ReaderKit';
import { display } from '@kit.ArkUI';

export class ReaderConstants {
  static readonly SAMPLE_BOOK_DIR: string = 'sample_books';
  static readonly SAMPLE_BOOK_NAME: string = 'sample.txt';
  static readonly CUSTOM_FONT_RAWFILE_PATH: string = 'fonts/CustomFont.ttf';
  static readonly CUSTOM_BG_RAWFILE_PATH: string = 'images/paper_texture.jpg';

  static readonly LIGHT_THEME_COLOR: string = '#FFFFFF';
  static readonly LIGHT_FONT_COLOR: string = '#000000';
  static readonly SEPIA_THEME_COLOR: string = '#F5EEDC';
  static readonly SEPIA_FONT_COLOR: string = '#3B2F1E';
  static readonly DARK_THEME_COLOR: string = '#202224';
  static readonly DARK_FONT_COLOR: string = '#FFFFFF';

  static readonly MIN_FONT_SIZE: number = 12;
  static readonly MAX_FONT_SIZE: number = 32;
  static readonly MIN_LINE_HEIGHT: number = 1.2;
  static readonly MAX_LINE_HEIGHT: number = 3.0;

  static readonly DEFAULT_VIEWPORT_WIDTH: number = 1260;
  static readonly DEFAULT_VIEWPORT_HEIGHT: number = 2720;

  static readonly SIDEBAR_WIDTH: number = 340;

  static readonly COLOR_TEXT_PRIMARY: string = '#1C1C1E';
  static readonly COLOR_TEXT_SECONDARY: string = '#6E6E73';
  static readonly COLOR_TEXT_ON_ACCENT: string = '#FFFFFF';
  static readonly COLOR_TEXT_ON_DARK: string = '#FFFFFF';
  static readonly COLOR_TEXT_ON_DARK_MUTED: string = '#CCFFFFFF';

  static readonly COLOR_ACCENT: string = '#2B5FD9';
  static readonly COLOR_ERROR: string = '#D92B2B';

  static readonly COLOR_SURFACE_TOPBAR: string = '#F7F8FA';
  static readonly COLOR_SURFACE_SIDEBAR: string = '#FBFBFD';
  static readonly COLOR_SURFACE_LOADING: string = '#FFFFFF';
  static readonly COLOR_SURFACE_NAVBAR: string = '#E61C1C1E';

  static readonly COLOR_CHIP_BG: string = '#ECECEE';
  static readonly COLOR_CHIP_BG_ACTIVE: string = ReaderConstants.COLOR_ACCENT;

  static readonly COLOR_DIVIDER: string = '#E1E1E6';
  static readonly COLOR_SWATCH_BORDER: string = '#C7C7CC';
  static readonly COLOR_SWATCH_BORDER_ACTIVE: string = ReaderConstants.COLOR_ACCENT;
  static readonly COLOR_COVER_PLACEHOLDER_BG: string = '#E5E5EA';

  static getDefaultReaderSetting(): readerCore.ReaderSetting {
    const scaledDensity = display.getDefaultDisplaySync().scaledDensity;
    return {
      fontName: 'System font',
      fontPath: '',
      fontSize: 18,
      fontColor: ReaderConstants.LIGHT_FONT_COLOR,
      fontWeight: 400,
      lineHeight: 1.9,
      nightMode: false,
      themeColor: ReaderConstants.LIGHT_THEME_COLOR,
      themeBgImg: '',
      flipMode: '0',
      scaledDensity: scaledDensity > 0 ? scaledDensity : 1,
      viewPortWidth: ReaderConstants.DEFAULT_VIEWPORT_WIDTH,
      viewPortHeight: ReaderConstants.DEFAULT_VIEWPORT_HEIGHT,
    };
  }
}
