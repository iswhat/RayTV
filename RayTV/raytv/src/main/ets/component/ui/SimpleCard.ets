/**
 * 简单卡片组件
 * 使用标准ArkTS语法的卡片组件
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct SimpleCard {
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop elevation: number = 1
  @Prop padding: string = '16px'
  @Prop margin: string = '8px'
  
  private getBoxShadow(): string {
    const elevations = [
      'none',
      '0 2px 4px rgba(0,0,0,0.1)',
      '0 4px 8px rgba(0,0,0,0.15)',
      '0 8px 16px rgba(0,0,0,0.2)',
      '0 12px 24px rgba(0,0,0,0.25)',
      '0 16px 32px rgba(0,0,0,0.3)'
    ]
    
    return elevations[Math.min(Math.max(this.elevation, 0), 5)]
  }
  
  build() {
    Stack()
    .width('100%')
    .padding(this.padding)
    .margin(this.margin)
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
    .boxShadow(this.getBoxShadow())
    {
      Column() {
        // 标题区域
        if (this.title) {
          Column() {
            Text(this.title)
              .fontSize('18px')
              .fontWeight('600')
              .color('#333333')
            
            if (this.subtitle) {
              Text(this.subtitle)
                .fontSize('14px')
                .color('#666666')
                .margin({ top: '4px' })
            }
          }
          .width('100%')
          .margin({ bottom: '12px' })
        }
        
        // 内容区域
        Column() {
          // 这里可以放置子内容
          Text('Card Content Area')
            .fontSize('14px')
            .color('#999999')
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
  }
}