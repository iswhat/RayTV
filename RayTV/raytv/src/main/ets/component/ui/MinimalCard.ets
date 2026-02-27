/**
 * 最小化卡片组件
 * 最基础的卡片实现
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct MinimalCard {
  @Prop title: string = ''
  
  build() {
    Stack()
    .width('100%')
    .padding('16px')
    .margin('8px')
    .backgroundColor('#FFFFFF')
    .borderRadius('12px')
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
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
  }
}