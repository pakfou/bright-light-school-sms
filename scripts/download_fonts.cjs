const fs = require('fs');
const path = require('path');
const https = require('https');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return download(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        return reject(new Error(`Failed to download ${url}: status code ${res.statusCode}`));
      }
      const dir = path.dirname(dest);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      const file = fs.createWriteStream(dest);
      res.pipe(file);
      file.on('finish', () => {
        file.close(() => {
          const stats = fs.statSync(dest);
          console.log(`Saved ${dest} (${stats.size} bytes)`);
          resolve();
        });
      });
      file.on('error', (err) => {
        fs.unlink(dest, () => reject(err));
      });
    }).on('error', reject);
  });
}

async function main() {
  const root = path.resolve(__dirname, '..');
  const fontsDir = path.join(root, 'assets', 'fonts');
  const googleFontsDir = path.join(root, 'assets', 'google_fonts');

  if (!fs.existsSync(fontsDir)) fs.mkdirSync(fontsDir, { recursive: true });
  if (!fs.existsSync(googleFontsDir)) fs.mkdirSync(googleFontsDir, { recursive: true });

  const tasks = [
    {
      url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/battambang/Battambang-Regular.ttf',
      dests: [
        path.join(fontsDir, 'KhmerOSbattambang.ttf'),
        path.join(fontsDir, 'Battambang-Regular.ttf'),
        path.join(googleFontsDir, 'Battambang-Regular.ttf')
      ]
    },
    {
      url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/battambang/Battambang-Bold.ttf',
      dests: [
        path.join(fontsDir, 'KhmerOSbattambang-Bold.ttf'),
        path.join(fontsDir, 'Battambang-Bold.ttf'),
        path.join(googleFontsDir, 'Battambang-Bold.ttf')
      ]
    },
    {
      url: 'https://raw.githubusercontent.com/google/fonts/main/ofl/moul/Moul-Regular.ttf',
      dests: [
        path.join(fontsDir, 'KhmerOSmuollight.ttf'),
        path.join(fontsDir, 'Moul-Regular.ttf'),
        path.join(googleFontsDir, 'Moul-Regular.ttf')
      ]
    }
  ];

  for (const task of tasks) {
    console.log(`Downloading ${task.url}...`);
    const tempFile = task.dests[0];
    await download(task.url, tempFile);
    for (let i = 1; i < task.dests.length; i++) {
      fs.copyFileSync(tempFile, task.dests[i]);
      console.log(`Copied to ${task.dests[i]}`);
    }
  }

  console.log('All fonts downloaded and copied successfully!');
}

main().catch(err => {
  console.error('Download failed:', err);
  process.exit(1);
});
