const { spawn } = require('child_process');
const path = require('path');

// 尝试使用DevEco Studio的hvigor工具进行构建
const hvigorPath = path.join('C:', 'Program Files', 'Huawei', 'DevEco Studio', 'tools', 'hvigor', 'bin', 'hvigorw.js');
const projectPath = process.cwd();

console.log(`Running build in ${projectPath}`);
console.log(`Using hvigor from ${hvigorPath}`);

// 尝试运行assembleApp命令
const buildProcess = spawn('node', [hvigorPath, 'assembleApp'], {
  cwd: projectPath,
  stdio: 'inherit'
});

buildProcess.on('close', (code) => {
  console.log(`Build process exited with code ${code}`);
  if (code === 0) {
    console.log('Build completed successfully');
  } else {
    console.log('Build failed');
  }
});