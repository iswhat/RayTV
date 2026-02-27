/**
 * 基础卡片组件
 * 使用最基础的ArkTS语法
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct BasicCard {
  @Prop title: string = ''
  
  build() {
    Stack()
    {
      Column() {
        if (this.title) {
          Text(this.title)
            .margin({ bottom: '12px' })
        }
        
        Column() {
          Text('Card Content')
        }
      }
    }
  }
}