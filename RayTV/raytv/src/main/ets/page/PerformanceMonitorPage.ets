/**
 * 性能监控页面
 * 展示应用性能指标和优化建议
 */
import { Component, State } from '@ohos/arkui'
import { PerformanceMonitor } from '../utils/PerformanceMonitor'
import { MemoryOptimizer } from '../utils/MemoryOptimizer'
import { LazyLoader } from '../utils/LazyLoader'

@Entry
@Component
struct PerformanceMonitorPage {
  @State performanceData: any = {}
  @State memoryStats: any = {}
  @State loadStats: any = {}
  
  private perfMonitor: PerformanceMonitor = PerformanceMonitor.getInstance()
  private memoryOptimizer: MemoryOptimizer = MemoryOptimizer.getInstance()
  private lazyLoader: LazyLoader = LazyLoader.getInstance()
  
  aboutToAppear() {
    this.updatePerformanceData()
    
    // 定期更新数据
    setInterval(() => {
      this.updatePerformanceData()
    }, 2000)
  }
  
  private updatePerformanceData(): void {
    this.performanceData = this.perfMonitor.getPerformanceReport()
    this.memoryStats = this.memoryOptimizer.getMemoryStats()
    this.loadStats = this.lazyLoader.getLoadStats()
  }
  
  private triggerManualGC(): void {
    this.memoryOptimizer.forceGarbageCollection()
    this.updatePerformanceData()
  }
  
  private simulateHeavyOperation(): void {
    const id = this.perfMonitor.startMeasurement('heavyOperation')
    
    // 模拟耗时操作
    setTimeout(() => {
      const duration = this.perfMonitor.endMeasurement(id)
      console.log(`重操作耗时: ${duration}ms`)
      this.updatePerformanceData()
    }, 100)
  }
  
  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('性能监控面板')
          .fontSize('24px')
          .fontWeight('bold')
          .margin({ bottom: '20px' })
        
        // 性能指标卡片
        this.renderPerformanceCard()
        
        // 内存统计卡片
        this.renderMemoryCard()
        
        // 加载统计卡片
        this.renderLoadCard()
        
        // 操作按钮
        this.renderActionButtons()
      }
      .width('100%')
      .padding('20px')
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  private renderPerformanceCard() {
    Column() {
      Text('性能指标')
        .fontSize('18px')
        .fontWeight('bold')
        .margin({ bottom: '12px' })
      
      if (this.performanceData.metrics) {
        ForEach(Object.entries(this.performanceData.metrics), ([name, data]: [string, any]) => {
          Column() {
            Text(`${name}:`)
              .fontSize('14px')
              .fontWeight('500')
            Text(`平均: ${data.average?.toFixed(2)}ms`)
              .fontSize('12px')
              .color('#666666')
            Text(`最大: ${data.max}ms, 最小: ${data.min}ms`)
              .fontSize('12px')
              .color('#999999')
          }
          .width('100%')
          .padding('8px')
          .backgroundColor('#F5F5F5')
          .borderRadius('6px')
          .margin({ bottom: '8px' })
        })
      } else {
        Text('暂无性能数据')
          .fontSize('14px')
          .color('#999999')
      }
    }
    .width('100%')
    .padding('16px')
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
    .elevation(2)
    .margin({ bottom: '16px' })
  }
  
  @Builder
  private renderMemoryCard() {
    Column() {
      Text('内存统计')
        .fontSize('18px')
        .fontWeight('bold')
        .margin({ bottom: '12px' })
      
      Text(`跟踪对象: ${this.memoryStats.trackedObjects || 0}`)
        .fontSize('14px')
        .margin({ bottom: '4px' })
      Text(`清理回调: ${this.memoryStats.cleanupCallbacks || 0}`)
        .fontSize('14px')
        .margin({ bottom: '4px' })
      Text(`时间戳: ${new Date(this.memoryStats.timestamp || Date.now()).toLocaleTimeString()}`)
        .fontSize('12px')
        .color('#999999')
    }
    .width('100%')
    .padding('16px')
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
    .elevation(2)
    .margin({ bottom: '16px' })
  }
  
  @Builder
  private renderLoadCard() {
    Column() {
      Text('加载统计')
        .fontSize('18px')
        .fontWeight('bold')
        .margin({ bottom: '12px' })
      
      Text(`已加载模块: ${this.loadStats.loadedModules || 0}`)
        .fontSize('14px')
        .margin({ bottom: '4px' })
      Text(`加载中: ${this.loadStats.loadingPromises || 0}`)
        .fontSize('14px')
        .margin({ bottom: '4px' })
      
      if (this.loadStats.modules && this.loadStats.modules.length > 0) {
        Text('模块列表:')
          .fontSize('14px')
          .fontWeight('500')
          .margin({ bottom: '4px' })
        ForEach(this.loadStats.modules, (module: string) => {
          Text(`• ${module}`)
            .fontSize('12px')
            .color('#666666')
            .margin({ bottom: '2px' })
        })
      }
    }
    .width('100%')
    .padding('16px')
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
    .elevation(2)
    .margin({ bottom: '16px' })
  }
  
  @Builder
  private renderActionButtons() {
    Row() {
      Button('手动GC')
        .backgroundColor('#FF6B6B')
        .fontColor('#FFFFFF')
        .margin({ right: '12px' })
        .onClick(() => this.triggerManualGC())
      
      Button('模拟重操作')
        .backgroundColor('#4ECDC4')
        .fontColor('#FFFFFF')
        .margin({ right: '12px' })
        .onClick(() => this.simulateHeavyOperation())
      
      Button('刷新数据')
        .backgroundColor('#45B7D1')
        .fontColor('#FFFFFF')
        .onClick(() => this.updatePerformanceData())
    }
    .width('100%')
    .justifyContent('center')
  }
}