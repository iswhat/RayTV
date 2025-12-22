// 测试脚本：验证ConfigParser的配置解析能力
import { ConfigParser } from './raytv/src/main/ets/service/config/ConfigParser';
import { readFileSync } from 'fs';

// 读取配置文件内容
const configContent = readFileSync('d:\\tv\\RayTV\\a.json', 'utf-8');

// 创建ConfigParser实例
const parser = ConfigParser.getInstance();

console.log('=== 测试配置解析能力 ===');

// 测试sites配置解析
try {
  console.log('1. 测试sites配置解析...');
  const sites = parser.parseSites(configContent);
  console.log(`   成功解析 ${sites.length} 个站点`);
  console.log('   站点列表：');
  sites.forEach((site, index) => {
    console.log(`   ${index + 1}. ${site.name} (${site.key}) - ${site.type}`);
  });
  console.log('   sites配置解析成功！');
} catch (error) {
  console.error('   sites配置解析失败:', error);
}

// 测试lives配置解析
try {
  console.log('\n2. 测试lives配置解析...');
  const liveCollection = parser.parseLives(configContent);
  console.log(`   成功解析 ${liveCollection.lives.length} 个直播配置`);
  console.log('   直播配置列表：');
  liveCollection.lives.forEach((item, index) => {
    if ('group' in item) {
      console.log(`   ${index + 1}. [分组] ${item.group} - ${item.channels.length}个频道`);
      item.channels.forEach((channel, channelIndex) => {
        console.log(`      ${channelIndex + 1}. ${channel.name}`);
      });
    } else {
      console.log(`   ${index + 1}. [直播源] ${item.name} - 类型: ${item.type}`);
      if (item.url) {
        console.log(`      URL: ${item.url}`);
      }
      if (item.epg) {
        console.log(`      EPG: ${item.epg}`);
      }
    }
  });
  console.log('   lives配置解析成功！');
} catch (error) {
  console.error('   lives配置解析失败:', error);
}

console.log('\n=== 配置解析测试完成 ===');
