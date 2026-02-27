import { BaseViewModel } from './BaseViewModel';

interface MainState {
  isLoading: boolean;
  error: string | null;
  content: any[];
  selectedItem: any | null;
}

class MainViewModel extends BaseViewModel {
  private state: MainState = {
    isLoading: false,
    error: null,
    content: [],
    selectedItem: null
  };

  getState(): MainState {
    return { ...this.state };
  }

  setState(partialState: Partial<MainState>): void {
    this.state = { ...this.state, ...partialState };
    this.emit('stateChange', this.getState());
  }

  async loadContent(): Promise<void> {
    this.setState({ isLoading: true, error: null });
    try {
      // 模拟数据加载
      await new Promise(resolve => setTimeout(resolve, 1000));
      this.setState({ 
        content: [
          { id: 1, title: 'Example 1', description: 'This is an example' },
          { id: 2, title: 'Example 2', description: 'Another example' }
        ],
        isLoading: false 
      });
    } catch (error) {
      this.setState({ 
        error: error instanceof Error ? error.message : 'Failed to load content',
        isLoading: false 
      });
    }
  }

  selectItem(item: any): void {
    this.setState({ selectedItem: item });
    this.emit('itemSelected', item);
  }

  clearSelection(): void {
    this.setState({ selectedItem: null });
  }

  refreshContent(): Promise<void> {
    return this.loadContent();
  }

  override dispose(): void {
    this.clearEvents();
    this.state = {
      isLoading: false,
      error: null,
      content: [],
      selectedItem: null
    };
  }
}

export { MainViewModel };