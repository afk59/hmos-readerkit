import { ReaderConstants } from '../common/ReaderConstants';

export interface FontOption {
  label: string;
  fontName: string;
  fontPath: string;
}

export interface BackgroundOption {
  label: string;
  themeColor: string;
  fontColor: string;
  themeBgImg: string;
  nightMode: boolean;
}

export const FONT_OPTIONS: FontOption[] = [
  { label: 'System', fontName: 'System font', fontPath: '' },
  { label: 'Custom Serif', fontName: 'Custom Serif', fontPath: ReaderConstants.CUSTOM_FONT_RAWFILE_PATH },
];

export const BACKGROUND_OPTIONS: BackgroundOption[] = [
  {
    label: 'Light',
    themeColor: ReaderConstants.LIGHT_THEME_COLOR,
    fontColor: ReaderConstants.LIGHT_FONT_COLOR,
    themeBgImg: '',
    nightMode: false
  },
  {
    label: 'Sepia',
    themeColor: ReaderConstants.SEPIA_THEME_COLOR,
    fontColor: ReaderConstants.SEPIA_FONT_COLOR,
    themeBgImg: '',
    nightMode: false
  },
  {
    label: 'Dark',
    themeColor: ReaderConstants.DARK_THEME_COLOR,
    fontColor: ReaderConstants.DARK_FONT_COLOR,
    themeBgImg: '',
    nightMode: true
  },
  {
    label: 'Image',
    themeColor: ReaderConstants.SEPIA_THEME_COLOR,
    fontColor: ReaderConstants.SEPIA_FONT_COLOR,
    themeBgImg: ReaderConstants.CUSTOM_BG_RAWFILE_PATH,
    nightMode: false
  },
];
