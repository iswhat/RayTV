/**
 * 基础设施集成测试 | Infrastructure Integration Test
 * 验证核心组件的功能和集成 | Verifies core component functionality and integration
 */
import Logger from '../common/util/Logger';
import DIContainer from '../common/di/Container';
import EventBus from '../common/event/EventBus';
import ConfigSourceService from '../service/config/ConfigSourceService';
import ContentAggregator from '../service/content/ContentAggregator';
import ParserManager from '../service/parser/ParserManager';
import PerformanceMonitor from '../common/util/PerformanceMonitor';
import { AppEvents } from '../common/event/EventBus';
import ApiResponse from '../data/dto/ApiResponse';

// 测试结果接口 | Test result interface
interface TestResult {
  name: string;
  passed: boolean;
  message: string;
  executionTime: number;
}

/**
 * 基础设施集成测试类 | Infrastructure integration test class
 */
export class InfrastructureIntegrationTest {
  private logger: Logger;
  private testResults: TestResult[] = [];

  constructor() {
    this.logger = new Logger('InfrastructureIntegrationTest');
  }

  /**
   * 运行所有集成测试 | Run all integration tests
   */
  public async runAllTests(): Promise<TestResult[]> {
    this.logger.info('Starting infrastructure integration tests...');
    
    // 清空之前的测试结果 | Clear previous test results
    this.testResults = [];

    try {
      // 运行各个测试 | Run individual tests
      await this.testDependencyInjection();
      await this.testEventBus();
      await this.testConfigSourceService();
      await this.testContentAggregator();
      await this.testParserManager();
      await this.testPerformanceMonitor();
      await this.testCrossComponentIntegration();

      this.logger.info(`Completed ${this.testResults.length} tests`);
      return this.testResults;

    } catch (error) {
      this.logger.error('Integration tests failed', error);
      throw error;
    }
  }

  /**
   * 测试依赖注入功能 | Test dependency injection functionality
   */
  private async testDependencyInjection(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 测试服务注册 | Test service registration
      DIContainer.register('TestService', () => ({ 
        getValue: () => 'test_value' 
      }), true);

      // 测试服务解析 | Test service resolution
      const testService = DIContainer.resolve<{ getValue: () => string }>('TestService');
      const value = testService.getValue();

      // 验证结果 | Verify results
      const passed = value === 'test_value';
      
      this.testResults.push({
        name: 'Dependency Injection',
        passed,
        message: passed ? 'Service registration and resolution works correctly' : 'Service resolution failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Dependency Injection',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试事件总线功能 | Test event bus functionality
   */
  private async testEventBus(): Promise<void> {
    const startTime = Date.now();
    
    try {
      let eventReceived = false;
      let eventData: any = null;

      // 订阅事件 | Subscribe to event
      const subscriptionId = EventBus.subscribe('test_event', (data) => {
        eventReceived = true;
        eventData = data;
      });

      // 发布事件 | Publish event
      EventBus.publish('test_event', { test: 'data' });

      // 验证事件接收 | Verify event reception
      const passed = eventReceived && eventData?.test === 'data';
      
      // 清理订阅 | Cleanup subscription
      EventBus.unsubscribe('test_event', subscriptionId);

      this.testResults.push({
        name: 'Event Bus',
        passed,
        message: passed ? 'Event publishing and subscription works correctly' : 'Event handling failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Event Bus',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试配置源服务 | Test config source service
   */
  private async testConfigSourceService(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 初始化服务 | Initialize service
      await ConfigSourceService.initialize();

      // 测试添加配置源 | Test adding config source
      const addResult = await ConfigSourceService.addSource(
        'https://test.example.com/config.json',
        'Test Config Source'
      );

      // 验证结果 | Verify results
      const passed = addResult.isSuccess();
      
      this.testResults.push({
        name: 'Config Source Service',
        passed,
        message: passed ? 'Config source management works correctly' : `Config source test failed: ${addResult.message}`,
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Config Source Service',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试内容聚合器 | Test content aggregator
   */
  private async testContentAggregator(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 设置依赖服务 | Set up dependent services
      ContentAggregator.setConfigSourceService(ConfigSourceService);

      // 初始化服务 | Initialize service
      await ContentAggregator.initialize();

      // 测试获取统计信息 | Test getting statistics
      const statsResult = await ContentAggregator.getStatistics();

      // 验证结果 | Verify results
      const passed = statsResult.isSuccess();
      
      this.testResults.push({
        name: 'Content Aggregator',
        passed,
        message: passed ? 'Content aggregation service works correctly' : `Aggregation test failed: ${statsResult.message}`,
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Content Aggregator',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试解析器管理器 | Test parser manager
   */
  private async testParserManager(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 初始化服务 | Initialize service
      await ParserManager.initialize();

      // 测试验证解析器文件 | Test validating parser file
      const validationResult = await ParserManager.validateParserFile('./test-parser.js');

      // 验证结果 | Verify results
      const passed = validationResult.isSuccess();
      
      this.testResults.push({
        name: 'Parser Manager',
        passed,
        message: passed ? 'Parser management works correctly' : `Parser test failed: ${validationResult.message}`,
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Parser Manager',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试性能监控 | Test performance monitor
   */
  private async testPerformanceMonitor(): Promise<void> {
    const startTime = Date.now();
    
    try {
      // 测试性能测量 | Test performance measurement
      const measurementId = PerformanceMonitor.startMeasurement('test_operation');
      
      // 模拟一些工作 | Simulate some work
      await new Promise(resolve => setTimeout(resolve, 10));
      
      const metric = PerformanceMonitor.endMeasurement(measurementId, true);

      // 验证结果 | Verify results
      const passed = metric !== null && metric.duration > 0;
      
      this.testResults.push({
        name: 'Performance Monitor',
        passed,
        message: passed ? 'Performance monitoring works correctly' : 'Performance measurement failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Performance Monitor',
        passed: false,
        message: `Test failed: ${(error as Error).message}`,
        executionTime: Date.now() - startTime
      });
    }
  }

  /**
   * 测试跨组件集成 | Test cross-component integration
   */
  private async testCrossComponentIntegration(): Promise<void> {
    const startTime = Date.now();
    
    try {
      let eventReceived = false;

      // 测试事件驱动的跨组件通信 | Test event-driven cross-component communication
      EventBus.subscribe(AppEvents.CONFIG_SOURCE_ADDED, (data) => {
        eventReceived = true;
      });

      // 通过配置源服务触发事件 | Trigger event through config source service
      await ConfigSourceService.addSource(
        'https://integration-test.example.com/config.json',
        'Integration Test Source'
      );

      // 验证事件传播 | Verify event propagation
      const passed = eventReceived;
      
      this.testResults.push({
        name: 'Cross-Component Integration',
        passed,
        message: passed ? 'Cross-component communication works correctly' : 'Cross-component integration failed',
        executionTime: Date.now() - startTime
      });

    } catch (error) {
      this.testResults.push({
        name: 'Cross-Component Integration',
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

    let report = '\n=== 基础设施集成测试报告 ===\n';
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
export default InfrastructureIntegrationTest;