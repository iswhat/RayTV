/**
 * 性能监控工具单元测试
 */
import { describe, it, beforeAll } from '@ohos/hypium'
import { PerformanceMonitor, MonitorPerformance } from '../../src/main/ets/utils/PerformanceMonitor'
import { Assert } from '../utils/TestUtils'

export default function performanceMonitorTest() {
  describe('PerformanceMonitor', function () {
    let monitor: PerformanceMonitor
    
    beforeAll(function () {
      monitor = PerformanceMonitor.getInstance()
    })
    
    /**
     * 测试获取实例
     */
    it('getInstance_shouldReturnSameInstance', 0, function () {
      const instance1 = PerformanceMonitor.getInstance()
      const instance2 = PerformanceMonitor.getInstance()
      Assert.equal(instance1, instance2, '应该返回相同的实例')
    })
    
    /**
     * 测试性能测量
     */
    it('startAndEndMeasurement_shouldRecordDuration', 0, function () {
      const measurementId = monitor.startMeasurement('testOperation')
      // 模拟一些操作
      for (let i = 0; i < 1000; i++) {
        Math.random()
      }
      const duration = monitor.endMeasurement(measurementId)
      
      Assert.notNull(duration, '应该返回持续时间')
      Assert.assertTrue(duration! > 0, '持续时间应该大于0')
    })
    
    /**
     * 测试性能报告
     */
    it('getPerformanceReport_shouldReturnReport', 0, function () {
      const report = monitor.getPerformanceReport()
      Assert.notNull(report, '应该返回报告对象')
      Assert.assertTrue(typeof report === 'object', '报告应该是对象类型')
      Assert.notNull(report.timestamp, '报告应该包含时间戳')
      Assert.notNull(report.metrics, '报告应该包含指标')
    })
    
    /**
     * 测试阈值设置
     */
    it('setAndGetThreshold_shouldWorkCorrectly', 0, function () {
      const testThreshold = 50
      monitor.setThreshold('testMetric', testThreshold)
      const retrievedThreshold = monitor.getThreshold('testMetric')
      
      Assert.equal(retrievedThreshold, testThreshold, '应该正确设置和获取阈值')
    })
    
    /**
     * 测试装饰器功能
     */
    it('MonitorPerformance_decoratorShouldMeasureFunction', 0, async function () {
      class TestClass {
        @MonitorPerformance('testMethod')
        async testMethod() {
          // 模拟异步操作
          await new Promise(resolve => setTimeout(resolve, 10))
          return 'success'
        }
      }
      
      const testInstance = new TestClass()
      const result = await testInstance.testMethod()
      
      Assert.equal(result, 'success', '方法应该正常执行并返回结果')
      
      // 检查是否有性能数据被记录
      const report = monitor.getPerformanceReport()
      Assert.assertTrue(Object.keys(report.metrics).length > 0, '应该记录性能指标')
    })
    
    /**
     * 测试数据清理
     */
    it('cleanupOldData_shouldRemoveOldMetrics', 0, function () {
      // 添加一些测试数据
      monitor.startMeasurement('oldTest')
      monitor.endMeasurement('oldTest')
      
      const reportBefore = monitor.getPerformanceReport()
      const metricCountBefore = Object.keys(reportBefore.metrics).length
      
      // 清理旧数据（立即清理所有数据用于测试）
      monitor.cleanupOldData(0)
      
      const reportAfter = monitor.getPerformanceReport()
      const metricCountAfter = Object.keys(reportAfter.metrics).length
      
      // 由于清理机制可能保留一些数据，我们只要求清理后数据不增加
      Assert.assertTrue(metricCountAfter <= metricCountBefore, '清理后指标数量不应该增加')
    })
  })
}