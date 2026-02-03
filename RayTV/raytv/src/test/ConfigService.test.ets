// ConfigService.test.ets - ConfigService测试文件 // ConfigService test file
// 测试ConfigService类的配置管理功能 // Tests ConfigService class configuration management functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ConfigService } from '../main/ets/service/config/ConfigService';
import { Config } from '../main/ets/data/bean/Config';

export default function configServiceTest() {
  describe('ConfigService测试 // ConfigService tests', () => {
    let configService: ConfigService;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      configService = ConfigService.getInstance();
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

    it('测试获取ConfigService单例实例 // Test get ConfigService singleton instance', 0, () => {
      // 测试获取单例实例功能 // Test get singleton instance functionality
      const instance1 = ConfigService.getInstance();
      const instance2 = ConfigService.getInstance();
      
      // 验证单例模式 // Verify singleton pattern
      expect(instance1).assertNotNull('实例1不能为空 // Instance 1 cannot be null');
      expect(instance2).assertNotNull('实例2不能为空 // Instance 2 cannot be null');
      expect(instance1).assertEqual(instance2, '两个实例应该是同一个对象 // Both instances should be the same object');
      
      console.log('ConfigService单例模式测试通过 // ConfigService singleton pattern test passed');
    });

    it('测试加载配置功能 // Test load config functionality', 0, async () => {
      // 测试加载配置功能 // Test load config functionality
      const loadResult = await configService.loadConfig();
      
      // 验证加载结果 // Verify load result
      expect(loadResult).assertTrue('配置加载应该成功 // Config load should succeed');
      
      console.log('配置加载测试通过 // Config load test passed');
    });

    it('测试获取配置功能 // Test get config functionality', 0, async () => {
      // 先加载配置 // Load config first
      await configService.loadConfig();
      
      // 测试获取配置功能 // Test get config functionality
      const config = await configService.getConfig();
      
      // 验证配置结果 // Verify config result
      expect(config).assertNotNull('配置不能为空 // Config cannot be null');
      expect(config).assertTypeOf('object', '配置应该是对象类型 // Config should be object type');
      
      console.log('获取配置测试通过 // Get config test passed');
    });

    it('测试保存配置功能 // Test save config functionality', 0, async () => {
      // 先加载配置 // Load config first
      await configService.loadConfig();
      const originalConfig = await configService.getConfig();
      
      // 测试保存配置功能 // Test save config functionality
      const saveResult = await configService.saveConfig(originalConfig);
      
      // 验证保存结果 // Verify save result
      expect(saveResult).assertTrue('配置保存应该成功 // Config save should succeed');
      
      console.log('保存配置测试通过 // Save config test passed');
    });

    it('测试获取站点配置功能 // Test get sites config functionality', 0, async () => {
      // 先加载配置 // Load config first
      await configService.loadConfig();
      
      // 测试获取站点配置功能 // Test get sites config functionality
      const sitesConfig = await configService.getSitesConfig();
      
      // 验证站点配置结果 // Verify sites config result
      expect(sitesConfig).assertNotNull('站点配置不能为空 // Sites config cannot be null');
      expect(sitesConfig).assertTypeOf('array', '站点配置应该是数组类型 // Sites config should be array type');
      
      console.log('获取站点配置测试通过 // Get sites config test passed');
    });

    it('测试获取直播配置功能 // Test get lives config functionality', 0, async () => {
      // 先加载配置 // Load config first
      await configService.loadConfig();
      
      // 测试获取直播配置功能 // Test get lives config functionality
      const livesConfig = await configService.getLivesConfig();
      
      // 验证直播配置结果 // Verify lives config result
      expect(livesConfig).assertNotNull('直播配置不能为空 // Lives config cannot be null');
      expect(livesConfig).assertTypeOf('array', '直播配置应该是数组类型 // Lives config should be array type');
      
      console.log('获取直播配置测试通过 // Get lives config test passed');
    });
  });
}
