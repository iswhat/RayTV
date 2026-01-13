// 简化的测试脚本，用于验证站点配置解析功能 | Simplified test script to verify site configuration parsing
// 直接使用JavaScript来解析JSON配置 | Directly use JavaScript to parse JSON configuration
const fs = require('fs');

// 读取配置文件内容 | Read configuration file content
const configContent = fs.readFileSync('d:\\tv\\RayTV\\a.json', 'utf-8');

// 清理JSON中的注释 | Clean comments in JSON
function cleanJson(jsonContent) {
  // 移除单行注释
  let clean = jsonContent.replace(/\/\/.*$/gm, '');
  // 移除多行注释
  clean = clean.replace(/\/\*[\s\S]*?\*\//g, '');
  // 移除多余的空白字符
  clean = clean.trim();
  return clean;
}

console.log('=== 测试站点配置解析 ===');

try {
  // 清理配置文件中的注释
  const cleanContent = cleanJson(configContent);
  
  // 解析JSON配置
  const config = JSON.parse(cleanContent);
  
  if (config.sites && Array.isArray(config.sites)) {
    console.log(`成功解析 ${config.sites.length} 个站点`);
    
    // 查找key为csp_Gz360的站点
    const targetSite = config.sites.find(site => site.key === 'csp_Gz360');
    
    if (targetSite) {
      console.log('\n找到目标站点:');
      console.log(`  Key: ${targetSite.key}`);
      console.log(`  Name: ${targetSite.name}`);
      console.log(`  Type: ${targetSite.type}`);
      console.log(`  API: ${targetSite.api}`);
      console.log(`  Searchable: ${targetSite.searchable}`);
      
      // 输出站点的完整配置
      console.log('\n站点完整配置:');
      console.log(JSON.stringify(targetSite, null, 2));
      
      console.log('\n站点配置解析验证通过！');
    } else {
      console.log('\n未找到key为csp_Gz360的站点');
      console.log('\n前10个站点的key:');
      config.sites.slice(0, 10).forEach(site => console.log(`  - ${site.key}`));
      
      // 搜索包含Gz360的站点
      console.log('\n搜索包含Gz360的站点:');
      const gz360Sites = config.sites.filter(site => site.key.includes('Gz360') || site.name.includes('Gz360'));
      gz360Sites.forEach(site => console.log(`  - ${site.key}`));
    }
  } else {
    console.log('配置文件中没有sites字段');
  }
} catch (error) {
  console.error('配置解析失败:', error);
  // 输出配置文件的前100个字符，方便调试
  console.log('\n配置文件前100字符:');
  console.log(configContent.substring(0, 100));
}

console.log('\n=== 测试完成 ===');
