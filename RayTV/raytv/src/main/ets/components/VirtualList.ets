import { VirtualListItem } from '../types/VirtualListTypes';

/**
 * 虚拟列表组件
 * 高性能长列表渲染解决方案
 */
@Component
struct VirtualList {
  @State private visibleItems: VirtualListItem[] = [];
  @State private scrollTop: number = 0;
  @State private containerHeight: number = 0;
  
  private itemHeight: number = 0;
  private bufferCount: number = 5;
  private scrollTimer: number | null = null;

  // 组件属性
  @Prop items: VirtualListItem[] = [];
  @Prop estimatedItemHeight: number = 60;
  @Prop bufferSize: number = 5;
  @Prop renderItem: (item: VirtualListItem, index: number) => CustomComponent;
  @Prop onScroll?: (offset: number) => void;
  @Prop onVisibleItemsChange?: (visibleItems: VirtualListItem[]) => void;

  aboutToAppear(): void {
    this.itemHeight = this.estimatedItemHeight;
    this.bufferCount = this.bufferSize;
    this.updateVisibleItems();
  }

  @Watch('items')
  onItemsChange(): void {
    this.updateVisibleItems();
  }

  @Watch('scrollTop')
  onScrollChange(): void {
    this.updateVisibleItems();
    this.onScroll?.(this.scrollTop);
  }

  private updateVisibleItems(): void {
    if (this.items.length === 0 || this.containerHeight === 0) {
      this.visibleItems = [];
      return;
    }

    const totalHeight = this.items.length * this.itemHeight;
    const startIndex = Math.max(0, Math.floor(this.scrollTop / this.itemHeight) - this.bufferCount);
    const endIndex = Math.min(
      this.items.length - 1,
      Math.floor((this.scrollTop + this.containerHeight) / this.itemHeight) + this.bufferCount
    );

    const newVisibleItems = [];
    for (let i = startIndex; i <= endIndex; i++) {
      if (i >= 0 && i < this.items.length) {
        newVisibleItems.push({
          id: this.items[i].id,
          data: this.items[i].data,
          index: i,
          top: i * this.itemHeight
        });
      }
    }

    this.visibleItems = newVisibleItems;
    this.onVisibleItemsChange?.(newVisibleItems);
  }

  private handleScroll(offset: number): void {
    this.scrollTop = Math.max(0, offset);
    
    // 防抖处理
    if (this.scrollTimer) {
      clearTimeout(this.scrollTimer);
    }
    
    this.scrollTimer = setTimeout(() => {
      this.updateVisibleItems();
    }, 16); // 约60fps
  }

  private getItemKey(item: VirtualListItem): string {
    return `${item.id}_${item.index}`;
  }

  build() {
    Scroll() {
      Column() {
        // 占位符 - 上方空白区域
        Blank()
          .height(`${this.getStartOffset()}px`)

        // 可见项目
        ForEach(this.visibleItems, (item: VirtualListItem) => {
          Row() {
            this.renderItem(item, item.index)
          }
          .key(this.getItemKey(item))
          .position({ x: 0, y: item.top - this.getStartOffset() })
          .height(`${this.itemHeight}px`)
        }, (item: VirtualListItem) => this.getItemKey(item))

        // 占位符 - 下方空白区域
        Blank()
          .height(`${this.getEndOffset()}px`)
      }
      .onAreaChange((oldArea: AreaInfo, newArea: AreaInfo) => {
        this.containerHeight = newArea.height;
        this.updateVisibleItems();
      })
    }
    .onScroll((scrollOffset: ScrollOffset) => {
      this.handleScroll(scrollOffset.yOffset);
    })
    .scrollable(ScrollDirection.Vertical)
  }

  private getStartOffset(): number {
    if (this.visibleItems.length === 0) return 0;
    const firstVisibleIndex = this.visibleItems[0].index;
    return firstVisibleIndex * this.itemHeight;
  }

  private getEndOffset(): number {
    if (this.visibleItems.length === 0) return this.items.length * this.itemHeight;
    const lastVisibleIndex = this.visibleItems[this.visibleItems.length - 1].index;
    return (this.items.length - lastVisibleIndex - 1) * this.itemHeight;
  }
}