import { VirtualListItem, VirtualListConfig, VirtualListState, VirtualListEvents } from '../types/VirtualListTypes';

/**
 * 滚动偏移量接口
 */
interface ScrollOffset {
  xOffset: number;
  yOffset: number;
}

/**
 * 虚拟列表组件
 * 高性能长列表渲染解决方案
 */
@Component
export struct VirtualList {
  @State private visibleItems: VirtualListItem[] = [];
  @State @Watch('onVerticalScrollChange') private scrollTop: number = 0;
  @State @Watch('onHorizontalScrollChange') private scrollLeft: number = 0;
  @State private containerHeight: number = 0;
  @State private containerWidth: number = 0;
  
  private itemHeight: number = 0;
  private itemWidth: number = 0;
  private bufferCount: number = 5;
  private scrollTimer: number | null = null;
  private itemHeights: Map<string, number> = new Map();
  private totalHeight: number = 0;
  private totalWidth: number = 0;

  // 组件属性
  @Prop @Watch('onItemsChange') items: VirtualListItem[] = [];
  @Prop estimatedItemHeight: number = 60;
  @Prop estimatedItemWidth: number = 200;
  @Prop bufferSize: number = 5;
  @Prop scrollDirection: ScrollDirection = ScrollDirection.Vertical;
  @Prop renderItem: (item: VirtualListItem, index: number) => CustomComponent;
  @Prop onScroll?: (state: VirtualListState) => void;
  @Prop onVisibleItemsChange?: (visibleItems: VirtualListItem[]) => void;
  @Prop onItemClick?: (item: VirtualListItem) => void;
  @Prop onItemWillEnterView?: (item: VirtualListItem) => void;
  @Prop onItemDidLeaveView?: (item: VirtualListItem) => void;
  @Prop config?: VirtualListConfig;

  aboutToAppear(): void {
    this.itemHeight = this.estimatedItemHeight;
    this.itemWidth = this.estimatedItemWidth;
    this.bufferCount = this.bufferSize;
    this.calculateTotalSize();
    this.updateVisibleItems();
  }

  onItemsChange(): void {
    this.calculateTotalSize();
    this.updateVisibleItems();
  }

  onVerticalScrollChange(): void {
    if (this.scrollDirection === ScrollDirection.Vertical) {
      this.updateVisibleItems();
      this.notifyScrollEvent();
    }
  }

  onHorizontalScrollChange(): void {
    if (this.scrollDirection === ScrollDirection.Horizontal) {
      this.updateVisibleItems();
      this.notifyScrollEvent();
    }
  }

  private calculateTotalSize(): void {
    this.totalHeight = 0;
    this.totalWidth = 0;
    
    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i];
      const height = item.height || this.itemHeight;
      const width = item.width || this.itemWidth;
      
      this.totalHeight += height;
      this.totalWidth += width;
      
