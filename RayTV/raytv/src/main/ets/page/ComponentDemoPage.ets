/**
 * 组件演示页面
 * 展示各种UI组件的使用方法和效果
 */
import { Column, Row, Text, Scroll, Stack } from '@ohos/arkui'
import { SimpleButton } from '../component/ui/SimpleButton'
import { SimpleCard } from '../component/ui/SimpleCard'

@Entry
@Component
struct ComponentDemoPage {
  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('UI组件演示')
          .fontSize('24px')
          .fontWeight('bold')
          .margin({ bottom: '20px' })
        
        // 按钮组件演示
        this.renderButtonDemo()
        
        // 卡片组件演示
        this.renderCardDemo()
        
        // 间距填充
        Stack()
          .height('50px')
      }
      .width('100%')
      .padding('20px')
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  private renderButtonDemo() {
    SimpleCard({
      title: '按钮组件演示',
      subtitle: '展示不同类型的按钮组件',
      elevation: 2
    }) {
      Column() {
        // 不同类型的按钮
        Row() {
          SimpleButton({
            text: 'Primary Button',
            type: 'primary'
          })
          .layoutWeight(1)
          .margin({ right: '8px' })
          
          SimpleButton({
            text: 'Secondary Button',
            type: 'secondary'
          })
          .layoutWeight(1)
          .margin({ left: '8px' })
        }
        .width('100%')
        .margin({ bottom: '12px' })
        
        Row() {
          SimpleButton({
            text: 'Danger Button',
            type: 'danger'
          })
          .layoutWeight(1)
          .margin({ right: '8px' })
          
          SimpleButton({
            text: 'Disabled Button',
            disabled: true
          })
          .layoutWeight(1)
          .margin({ left: '8px' })
        }
        .width('100%')
        .margin({ bottom: '12px' })
        
        // 不同尺寸的按钮
        Row() {
          SimpleButton({
            text: 'Small',
            size: 'small'
          })
          .margin({ right: '8px' })
          
          SimpleButton({
            text: 'Medium'
          })
          .margin({ horizontal: '8px' })
          
          SimpleButton({
            text: 'Large',
            size: 'large'
          })
          .margin({ left: '8px' })
        }
        .width('100%')
      }
      .width('100%')
    }
  }
  
  @Builder
  private renderCardDemo() {
    Column() {
      // 基础卡片
      SimpleCard({
        title: '基础卡片',
        subtitle: '这是一个带有标题和副标题的基础卡片',
        elevation: 1
      })
      
      // 高阴影卡片
      SimpleCard({
        title: '高阴影卡片',
        subtitle: '这个卡片有更强的阴影效果',
        elevation: 3
      })
      .margin({ top: '16px' })
      
      // 无标题卡片
      SimpleCard({
        elevation: 2
      }) {
        Column() {
          Text('无标题卡片')
            .fontSize('16px')
            .fontWeight('500')
            .color('#333333')
            .margin({ bottom: '8px' })
          
          Text('这是一个没有预设标题的卡片，内容完全自定义')
            .fontSize('14px')
            .color('#666666')
        }
        .width('100%')
      }
      .margin({ top: '16px' })
    }
    .width('100%')
  }
}