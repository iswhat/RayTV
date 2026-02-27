/**
 * 简单演示页面
 * 展示基础UI组件
 */
import { Column, Text, Scroll } from '@ohos/arkui'
import { MinimalButton } from '../component/ui/MinimalButton'
import { MinimalCard } from '../component/ui/MinimalCard'

@Entry
@Component
struct SimpleDemoPage {
  build() {
    Scroll() {
      Column() {
        Text('组件演示')
          .fontSize('24px')
          .fontWeight('bold')
          .margin({ bottom: '20px' })
        
        MinimalCard({
          title: '按钮演示'
        }) {
          Column() {
            MinimalButton({
              text: '点击我',
              onPress: () => {
                console.log('按钮被点击了')
              }
            })
            .margin({ bottom: '12px' })
            
            MinimalButton({
              text: '另一个按钮',
              onPress: () => {
                console.log('第二个按钮被点击了')
              }
            })
          }
          .width('100%')
        }
        
        MinimalCard({
          title: '卡片演示'
        }) {
          Column() {
            Text('这是卡片内容')
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