      // 存储每个项目的实际高度
      this.itemHeights.set(item.id, height);
    }
  }

  private updateVisibleItems(): void {
    if (this.items.length === 0 || (this.containerHeight === 0 && this.containerWidth === 0)) {
      this.visibleItems = [];
      this.onVisibleItemsChange?.([]);
      return;
    }

    let startIndex = 0;
    let endIndex = this.items.length - 1;
    let currentPosition = 0;

    if (this.scrollDirection === ScrollDirection.Vertical) {
      // 垂直滚动计算
      startIndex = this.findStartIndex(this.scrollTop);
      endIndex = this.findEndIndex(this.scrollTop + this.containerHeight);
    } else {
      // 水平滚动计算
      startIndex = this.findStartIndexHorizontal(this.scrollLeft);
      endIndex = this.findEndIndexHorizontal(this.scrollLeft + this.containerWidth);
    }

    // 添加缓冲区
    startIndex = Math.max(0, startIndex - this.bufferCount);
    endIndex = Math.min(this.items.length - 1, endIndex + this.bufferCount);

    const newVisibleItems: VirtualListItem[] = [];
    const visibleItemIds = new Set(this.visibleItems.map(item => item.id));
    const newVisibleItemIds = new Set<string>();

    for (let i = startIndex; i <= endIndex; i++) {
      if (i >= 0 && i < this.items.length) {
        const item = this.items[i];
        const height = this.itemHeights.get(item.id) || this.itemHeight;
        const width = item.width || this.itemWidth;
        
        // 计算项目位置
        let top = 0;
        let left = 0;
        
        if (this.scrollDirection === ScrollDirection.Vertical) {
          for (let j = 0; j < i; j++) {
            top += this.itemHeights.get(this.items[j].id) || this.itemHeight;
          }
        } else {
          for (let j = 0; j < i; j++) {
            left += this.items[j].width || this.itemWidth;
          }
        }

        const virtualItem: VirtualListItem = {
          id: item.id,
          data: item.data,
          index: i,
          top: top,
          left: left,
          height: height,
          width: width,
          visible: true
        };

        newVisibleItems.push(virtualItem);
        newVisibleItemIds.add(item.id);

        // 触发进入视口事件
        if (!visibleItemIds.has(item.id)) {
          this.onItemWillEnterView?.(virtualItem);
        }
      }
    }

    // 触发离开视口事件
    for (const item of this.visibleItems) {
      if (!newVisibleItemIds.has(item.id)) {
        this.onItemDidLeaveView?.(item);
      }
    }

    this.visibleItems = newVisibleItems;
    this.onVisibleItemsChange?.(newVisibleItems);
  }

  private findStartIndex(scrollTop: number): number {
    let currentPosition = 0;
    for (let i = 0; i < this.items.length; i++) {
      const height = this.itemHeights.get(this.items[i].id) || this.itemHeight;
      if (currentPosition + height > scrollTop) {
        return i;
      }
      currentPosition += height;
    }
    return this.items.length - 1;
  }

  private findEndIndex(scrollBottom: number): number {
    let currentPosition = 0;
    for (let i = 0; i < this.items.length; i++) {
      const height = this.itemHeights.get(this.items[i].id) || this.itemHeight;
      currentPosition += height;
      if (currentPosition >= scrollBottom) {
        return i;
      }
    }
    return this.items.length - 1;
  }

  private findStartIndexHorizontal(scrollLeft: number): number {
    let currentPosition = 0;
    for (let i = 0; i < this.items.length; i++) {
      const width = this.items[i].width || this.itemWidth;
      if (currentPosition + width > scrollLeft) {
        return i;
      }
      currentPosition += width;
    }
    return this.items.length - 1;
  }

  private findEndIndexHorizontal(scrollRight: number): number {
    let currentPosition = 0;
    for (let i = 0; i < this.items.length; i++) {
      const width = this.items[i].width || this.itemWidth;
      currentPosition += width;
      if (currentPosition >= scrollRight) {
        return i;
      }
    }
    return this.items.length - 1;
  }

  private handleScroll(scrollOffset: ScrollOffset): void {
    if (this.scrollDirection === ScrollDirection.Vertical) {
      this.scrollTop = Math.max(0, scrollOffset.yOffset);
    } else {
      this.scrollLeft = Math.max(0, scrollOffset.xOffset);
    }
    
    // 防抖处理
    if (this.scrollTimer) {
      clearTimeout(this.scrollTimer);
    }
    
    this.scrollTimer = setTimeout(() => {
      this.updateVisibleItems();
    }, this.config?.throttleTime || 16); // 约60fps
  }

  private notifyScrollEvent(): void {
    const state: VirtualListState = {
      containerHeight: this.containerHeight,
      scrollTop: this.scrollTop,
      visibleRange: {
        start: this.visibleItems.length > 0 ? this.visibleItems[0].index : 0,
        end: this.visibleItems.length > 0 ? this.visibleItems[this.visibleItems.length - 1].index : 0
      },
      totalItems: this.items.length,
      renderedItems: this.visibleItems.length
    };
    this.onScroll?.(state);
  }

  private getItemKey(item: VirtualListItem): string {
    return `${item.id}_${item.index}`;
  }

  private handleItemClick(item: VirtualListItem): void {
    this.onItemClick?.(item);
  }

  build() {
    Scroll() {
      if (this.scrollDirection === ScrollDirection.Vertical) {
        Column() {
          // 占位符 - 上方空白区域
          Blank()
            .height(`${this.getStartOffset()}px`)

          // 可见项目
          ForEach(this.visibleItems, (item: VirtualListItem) => {
            Column() {
              this.renderItem(item, item.index)
            }
            .key(this.getItemKey(item))
            .position({ x: 0, y: item.top - this.getStartOffset() })
            .height(`${item.height || this.itemHeight}px`)
            .onClick(() => this.handleItemClick(item))
          }, (item: VirtualListItem) => this.getItemKey(item))

          // 占位符 - 下方空白区域
          Blank()
            .height(`${this.getEndOffset()}px`)
        }
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.containerHeight = newArea.height as number;
          this.updateVisibleItems();
        })
      } else {
        Row() {
          // 占位符 - 左侧空白区域
          Blank()
            .width(`${this.getStartOffsetHorizontal()}px`)

          // 可见项目
          ForEach(this.visibleItems, (item: VirtualListItem) => {
            Row() {
              this.renderItem(item, item.index)
            }
            .key(this.getItemKey(item))
            .position({ x: (item.left || 0) - this.getStartOffsetHorizontal(), y: 0 })
            .width(`${item.width || this.itemWidth}px`)
            .onClick(() => this.handleItemClick(item))
          }, (item: VirtualListItem) => this.getItemKey(item))

          // 占位符 - 右侧空白区域
          Blank()
            .width(`${this.getEndOffsetHorizontal()}px`)
        }
        .onAreaChange((oldArea: Area, newArea: Area) => {
          this.containerWidth = newArea.width as number;
          this.updateVisibleItems();
        })
      }
    }
    .onScroll((xOffset: number, yOffset: number) => {
      const offset: ScrollOffset = { xOffset: xOffset, yOffset: yOffset };
      this.handleScroll(offset);
    })
    .scrollable(this.scrollDirection)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
  }

  private getStartOffset(): number {
    if (this.visibleItems.length === 0) return 0;
    return this.visibleItems[0].top;
  }

  private getEndOffset(): number {
    if (this.visibleItems.length === 0) return this.totalHeight;
    const lastItem = this.visibleItems[this.visibleItems.length - 1];
    return this.totalHeight - (lastItem.top + (lastItem.height || this.itemHeight));
  }

  private getStartOffsetHorizontal(): number {
    if (this.visibleItems.length === 0) return 0;
    return this.visibleItems[0].left || 0;
  }

  private getEndOffsetHorizontal(): number {
    if (this.visibleItems.length === 0) return this.totalWidth;
    const lastItem = this.visibleItems[this.visibleItems.length - 1];
    return this.totalWidth - ((lastItem.left || 0) + (lastItem.width || this.itemWidth));
  }
}