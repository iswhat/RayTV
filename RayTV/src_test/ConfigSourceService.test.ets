/**
 * 配置服务测试套件 | Config Service Test Suite
 * P0级优先级 - 核心配置管理服务测试
 */

import { ConfigSourceService } from '../service/config/ConfigSourceService';
import { EnhancedDIContainer } from '../common/di/EnhancedContainer';
import { HttpService } from '../service/HttpService';

// ==================== Mock服务 | Mock Services ====================

class MockHttpService extends HttpService {
  private mockResponses: Map<string, any> = new Map();
  private callCounts: Map<string, number> = new Map();
  
  public setMockResponse(url: string, response: any): void {
    this.mockResponses.set(url, response);
  }
  
  public getCallCount(url: string): number {
    return this.callCounts.get(url) || 0;
  }
  
  public async get<T>(url: string, options?: RequestConfig): Promise<T> {
    const count = this.callCounts.get(url) || 0;
    this.callCounts.set(url, count + 1);
    
    const response = this.mockResponses.get(url);
    if (response) {
      if (response instanceof Promise) {
        return response;
      }
      return Promise.resolve(response);
    }
    return Promise.reject(new Error(`No mock response for ${url}`));
  }
  
  public async post<T>(url: string, data?: any, options?: RequestConfig): Promise<T> {
    const count = this.callCounts.get(url) || 0;
    this.callCounts.set(url, count + 1);
    
    const response = this.mockResponses.get(url);
    if (response) {
      return Promise.resolve(response);
    }
    return Promise.reject(new Error(`No mock response for ${url}`));
  }
}

