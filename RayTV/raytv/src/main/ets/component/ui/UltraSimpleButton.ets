/**
 * 超简单按钮组件
 * 移除了所有可能有问题的样式属性
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct UltraSimpleButton {
  @Prop text: string = 'Button'
  @Prop onPress: () => void = () => {}
  
  build() {
    Stack({
      onClick: () => {
        this.onPress()
      }
    })
    .width('100%')
    .height('40px')
    .backgroundColor('#007AFF')
    {
      Text(this.text)
        .fontSize('16px')
        .color('#FFFFFF')
    }
  }
}