// NetworkSourceSpiderTest.ets
// 验证网络源中spider解析能力的测试类

import NetworkSourceManager from '../service/config/NetworkSourceManager';
import CrawlerService from '../service/spider/CrawlerService';
import SourcePoolManager from '../service/pool/SourcePoolManager';
import Logger from '../common/util/Logger';

/**
 * 网络源Spider解析能力验证测试
 */
export class NetworkSourceSpiderTest {
  private static instance: NetworkSourceSpiderTest | null = null;
  private networkSourceManager: NetworkSourceManager;
  private crawlerService: CrawlerService;
  private sourcePoolManager: SourcePoolManager;
  private logger: Logger;
  
  /**
   * 获取单例实例
   */
  public static getInstance(): NetworkSourceSpiderTest {
    if (!NetworkSourceSpiderTest.instance) {
      NetworkSourceSpiderTest.instance = new NetworkSourceSpiderTest();
    }
    return NetworkSourceSpiderTest.instance;
  }
  
  /**
   * 构造函数
   */
  private constructor() {
    this.networkSourceManager = NetworkSourceManager;
    this.crawlerService = CrawlerService.getInstance();
    this.sourcePoolManager = SourcePoolManager.getInstance();
    this.logger = Logger.getInstance('NetworkSourceSpiderTest');
  }
  
