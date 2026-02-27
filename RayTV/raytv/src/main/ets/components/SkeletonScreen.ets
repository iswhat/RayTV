// 骨架屏组件 | Skeleton screen component
// 用于在数据加载过程中显示占位内容，提升用户体验

import { Row, Column, Text, Progress, FlexAlign, Animation } from '@ohos/arkui';

// 骨架屏组件参数 | Skeleton screen component parameters
interface SkeletonScreenParams {
  type?: 'list' | 'card' | 'detail' | 'custom'; // 骨架屏类型 | Skeleton screen type
  count?: number; // 显示的骨架项数量 | Number of skeleton items to show
  animated?: boolean; // 是否启用动画 | Whether to enable animation
  animationDuration?: number; // 动画持续时间（毫秒）| Animation duration (milliseconds)
  customContent?: object[]; // 自定义骨架内容 | Custom skeleton content
}

@Component
export struct SkeletonScreen {
  private readonly TAG: string = 'SkeletonScreen';
  
  // 参数 | Parameters
  @Prop type: 'list' | 'card' | 'detail' | 'custom' = 'list';
  @Prop count: number = 5;
  @Prop animated: boolean = true;
  @Prop animationDuration: number = 1500;
  @Prop customContent: object[] = [];
  
  // 移除构造函数，在struct中不需要
  // Remove constructor, not needed in struct
  
  // 渲染列表骨架屏 | Render list skeleton screen
  @Builder
  private renderListSkeleton() {
    Column() {
      ForEach(Array.from({ length: this.count }), (_, index: number) => {
        Row() {
          // 左侧图片占位 | Left image placeholder
          Column()
            .width(80)
            .height(80)
            .backgroundColor('#E0E0E0')
            .borderRadius(8)
            .margin({ right: 16 })
            .animation(this.animated ? this.getAnimation() : undefined)
          
          // 右侧文本占位 | Right text placeholders
          Column() {
            Column()
              .width('60%')
              .height(16)
              .backgroundColor('#E0E0E0')
              .borderRadius(4)
              .margin({ bottom: 8 })
              .animation(this.animated ? this.getAnimation() : undefined)
            
            Column()
              .width('40%')
              .height(12)
              .backgroundColor('#E0E0E0')
              .borderRadius(4)
              .animation(this.animated ? this.getAnimation() : undefined)
          }
          .flexGrow(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      })
    }
  }
  
  // 渲染卡片骨架屏 | Render card skeleton screen
  @Builder
  private renderCardSkeleton() {
    Row() {
      ForEach(Array.from({ length: this.count }), (_, index: number) => {
        Column() {
          // 图片占位 | Image placeholder
          Column()
            .width(180)
            .height(240)
            .backgroundColor('#E0E0E0')
            .borderRadius(8)
            .margin({ bottom: 12 })
            .animation(this.animated ? this.getAnimation() : undefined)
          
          // 标题占位 | Title placeholder
          Column()
            .width(160)
            .height(16)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)
            .margin({ bottom: 8 })
            .animation(this.animated ? this.getAnimation() : undefined)
          
          // 描述占位 | Description placeholder
          Column()
            .width(140)
            .height(12)
            .backgroundColor('#E0E0E0')
            .borderRadius(4)
            .animation(this.animated ? this.getAnimation() : undefined)
        }
        .width(180)
        .padding(12)
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12 })
    .wrap(true)
  }
  
  // 渲染详情骨架屏 | Render detail skeleton screen
  @Builder
  private renderDetailSkeleton() {
    Column() {
      // 顶部图片占位 | Top image placeholder
      Column()
        .width('100%')
        .height(300)
        .backgroundColor('#E0E0E0')
        .borderRadius(8)
        .margin({ bottom: 24 })
        .animation(this.animated ? this.getAnimation() : undefined)
      
      // 标题占位 | Title placeholder
      Column()
        .width('80%')
        .height(24)
        .backgroundColor('#E0E0E0')
        .borderRadius(4)
        .margin({ bottom: 16, left: 20, right: 20 })
        .animation(this.animated ? this.getAnimation() : undefined)
      
      // 描述占位 | Description placeholders
      ForEach(Array.from({ length: 3 }), (_, index: number) => {
        Column()
          .width('90%')
          .height(16)
          .backgroundColor('#E0E0E0')
          .borderRadius(4)
          .margin({ bottom: 8, left: 20, right: 20 })
          .animation(this.animated ? this.getAnimation() : undefined)
      })
      
      // 底部操作区占位 | Bottom action area placeholder
      Row() {
        Column()
          .width(120)
          .height(40)
          .backgroundColor('#E0E0E0')
          .borderRadius(8)
          .margin({ right: 16 })
          .animation(this.animated ? this.getAnimation() : undefined)
        
        Column()
          .width(120)
          .height(40)
          .backgroundColor('#E0E0E0')
          .borderRadius(8)
          .animation(this.animated ? this.getAnimation() : undefined)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding(20)
  }
  
  // 渲染自定义骨架屏 | Render custom skeleton screen
  @Builder
  private renderCustomSkeleton() {
    Column() {
      if (this.customContent && this.customContent.length > 0) {
        ForEach(this.customContent, (content: object) => {
          content
        })
      }
    }
  }
  
  // 获取动画配置 | Get animation configuration
  private getAnimation(): Animation {
    return {
      duration: this.animationDuration,
      tempo: 1,
      curve: 'ease-in-out',
      iterations: -1,
      direction: 'alternate',
      delay: 0
    };
  }
  
  build() {
    Column() {
      switch (this.type) {
        case 'list':
          this.renderListSkeleton();
          break;
        case 'card':
          this.renderCardSkeleton();
          break;
        case 'detail':
          this.renderDetailSkeleton();
          break;
        case 'custom':
          this.renderCustomSkeleton();
          break;
        default:
          this.renderListSkeleton();
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

export default SkeletonScreen;