import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ConfigParser } from '../main/ets/service/config/ConfigParser';
import { readFileSync } from 'fs';

export default function configParserTest() {
  describe('ConfigParser测试', () => {
    let parser: ConfigParser;
    let configContent: string;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次
      parser = ConfigParser.getInstance();
      // 读取配置文件内容
      configContent = readFileSync('d:\\tv\\RayTV\\a.json', 'utf-8');
    });

    beforeEach(() => {
      // 在每个测试用例开始前执行
    });

    afterEach(() => {
      // 在每个测试用例结束后执行
    });

    afterAll(() => {
      // 在所有测试用例结束后执行一次
    });

    it('测试sites配置解析', 0, () => {
      // 测试sites配置解析功能
      const sites = parser.parseSites(configContent);
      
      // 验证解析结果
      expect(sites.length).assertGreater(0, '至少解析到一个站点');
      
      // 验证站点属性
      for (const site of sites) {
        expect(site.key).assertTypeOf('string', '站点key必须是字符串');
        expect(site.name).assertTypeOf('string', '站点名称必须是字符串');
        expect(site.type).assertTypeOf('string', '站点类型必须是字符串');
      }
      
      console.log(`成功解析 ${sites.length} 个站点`);
    });

    it('测试lives配置解析', 0, () => {
      // 测试lives配置解析功能
      const liveCollection = parser.parseLives(configContent);
      
      // 验证解析结果
      expect(liveCollection.lives.length).assertGreater(0, '至少解析到一个直播配置');
      
      // 验证直播配置属性
      for (const item of liveCollection.lives) {
        if ('group' in item) {
          // 分组格式
          expect(item.group).assertTypeOf('string', '分组名称必须是字符串');
          expect(item.channels.length).assertGreater(0, '分组必须包含至少一个频道');
          
          // 验证频道属性
          for (const channel of item.channels) {
            expect(channel.name).assertTypeOf('string', '频道名称必须是字符串');
          }
        } else {
          // 直接直播源格式
          expect(item.name).assertTypeOf('string', '直播源名称必须是字符串');
          expect(item.type).assertTypeOf('number', '直播源类型必须是数字');
        }
      }
      
      console.log(`成功解析 ${liveCollection.lives.length} 个直播配置`);
    });

    it('测试配置解析完整性', 0, () => {
      // 测试完整配置解析
      const sites = parser.parseSites(configContent);
      const liveCollection = parser.parseLives(configContent);
      
      // 验证解析结果不为空
      expect(sites).assertNotNull('sites解析结果不能为空');
      expect(liveCollection).assertNotNull('lives解析结果不能为空');
      expect(liveCollection.lives).assertNotNull('lives集合不能为空');
      
      console.log('配置解析完整性测试通过');
    });
  });
}
