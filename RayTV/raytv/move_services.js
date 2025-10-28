// 服务移动脚本 - 根据实现计划移动服务类到正确位置
const fs = require('fs');
const path = require('path');

// 源目录和目标目录
const SOURCE_DIR = 'd:\\tv\\RayTV\\raytv\\src\\main\\ets\\data\\service';
const TARGET_DIR = 'd:\\tv\\RayTV\\raytv\\src\\main\\ets\\service';

// 服务移动映射 - 确定每个服务应该移动到的位置
const serviceMapping = {
  // 已存在的服务不需要移动
  'AppService.ets': null,                    // 可能需要放在根目录
  'AuthService.ets': null,                   // 需要删除，因为不需要用户功能
  'CollectionService.ets': 'collection\\',  // 收藏服务
  'ConfigManager.ets': null,                 // 可能与ConfigService重复
  'ConfigService.ts': null,                  // 已经在config目录实现
  'DataSyncService.ets': 'sync\\',          // 数据同步服务
  'DeviceManager.ets': 'device\\',          // 设备管理
  'DeviceService.ts': 'device\\',           // 设备服务
  'DistributedDataService.ets': 'sync\\',   // 分布式数据服务
  'FileService.ets': 'storage\\',           // 文件服务
  'MediaCacheService.ets': 'media\\',       // 媒体缓存
  'MediaService.ets': 'media\\',            // 媒体服务
  'MovieService.ets': 'media\\',            // 电影服务
  'NetworkService.ets': null,                // 可能与HttpService重复
  'PlayerService.ets': 'player\\',          // 播放器服务
  'SearchService.ets': null,                 // 已经在search目录实现
  'ServiceFactory.ets': null,                // 工厂类保留在根目录
  'SettingService.ets': 'config\\',         // 设置服务
  'SiteService.ets': 'spider\\',            // 站点服务
  'SubtitleService.ets': 'media\\'          // 字幕服务
};

// 创建目标目录
function ensureDirectoryExists(dirPath) {
  if (dirPath && !fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`创建目录: ${dirPath}`);
  }
}

// 移动文件
function moveServiceFiles() {
  try {
    console.log('开始移动服务文件...');
    
    // 确保目标根目录存在
    ensureDirectoryExists(TARGET_DIR);
    
    // 遍历服务映射
    Object.entries(serviceMapping).forEach(([fileName, targetSubDir]) => {
      const sourcePath = path.join(SOURCE_DIR, fileName);
      
      if (!fs.existsSync(sourcePath)) {
        console.log(`跳过不存在的文件: ${fileName}`);
        return;
      }
      
      if (targetSubDir === null) {
        // 特殊处理：不需要移动或需要删除的文件
        if (fileName === 'AuthService.ets') {
          console.log(`删除不需要的服务: ${fileName}`);
          // 实际删除将在确认后执行
        } else {
          console.log(`保留在原位: ${fileName}`);
        }
      } else {
        // 移动到目标子目录
        const targetPath = path.join(TARGET_DIR, targetSubDir, fileName);
        ensureDirectoryExists(path.dirname(targetPath));
        
        console.log(`将移动: ${fileName} -> ${targetSubDir}${fileName}`);
        // 实际移动将在确认后执行
        // fs.renameSync(sourcePath, targetPath);
      }
    });
    
    console.log('移动计划生成完成。请检查以上计划后执行实际移动。');
    
  } catch (error) {
    console.error('移动文件时出错:', error);
  }
}

// 执行移动计划
moveServiceFiles();
