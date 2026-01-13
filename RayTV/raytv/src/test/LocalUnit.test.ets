// LocalUnit.test.ets - 本地单元测试文件 // Local unit test file
// 测试基本的断言功能 // Tests basic assertion functionality
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

/**
 * Local unit test function | 本地单元测试函数
 * 执行基本的断言测试 // Execute basic assertion tests
 */
export default function localUnitTest() {
  describe('localUnitTest // 本地单元测试', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function. // 定义测试套件，支持两个参数：测试套件名称和测试套件函数
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start. // 预设动作，在测试套件所有测试用例开始前只执行一次
      // This API supports only one parameter: preset action function. // 此API只支持一个参数：预设动作函数
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts. // 预设动作，在每个单元测试用例开始前执行
      // The number of execution times is the same as the number of test cases defined by **it**. // 执行次数与**it**定义的测试用例数量相同
      // This API supports only one parameter: preset action function. // 此API只支持一个参数：预设动作函数
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends. // 预设清理动作，在每个单元测试用例结束后执行
      // The number of execution times is the same as the number of test cases defined by **it**. // 执行次数与**it**定义的测试用例数量相同
      // This API supports only one parameter: clear action function. // 此API只支持一个参数：清理动作函数
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end. // 预设清理动作，在测试套件所有测试用例结束后执行
      // This API supports only one parameter: clear action function. // 此API只支持一个参数：清理动作函数
    });
    it('assertContain // 测试包含断言', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function. // 定义测试用例，此API支持三个参数：测试用例名称、过滤参数和测试用例函数
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions. // 定义各种断言方法，用于声明期望的布尔条件
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
  });
}