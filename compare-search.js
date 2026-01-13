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

// 搜索关键词
const SEARCH_KEYWORD = '百变星君';

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

// 模拟RayTV项目搜索逻辑
async function simulateRayTvSearch() {
  log('=== 模拟RayTV项目搜索 ===');
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
    
    // 3. 模拟搜索请求
    // 注意：由于无法直接调用实际的搜索方法，这里模拟搜索结果格式
    // 实际RayTV会调用siteManager.callSiteMethod(site.key, 'search', [...])
    // 实际封面URL会从搜索结果中获取，这里使用模拟数据
    const searchResult = {
      site: targetSite,
      keyword: SEARCH_KEYWORD,
      timestamp: Date.now(),
      results: [
        {
          id: 'raytv_1',
          type: 'movie',
          title: '百变星君',
          coverUrl: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p1363981561.jpg', // 模拟豆瓣封面URL
          rating: 8.5,
          genre: ['喜剧', '科幻'],
          siteKey: targetSite.key,
          siteName: targetSite.name
        }
      ],
      total: 1,
      successSites: 1,
      totalSites: 1,
      searchTime: 500
    };
    
    return searchResult;
  } catch (error) {
    log(`RayTV: 搜索失败 - ${error.message}`);
    return null;
  }
}

// 模拟AndroidVer项目搜索逻辑
async function simulateAndroidSearch() {
  log('=== 模拟AndroidVer项目搜索 ===');
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
    
    // 3. 模拟搜索请求
    // 实际AndroidVer会根据站点类型调用不同的搜索方法
    // 对于类型为3的站点：site.spider().searchContent(keyword, quick)
    // 对于其他类型站点：call(site, params)
    // 实际封面URL会从搜索结果中获取，这里使用模拟数据
    const searchResult = {
      site: targetSite,
      keyword: SEARCH_KEYWORD,
      timestamp: Date.now(),
      results: [
        {
          id: 'android_1',
          title: '百变星君',
          cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p1363981561.jpg', // 模拟豆瓣封面URL
          rating: 8.5,
          updateInfo: '已完结',
          tags: ['喜剧', '科幻'],
          category: '电影',
          siteKey: targetSite.key,
          siteName: targetSite.name
        }
      ],
      total: 1,
      success: true
    };
    
    return searchResult;
  } catch (error) {
    log(`Android: 搜索失败 - ${error.message}`);
    return null;
  }
}

// 对比搜索结果
function compareSearchResults(rayTvResult, androidResult) {
  log('=== 搜索结果对比 ===');
  
  // 检查结果是否存在
  if (!rayTvResult && !androidResult) {
    log('两个项目都未获取到搜索结果');
    return;
  }
  
  if (!rayTvResult) {
    log('RayTV项目未获取到搜索结果');
    return;
  }
  
  if (!androidResult) {
    log('AndroidVer项目未获取到搜索结果');
    return;
  }
  
  // 对比基本信息
  log(`RayTV搜索关键词: ${rayTvResult.keyword}`);
  log(`Android搜索关键词: ${androidResult.keyword}`);
  log(`RayTV结果数量: ${rayTvResult.total}`);
  log(`Android结果数量: ${androidResult.total}`);
  
  // 对比结果详情
  log('\n=== 结果详情对比 ===');
  
  const rayTvResults = rayTvResult.results || [];
  const androidResults = androidResult.results || [];
  
  log(`RayTV结果列表:`);
  rayTvResults.forEach((result, index) => {
    log(`  ${index + 1}. ${result.title} (评分: ${result.rating}, 类型: ${result.genre?.join(', ') || '未知'})`);
  });
  
  log(`\nAndroid结果列表:`);
  androidResults.forEach((result, index) => {
    log(`  ${index + 1}. ${result.title} (评分: ${result.rating}, 类型: ${result.tags?.join(', ') || '未知'})`);
  });
  
  // 保存详细对比到文件
  const detailedCompare = {
    timestamp: new Date().toISOString(),
    keyword: SEARCH_KEYWORD,
    rayTv: rayTvResult,
    android: androidResult,
    comparison: {
      sameKeyword: rayTvResult.keyword === androidResult.keyword,
      sameTotalResults: rayTvResult.total === androidResult.total,
      rayTvResultCount: rayTvResults.length,
      androidResultCount: androidResults.length
    }
  };
  
  fs.writeFileSync(
    path.join(__dirname, 'search-compare-result.json'),
    JSON.stringify(detailedCompare, null, 2),
    'utf8'
  );
  
  log('\n详细对比结果已保存到 search-compare-result.json');
  
  // 总结
  log('\n=== 总结 ===');
  if (rayTvResult.total === androidResult.total) {
    log('两个项目获取到的结果数量一致');
  } else {
    log('两个项目获取到的结果数量不一致');
  }
  
  if (rayTvResults.length === androidResults.length) {
    log('两个项目获取到的结果列表长度一致');
  } else {
    log('两个项目获取到的结果列表长度不一致');
  }
}

// 主函数
async function main() {
  log('开始对比两个项目的搜索结果');
  log(`搜索关键词: ${SEARCH_KEYWORD}`);
  log(`网络源: ${SOURCE_URL}`);
  log(`测试线路: ${TEST_LINE.name} (${TEST_LINE.key})`);
  
  try {
    // 并行获取两个项目的搜索结果
    const [rayTvResult, androidResult] = await Promise.all([
      simulateRayTvSearch(),
      simulateAndroidSearch()
    ]);
    
    // 对比结果
    compareSearchResults(rayTvResult, androidResult);
    
    log('\n搜索结果对比完成');
  } catch (error) {
    log(`程序执行错误: ${error.message}`);
    process.exit(1);
  }
}

// 执行主函数
main();
