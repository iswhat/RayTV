// SiteRepository.test.ets - SiteRepository测试文件 // SiteRepository test file
// 测试SiteRepository类的站点数据管理功能 // Tests SiteRepository class site data management functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { SiteRepository } from '../main/ets/data/repository/SiteRepository';
import { Site, SiteType, LoaderType, SiteSearchConfig, SiteFilterConfig, SitePerformanceConfig, SiteStats, SiteLifecycle } from '../main/ets/data/bean/Site';

const createMockSite = (): Site => ({
  key: `test-site-${Date.now()}`,
  name: 'Test Site',
  type: SiteType.VOD,
  loaderType: LoaderType.JS,
  api: 'https://example.com/api',
  searchConfig: {
    enabled: true
  },
  filterConfig: {
    enabled: false
  },
  performanceConfig: {
    timeout: 30000,
    retryCount: 3
  },
  stats: {
    queryCount: 0,
    errorCount: 0,
    avgResponseTime: 0
  },
  lifecycle: {
    initialized: false,
    loading: false,
    error: false
  },
  enabled: true,
  order: 0,
  createdAt: Date.now(),
  updatedAt: Date.now()
});

export default function siteRepositoryTest() {
  describe('SiteRepository测试 // SiteRepository tests', () => {
    let repository: SiteRepository;
    let testSite: Site;

    beforeAll(() => {
      // 在所有测试用例开始前执行一次 // Execute once before all test cases
      repository = SiteRepository.getInstance();
      testSite = createMockSite();
    });

    beforeEach(() => {
      // 在每个测试用例开始前执行 // Execute before each test case
      testSite = createMockSite();
    });

    afterEach(() => {
      // 在每个测试用例结束后执行 // Execute after each test case
    });

    afterAll(() => {
      // 在所有测试用例结束后执行一次 // Execute once after all test cases
    });

    it('测试保存站点功能 // Test save site functionality', 0, async () => {
      // 测试保存站点功能 // Test save site functionality
      const result = await repository.saveSite(testSite);
      
      // 验证保存结果 // Verify save result
      expect(result).assertTrue('站点保存应该成功 // Site save should succeed');
      
      console.log(`成功保存站点: ${testSite.name} // Successfully saved site: ${testSite.name}`);
    });

    it('测试获取站点功能 // Test get site functionality', 0, async () => {
      // 先保存站点 // Save site first
      await repository.saveSite(testSite);
      
      // 测试获取站点功能 // Test get site functionality
      const retrievedSite = await repository.getSiteByKey(testSite.key);
      
      // 验证获取结果 // Verify retrieve result
      expect(retrievedSite).assertNotNull('获取的站点不能为空 // Retrieved site cannot be null');
      expect(retrievedSite?.key).assertEqual(testSite.key, '站点key应该匹配 // Site key should match');
      expect(retrievedSite?.name).assertEqual(testSite.name, '站点名称应该匹配 // Site name should match');
      
      console.log(`成功获取站点: ${retrievedSite?.name} // Successfully retrieved site: ${retrievedSite?.name}`);
    });

    it('测试获取所有站点功能 // Test get all sites functionality', 0, async () => {
      // 先保存测试站点 // Save test site first
      await repository.saveSite(testSite);
      
      // 测试获取所有站点功能 // Test get all sites functionality
      const sites = await repository.getAllSites();
      
      // 验证获取结果 // Verify retrieve result
      expect(sites).assertNotNull('获取的站点列表不能为空 // Retrieved site list cannot be null');
      expect(sites.length).assertGreater(0, '站点列表至少应该包含一个站点 // Site list should contain at least one site');
      
      console.log(`成功获取 ${sites.length} 个站点 // Successfully retrieved ${sites.length} sites`);
    });

    it('测试删除站点功能 // Test delete site functionality', 0, async () => {
      // 先保存站点 // Save site first
      await repository.saveSite(testSite);
      
      // 测试删除站点功能 // Test delete site functionality
      const deleteResult = await repository.deleteSite(testSite.key);
      
      // 验证删除结果 // Verify delete result
      expect(deleteResult).assertTrue('站点删除应该成功 // Site delete should succeed');
      
      // 验证站点已被删除 // Verify site has been deleted
      const retrievedSite = await repository.getSiteByKey(testSite.key);
      expect(retrievedSite).assertNull('删除后应该无法获取到站点 // Should not be able to retrieve deleted site');
      
      console.log(`成功删除站点: ${testSite.key} // Successfully deleted site: ${testSite.key}`);
    });

    it('测试批量保存站点功能 // Test batch save sites functionality', 0, async () => {
      // 创建多个测试站点 // Create multiple test sites
      const testSites = [
        { ...createMockSite(), name: 'Test Site 1' },
        { ...createMockSite(), name: 'Test Site 2' },
        { ...createMockSite(), name: 'Test Site 3' }
      ];
      
      // 测试批量保存站点功能 // Test batch save sites functionality
      const successCount = await repository.saveSites(testSites);
      
      // 验证保存结果 // Verify save result
      expect(successCount).assertEqual(testSites.length, `应该成功保存 ${testSites.length} 个站点 // Should successfully save ${testSites.length} sites`);
      
      console.log(`成功批量保存 ${successCount} 个站点 // Successfully batch saved ${successCount} sites`);
    });

    it('测试更新站点启用状态功能 // Test update site enabled status functionality', 0, async () => {
      // 先保存站点 // Save site first
      await repository.saveSite(testSite);
      
      // 测试更新站点启用状态功能 // Test update site enabled status functionality
      const updateResult = await repository.updateSiteEnabled(testSite.key, false);
      
      // 验证更新结果 // Verify update result
      expect(updateResult).assertTrue('站点启用状态更新应该成功 // Site enabled status update should succeed');
      
      // 验证状态已更新 // Verify status has been updated
      const updatedSite = await repository.getSiteByKey(testSite.key);
      expect(updatedSite?.enabled).assertFalse('站点应该被禁用 // Site should be disabled');
      
      console.log(`成功更新站点启用状态 // Successfully updated site enabled status`);
    });

    it('测试更新站点排序功能 // Test update site sort order functionality', 0, async () => {
      // 先保存站点 // Save site first
      await repository.saveSite(testSite);
      
      const newSortOrder = 10;
      
      // 测试更新站点排序功能 // Test update site sort order functionality
      const updateResult = await repository.updateSiteSortOrder(testSite.key, newSortOrder);
      
      // 验证更新结果 // Verify update result
      expect(updateResult).assertTrue('站点排序更新应该成功 // Site sort order update should succeed');
      
      console.log(`成功更新站点排序为: ${newSortOrder} // Successfully updated site sort order to: ${newSortOrder}`);
    });
  });
}
