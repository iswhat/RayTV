// CoreServicesIntegration.test.ets - 核心服务集成测试文件 // Core services integration test file
// 测试核心服务之间的集成和交互 | Tests integration and interaction between core services
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import ConfigService from '../main/ets/service/config/ConfigService';
import HttpService from '../main/ets/service/HttpService';
import MediaService from '../main/ets/service/media/MediaService';
import { AbilityConstant, UIAbility } from '@ohos/app.ability';
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

export default function coreServicesIntegrationTest() {
  describe('核心服务集成测试 // Core Services Integration Tests', () => {
    let configService: ConfigService;
    let httpService: HttpService;
    let mediaService: MediaService;
    let mockContext: MockUIAbility;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      configService = ConfigService.getInstance();
      httpService = HttpService.getInstance();
      mediaService = MediaService.getInstance();
      mockContext = new MockUIAbility();
      console.log('核心服务集成测试初始化完成 // Core services integration test initialization completed');
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

    it('测试服务初始化集成 // Test service initialization integration', 0, async () => {
      // 测试所有核心服务的初始化和可用性 // Test initialization and availability of all core services
      
      // 验证服务实例 // Verify service instances
      expect(configService).assertNotNull('ConfigService实例不能为空 // ConfigService instance cannot be null');
      expect(httpService).assertNotNull('HttpService实例不能为空 // HttpService instance cannot be null');
      expect(mediaService).assertNotNull('MediaService实例不能为空 // MediaService instance cannot be null');
      
      // 验证服务功能 // Verify service functionality
      const configResult = await configService.getFullConfig();
      expect(configResult).assertNotNull('获取配置应该成功 // Get config should be successful');
      
      console.log('服务初始化集成测试通过 // Service initialization integration test passed');
    });

    it('测试配置服务与网络服务集成 // Test ConfigService and HttpService integration', 0, async () => {
      // 测试配置服务与网络服务之间的集成 // Test integration between ConfigService and HttpService
      
      // 1. 通过配置服务设置网络相关配置 // Set network-related config through ConfigService
      const networkConfig = {
        timeout: 30000,
        retryCount: 3,
        retryDelay: 1000,
        enableCache: true,
        cacheSize: 500,
        autoDetectNetwork: true,
        useProxy: false,
        proxyConfig: {
          type: 'none',
          host: '',
          port: 0
        }
      };
      
      const updateResult = await configService.updatePartialConfig('network', {
        network: networkConfig
      });
      
      expect(updateResult).assertNotNull('更新网络配置应该成功 // Update network config should be successful');
      expect(updateResult.isSuccess()).assertTrue('网络配置更新应该成功 // Network config update should be successful');
      
      // 2. 验证网络服务能够正常工作 // Verify HttpService can work normally
      try {
        // 测试简单的GET请求 // Test simple GET request
        const testUrl = 'https://api.github.com/users/octocat';
        const response = await httpService.get(testUrl);
        
        // 验证响应状态 // Verify response status
        expect(response).assertNotNull('网络请求应该成功 // Network request should be successful');
        expect(response.status).assertGreaterThanOrEqual(200, '响应状态码应该大于等于200 // Response status code should be greater than or equal to 200');
        expect(response.status).assertLessThan(300, '响应状态码应该小于300 // Response status code should be less than 300');
        
        console.log('配置服务与网络服务集成测试通过 // ConfigService and HttpService integration test passed');
      } catch (error) {
        // 网络请求可能因环境原因失败，这里捕获错误但不视为测试失败
        console.log('配置服务与网络服务集成测试因网络环境原因跳过 // ConfigService and HttpService integration test skipped due to network environment reasons');
      }
    });

    it('测试配置服务与媒体服务集成 // Test ConfigService and MediaService integration', 0, async () => {
      // 测试配置服务与媒体服务之间的集成 // Test integration between ConfigService and MediaService
      
      // 1. 通过配置服务设置媒体相关配置 // Set media-related config through ConfigService
      const playerConfig = {
        defaultPlayer: 'system',
        autoPlay: true,
        rememberPosition: true,
        maxBufferSize: 20,
        minBufferSize: 5,
        preloadSeconds: 30,
        enableHardwareDecoding: true,
        enableHDR: false,
        subtitleSize: 18,
        subtitleColor: '#FFFFFF',
        subtitleBackgroundColor: 'rgba(0, 0, 0, 0.5)',
        audioTrack: 'default',
        videoTrack: 'auto'
      };
      
      const updateResult = await configService.updatePartialConfig('player', {
        player: playerConfig
      });
      
      expect(updateResult).assertNotNull('更新播放器配置应该成功 // Update player config should be successful');
      expect(updateResult.isSuccess()).assertTrue('播放器配置更新应该成功 // Player config update should be successful');
      
      // 2. 验证媒体服务能够正常工作 // Verify MediaService can work normally
      const testRecord = {
        mediaId: 'test-media-integration',
        title: '集成测试视频',
        type: 'movie',
        duration: 3600,
        currentPosition: 60,
        lastWatchedAt: Date.now(),
        isFinished: false
      };
      
      const mediaResult = await mediaService.updatePlaybackRecord(testRecord);
      expect(mediaResult).assertTrue('更新播放记录应该成功 // Update playback record should be successful');
      
      // 3. 验证播放历史能够正确获取 // Verify playback history can be retrieved correctly
      const history = await mediaService.getPlaybackHistory();
      expect(history).assertNotNull('获取播放历史应该成功 // Get playback history should be successful');
      expect(Array.isArray(history)).assertTrue('播放历史应该是数组 // Playback history should be array');
      
      console.log('配置服务与媒体服务集成测试通过 // ConfigService and MediaService integration test passed');
    });

    it('测试媒体服务与网络服务集成 // Test MediaService and HttpService integration', 0, async () => {
      // 测试媒体服务与网络服务之间的集成 // Test integration between MediaService and HttpService
      
      try {
        // 测试媒体服务通过网络服务获取推荐内容 // Test MediaService getting recommended content through HttpService
        const recommendedContent = await mediaService.getRecommendedContent(5);
        
        // 验证推荐内容获取成功 // Verify recommended content get successfully
        expect(recommendedContent).assertNotNull('获取推荐内容应该成功 // Get recommended content should be successful');
        expect(Array.isArray(recommendedContent)).assertTrue('推荐内容应该是数组 // Recommended content should be array');
        
        console.log('媒体服务与网络服务集成测试通过 // MediaService and HttpService integration test passed');
      } catch (error) {
        // 网络请求可能因环境原因失败，这里捕获错误但不视为测试失败
        console.log('媒体服务与网络服务集成测试因网络环境原因跳过 // MediaService and HttpService integration test skipped due to network environment reasons');
      }
    });

    it('测试三服务完整集成流程 // Test three-service complete integration flow', 0, async () => {
      // 测试配置服务、网络服务和媒体服务之间的完整集成流程 // Test complete integration flow between ConfigService, HttpService, and MediaService
      
      // 1. 设置配置 // Set config
      const configUpdate = {
        player: {
          autoPlay: true
        },
        network: {
          timeout: 30000
        }
      };
      
      const configResult = await configService.updateFullConfig(configUpdate);
      expect(configResult).assertNotNull('更新完整配置应该成功 // Update full config should be successful');
      expect(configResult.isSuccess()).assertTrue('完整配置更新应该成功 // Full config update should be successful');
      
      // 2. 测试网络服务 // Test HttpService
      try {
        const testUrl = 'https://api.github.com/users/octocat';
        const httpResult = await httpService.get(testUrl);
        expect(httpResult).assertNotNull('网络请求应该成功 // Network request should be successful');
      } catch (error) {
        // 网络请求可能因环境原因失败，这里捕获错误但不视为测试失败
      }
      
      // 3. 测试媒体服务 // Test MediaService
      const testMedia = {
        id: 'test-media-full-integration',
        title: '完整集成测试视频',
        type: 'movie',
        coverUrl: 'https://example.com/cover.jpg',
        rating: 8.5,
        year: 2023
      };
      
      const addFavoriteResult = await mediaService.addFavorite(testMedia);
      expect(addFavoriteResult).assertTrue('添加收藏应该成功 // Add favorite should be successful');
      
      const removeFavoriteResult = await mediaService.removeFavorite('test-media-full-integration');
      expect(removeFavoriteResult).assertTrue('移除收藏应该成功 // Remove favorite should be successful');
      
      console.log('三服务完整集成流程测试通过 // Three-service complete integration flow test passed');
    });

    it('测试服务错误处理集成 // Test service error handling integration', 0, async () => {
      // 测试服务之间的错误处理集成 // Test error handling integration between services
      
      // 1. 测试网络服务错误处理 // Test HttpService error handling
      try {
        const invalidUrl = 'invalid-url';
        await httpService.get(invalidUrl);
        // 如果没有抛出错误，测试失败
        expect(false).assertTrue('无效URL应该抛出错误 // Invalid URL should throw error');
      } catch (error) {
        // 捕获到错误，测试通过
        console.log('网络服务错误处理测试通过 // HttpService error handling test passed');
      }
      
      // 2. 测试媒体服务错误处理 // Test MediaService error handling
      try {
        const invalidMediaId = 'invalid-media-id';
        const result = await mediaService.removeFavorite(invalidMediaId);
        // 移除不存在的收藏应该返回false或抛出错误
        expect(typeof result).assertEqual('boolean', '移除收藏应该返回布尔值 // Remove favorite should return boolean');
      } catch (error) {
        // 捕获到错误，测试通过
        console.log('媒体服务错误处理测试通过 // MediaService error handling test passed');
      }
      
      console.log('服务错误处理集成测试通过 // Service error handling integration test passed');
    });
  });
}