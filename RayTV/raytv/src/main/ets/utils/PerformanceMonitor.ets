/**
 * 性能监控工具
 * 用于监控应用性能指标和优化建议
 */
export class PerformanceMonitor {
  private static instance: PerformanceMonitor
  private metrics: Map<string, any[]> = new Map()
  private thresholds: Map<string, number> = new Map()
  
  private constructor() {
    // 设置默认阈值
    this.thresholds.set('renderTime', 16) // 60fps
    this.thresholds.set('memoryUsage', 100) // MB
    this.thresholds.set('networkLatency', 1000) // ms
    this.thresholds.set('cpuUsage', 80) // %
  }
  
  public static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor()
    }
    return PerformanceMonitor.instance
  }
  
  /**
   * 开始性能测量
   */
  public startMeasurement(name: string): string {
    const id = `${name}_${Date.now()}_${Math.random()}`
    this.metrics.set(id, [{
      name: name,
      startTime: Date.now(),
      type: 'start'
    }])
    return id
  }
  
  /**
   * 结束性能测量
   */
  public endMeasurement(id: string): number | null {
    const measurements = this.metrics.get(id)
    if (!measurements) return null
    
    const endTime = Date.now()
    const startTime = measurements[0].startTime
    const duration = endTime - startTime
    
    measurements.push({
      name: measurements[0].name,
      endTime: endTime,
      duration: duration,
      type: 'end'
    })
    
    // 检查是否超过阈值
    const threshold = this.thresholds.get(measurements[0].name)
    if (threshold && duration > threshold) {
      this.logPerformanceWarning(measurements[0].name, duration, threshold)
    }
    
    return duration
  }
  
  /**
   * 记录内存使用情况
   */
  public recordMemoryUsage(): void {
    // 在实际应用中，这里会获取真实的内存信息
    const memoryInfo = {
      used: this.getUsedMemory(),
      total: this.getTotalMemory(),
      timestamp: Date.now()
    }
    
    this.addMetric('memoryUsage', memoryInfo)
    
    // 检查内存使用是否过高
    const threshold = this.thresholds.get('memoryUsage')
    if (threshold && memoryInfo.used > threshold) {
      this.logMemoryWarning(memoryInfo.used, threshold)
    }
  }
  
  /**
   * 记录网络请求性能
   */
  public recordNetworkPerformance(url: string, startTime: number, endTime: number): void {
    const duration = endTime - startTime
    const networkInfo = {
      url: url,
      duration: duration,
      timestamp: Date.now()
    }
    
    this.addMetric('networkPerformance', networkInfo)
    
    // 检查网络延迟是否过高
    const threshold = this.thresholds.get('networkLatency')
    if (threshold && duration > threshold) {
      this.logNetworkWarning(url, duration, threshold)
    }
  }
  
  /**
   * 获取性能报告
   */
  public getPerformanceReport(): any {
    const report: any = {
      timestamp: Date.now(),
      metrics: {}
    }
    
    for (const [key, values] of this.metrics.entries()) {
      if (values.length > 0) {
        report.metrics[values[0].name] = {
          count: values.length,
          average: this.calculateAverage(values),
          max: this.calculateMax(values),
          min: this.calculateMin(values)
        }
      }
    }
    
    return report
  }
  
  /**
   * 设置性能阈值
   */
  public setThreshold(metricName: string, threshold: number): void {
    this.thresholds.set(metricName, threshold)
  }
  
  /**
   * 获取性能阈值
   */
  public getThreshold(metricName: string): number | undefined {
    return this.thresholds.get(metricName)
  }
  
  /**
   * 清理旧的性能数据
   */
  public cleanupOldData(maxAge: number = 300000): void { // 5分钟
    const now = Date.now()
    for (const [key, values] of this.metrics.entries()) {
      if (values.length > 0 && now - values[0].timestamp > maxAge) {
        this.metrics.delete(key)
      }
    }
  }
  
  // 私有辅助方法
  private addMetric(name: string, data: any): void {
    if (!this.metrics.has(name)) {
      this.metrics.set(name, [])
    }
    
    const metricData = {
      ...data,
      timestamp: Date.now()
    }
    
    this.metrics.get(name)!.push(metricData)
    
    // 限制存储的数据量
    const values = this.metrics.get(name)!
    if (values.length > 1000) {
      values.shift()
    }
  }
  
  private calculateAverage(values: any[]): number {
    if (values.length === 0) return 0
    const sum = values.reduce((acc, val) => acc + (val.duration || 0), 0)
    return sum / values.length
  }
  
  private calculateMax(values: any[]): number {
    return Math.max(...values.map(val => val.duration || 0))
  }
  
  private calculateMin(values: any[]): number {
    return Math.min(...values.map(val => val.duration || 0))
  }
  
  private getUsedMemory(): number {
    // 模拟内存使用，实际应用中需要获取真实数据
    return Math.floor(Math.random() * 150) + 50
  }
  
  private getTotalMemory(): number {
    // 模拟总内存
    return 512
  }
  
  private logPerformanceWarning(name: string, duration: number, threshold: number): void {
    console.warn(`[Performance] ${name} 耗时 ${duration}ms，超过阈值 ${threshold}ms`)
  }
  
  private logMemoryWarning(used: number, threshold: number): void {
    console.warn(`[Performance] 内存使用 ${used}MB，超过阈值 ${threshold}MB`)
  }
  
  private logNetworkWarning(url: string, duration: number, threshold: number): void {
    console.warn(`[Performance] 网络请求 ${url} 耗时 ${duration}ms，超过阈值 ${threshold}ms`)
  }
}

// 性能装饰器
export function MonitorPerformance(metricName: string) {
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value
    const monitor = PerformanceMonitor.getInstance()
    
    descriptor.value = function(...args: any[]) {
      const measurementId = monitor.startMeasurement(metricName)
      const result = originalMethod.apply(this, args)
      
      if (result instanceof Promise) {
        return result.then((res) => {
          monitor.endMeasurement(measurementId)
          return res
        }).catch((error) => {
          monitor.endMeasurement(measurementId)
          throw error
        })
      } else {
        monitor.endMeasurement(measurementId)
        return result
      }
    }
    
    return descriptor
  }
}