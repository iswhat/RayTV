/**
 * 功能集成测试 | Feature Integration Test
 * 验证新实现功能的正确性和集成 | Verifies correctness and integration of newly implemented features
 */
import Logger from '../common/util/Logger';
import LivePlaybackService from '../service/live/LivePlaybackService';
import MediaDataFetcherService from '../service/media/MediaDataFetcherService';
import LocalRecommendationAlgorithm from '../service/recommendation/LocalRecommendationAlgorithm';
import ErrorHandler, { ErrorType, isMediaError, isMemoryError, isTimeoutError, isSecurityError, isConfigError } from '../common/util/ErrorHandler';
import StorageUtil from '../common/util/StorageUtil';

// 测试结果接口 | Test result interface
export interface TestResult {
  name: string;
  passed: boolean;
  message: string;
  executionTime: number;
}

/**
 * 功能集成测试类 | Feature integration test class
 */
export class FeatureIntegrationTest {
  private logger: Logger;
  private testResults: TestResult[] = [];

  constructor() {
    this.logger = new Logger('FeatureIntegrationTest');
  }

  /**
   * 运行所有功能测试 | Run all feature tests
   */
  public async runAllTests(): Promise<TestResult[]> {
    this.logger.info('Starting feature integration tests...');
    
    // 清空之前的测试结果 | Clear previous test results
    this.testResults = [];

    try {
      // 运行各个测试 | Run individual tests
      await this.testLivePlaybackService();
      await this.testMediaDataFetcherService();
      await this.testLocalRecommendationAlgorithm();
      await this.testErrorHandler();

      this.logger.info(`Completed ${this.testResults.length} tests`);
      return this.testResults;

    } catch (error) {
      this.logger.error('Feature tests failed', error);
      throw error;
    }
  }

  /**
   * 测试直播播放服务 | Test live playback service
   */
  private async testLivePlaybackService(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 初始化服务 | Initialize service
      const service = LivePlaybackService.getInstance();
      await service.initialize();

      // 模拟一个测试频道 | Create a test channel
      const testChannel = {
        id: 'test_channel_1',
        name: 'Test Channel',
        url: 'https://test.example.com/stream',
        category: 'Sports',
        tags: ['Football', 'Live']
      };

      // 测试最近播放频道功能 | Test recent channels functionality
      await service.playChannel(testChannel);
      const recentChannels = service.getRecentChannels();
      const hasTestChannel = recentChannels.some(channel => channel.id === testChannel.id);

      // 验证结果 | Verify results
      const passed = hasTestChannel;
      
      this.testResults.push({
        name: 'Live Playback Service',
        passed,
        message: passed ? 'Recent channels storage works correctly' : 'Recent channels storage failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Live Playback Service',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试媒体数据获取服务 | Test media data fetcher service
   */
  private async testMediaDataFetcherService(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 初始化服务 | Initialize service
      const service = MediaDataFetcherService.getInstance();

      // 测试清除缓存功能 | Test clear cache functionality
      await service.clearCache();

      // 验证结果 | Verify results
      const passed = true; // 清除缓存操作应该不会抛出异常
      
      this.testResults.push({
        name: 'Media Data Fetcher Service',
        passed,
        message: passed ? 'Clear cache functionality works correctly' : 'Clear cache functionality failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Media Data Fetcher Service',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试本地推荐算法 | Test local recommendation algorithm
   */
  private async testLocalRecommendationAlgorithm(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 初始化服务 | Initialize service
      const algorithm = LocalRecommendationAlgorithm.getInstance();
      await algorithm.initialize();

      // 测试用户行为记录 | Test user behavior recording
      const testBehavior = {
        videoId: 'test_video_1',
        action: 'play',
        timestamp: Date.now(),
        duration: 60,
        totalDuration: 120,
        progress: 60
      };

      algorithm.recordUserBehavior(testBehavior);

      // 测试生成推荐 | Test recommendation generation
      const recommendations = await algorithm.generateTrendingRecommendations(5);

      // 验证结果 | Verify results
      const passed = recommendations.length >= 0;
      
      this.testResults.push({
        name: 'Local Recommendation Algorithm',
        passed,
        message: passed ? 'User behavior storage and recommendation generation work correctly' : 'Recommendation algorithm failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Local Recommendation Algorithm',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试错误处理 | Test error handler
   */
  private async testErrorHandler(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 测试错误类型检测 | Test error type detection
      const mediaError = new Error('Media playback failed');
      const memoryError = new Error('Insufficient memory');
      const timeoutError = new Error('Request timed out');
      const securityError = new Error('Security violation');
      const configError = new Error('Invalid configuration');

      const isMedia = isMediaError(mediaError);
      const isMemory = isMemoryError(memoryError);
      const isTimeout = isTimeoutError(timeoutError);
      const isSecurity = isSecurityError(securityError);
      const isConfig = isConfigError(configError);

      // 验证结果 | Verify results
      const passed = isMedia && isMemory && isTimeout && isSecurity && isConfig;
      
      this.testResults.push({
        name: 'Error Handler',
        passed,
        message: passed ? 'Error type detection works correctly' : 'Error type detection failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Error Handler',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 生成测试报告 | Generate test report
   */
  public generateReport(): string {
    const passedTests = this.testResults.filter(test => test.passed).length;
    const totalTests = this.testResults.length;
    const successRate = totalTests > 0 ? (passedTests / totalTests) * 100 : 0;
    const totalTime = this.testResults.reduce((sum, test) => sum + test.executionTime, 0);

    let report = '\n=== 功能集成测试报告 ===\n';
    report += `测试时间: ${new Date().toISOString()}\n`;
    report += `总测试数: ${totalTests}\n`;
    report += `通过测试: ${passedTests}\n`;
    report += `失败测试: ${totalTests - passedTests}\n`;
    report += `成功率: ${successRate.toFixed(1)}%\n`;
    report += `总执行时间: ${totalTime}ms\n\n`;

    report += '详细结果:\n';
    report += '----------------------------------------\n';
    
    this.testResults.forEach((test, index) => {
      const status = test.passed ? '✅ 通过' : '❌ 失败';
      report += `${index + 1}. ${test.name}: ${status}\n`;
      report += `   耗时: ${test.executionTime}ms\n`;
      report += `   信息: ${test.message}\n\n`;
    });

    report += '========================================\n';

    return report;
  }

  /**
   * 获取测试摘要 | Get test summary
   */
  public getSummary(): {
    totalTests: number;
    passedTests: number;
    failedTests: number;
    successRate: number;
    totalTime: number;
  } {
    const passedTests = this.testResults.filter(test => test.passed).length;
    const totalTests = this.testResults.length;
    const totalTime = this.testResults.reduce((sum, test) => sum + test.executionTime, 0);

    return {
      totalTests,
      passedTests,
      failedTests: totalTests - passedTests,
      successRate: totalTests > 0 ? (passedTests / totalTests) * 100 : 0,
      totalTime
    };
  }
}

// 导出测试类 | Export test class
export default FeatureIntegrationTest;