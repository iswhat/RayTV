/**
 * 超简单卡片组件
 * 移除了所有可能有问题的样式属性
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct UltraSimpleCard {
  @Prop title: string = ''
  
  build() {
    Stack()
    .width('100%')
    .padding('16px')
    .backgroundColor('#FFFFFF')
    {
      Column() {
        if (this.title) {
          Text(this.title)
            .fontSize('18px')
            .fontWeight('600')
            .color('#333333')
            .margin({ bottom: '12px' })
        }
        
        Column() {
          Text('Card Content')
            .fontSize('14px')
            .color('#666666')
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
    }
  }
}