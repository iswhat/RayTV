// SiteService.test.ets - SiteService测试文件 // SiteService test file
// 测试SiteService类的站点管理功能 // Tests SiteService class site management functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { SiteService } from '../main/ets/service/spider/SiteService';

export default function siteServiceTest() {
  describe('SiteService测试 // SiteService tests', () => {
    let siteService: SiteService;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      siteService = SiteService.getInstance();
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

    it('测试获取SiteService单例实例 // Test get SiteService singleton instance', 0, () => {
      // 测试获取单例实例功能 // Test get singleton instance functionality
      const instance1 = SiteService.getInstance();
      const instance2 = SiteService.getInstance();
      
      // 验证单例模式 // Verify singleton pattern
      expect(instance1).assertNotNull('实例1不能为空 // Instance 1 cannot be null');
      expect(instance2).assertNotNull('实例2不能为空 // Instance 2 cannot be null');
      expect(instance1).assertEqual(instance2, '两个实例应该是同一个对象 // Both instances should be the same object');
      
      console.log('SiteService单例模式测试通过 // SiteService singleton pattern test passed');
    });

    it('测试初始化站点功能 // Test initialize sites functionality', 0, async () => {
      // 测试初始化站点功能 // Test initialize sites functionality
      const initResult = await siteService.initializeSites();
      
      // 验证初始化结果 // Verify initialization result
      expect(initResult).assertTrue('站点初始化应该成功 // Sites initialization should succeed');
      
      console.log('站点初始化测试通过 // Sites initialization test passed');
    });

    it('测试获取所有站点功能 // Test get all sites functionality', 0, async () => {
      // 先初始化站点 // Initialize sites first
      await siteService.initializeSites();
      
      // 测试获取所有站点功能 // Test get all sites functionality
      const sites = await siteService.getAllSites();
      
      // 验证站点结果 // Verify sites result
      expect(sites).assertNotNull('站点列表不能为空 // Sites list cannot be null');
      expect(sites).assertTypeOf('array', '站点列表应该是数组类型 // Sites list should be array type');
      
      console.log(`获取站点列表测试通过，共 ${sites.length} 个站点 // Get sites list test passed, total ${sites.length} sites`);
    });

    it('测试获取启用的站点功能 // Test get enabled sites functionality', 0, async () => {
      // 先初始化站点 // Initialize sites first
      await siteService.initializeSites();
      
      // 测试获取启用的站点功能 // Test get enabled sites functionality
      const enabledSites = await siteService.getEnabledSites();
      
      // 验证启用站点结果 // Verify enabled sites result
      expect(enabledSites).assertNotNull('启用站点列表不能为空 // Enabled sites list cannot be null');
      expect(enabledSites).assertTypeOf('array', '启用站点列表应该是数组类型 // Enabled sites list should be array type');
      
      console.log(`获取启用站点列表测试通过，共 ${enabledSites.length} 个启用站点 // Get enabled sites list test passed, total ${enabledSites.length} enabled sites`);
    });

    it('测试刷新站点功能 // Test refresh sites functionality', 0, async () => {
      // 测试刷新站点功能 // Test refresh sites functionality
      const refreshResult = await siteService.refreshSites();
      
      // 验证刷新结果 // Verify refresh result
      expect(refreshResult).assertTrue('站点刷新应该成功 // Sites refresh should succeed');
      
      console.log('站点刷新测试通过 // Sites refresh test passed');
    });
  });
}
