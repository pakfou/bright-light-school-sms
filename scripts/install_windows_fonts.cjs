const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function installUserFonts() {
  const localAppData = process.env.LOCALAPPDATA;
  if (!localAppData) {
    console.log('LOCALAPPDATA not defined');
    return;
  }

  const userFontsDir = path.join(localAppData, 'Microsoft', 'Windows', 'Fonts');
  if (!fs.existsSync(userFontsDir)) {
    fs.mkdirSync(userFontsDir, { recursive: true });
  }

  const projectFontsDir = path.resolve(__dirname, '..', 'assets', 'fonts');
  const fontFiles = [
    { src: 'KhmerOSbattambang.ttf', regName: 'Khmer OS Battambang (TrueType)' },
    { src: 'KhmerOSbattambang-Bold.ttf', regName: 'Khmer OS Battambang Bold (TrueType)' },
    { src: 'KhmerOSmuollight.ttf', regName: 'Khmer OS Muol Light (TrueType)' },
    { src: 'KhmerOSmuollight.ttf', regName: 'Khmer OS Muol (TrueType)' },
    { src: 'KhmerOSbattambang.ttf', regName: 'Battambang (TrueType)' },
    { src: 'KhmerOSmuollight.ttf', regName: 'Moul (TrueType)' }
  ];

  for (const item of fontFiles) {
    const srcPath = path.join(projectFontsDir, item.src);
    const destPath = path.join(userFontsDir, item.src);

    if (fs.existsSync(srcPath)) {
      fs.copyFileSync(srcPath, destPath);
      console.log(`Copied ${item.src} to ${destPath}`);

      // Add to HKCU Registry for per-user font registration without admin rights
      try {
        const regCmd = `reg add "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" /v "${item.regName}" /t REG_SZ /d "${destPath}" /f`;
        execSync(regCmd, { stdio: 'pipe' });
        console.log(`Registered in registry: ${item.regName}`);
      } catch (err) {
        console.warn(`Could not add registry entry for ${item.regName}:`, err.message);
      }
    }
  }

  console.log('Windows font installation complete!');
}

installUserFonts();
