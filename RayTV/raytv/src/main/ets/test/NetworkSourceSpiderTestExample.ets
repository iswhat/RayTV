// NetworkSourceSpiderTestExample.ets
// 网络源Spider解析能力测试使用示例

import NetworkSourceSpiderTest from './NetworkSourceSpiderTest';
import Logger from '../common/util/Logger';

/**
 * 网络源Spider解析能力测试示例
 */
export class NetworkSourceSpiderTestExample {
  private static instance: NetworkSourceSpiderTestExample | null = null;
  private testService: NetworkSourceSpiderTest;
  private logger: Logger;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NetworkSourceSpiderTestExample {
    if (!NetworkSourceSpiderTestExample.instance) {
      NetworkSourceSpiderTestExample.instance = new NetworkSourceSpiderTestExample();
    }
    return NetworkSourceSpiderTestExample.instance;
  }
  
  /**
   * 构造函数
   */
  private constructor() {
    this.testService = NetworkSourceSpiderTest;
    this.logger = Logger.getInstance('NetworkSourceSpiderTestExample');
  }
  
  /**
   * 运行完整测试示例
   */
  public async runCompleteTestExample(): Promise<void> {
    try {
      this.logger.info('=== 开始网络源Spider解析能力完整测试 ===');
      
      // 初始化测试环境
      await this.testService.initialize();
      
      // 执行完整测试
      const result = await this.testService.runCompleteTest();
      
      // 生成测试报告
      const report = this.testService.generateTestReport(result);
      
      // 输出测试报告
      this.logger.info('\n=== 测试报告 ===');
      this.logger.info(report);
      
      // 分析测试结果
      this.analyzeTestResult(result);
      
    } catch (error) {
      this.logger.error('测试执行失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 运行快速测试示例
   */
  public async runQuickTestExample(): Promise<void> {
    try {
      this.logger.info('=== 开始网络源Spider解析能力快速测试 ===');
      
      // 初始化测试环境
      await this.testService.initialize();
      
      // 执行快速测试
      const result = await this.testService.runQuickTest();
      
      // 生成测试报告
      const report = this.testService.generateTestReport(result);
      
      // 输出测试报告
      this.logger.info('\n=== 快速测试报告 ===');
      this.logger.info(report);
      
      // 分析测试结果
      this.analyzeTestResult(result);
      
    } catch (error) {
      this.logger.error('快速测试执行失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 测试特定网络源示例
   */
  public async testSpecificSourceExample(sourceId: string): Promise<void> {
    try {
      this.logger.info(`=== 开始测试特定网络源: ${sourceId} ===`);
      
      // 初始化测试环境
      await this.testService.initialize();
      
      // 测试特定网络源
      const result = await this.testService.testSpecificSource(sourceId);
      
      // 生成测试报告
      const report = this.testService.generateTestReport(result);
      
      // 输出测试报告
      this.logger.info('\n=== 特定网络源测试报告 ===');
      this.logger.info(report);
      
      // 分析测试结果
      this.analyzeTestResult(result);
      
    } catch (error) {
      this.logger.error('特定网络源测试执行失败', error instanceof Error ? error : new Error(String(error)));
    }
  }
  
  /**
   * 分析测试结果
   */
  private analyzeTestResult(result: any): void {
    const summary = result.summary;
    
    this.logger.info('\n=== 测试结果分析 ===');
    this.logger.info(`网络源总数: ${summary.totalSources}`);
    this.logger.info(`激活的网络源: ${summary.activeSources}`);
    this.logger.info(`解析出的站点数: ${result.spiders.length}`);
    this.logger.info(`测试总数: ${summary.totalTests}`);
    this.logger.info(`通过测试: ${summary.testPassed}`);
    this.logger.info(`失败测试: ${summary.testFailed}`);
    this.logger.info(`成功率: ${summary.successRate.toFixed(2)}%`);
    
    // 分析失败的测试
    const failedTests = result.tests.filter((test: any) => !test.passed);
    if (failedTests.length > 0) {
      this.logger.info('\n=== 失败测试分析 ===');
      failedTests.forEach((test: any) => {
        this.logger.info(`- ${test.testName} (${test.siteKey}.${test.method}): ${test.error}`);
      });
    }
    
    // 分析站点性能
    this.logger.info('\n=== 站点性能分析 ===');
    const sitePerformance = new Map<string, { totalTests: number; passedTests: number; avgResponseTime: number }>();
    
    result.tests.forEach((test: any) => {
      if (!sitePerformance.has(test.siteKey)) {
        sitePerformance.set(test.siteKey, { totalTests: 0, passedTests: 0, avgResponseTime: 0 });
      }
      
      const perf = sitePerformance.get(test.siteKey)!;
      perf.totalTests++;
      if (test.passed) {
        perf.passedTests++;
        perf.avgResponseTime += test.responseTime;
      }
      
      sitePerformance.set(test.siteKey, perf);
    });
    
    sitePerformance.forEach((perf, siteKey) => {
      const siteName = result.spiders.find((s: any) => s.key === siteKey)?.name || siteKey;
      const successRate = (perf.passedTests / perf.totalTests) * 100;
      const avgTime = perf.passedTests > 0 ? (perf.avgResponseTime / perf.passedTests).toFixed(2) : 'N/A';
      
      this.logger.info(`${siteName}: 成功率 ${successRate.toFixed(2)}%, 平均响应时间 ${avgTime}ms`);
    });
  }
  
  /**
   * 运行所有测试示例
   */
  public async runAllExamples(): Promise<void> {
    this.logger.info('=== 运行所有网络源Spider解析能力测试示例 ===');
    
    // 运行快速测试
    await this.runQuickTestExample();
    
    // 等待3秒
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 运行完整测试
    await this.runCompleteTestExample();
    
    // 等待3秒
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // 测试特定网络源（示例：默认配置源A）
    await this.testSpecificSourceExample('source_default_a');
    
    this.logger.info('=== 所有测试示例运行完成 ===');
  }
}

// 导出单例实例
export default NetworkSourceSpiderTestExample.getInstance();

// 示例运行代码（可以在适当的地方调用）
// async function runTestExamples() {
//   const testExample = NetworkSourceSpiderTestExample.getInstance();
//   await testExample.runAllExamples();
// }
// 
// // 运行测试示例
// runTestExamples().catch(err => {
//   console.error('测试示例运行失败:', err);
// });
