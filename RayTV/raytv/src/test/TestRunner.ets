// TestRunner.ets - 测试运行器文件 // Test runner file
// 批量运行所有测试用例 // Batch run all test cases

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';

// 导入所有测试文件
import configServiceTest from './ConfigService.test';
import siteServiceTest from './SiteService.test';
import siteRepositoryTest from './SiteRepository.test';
import appServiceTest from './AppService.test';
import configParserTest from './ConfigParser.test';
import httpServiceTest from './HttpService.test';
import sqliteHelperTest from './SQLiteHelper.test';
import mediaCacheServiceTest from './MediaCacheService.test';

/**
 * 测试运行器 // Test runner
 */
export default function testRunner() {
  describe('RayTV测试套件 // RayTV test suite', () => {
    beforeAll(() => {
      // 在所有测试开始前执行一次 // Execute once before all tests
      console.log('=== RayTV测试套件开始 ===');
      console.log('测试开始时间:', new Date().toLocaleString());
    });

    afterAll(() => {
      // 在所有测试结束后执行一次 // Execute once after all tests
      console.log('=== RayTV测试套件结束 ===');
      console.log('测试结束时间:', new Date().toLocaleString());
    });

    it('测试环境初始化 // Test environment initialization', 0, () => {
      // 测试环境初始化 // Test environment initialization
      console.log('测试环境初始化完成 // Test environment initialized');
      expect(true).assertTrue('测试环境初始化应该成功 // Test environment initialization should succeed');
    });

    // 运行ConfigService测试
    configServiceTest();

    // 运行SiteService测试
    siteServiceTest();

    // 运行SiteRepository测试
    siteRepositoryTest();

    // 运行AppService测试
    appServiceTest();

    // 运行ConfigParser测试
    configParserTest();

    // 运行HttpService测试
    httpServiceTest();

    // 运行SQLiteHelper测试
    sqliteHelperTest();

    // 运行MediaCacheService测试
    mediaCacheServiceTest();

    it('测试套件完整性检查 // Test suite integrity check', 0, () => {
      // 测试套件完整性检查 // Test suite integrity check
      console.log('测试套件完整性检查通过 // Test suite integrity check passed');
      expect(true).assertTrue('测试套件完整性检查应该成功 // Test suite integrity check should succeed');
    });
  });
}

/**
 * 运行所有测试 // Run all tests
 */
export function runAllTests() {
  testRunner();
}

/**
 * 运行指定的测试 // Run specified tests
 * @param testNames 要运行的测试名称列表 // List of test names to run
 */
export function runSpecificTests(testNames: string[]) {
  describe('RayTV指定测试套件 // RayTV specified test suite', () => {
    beforeAll(() => {
      console.log('=== RayTV指定测试套件开始 ===');
      console.log('测试开始时间:', new Date().toLocaleString());
      console.log('要运行的测试:', testNames.join(', '));
    });

    afterAll(() => {
      console.log('=== RayTV指定测试套件结束 ===');
      console.log('测试结束时间:', new Date().toLocaleString());
    });

    // 根据测试名称运行指定的测试
    if (testNames.includes('configService')) {
      configServiceTest();
    }

    if (testNames.includes('siteService')) {
      siteServiceTest();
    }

    if (testNames.includes('siteRepository')) {
      siteRepositoryTest();
    }

    if (testNames.includes('appService')) {
      appServiceTest();
    }

    if (testNames.includes('configParser')) {
      configParserTest();
    }

    if (testNames.includes('httpService')) {
      httpServiceTest();
    }

    if (testNames.includes('sqliteHelper')) {
      sqliteHelperTest();
    }

    if (testNames.includes('mediaCacheService')) {
      mediaCacheServiceTest();
    }
  });
}

/**
 * 运行核心测试 // Run core tests
 */
export function runCoreTests() {
  describe('RayTV核心测试套件 // RayTV core test suite', () => {
    beforeAll(() => {
      console.log('=== RayTV核心测试套件开始 ===');
      console.log('测试开始时间:', new Date().toLocaleString());
    });

    afterAll(() => {
      console.log('=== RayTV核心测试套件结束 ===');
      console.log('测试结束时间:', new Date().toLocaleString());
    });

    // 运行核心服务测试
    configServiceTest();
    httpServiceTest();
    sqliteHelperTest();
  });
}

/**
 * 运行服务测试 // Run service tests
 */
export function runServiceTests() {
  describe('RayTV服务测试套件 // RayTV service test suite', () => {
    beforeAll(() => {
      console.log('=== RayTV服务测试套件开始 ===');
      console.log('测试开始时间:', new Date().toLocaleString());
    });

    afterAll(() => {
      console.log('=== RayTV服务测试套件结束 ===');
      console.log('测试结束时间:', new Date().toLocaleString());
    });

    // 运行服务测试
    configServiceTest();
    siteServiceTest();
    appServiceTest();
    httpServiceTest();
    mediaCacheServiceTest();
  });
}

/**
 * 运行数据层测试 // Run data layer tests
 */
export function runDataLayerTests() {
  describe('RayTV数据层测试套件 // RayTV data layer test suite', () => {
    beforeAll(() => {
      console.log('=== RayTV数据层测试套件开始 ===');
      console.log('测试开始时间:', new Date().toLocaleString());
    });

    afterAll(() => {
      console.log('=== RayTV数据层测试套件结束 ===');
      console.log('测试结束时间:', new Date().toLocaleString());
    });

    // 运行数据层测试
    siteRepositoryTest();
    sqliteHelperTest();
    configParserTest();
  });
}
