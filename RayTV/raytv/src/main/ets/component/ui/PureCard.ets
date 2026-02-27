/**
 * 纯净卡片组件
 * 不使用任何样式属性，仅使用基本布局
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct PureCard {
  @Prop title: string = ''
  
  build() {
    Stack()
    .width('100%')
    .padding('16px')
    {
      Column() {
        if (this.title) {
          Text(this.title)
            .fontSize('18px')
            .margin({ bottom: '12px' })
        }
        
        Column() {
          Text('Card Content')
            .fontSize('14px')
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
    }
  }
}