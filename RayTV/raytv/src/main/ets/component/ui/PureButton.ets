/**
 * 纯净按钮组件
 * 不使用任何样式属性，仅使用基本布局
 */
import { Component, Prop } from '@ohos/arkui'

@Component
export struct PureButton {
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
    {
      Text(this.text)
        .fontSize('16px')
    }
  }
}