  /**
   * 初始化测试环境
   */
  public async initialize(): Promise<void> {
    try {
      this.logger.info('开始初始化测试环境...');
      
      // 初始化网络源管理器
      await this.networkSourceManager.initialize();
      this.logger.info('网络源管理器初始化完成');
      
      // 初始化爬虫服务
      await this.crawlerService.initialize();
      this.logger.info('爬虫服务初始化完成');
      
      // 初始化源池管理器
      await this.sourcePoolManager.initialize();
      this.logger.info('源池管理器初始化完成');
      
      this.logger.info('测试环境初始化完成');
    } catch (error) {
      this.logger.error('测试环境初始化失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
  }
  
  /**
   * 执行完整的网络源Spider解析能力测试
   */
  public async runCompleteTest(): Promise<TestResult> {
    this.logger.info('开始执行完整的网络源Spider解析能力测试...');
    
    const result: TestResult = {
      networkSources: [],
      spiders: [],
      tests: [],
      summary: {
        totalSources: 0,
        activeSources: 0,
        testPassed: 0,
        testFailed: 0,
        totalTests: 0,
        successRate: 0
      }
    };
    
    try {
      // 1. 获取所有网络源
      const networkSources = this.networkSourceManager.getAllSources();
      result.networkSources = networkSources;
      result.summary.totalSources = networkSources.length;
      result.summary.activeSources = networkSources.filter(s => s.isActive).length;
      
      this.logger.info(`发现 ${networkSources.length} 个网络源，其中 ${networkSources.filter(s => s.isActive).length} 个处于激活状态`);
      
      // 2. 重建源池
      await this.networkSourceManager.rebuildPools();
      this.logger.info('源池重建完成');
      
      // 3. 获取所有站点（来自网络源的spider）
      const sites = await this.crawlerService.getAllSites();
      result.spiders = sites;
      
      this.logger.info(`从网络源中解析出 ${sites.length} 个站点`);
      
      // 4. 对每个激活的站点进行测试
      for (const site of sites) {
        if (site.enabled) {
          await this.testSiteSpider(site, result);
        }
      }
      
      // 5. 计算测试结果
      result.summary.totalTests = result.tests.length;
      result.summary.testPassed = result.tests.filter(t => t.passed).length;
      result.summary.testFailed = result.tests.filter(t => !t.passed).length;
      result.summary.successRate = result.summary.totalTests > 0 
        ? (result.summary.testPassed / result.summary.totalTests) * 100 
        : 0;
      
      this.logger.info(`测试完成：共 ${result.summary.totalTests} 项测试，${result.summary.testPassed} 项通过，${result.summary.testFailed} 项失败，成功率：${result.summary.successRate.toFixed(2)}%`);
      
    } catch (error) {
      this.logger.error('测试执行失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
    
    return result;
  }
  
  /**
   * 测试单个站点的Spider能力
   */
  private async testSiteSpider(site: string, result: TestResult): Promise<void> {
    this.logger.info(`开始测试站点: ${site.name} (${site.key})`);
    
    // 测试站点信息获取
    await this.testMethod(site.key, 'getSiteInfo', [], '获取站点信息', result);
    
    // 测试推荐列表获取
    await this.testMethod(site.key, 'getRecommendList', [], '获取推荐列表', result);
    
    // 测试热门列表获取
    await this.testMethod(site.key, 'getHotList', [], '获取热门列表', result);
    
    // 测试最新更新获取
    await this.testMethod(site.key, 'getLatestList', [], '获取最新更新', result);
    
    // 测试分类列表获取
    await this.testMethod(site.key, 'getCategories', [], '获取分类列表', result);
    
    // 测试搜索功能
    await this.testMethod(site.key, 'search', ['测试'], '搜索功能', result);
  }
  
  /**
   * 测试单个方法
   */
  private async testMethod(
    siteKey: string, 
    methodName: string, 
    args: string[], 
    testName: string, 
    result: TestResult
  ): Promise<void> {
    const test: TestCase = {
      siteKey,
      method: methodName,
      testName,
      args,
      passed: false,
      error: '',
      responseTime: 0,
      timestamp: Date.now()
    };
    
    try {
      const startTime = Date.now();
      await this.crawlerService.callSiteMethod(siteKey, methodName, args);
      test.responseTime = Date.now() - startTime;
      test.passed = true;
      this.logger.info(`✓ 测试通过: ${siteKey}.${methodName}`);
    } catch (error) {
      test.error = error instanceof Error ? error.message : String(error);
      this.logger.warn(`✗ 测试失败: ${siteKey}.${methodName} - ${test.error}`);
    }
    
    result.tests.push(test);
  }
  
  /**
   * 测试特定网络源的Spider能力
   */
  public async testSpecificSource(sourceId: string): Promise<TestResult> {
    this.logger.info(`开始测试特定网络源: ${sourceId}`);
    
    const result: TestResult = {
      networkSources: [],
      spiders: [],
      tests: [],
      summary: {
        totalSources: 1,
        activeSources: 0,
        testPassed: 0,
        testFailed: 0,
        totalTests: 0,
        successRate: 0
      }
    };
    
    try {
      // 获取指定网络源
      const source = this.networkSourceManager.getSourceById(sourceId);
      if (!source) {
        throw new Error(`网络源 ${sourceId} 不存在`);
      }
      
      result.networkSources.push(source);
      result.summary.activeSources = source.isActive ? 1 : 0;
      
      // 如果源未激活，先激活它
      let wasInactive = false;
      if (!source.isActive) {
        wasInactive = true;
        await this.networkSourceManager.toggleSource(sourceId, true);
      }
      
      // 重建源池
      await this.networkSourceManager.rebuildPools();
      
      // 获取所有站点
      const sites = await this.crawlerService.getAllSites();
      result.spiders = sites;
      
      // 测试每个站点
      for (const site of sites) {
        if (site.enabled) {
          await this.testSiteSpider(site, result);
        }
      }
      
      // 恢复源的状态
      if (wasInactive) {
        await this.networkSourceManager.toggleSource(sourceId, false);
        await this.networkSourceManager.rebuildPools();
      }
      
      // 计算测试结果
      result.summary.totalTests = result.tests.length;
      result.summary.testPassed = result.tests.filter(t => t.passed).length;
      result.summary.testFailed = result.tests.filter(t => !t.passed).length;
      result.summary.successRate = result.summary.totalTests > 0 
        ? (result.summary.testPassed / result.summary.totalTests) * 100 
        : 0;
      
    } catch (error) {
      this.logger.error('测试特定网络源失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
    
    return result;
  }
  
  /**
   * 生成测试报告
   */
  public generateTestReport(result: TestResult): string {
    let report = `# 网络源Spider解析能力测试报告\n\n`;
    
    report += `## 测试摘要\n`;
    report += `- 网络源总数: ${result.summary.totalSources}\n`;
    report += `- 激活的网络源: ${result.summary.activeSources}\n`;
    report += `- 解析出的站点数: ${result.spiders.length}\n`;
    report += `- 测试总数: ${result.summary.totalTests}\n`;
    report += `- 通过测试: ${result.summary.testPassed}\n`;
    report += `- 失败测试: ${result.summary.testFailed}\n`;
    report += `- 成功率: ${result.summary.successRate.toFixed(2)}%\n\n`;
    
    report += `## 网络源详情\n`;
    for (const source of result.networkSources) {
      report += `### ${source.name} (${source.id})\n`;
      report += `- URL: ${source.url}\n`;
      report += `- 状态: ${source.isActive ? '激活' : '未激活'}\n`;
      report += `- 健康状态: ${source.healthStatus}\n`;
      report += `- 优先级: ${source.priority}\n`;
      report += `- 内容使用: ${JSON.stringify(source.contentUsage)}\n\n`;
    }
    
    report += `## 站点详情\n`;
    for (const site of result.spiders) {
      report += `### ${site.name} (${site.key})\n`;
      report += `- 类型: ${site.type}\n`;
      report += `- URL: ${site.url}\n`;
      report += `- 状态: ${site.enabled ? '启用' : '禁用'}\n\n`;
    }
    
    report += `## 测试详情\n`;
    for (const test of result.tests) {
      const status = test.passed ? '✓ 通过' : '✗ 失败';
      report += `- ${status}: ${test.testName} (${test.siteKey}.${test.method})\n`;
      if (!test.passed) {
        report += `  - 错误: ${test.error}\n`;
      }
      report += `  - 响应时间: ${test.responseTime}ms\n`;
    }
    
    return report;
  }
  
  /**
   * 执行快速测试（只测试基本功能）
   */
  public async runQuickTest(): Promise<TestResult> {
    this.logger.info('开始执行快速测试...');
    
    const result: TestResult = {
      networkSources: [],
      spiders: [],
      tests: [],
      summary: {
        totalSources: 0,
        activeSources: 0,
        testPassed: 0,
        testFailed: 0,
        totalTests: 0,
        successRate: 0
      }
    };
    
    try {
      // 获取所有网络源
      const networkSources = this.networkSourceManager.getAllSources();
      result.networkSources = networkSources;
      result.summary.totalSources = networkSources.length;
      result.summary.activeSources = networkSources.filter(s => s.isActive).length;
      
      // 重建源池
      await this.networkSourceManager.rebuildPools();
      
      // 获取所有站点
      const sites = await this.crawlerService.getAllSites();
      result.spiders = sites;
      
      // 对每个激活的站点只测试基本功能
      for (const site of sites) {
        if (site.enabled) {
          // 只测试站点信息和推荐列表
          await this.testMethod(site.key, 'getSiteInfo', [], '获取站点信息', result);
          await this.testMethod(site.key, 'getRecommendList', [], '获取推荐列表', result);
        }
      }
      
      // 计算测试结果
      result.summary.totalTests = result.tests.length;
      result.summary.testPassed = result.tests.filter(t => t.passed).length;
      result.summary.testFailed = result.tests.filter(t => !t.passed).length;
      result.summary.successRate = result.summary.totalTests > 0 
        ? (result.summary.testPassed / result.summary.totalTests) * 100 
        : 0;
      
    } catch (error) {
      this.logger.error('快速测试执行失败', error instanceof Error ? error : new Error(String(error)));
      throw error;
    }
    
    return result;
  }
}

/**
 * 测试结果接口
 */
export interface TestResult {
  networkSources: string[];
  spiders: string[];
  tests: TestCase[];
  summary: TestSummary;
}

/**
 * 测试用例接口
 */
export interface TestCase {
  siteKey: string;
  method: string;
  testName: string;
  args: string[];
  passed: boolean;
  error: string;
  responseTime: number;
  timestamp: number;
}

/**
 * 测试摘要接口
 */
export interface TestSummary {
  totalSources: number;
  activeSources: number;
  testPassed: number;
  testFailed: number;
  totalTests: number;
  successRate: number;
}

// 导出单例实例
export default NetworkSourceSpiderTest.getInstance();
