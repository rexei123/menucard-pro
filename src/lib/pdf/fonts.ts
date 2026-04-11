import { Font } from '@react-pdf/renderer';
import path from 'path';

const fontsDir = path.join(process.cwd(), 'public', 'fonts');

// Helper: register a font family with available weights
function tryRegister(family: string, files: { weight: number; style: string; file: string }[]) {
  const sources = files
    .filter(f => {
      try {
        require('fs').accessSync(path.join(fontsDir, f.file));
        return true;
      } catch { return false; }
    })
    .map(f => ({
      src: path.join(fontsDir, f.file),
      fontWeight: f.weight as any,
      fontStyle: f.style as any,
    }));

  if (sources.length > 0) {
    Font.register({ family, fonts: sources });
    return true;
  }
  return false;
}

let registered = false;

export function registerFonts() {
  if (registered) return;
  registered = true;

  // Playfair Display
  tryRegister('Playfair Display', [
    { weight: 400, style: 'normal', file: 'PlayfairDisplay-Regular.ttf' },
    { weight: 500, style: 'normal', file: 'PlayfairDisplay-Medium.ttf' },
    { weight: 600, style: 'normal', file: 'PlayfairDisplay-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'PlayfairDisplay-Bold.ttf' },
    { weight: 800, style: 'normal', file: 'PlayfairDisplay-ExtraBold.ttf' },
    { weight: 400, style: 'italic', file: 'PlayfairDisplay-Italic.ttf' },
    { weight: 700, style: 'italic', file: 'PlayfairDisplay-BoldItalic.ttf' },
  ]);

  // Source Sans 3
  tryRegister('Source Sans 3', [
    { weight: 300, style: 'normal', file: 'SourceSans3-Light.ttf' },
    { weight: 400, style: 'normal', file: 'SourceSans3-Regular.ttf' },
    { weight: 600, style: 'normal', file: 'SourceSans3-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'SourceSans3-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'SourceSans3-Italic.ttf' },
  ]);

  // Inter
  tryRegister('Inter', [
    { weight: 400, style: 'normal', file: 'Inter-Regular.ttf' },
    { weight: 500, style: 'normal', file: 'Inter-Medium.ttf' },
    { weight: 600, style: 'normal', file: 'Inter-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'Inter-Bold.ttf' },
    { weight: 800, style: 'normal', file: 'Inter-ExtraBold.ttf' },
  ]);

  // Dancing Script
  tryRegister('Dancing Script', [
    { weight: 400, style: 'normal', file: 'DancingScript-Regular.ttf' },
    { weight: 700, style: 'normal', file: 'DancingScript-Bold.ttf' },
  ]);

  // Lato
  tryRegister('Lato', [
    { weight: 300, style: 'normal', file: 'Lato-Light.ttf' },
    { weight: 400, style: 'normal', file: 'Lato-Regular.ttf' },
    { weight: 700, style: 'normal', file: 'Lato-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'Lato-Italic.ttf' },
  ]);

  // Cormorant Garamond
  tryRegister('Cormorant Garamond', [
    { weight: 400, style: 'normal', file: 'CormorantGaramond-Regular.ttf' },
    { weight: 600, style: 'normal', file: 'CormorantGaramond-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'CormorantGaramond-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'CormorantGaramond-Italic.ttf' },
  ]);

  // Fallback: Helvetica is always available in @react-pdf
  // No registration needed

  // Hyphenation callback (disable for German)
  Font.registerHyphenationCallback(word => [word]);
}

// Map font name to PDF-safe font family
export function pdfFont(fontName: string): string {
  const available = ['Playfair Display', 'Source Sans 3', 'Inter', 'Dancing Script', 'Lato', 'Cormorant Garamond'];
  if (available.includes(fontName)) return fontName;
  // Fallback mapping
  if (fontName.includes('Sans') || fontName === 'Open Sans' || fontName === 'Montserrat' || fontName === 'Raleway' || fontName === 'Josefin Sans') return 'Helvetica';
  if (fontName.includes('Garamond') || fontName.includes('Baskerville')) return 'Times-Roman';
  return 'Helvetica';
}
