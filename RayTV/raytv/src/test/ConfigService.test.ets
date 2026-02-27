// ConfigService.test.ets - ConfigService测试文件 // ConfigService test file
// 测试ConfigService类的配置管理功能，包括安全存储功能 // Tests ConfigService class configuration management functionality, including secure storage functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import ConfigService from '../main/ets/service/config/ConfigService';
import { ConfigKey } from '../main/ets/service/config/ConfigService';
import { AbilityConstant, UIAbility } from '@ohos.app.ability';
import { Want } from '@ohos.app.ability';

// 模拟UIAbility上下文
class MockUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  }
  onDestroy(): void {
  }
  onWindowStageCreate(windowStage: any): void {
  }
  onWindowStageDestroy(): void {
  }
  onForeground(): void {
  }
  onBackground(): void {
  }
}

export default function configServiceTest() {
  describe('ConfigService测试 // ConfigService tests', () => {
    let configService: ConfigService;
    let mockContext: MockUIAbility;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      configService = ConfigService.getInstance();
      mockContext = new MockUIAbility();
      console.log('ConfigService测试初始化完成 // ConfigService test initialization completed');
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

    it('测试获取完整配置 // Test get full config', 0, async () => {
      // 测试获取完整配置功能 // Test get full config functionality
      const fullConfig = await configService.getFullConfig();
      
      // 验证配置获取成功 // Verify config get successfully
      expect(fullConfig).assertNotNull('完整配置不能为空 // Full config cannot be null');
      expect(fullConfig.player).assertNotNull('播放器配置不能为空 // Player config cannot be null');
      expect(fullConfig.display).assertNotNull('显示配置不能为空 // Display config cannot be null');
      expect(fullConfig.network).assertNotNull('网络配置不能为空 // Network config cannot be null');
      
      console.log('获取完整配置测试通过 // Get full config test passed');
    });

    it('测试更新完整配置 // Test update full config', 0, async () => {
      // 测试更新完整配置功能 // Test update full config functionality
      const updateConfig = {
        player: {
          autoPlay: true
        }
      };
      
      const result = await configService.updateFullConfig(updateConfig);
      
      // 验证配置更新成功 // Verify config update successfully
      expect(result).assertNotNull('更新结果不能为空 // Update result cannot be null');
      expect(result.isSuccess()).assertTrue('配置更新应该成功 // Config update should be successful');
      
      console.log('更新完整配置测试通过 // Update full config test passed');
    });

    it('测试获取部分配置 // Test get partial config', 0, async () => {
      // 测试获取部分配置功能 // Test get partial config functionality
      const playerConfig = await configService.getPartialConfig('player');
      const displayConfig = await configService.getPartialConfig('display');
      
      // 验证配置获取成功 // Verify config get successfully
      expect(playerConfig).assertNotNull('播放器配置不能为空 // Player config cannot be null');
      expect(displayConfig).assertNotNull('显示配置不能为空 // Display config cannot be null');
      
      console.log('获取部分配置测试通过 // Get partial config test passed');
    });

    it('测试更新部分配置 // Test update partial config', 0, async () => {
      // 测试更新部分配置功能 // Test update partial config functionality
      const updateConfig = {
        player: {
          autoPlay: false
        }
      };
      
      const result = await configService.updatePartialConfig('player', updateConfig);
      
      // 验证配置更新成功 // Verify config update successfully
      expect(result).assertNotNull('更新结果不能为空 // Update result cannot be null');
      expect(result.isSuccess()).assertTrue('配置更新应该成功 // Config update should be successful');
      
      console.log('更新部分配置测试通过 // Update partial config test passed');
    });

    it('测试安全存储配置功能 // Test secure storage config functionality', 0, async () => {
      // 测试安全存储配置功能 // Test secure storage config functionality
      const testKey = 'test_api_key';
      const testValue = 'test_value_123';
      
      // 测试设置安全配置
      const setResult = await configService.setSecureConfig(testKey, testValue);
      expect(setResult).assertTrue('设置安全配置应该成功 // Set secure config should be successful');
      
      // 测试获取安全配置
      const getResult = await configService.getSecureConfig(testKey);
      expect(getResult).assertNotNull('获取安全配置不能为空 // Get secure config cannot be null');
      expect(getResult).assertEqual(testValue, '获取的安全配置值应该与设置的值相同 // Get secure config value should be the same as set value');
      
      // 测试移除安全配置
      const removeResult = await configService.removeSecureConfig(testKey);
      expect(removeResult).assertTrue('移除安全配置应该成功 // Remove secure config should be successful');
      
      // 验证安全配置已被移除
      const removedResult = await configService.getSecureConfig(testKey);
      expect(removedResult).assertNull('移除后获取安全配置应该为空 // Get secure config should be null after removal');
      
      console.log('安全存储配置功能测试通过 // Secure storage config functionality test passed');
    });

    it('测试字幕API密钥管理功能 // Test subtitle API key management functionality', 0, async () => {
      // 测试字幕API密钥管理功能 // Test subtitle API key management functionality
      const testProvider = 'SubHD';
      const testApiKey = 'test_subtitle_api_key_123';
      
      // 测试设置字幕API密钥
      const setResult = await configService.setSubtitleApiKey(testProvider, testApiKey);
      expect(setResult).assertTrue('设置字幕API密钥应该成功 // Set subtitle API key should be successful');
      
      // 测试获取字幕API密钥
      const getResult = await configService.getSubtitleApiKey(testProvider);
      expect(getResult).assertNotNull('获取字幕API密钥不能为空 // Get subtitle API key cannot be null');
      expect(getResult).assertEqual(testApiKey, '获取的字幕API密钥应该与设置的值相同 // Get subtitle API key should be the same as set value');
      
      console.log('字幕API密钥管理功能测试通过 // Subtitle API key management functionality test passed');
    });

    it('测试云同步令牌管理功能 // Test cloud sync token management functionality', 0, async () => {
      // 测试云同步令牌管理功能 // Test cloud sync token management functionality
      const testToken = 'test_cloud_sync_token_123';
      
      // 测试设置云同步令牌
      const setResult = await configService.setCloudSyncToken(testToken);
      expect(setResult).assertTrue('设置云同步令牌应该成功 // Set cloud sync token should be successful');
      
      // 测试获取云同步令牌
      const getResult = await configService.getCloudSyncToken();
      expect(getResult).assertNotNull('获取云同步令牌不能为空 // Get cloud sync token cannot be null');
      expect(getResult).assertEqual(testToken, '获取的云同步令牌应该与设置的值相同 // Get cloud sync token should be the same as set value');
      
      console.log('云同步令牌管理功能测试通过 // Cloud sync token management functionality test passed');
    });

    it('测试清除所有安全配置功能 // Test clear all secure config functionality', 0, async () => {
      // 测试清除所有安全配置功能 // Test clear all secure config functionality
      // 先设置一些安全配置
      await configService.setSecureConfig('test_key_1', 'test_value_1');
      await configService.setSecureConfig('test_key_2', 'test_value_2');
      
      // 测试清除所有安全配置
      const clearResult = await configService.clearAllSecureConfig();
      expect(clearResult).assertTrue('清除所有安全配置应该成功 // Clear all secure config should be successful');
      
      // 验证安全配置已被清除
      const result1 = await configService.getSecureConfig('test_key_1');
      const result2 = await configService.getSecureConfig('test_key_2');
      expect(result1).assertNull('清除后获取安全配置1应该为空 // Get secure config 1 should be null after clearing');
      expect(result2).assertNull('清除后获取安全配置2应该为空 // Get secure config 2 should be null after clearing');
      
      console.log('清除所有安全配置功能测试通过 // Clear all secure config functionality test passed');
    });
  });
}
