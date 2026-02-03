// ConfigParser.test.ets - ConfigParser测试文件 // ConfigParser test file
// 测试ConfigParser类的配置解析功能 // Tests ConfigParser class configuration parsing functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ConfigParser } from '../main/ets/service/config/ConfigParser';
import { readFileSync } from 'fs';

export default function configParserTest() {
  describe('ConfigParser测试 // ConfigParser tests', () => {
    let parser: ConfigParser = ConfigParser.getInstance();
    let configContent: string = '';

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      parser = ConfigParser.getInstance();
      // 读取配置文件内容 // Read config file content
      configContent = readFileSync('d:\tv\RayTV\a.json', 'utf-8');
    });

    beforeEach(() => {
      // 在每个测试用例开始前执行 // Execute before each test case
    });

    afterEach(() => {
      // 在每个测试用例结束后执行 // Execute after each test case
    });

    afterAll(() => {
      // 在所有测试用例结束后执行一次 // Execute once after all test cases
    });

    it('测试sites配置解析 // Test sites config parsing', 0, () => {
      // 测试sites配置解析功能 // Test sites config parsing functionality
      const sites = parser.parseSites(configContent);
      
      // 验证解析结果 // Verify parsing result
      expect(sites.length).assertGreater(0, '至少解析到一个站点 // At least one site should be parsed');
      
      // 验证站点属性 // Verify site properties
      for (const site of sites) {
        expect(site.key).assertTypeOf('string', '站点key必须是字符串 // Site key must be string');
        expect(site.name).assertTypeOf('string', '站点名称必须是字符串 // Site name must be string');
        expect(site.type).assertTypeOf('string', '站点类型必须是字符串 // Site type must be string');
      }
      
      console.log(`成功解析 ${sites.length} 个站点 // Successfully parsed ${sites.length} sites`);
    });

    it('测试lives配置解析 // Test lives config parsing', 0, () => {
      // 测试lives配置解析功能 // Test lives config parsing functionality
      const liveCollection = parser.parseLives(configContent);
      
      // 验证解析结果 // Verify parsing result
      expect(liveCollection.lives.length).assertGreater(0, '至少解析到一个直播配置 // At least one live config should be parsed');
      
      // 验证直播配置属性 // Verify live config properties
      for (const item of liveCollection.lives) {
        if ('group' in item) {
          // 分组格式 // Group format
          expect(item.group).assertTypeOf('string', '分组名称必须是字符串 // Group name must be string');
          expect(item.channels.length).assertGreater(0, '分组必须包含至少一个频道 // Group must contain at least one channel');
          
          // 验证频道属性 // Verify channel properties
          for (const channel of item.channels) {
            expect(channel.name).assertTypeOf('string', '频道名称必须是字符串 // Channel name must be string');
          }
        } else {
          // 直接直播源格式 // Direct live source format
          expect(item.name).assertTypeOf('string', '直播源名称必须是字符串 // Live source name must be string');
          expect(item.type).assertTypeOf('number', '直播源类型必须是数字 // Live source type must be number');
        }
      }
      
      console.log(`成功解析 ${liveCollection.lives.length} 个直播配置 // Successfully parsed ${liveCollection.lives.length} live configs`);
    });

    it('测试配置解析完整性 // Test config parsing completeness', 0, () => {
      // 测试完整配置解析 // Test complete config parsing
      const sites = parser.parseSites(configContent);
      const liveCollection = parser.parseLives(configContent);
      
      // 验证解析结果不为空 // Verify parsing results are not empty
      expect(sites).assertNotNull('sites解析结果不能为空 // sites parsing result cannot be null');
      expect(liveCollection).assertNotNull('lives解析结果不能为空 // lives parsing result cannot be null');
      expect(liveCollection.lives).assertNotNull('lives集合不能为空 // lives collection cannot be null');
      
      console.log('配置解析完整性测试通过 // Config parsing completeness test passed');
    });
  });
}
