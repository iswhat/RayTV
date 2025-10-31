// CategoryNavigation.ets - 分类导航组件
import { Scroller, BarState, ScrollDirection, Text, Button, Row, Scroll, ForEach } from '@ohos.arkui';
import { FontWeight } from '@ohos.arkui.text';

interface Category {
  id: string;
  name: string;
  icon?: string;
}

interface CategoryNavigationProps {
  categories: Category[];
  selectedCategoryId: string;
  onCategoryChange: (categoryId: string) => void;
  showScrollButtons?: boolean;
}

/**
 * 滚动偏移量接口
 */
export interface ScrollOffset {
  x: number;
  y: number;
}

@Component
export default struct CategoryNavigation {
  private scrollController: Scroller = new Scroller();
  @State private isScrollingRight: boolean = false;
  @State private isScrollingLeft: boolean = false;
  
  private props: CategoryNavigationProps = {} as CategoryNavigationProps;
  private scrollButtonWidth: number = 50;
  
  constructor(props: CategoryNavigationProps) {
    this.props = props;
  }
  
  // 检查滚动状态
  checkScrollPosition(): void {
    try {
      const scrollOffset = this.scrollController.currentOffset();
      this.isScrollingLeft = scrollOffset.x > 10;
      
      // 计算可滚动距离的近似值
      this.isScrollingRight = true; // 默认显示右侧滚动按钮，实际应用中可以根据内容动态计算
    } catch (error) {
      console.error('Failed to check scroll position');
    }
  }
  
  // 滚动到左侧
  scrollToLeft(): void {
    try {
      this.scrollController.scrollPage({ next: false });
      setTimeout(() => this.checkScrollPosition(), 100);
    } catch (error) {
      console.error('Failed to scroll left');
    }
  }
  
  // 滚动到右侧
  scrollToRight(): void {
    try {
      this.scrollController.scrollPage({ next: true });
      setTimeout(() => this.checkScrollPosition(), 100);
    } catch (error) {
      console.error('Failed to scroll right');
    }
  }
  
  build() {
    // 在build方法外调用
    const showScrollButtons = this.props.showScrollButtons || false;
    
    Row() {
      // 左侧滚动按钮
      if (showScrollButtons && this.isScrollingLeft) {
        Button() {
          Text('←')
            .fontSize(24)
        }
        .width(this.scrollButtonWidth)
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.8)')
        .onClick(() => this.scrollToLeft())
        .position({ x: 0, y: 0 })
        .zIndex(1)
      }
      
      // 分类列表
      Scroll(this.scrollController) {
        Row() {
          ForEach(this.props.categories, (category) => {
            const isSelected = category.id === this.props.selectedCategoryId;
            
            Row() {
              if (category.icon) {
                Text(category.icon)
                  .fontSize(20)
                  .marginRight(8)
              }
              Text(category.name)
                .fontSize(16)
                .fontWeight(isSelected ? FontWeight.Bold : FontWeight.Normal)
            }
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor(isSelected ? '#37a2da' : 'transparent')
            .borderRadius(24)
            .onClick(() => this.props.onCategoryChange(category.id))
          })
        }
        .padding({ left: this.props.showScrollButtons ? this.scrollButtonWidth : 0 })
        .paddingRight(this.props.showScrollButtons ? this.scrollButtonWidth : 0)
        .onScroll(() => this.checkScrollPosition())
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .flexGrow(1)
      .height(60)
      
      // 右侧滚动按钮
      if (showScrollButtons && this.isScrollingRight) {
        Button() {
          Text('→')
            .fontSize(24)
        }
        .width(this.scrollButtonWidth)
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.8)')
        .onClick(() => this.scrollToRight())
        .position({ x: '100%', y: 0, offsetX: -this.scrollButtonWidth })
        .zIndex(1)
      }
    }
    .width('100%')
    .height(60)
    .backgroundColor('#1a1a1a')
    .onAppear(() => {
      // 延迟检查滚动位置，确保组件已渲染
      setTimeout(() => {
        this.checkScrollPosition();
      }, 100);
    })
  }
}