describe('ConfigSourceService Tests', () => {
  let configService: ConfigSourceService;
  let httpService: MockHttpService;
  let diContainer: EnhancedDIContainer;
  
  beforeEach(() => {
    diContainer = EnhancedDIContainer.getInstance();
    httpService = new MockHttpService();
    configService = new ConfigSourceService();
    
    // 注册mock服务到容器
    diContainer.register('HttpService', () => httpService, true);
  });
  
  afterEach(async () => {
    await diContainer.destroy();
  });
  
  // ==================== 基础功能测试 | Basic Functionality Tests ====================
  
  describe('基础创建和初始化测试', () => {
    it('应该正确创建ConfigSourceService实例', () => {
      expect(configService).toBeInstanceOf(ConfigSourceService);
      expect(configService).toBeDefined();
    });
    
    it('应该能够正确初始化服务', async () => {
      // Mock配置响应
      httpService.setMockResponse('/api/config/sources', [
        { id: '1', name: '默认源', url: 'https://default.com/config.json', enabled: true },
        { id: '2', name: '备用源', url: 'https://backup.com/config.json', enabled: false }
      ]);
      
      await configService.initialize();
      
      // 验证初始化结果
      const sources = configService.getConfigSources();
      expect(sources).toHaveLength(2);
      expect(sources[0].name).toBe('默认源');
      expect(sources[0].enabled).toBe(true);
    });
    
    it('应该正确处理初始化失败', async () => {
      // Mock失败的配置请求
      httpService.setMockResponse('/api/config/sources', 
        Promise.reject(new Error('Network error')));
      
      try {
        await configService.initialize();
        expect(true).toBe(false); // 不应该到达这里
      } catch (error) {
        expect(error).toBeDefined();
        expect(error.message).toContain('Network error');
      }
    });
  });
  
  // ==================== 配置源管理测试 | Config Source Management Tests ====================
  
  describe('配置源管理测试', () => {
    beforeEach(async () => {
      // 设置基础mock数据
      httpService.setMockResponse('/api/config/sources', [
        { id: '1', name: '源1', url: 'https://source1.com', enabled: true },
        { id: '2', name: '源2', url: 'https://source2.com', enabled: false }
      ]);
      
      await configService.initialize();
    });
    
    it('应该能够获取所有配置源', () => {
      const sources = configService.getConfigSources();
      expect(sources).toHaveLength(2);
      expect(sources[0].id).toBe('1');
      expect(sources[1].id).toBe('2');
    });
    
    it('应该能够根据ID获取特定配置源', () => {
      const source = configService.getConfigSourceById('1');
      expect(source).toBeDefined();
      expect(source?.id).toBe('1');
      expect(source?.name).toBe('源1');
    });
    
    it('应该正确处理不存在的配置源ID', () => {
      const source = configService.getConfigSourceById('non-existent');
      expect(source).toBeNull();
    });
    
    it('应该能够获取启用的配置源', () => {
      const enabledSources = configService.getEnabledConfigSources();
      expect(enabledSources).toHaveLength(1);
      expect(enabledSources[0].id).toBe('1');
      expect(enabledSources[0].enabled).toBe(true);
    });
    
    it('应该能够添加新的配置源', async () => {
      const newSource = {
        id: '3',
        name: '新源',
        url: 'https://new-source.com',
        enabled: true
      };
      
      httpService.setMockResponse('/api/config/sources', Promise.resolve({ success: true }));
      
      await configService.addConfigSource(newSource);
      
      // 验证添加成功
      const sources = configService.getConfigSources();
      expect(sources).toHaveLength(3);
      expect(sources[2].id).toBe('3');
    });
    
    it('应该能够更新现有配置源', async () => {
      const updatedSource = {
        id: '1',
        name: '更新后的源1',
        url: 'https://updated-source1.com',
        enabled: false
      };
      
      httpService.setMockResponse('/api/config/sources/1', Promise.resolve({ success: true }));
      
      await configService.updateConfigSource(updatedSource);
      
      // 验证更新成功
      const source = configService.getConfigSourceById('1');
      expect(source?.name).toBe('更新后的源1');
      expect(source?.enabled).toBe(false);
    });
    
    it('应该能够删除配置源', async () => {
      httpService.setMockResponse('/api/config/sources/2', Promise.resolve({ success: true }));
      
      await configService.deleteConfigSource('2');
      
      // 验证删除成功
      const sources = configService.getConfigSources();
      expect(sources).toHaveLength(1);
      expect(sources[0].id).toBe('1');
    });
  });
  
  // ==================== 配置加载测试 | Config Loading Tests ====================
  
  describe('配置加载测试', () => {
    beforeEach(async () => {
      // 设置配置源
      httpService.setMockResponse('/api/config/sources', [
        { 
          id: 'main', 
          name: '主配置源', 
          url: 'https://main-config.com/config.json', 
          enabled: true 
        }
      ]);
      
      await configService.initialize();
    });
    
    it('应该能够从配置源加载配置', async () => {
      // Mock配置数据
      const mockConfig = {
        version: '1.0.0',
        siteConfigs: [
          { id: 'site1', name: '网站1', apiUrl: 'https://site1.com/api' }
        ],
        features: {
          enableSearch: true,
          enableLive: false
        }
      };
      
      httpService.setMockResponse('https://main-config.com/config.json', mockConfig);
      
      const config = await configService.loadConfigFromSource('main');
      
      expect(config).toBeDefined();
      expect(config.version).toBe('1.0.0');
      expect(config.siteConfigs).toHaveLength(1);
      expect(config.features.enableSearch).toBe(true);
    });
    
    it('应该正确处理配置加载失败', async () => {
      httpService.setMockResponse('https://main-config.com/config.json', 
        Promise.reject(new Error('Config load failed')));
      
      try {
        await configService.loadConfigFromSource('main');
        expect(true).toBe(false);
      } catch (error) {
        expect(error).toBeDefined();
        expect(error.message).toBe('Config load failed');
      }
    });
    
    it('应该能够从多个源加载配置', async () => {
      // 添加备用配置源
      const backupSource = {
        id: 'backup',
        name: '备用源',
        url: 'https://backup-config.com/config.json',
        enabled: true
      };
      
      httpService.setMockResponse('/api/config/sources', [
        { id: 'main', name: '主源', url: 'https://main.com/config.json', enabled: true },
        backupSource
      ]);
      
      httpService.setMockResponse('https://main.com/config.json', 
        Promise.reject(new Error('Main source failed')));
      httpService.setMockResponse('https://backup-config.com/config.json', {
        version: '1.0.0',
        siteConfigs: [{ id: 'backup-site', name: '备用网站' }]
      });
      
      await configService.initialize();
      
      const config = await configService.loadConfigFromSources();
      expect(config).toBeDefined();
      expect(config.version).toBe('1.0.0');
      expect(config.siteConfigs[0].name).toBe('备用网站');
    });
  });
  
  // ==================== 配置验证测试 | Config Validation Tests ====================
  
  describe('配置验证测试', () => {
    it('应该正确验证有效的配置', () => {
      const validConfig = {
        version: '1.0.0',
        siteConfigs: [
          { 
            id: 'site1', 
            name: '有效网站', 
            apiUrl: 'https://valid-site.com/api' 
          }
        ],
        features: {
          enableSearch: true
        }
      };
      
      const isValid = configService.validateConfig(validConfig);
      expect(isValid).toBe(true);
    });
    
    it('应该正确识别无效的配置', () => {
      const invalidConfigs = [
        {}, // 空配置
        { version: '1.0.0' }, // 缺少必要字段
        { 
          version: '1.0.0', 
          siteConfigs: [{ id: 'no-name' }] // 站点配置不完整
        }
      ];
      
      invalidConfigs.forEach(config => {
        const isValid = configService.validateConfig(config);
        expect(isValid).toBe(false);
      });
    });
    
    it('应该正确验证站点配置', () => {
      const validSite = {
        id: 'site1',
        name: '测试网站',
        apiUrl: 'https://test-site.com/api'
      };
      
      const isValid = configService.validateSiteConfig(validSite);
      expect(isValid).toBe(true);
    });
    
    it('应该正确识别无效的站点配置', () => {
      const invalidSites = [
        {}, // 空站点
        { id: 'no-name' }, // 缺少名称
        { name: 'no-id' }, // 缺少ID
        { id: 'invalid-url', name: '无效URL', apiUrl: 'not-a-url' } // 无效URL
      ];
      
      invalidSites.forEach(site => {
        const isValid = configService.validateSiteConfig(site);
        expect(isValid).toBe(false);
      });
    });
  });
  
  // ==================== 缓存机制测试 | Caching Tests ====================
  
  describe('缓存机制测试', () => {
    beforeEach(async () => {
      httpService.setMockResponse('/api/config/sources', [
        { id: 'cache-test', name: '缓存测试源', url: 'https://cache-test.com/config.json', enabled: true }
      ]);
      
      httpService.setMockResponse('https://cache-test.com/config.json', {
        version: '1.0.0',
        timestamp: Date.now()
      });
      
      await configService.initialize();
    });
    
    it('应该正确缓存配置数据', async () => {
      // 第一次加载
      const config1 = await configService.loadConfigFromSource('cache-test');
      const firstCalls = httpService.getCallCount('https://cache-test.com/config.json');
      
      // 第二次加载（应该使用缓存）
      const config2 = await configService.loadConfigFromSource('cache-test');
      const secondCalls = httpService.getCallCount('https://cache-test.com/config.json');
      
      expect(firstCalls).toBe(1);
      expect(secondCalls).toBe(1); // 应该没有增加
      expect(config1.timestamp).toBe(config2.timestamp);
    });
    
    it('应该正确处理缓存过期', async () => {
      // 设置较短的缓存时间用于测试
      (configService as any).cacheExpiry = 100; // 100ms
      
      // 第一次加载
      await configService.loadConfigFromSource('cache-test');
      const firstCalls = httpService.getCallCount('https://cache-test.com/config.json');
      
      // 等待缓存过期
      await new Promise(resolve => setTimeout(resolve, 150));
      
      // 第二次加载（缓存已过期，应该重新请求）
      await configService.loadConfigFromSource('cache-test');
      const secondCalls = httpService.getCallCount('https://cache-test.com/config.json');
      
      expect(firstCalls).toBe(1);
      expect(secondCalls).toBe(2); // 应该增加了
    });
    
    it('应该能够清除配置缓存', async () => {
      await configService.loadConfigFromSource('cache-test');
      const callsBeforeClear = httpService.getCallCount('https://cache-test.com/config.json');
      
      configService.clearConfigCache();
      
      await configService.loadConfigFromSource('cache-test');
      const callsAfterClear = httpService.getCallCount('https://cache-test.com/config.json');
      
      expect(callsBeforeClear).toBe(1);
      expect(callsAfterClear).toBe(2); // 缓存清除后应该重新请求
    });
  });
  
  // ==================== 性能测试 | Performance Tests ====================
  
  describe('性能测试', () => {
    it('应该在合理时间内完成配置源初始化', async () => {
      httpService.setMockResponse('/api/config/sources', [
        { id: '1', name: '源1', url: 'https://source1.com', enabled: true },
        { id: '2', name: '源2', url: 'https://source2.com', enabled: true },
        { id: '3', name: '源3', url: 'https://source3.com', enabled: true }
      ]);
      
      const startTime = performance.now();
      await configService.initialize();
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      expect(duration).toBeLessThan(200); // 200ms内完成
      
      const sources = configService.getConfigSources();
      expect(sources).toHaveLength(3);
    });
    
    it('应该在合理时间内加载多个配置', async () => {
      // 设置多个配置源
      const sources = [];
      for (let i = 0; i < 10; i++) {
        sources.push({
          id: `source-${i}`,
          name: `源${i}`,
          url: `https://source${i}.com/config.json`,
          enabled: true
        });
        
        httpService.setMockResponse(`https://source${i}.com/config.json`, {
          version: '1.0.0',
          sourceId: `source-${i}`
        });
      }
      
      httpService.setMockResponse('/api/config/sources', sources);
      await configService.initialize();
      
      const startTime = performance.now();
      const configs = await configService.loadMultipleConfigs(sources.map(s => s.id));
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      expect(duration).toBeLessThan(500); // 500ms内完成10个配置加载
      expect(configs).toHaveLength(10);
    });
    
    it('应该正确处理并发配置请求', async () => {
      // 设置并发请求的mock响应
      for (let i = 0; i < 5; i++) {
        httpService.setMockResponse(`/api/config/source-${i}`, {
          id: `source-${i}`,
          name: `并发源${i}`,
          enabled: true
        });
      }
      
      const startTime = performance.now();
      
      // 并发执行多个请求
      const promises = [];
      for (let i = 0; i < 5; i++) {
        promises.push(configService.loadConfigFromSource(`source-${i}`));
      }
      
      const results = await Promise.all(promises);
      const endTime = performance.now();
      
      const duration = endTime - startTime;
      expect(duration).toBeLessThan(300); // 300ms内完成5个并发请求
      expect(results).toHaveLength(5);
    });
  });
  
  // ==================== 错误处理测试 | Error Handling Tests ====================
  
  describe('错误处理测试', () => {
    it('应该正确处理网络错误', async () => {
      httpService.setMockResponse('/api/config/sources', 
        Promise.reject(new TypeError('Network connection failed')));
      
      try {
        await configService.initialize();
        expect(true).toBe(false);
      } catch (error) {
        expect(error).toBeInstanceOf(TypeError);
        expect(error.message).toBe('Network connection failed');
      }
    });
    
    it('应该正确处理API错误响应', async () => {
      httpService.setMockResponse('/api/config/sources', 
        Promise.reject({
          status: 500,
          statusText: 'Internal Server Error',
          data: { error: 'Server temporarily unavailable' }
        }));
      
      try {
        await configService.initialize();
        expect(true).toBe(false);
      } catch (error) {
        expect(error.status).toBe(500);
        expect(error.data.error).toBe('Server temporarily unavailable');
      }
    });
    
    it('应该正确处理配置解析错误', async () => {
      httpService.setMockResponse('/api/config/sources', [
        { id: 'parse-test', name: '解析测试', url: 'https://parse-test.com/config.json', enabled: true }
      ]);
      
      httpService.setMockResponse('https://parse-test.com/config.json', 
        '{ invalid json }');
      
      await configService.initialize();
      
      try {
        await configService.loadConfigFromSource('parse-test');
        expect(true).toBe(false);
      } catch (error) {
        expect(error).toBeDefined();
        expect(error.message).toContain('parse');
      }
    });
  });
});

// ==================== 集成测试 | Integration Tests ====================

describe('ConfigService集成测试', () => {
  let configService: ConfigSourceService;
  let httpService: MockHttpService;
  
  beforeEach(() => {
    httpService = new MockHttpService();
    configService = new ConfigSourceService();
  });
  
  it('应该能够与DI容器正确集成', async () => {
    const diContainer = EnhancedDIContainer.getInstance();
    diContainer.register('HttpService', () => httpService, true);
    diContainer.register('ConfigSourceService', () => configService, true);
    
    // 通过容器获取服务
    const resolvedService = diContainer.resolve<ConfigSourceService>('ConfigSourceService');
    expect(resolvedService).toBe(configService);
    
    await diContainer.destroy();
  });
  
  it('应该正确处理服务生命周期', async () => {
    httpService.setMockResponse('/api/config/sources', []);
    
    // 测试初始化
    await configService.initialize();
    expect(configService.getConfigSources()).toBeDefined();
    
    // 测试销毁
    await configService.destroy();
    // 销毁后应该清理资源
  });
});