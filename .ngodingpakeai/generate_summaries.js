const fs = require('fs');
const path = require('path');

const pendingPath = path.join(__dirname, 'pending.json');
const summariesPath = path.join(__dirname, 'summaries.json');

if (!fs.existsSync(pendingPath)) {
  console.error('pending.json not found at', pendingPath);
  process.exit(1);
}

const pendingData = JSON.parse(fs.readFileSync(pendingPath, 'utf8'));
const files = pendingData.files || [];

console.log('Total files to summarize:', files.length);

const summaries = {};

for (const f of files) {
  const relPath = f.path;
  const fullPath = path.resolve(process.cwd(), relPath);

  let content = '';
  if (fs.existsSync(fullPath)) {
    try {
      content = fs.readFileSync(fullPath, 'utf8');
    } catch (e) {
      console.warn('Could not read file:', fullPath, e.message);
    }
  }

  const lines = content ? content.split(/\r?\n/) : [];
  const fileName = path.basename(relPath);
  let summary = '';
  const sections = [];

  if (relPath.endsWith('.dart')) {
    const classes = [];
    const enums = [];
    const functions = [];

    lines.forEach((line, idx) => {
      const classMatch = line.match(/(?:abstract\s+)?class\s+(\w+)/);
      if (classMatch && !classes.includes(classMatch[1])) {
        classes.push(classMatch[1]);
        sections.push({
          symbol: classMatch[1],
          startLine: idx + 1,
          endLine: Math.min(idx + 50, lines.length),
          summary: `Definisi class ${classMatch[1]}`
        });
      }
      const enumMatch = line.match(/enum\s+(\w+)/);
      if (enumMatch && !enums.includes(enumMatch[1])) {
        enums.push(enumMatch[1]);
        sections.push({
          symbol: enumMatch[1],
          startLine: idx + 1,
          endLine: Math.min(idx + 20, lines.length),
          summary: `Definisi enum ${enumMatch[1]}`
        });
      }
    });

    const symbolsStr = [...classes, ...enums].join(', ');

    if (relPath.includes('/models/') || relPath.includes('/model/')) {
      summary = `Model data Dart untuk representasi entitas dan struktur data: ${symbolsStr || fileName}. Mendukung serialisasi, parsing JSON, atau representasi state database Supabase.`;
    } else if (relPath.includes('/screens/') || relPath.includes('/pages/') || relPath.includes('/views/')) {
      summary = `Halaman antarmuka pengguna (UI Screen) Flutter: ${symbolsStr || fileName}. Menangani tampilan, interaksi pengguna, navigasi, dan integrasi dengan state/controller.`;
    } else if (relPath.includes('/widgets/') || relPath.includes('/components/')) {
      summary = `Komponen UI / Widget Flutter reusable: ${symbolsStr || fileName}. Digunakan sebagai building block visual di berbagai halaman aplikasi.`;
    } else if (relPath.includes('/services/') || relPath.includes('/repositories/') || relPath.includes('/providers/') || relPath.includes('/controllers/')) {
      summary = `Service / Controller / Logika Bisnis: ${symbolsStr || fileName}. Mengelola komunikasi data, API/Supabase client, atau state aplikasi.`;
    } else if (relPath.includes('routes') || relPath.includes('router')) {
      summary = `Konfigurasi dan manajemen rute navigasi aplikasi Flutter: ${symbolsStr || fileName}.`;
    } else if (relPath.includes('/utils/') || relPath.includes('/helpers/') || relPath.includes('/constants/') || relPath.includes('/theme/')) {
      summary = `Utilitas helper, konstanta, tema styling, atau fungsi bantuan aplikasi: ${symbolsStr || fileName}.`;
    } else if (relPath.startsWith('test/')) {
      summary = `Unit/widget test untuk pengujian otomatis fungsionalitas komponen: ${fileName}.`;
    } else {
      summary = `Modul Dart ${symbolsStr ? 'mendefinisikan ' + symbolsStr : fileName} untuk mendukung fungsionalitas aplikasi Flutter SkolaApp.`;
    }
  } else if (relPath.endsWith('.md')) {
    const firstHeader = lines.find(l => l.trim().startsWith('#')) || '';
    const title = firstHeader.replace(/^#+\s*/, '').trim() || fileName;
    summary = `Dokumentasi / Panduan Markdown: ${title}. Berisi spesifikasi, petunjuk teknis, atau instruksi pengembangan.`;
  } else if (relPath.endsWith('.json')) {
    summary = `File konfigurasi data berformat JSON: ${fileName}.`;
  } else if (relPath.endsWith('.yaml') || relPath.endsWith('.yml')) {
    summary = `File konfigurasi YAML (${fileName}) untuk dependensi pubspec, tooling, atau setup build.`;
  } else if (relPath.endsWith('.sql')) {
    summary = `Skrip SQL migrasi atau definisi skema database PostgreSQL / Supabase: ${fileName}.`;
  } else if (relPath.includes('android/') || relPath.endsWith('.gradle') || relPath.endsWith('.properties')) {
    summary = `File konfigurasi native Android / Gradle build system untuk platform Android.`;
  } else if (relPath.includes('ios/') || relPath.endsWith('.plist') || relPath.endsWith('.pbxproj')) {
    summary = `File konfigurasi native iOS / Xcode build project untuk platform iOS.`;
  } else {
    summary = `File resource atau konfigurasi proyek SkolaApp: ${fileName}.`;
  }

  if (summary.length < 10) {
    summary = `File konfigurasi dan source code ${fileName} pada proyek SkolaApp.`;
  } else if (summary.length > 1900) {
    summary = summary.substring(0, 1900);
  }

  summaries[relPath] = {
    summary: summary,
    ...(sections.length > 0 && sections.length <= 10 ? { sections } : {})
  };
}

fs.writeFileSync(summariesPath, JSON.stringify(summaries, null, 2), 'utf8');
console.log('Successfully written', Object.keys(summaries).length, 'file summaries to', summariesPath);
