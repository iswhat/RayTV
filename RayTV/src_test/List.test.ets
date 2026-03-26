// List.test.ets - 测试套件入口文件 // Test suite entry file
// 导入并执行本地单元测试 // Import and execute local unit tests
import localUnitTest from './LocalUnit.test';

/**
 * Test suite function | 测试套件函数
 * 执行本地单元测试 // Execute local unit tests
 */
export default function testsuite() {
  localUnitTest();
}