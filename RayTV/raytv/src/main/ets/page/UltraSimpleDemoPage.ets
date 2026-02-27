/**
 * 超简单演示页面
 * 使用最基本的组件
 */
import { Column, Text, Scroll } from '@ohos/arkui'
import { UltraSimpleButton } from '../component/ui/UltraSimpleButton'
import { UltraSimpleCard } from '../component/ui/UltraSimpleCard'

@Entry
@Component
struct UltraSimpleDemoPage {
  build() {
    Scroll() {
      Column() {
        Text('基础组件演示')
          .fontSize('24px')
          .fontWeight('bold')
          .margin({ bottom: '20px' })
        
        UltraSimpleCard({
          title: '按钮演示'
        }) {
          Column() {
            UltraSimpleButton({
              text: '点击测试',
              onPress: () => {
                console.log('按钮被点击')
              }
            })
            .margin({ bottom: '12px' })
            
            UltraSimpleButton({
              text: '第二个按钮',
              onPress: () => {
                console.log('第二个按钮被点击')
              }
            })
          }
          .width('100%')
        }
        
        UltraSimpleCard({
          title: '卡片演示'
        }) {
          Column() {
            Text('这是卡片的基本内容展示')
              .fontSize('14px')
              .color('#666666')
          }
          .width('100%')
        }
        .margin({ top: '16px' })
      }
      .width('100%')
      .padding('20px')
    }
    .width('100%')
    .height('100%')
  }
}