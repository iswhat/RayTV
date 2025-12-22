// 测试站点配置解析脚本
import { ConfigParser } from './src/main/ets/service/config/ConfigParser';
import { readFileSync } from 'fs';

// 读取配置文件内容
const configContent = readFileSync('d:\\tv\\RayTV\\a.json', 'utf-8');

// 创建ConfigParser实例
const parser = ConfigParser.getInstance();

console.log('=== 测试站点配置解析 ===');

try {
  // 解析sites配置
  const sites = parser.parseSites(configContent);
  console.log(`成功解析 ${sites.length} 个站点`);
  
  // 查找key为cps_Gz360的站点
  const targetSite = sites.find(site => site.key === 'csp_Gz360');
  
  if (targetSite) {
    console.log('\n找到目标站点:');
    console.log(`  Key: ${targetSite.key}`);
    console.log(`  Name: ${targetSite.name}`);
    console.log(`  Type: ${targetSite.type}`);
    console.log(`  API: ${targetSite.api}`);
    console.log(`  Enabled: ${targetSite.enabled}`);
    
    console.log('\n站点配置验证通过，具备解析首页内容的基础条件！');
  } else {
    console.log('\n未找到key为csp_Gz360的站点');
    // 输出所有站点的key，方便调试
    console.log('\n所有站点的key列表:');
    sites.forEach(site => console.log(`  - ${site.key}`));
  }
} catch (error) {
  console.error('配置解析失败:', error);
}

console.log('\n=== 测试完成 ===');
