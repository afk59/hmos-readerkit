import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ReaderConstants } from '../common/ReaderConstants';

const DOMAIN = 0x0000;
const TAG = 'SampleBookProvider';

export class SampleBookProvider {
  static async ensureSampleBook(context: common.UIAbilityContext): Promise<string> {
    const dirPath = `${context.filesDir}/${ReaderConstants.SAMPLE_BOOK_DIR}`;
    const filePath = `${dirPath}/${ReaderConstants.SAMPLE_BOOK_NAME}`;
    try {
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath);
      }
      if (!fs.accessSync(filePath)) {
        SampleBookProvider.writeSampleContent(filePath);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `ensureSampleBook failed, code: ${err.code}, message: ${err.message}`);
    }
    return filePath;
  }

  private static writeSampleContent(filePath: string): void {
    const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    try {
      const chapters: string[] = [
        SampleBookProvider.buildChapter(
          'Chapter 1: Welcome to Reader Kit',
          'This sample book is generated on your device the first time the app runs, so the showcase works without any manual file import. '),
        SampleBookProvider.buildChapter(
          'Chapter 2: Turning Pages',
          'Swipe, tap, or use the manual navigation buttons in the control panel to move between pages. '),
        SampleBookProvider.buildChapter(
          'Chapter 3: Personalizing the Page',
          'Try switching the font, background, page-turning mode, and font size from the side panel while reading. '),
        SampleBookProvider.buildChapter(
          'Chapter 4: Closing Notes',
          'Reader Kit reports your reading position through the pageShow callback so an app can resume later. '),
      ];
      fs.writeSync(file.fd, chapters.join('\n\n'));
    } finally {
      fs.closeSync(file);
    }
  }

  private static buildChapter(title: string, paragraph: string): string {
    return `${title}\n${paragraph.repeat(24)}`;
  }
}
