/**
 * 基础TV网格组件
 */

export interface GridItem {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  rating?: string;
  tags?: string[];
  isFavorite?: boolean;
}

@Component
export struct BasicTVGrid {
  @Prop items: GridItem[] = []
  @Prop onItemClick: (item: GridItem) => void = () => {}
  
  build() {
    Grid()
    {
      ForEach(this.items, (item: GridItem, index: number) => {
        Stack()
        {
          Text(item.title || `Item ${index + 1}`)
        }
        .onClick(() => this.onItemClick(item))
      }, (item: GridItem, index: number) => `${index}`)
    }
  }
}