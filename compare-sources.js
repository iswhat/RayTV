const https = require('https');
const fs = require('fs');
const path = require('path');

// 网络源URL
const SOURCE_URL = 'https://q.uoouo.com/dianshi.json';

// 要测试的线路信息
const TEST_LINE = {
  key: 'drpy_js_豆瓣',
  name: '搜索 | 豆瓣[js]'
};

// 日志函数
function log(message) {
  console.log(`[${new Date().toISOString()}] ${message}`);
}

// 从URL获取数据
async function fetchData(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        resolve(data);
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

// 解析JSON数据
function parseJson(data) {
  try {
    return JSON.parse(data);
  } catch (err) {
    log(`JSON解析错误: ${err.message}`);
    return null;
  }
}

// 查找指定线路
function findLine(sources, key) {
  if (!sources || !sources.length) {
    return null;
  }
  
  return sources.find(source => source.key === key);
}

// 对比两个结果
function compareResults(rayTvResult, androidResult) {
  log('=== 结果对比 ===');
  
  // 检查结果是否存在
  if (!rayTvResult && !androidResult) {
    log('两个项目都未获取到结果');
    return;
  }
  
  if (!rayTvResult) {
    log('RayTV项目未获取到结果');
    return;
  }
  
  if (!androidResult) {
    log('AndroidVer项目未获取到结果');
    return;
  }
  
  // 对比基本信息
  log(`RayTV结果类型: ${typeof rayTvResult}`);
  log(`Android结果类型: ${typeof androidResult}`);
  
  // 如果是对象，对比属性
  if (typeof rayTvResult === 'object' && typeof androidResult === 'object') {
    const rayTvKeys = Object.keys(rayTvResult);
    const androidKeys = Object.keys(androidResult);
    
    log(`RayTV结果属性数: ${rayTvKeys.length}`);
    log(`Android结果属性数: ${androidKeys.length}`);
    
    // 找出差异
    const onlyInRayTv = rayTvKeys.filter(key => !androidKeys.includes(key));
    const onlyInAndroid = androidKeys.filter(key => !rayTvKeys.includes(key));
    
    if (onlyInRayTv.length > 0) {
      log(`仅RayTV结果有的属性: ${onlyInRayTv.join(', ')}`);
    }
    
    if (onlyInAndroid.length > 0) {
      log(`仅Android结果有的属性: ${onlyInAndroid.join(', ')}`);
    }
    
    // 对比共同属性的值
    const commonKeys = rayTvKeys.filter(key => androidKeys.includes(key));
    log(`共同属性数: ${commonKeys.length}`);
    
    // 保存详细对比到文件
    const detailedCompare = {
      timestamp: new Date().toISOString(),
      rayTv: rayTvResult,
      android: androidResult,
      differences: {
        onlyInRayTv,
        onlyInAndroid,
        commonKeys
      }
    };
    
    fs.writeFileSync(
      path.join(__dirname, 'compare-result.json'),
      JSON.stringify(detailedCompare, null, 2),
      'utf8'
    );
    
    log('详细对比结果已保存到 compare-result.json');
  }
}

// 模拟RayTV项目获取数据
async function simulateRayTv() {
  log('=== 模拟RayTV项目获取数据 ===');
  try {
    // 1. 获取完整配置
    const configData = await fetchData(SOURCE_URL);
    const config = parseJson(configData);
    
    if (!config || !config.sites) {
      log('RayTV: 配置格式错误，未找到sites字段');
      return null;
    }
    
    // 2. 查找指定线路
    const targetSite = findLine(config.sites, TEST_LINE.key);
    if (!targetSite) {
      log(`RayTV: 未找到指定线路 ${TEST_LINE.key}`);
      return null;
    }
    
    log(`RayTV: 找到线路 - ${targetSite.name}`);
    log(`RayTV: 线路API - ${targetSite.api}`);
    
    // 3. 模拟获取首页数据（假设直接返回线路配置）
    return {
      site: targetSite,
      config: config,
      sourceCount: config.sites.length
    };
  } catch (error) {
    log(`RayTV: 获取数据失败 - ${error.message}`);
    return null;
  }
}

// 模拟AndroidVer项目获取数据
async function simulateAndroid() {
  log('=== 模拟AndroidVer项目获取数据 ===');
  try {
    // 1. 获取完整配置
    const configData = await fetchData(SOURCE_URL);
    const config = parseJson(configData);
    
    if (!config || !config.sites) {
      log('Android: 配置格式错误，未找到sites字段');
      return null;
    }
    
    // 2. 查找指定线路
    const targetSite = findLine(config.sites, TEST_LINE.key);
    if (!targetSite) {
      log(`Android: 未找到指定线路 ${TEST_LINE.key}`);
      return null;
    }
    
    log(`Android: 找到线路 - ${targetSite.name}`);
    log(`Android: 线路API - ${targetSite.api}`);
    
    // 3. 模拟获取首页数据（假设直接返回线路配置）
    return {
      site: targetSite,
      config: config,
      sourceCount: config.sites.length
    };
  } catch (error) {
    log(`Android: 获取数据失败 - ${error.message}`);
    return null;
  }
}

// 主函数
async function main() {
  log('开始对比两个项目的网络源获取结果');
  log(`网络源URL: ${SOURCE_URL}`);
  log(`测试线路: ${TEST_LINE.name} (${TEST_LINE.key})`);
  
  try {
    // 并行获取两个项目的模拟结果
    const [rayTvResult, androidResult] = await Promise.all([
      simulateRayTv(),
      simulateAndroid()
    ]);
    
    // 对比结果
    compareResults(rayTvResult, androidResult);
    
    log('对比完成');
  } catch (error) {
    log(`程序执行错误: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
main();
