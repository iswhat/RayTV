/**
 * ViewModel 单元测试 | ViewModel Unit Tests
 * 测试BaseViewModel和MainViewModel的核心功能
 * Tests core functionality of BaseViewModel and MainViewModel
 */
import { BaseViewModel, Observable, StateManager } from '../presentation/viewmodel/BaseViewModel';
import { MainViewModel } from '../presentation/viewmodel/MainViewModel';
import { EventBus } from '../common/event/EventBus';
import { EnhancedDIContainer } from '../common/di/EnhancedContainer';

// 测试用的ViewModel实现 | Test ViewModel implementation
class TestViewModel extends BaseViewModel {
  public testState: string = 'initial';
  public testNumber: number = 0;
  
  constructor() {
    super('Test');
  }
  
  protected setupGlobalEventListeners(): void {
    // 测试用的事件监听器设置 | Test event listener setup
  }
  
  public async testDataOperation(): Promise<string> {
    return await this.handleAsyncOperation(
      async () => {
        await this.delay(10);
        return 'success';
      },
      'loading',
      'error'
    );
  }
  
  public getTestState(): string {
    return this.testState;
  }
  
  public setTestState(value: string): void {
    this.testState = value;
  }
}

describe('BaseViewModel', () => {
  let viewModel: TestViewModel;
  let eventBus: EventBus;
  let diContainer: EnhancedDIContainer;
  
  beforeEach(() => {
    viewModel = new TestViewModel();
    eventBus = EventBus.getInstance();
    diContainer = EnhancedDIContainer.getInstance();
  });
  
  afterEach(async () => {
    await viewModel.destroy();
  });
  
  describe('状态管理功能', () => {
    it('应该能够正确设置和获取状态', () => {
      // Arrange & Act
      viewModel.setState('testKey', 'testValue');
      const result = viewModel.getState<string>('testKey');
      
      // Assert
      expect(result).toBe('testValue');
    });
    
    it('应该能够观察状态变化', () => {
      // Arrange
      let observedValue: string | undefined;
      let oldValue: string | undefined;
      
      // Act
      const subscriptionId = viewModel.observeState<string>('testKey', (newVal, oldVal) => {
        observedValue = newVal;
        oldValue = oldVal;
      });
      
      viewModel.setState('testKey', 'newValue');
      
      // Assert
      expect(observedValue).toBe('newValue');
      expect(oldValue).toBeUndefined();
    });
    
    it('应该支持批量状态更新', () => {
      // Arrange
      const updates = {
        key1: 'value1',
        key2: 'value2',
        key3: 'value3'
      };
      
      // Act
      viewModel.batchUpdateStates(updates);
      
      // Assert
      expect(viewModel.getState('key1')).toBe('value1');
      expect(viewModel.getState('key2')).toBe('value2');
      expect(viewModel.getState('key3')).toBe('value3');
    });
  });
  
  describe('事件处理功能', () => {
    it('应该能够订阅和发布事件', () => {
      // Arrange
      let eventReceived = false;
      let eventData: any;
      
      // Act
      viewModel.subscribe('test:event', (data) => {
        eventReceived = true;
        eventData = data;
      });
      
      viewModel.publish('test:event', { message: 'hello' });
      
      // Assert
      expect(eventReceived).toBe(true);
      expect(eventData.message).toBe('hello');
    });
    
    it('应该在销毁时清理事件订阅', async () => {
      // Arrange
      let callCount = 0;
      
      viewModel.subscribe('test:event', () => {
        callCount++;
      });
      
      // Act
      await viewModel.destroy();
      viewModel.publish('test:event', {});
      
      // Assert
      expect(callCount).toBe(0);
    });
  });
  
  describe('异步操作处理', () => {
    it('应该正确处理成功的异步操作', async () => {
      // Act
      const result = await viewModel.testDataOperation();
      
      // Assert
      expect(result).toBe('success');
      expect(viewModel.getState('loading')).toBe(false);
      expect(viewModel.getState('error')).toBeNull();
    });
    
    it('应该正确处理失败的异步操作', async () => {
      // Arrange
      const failingOperation = async () => {
        await viewModel.handleAsyncOperation(
          async () => {
            throw new Error('Test error');
          },
          'loading',
          'error'
        );
      };
      
      // Act
      await failingOperation();
      
      // Assert
      expect(viewModel.getState('loading')).toBe(false);
      expect(viewModel.getState('error')).toBe('Test error');
    });
  });
  
  describe('生命周期管理', () => {
    it('应该正确执行初始化流程', async () => {
      // Act
      await viewModel.initialize();
      
      // Assert
      expect(viewModel['isInitialized']).toBe(true);
    });
    
    it('应该正确执行激活/停用流程', () => {
      // Arrange
      viewModel['isInitialized'] = true;
      
      // Act
      viewModel.activate();
      
      // Assert
      expect(viewModel['isActive']).toBe(true);
      
      // Act
      viewModel.deactivate();
      
      // Assert
      expect(viewModel['isActive']).toBe(false);
    });
    
    it('不应该重复初始化', async () => {
      // Arrange
      await viewModel.initialize();
      const initialState = viewModel['isInitialized'];
      
      // Act
      await viewModel.initialize();
      
      // Assert
      expect(viewModel['isInitialized']).toBe(initialState);
    });
  });
  
  describe('工具函数', () => {
    it('应该正确实现防抖功能', (done) => {
      // Arrange
      let callCount = 0;
      const debouncedFunc = viewModel.debounce(() => {
        callCount++;
      }, 50);
      
      // Act
      debouncedFunc();
      debouncedFunc();
      debouncedFunc();
      
      // Assert
      setTimeout(() => {
        expect(callCount).toBe(1);
        done();
      }, 100);
    });
    
    it('应该正确实现节流功能', (done) => {
      // Arrange
      let callCount = 0;
      const throttledFunc = viewModel.throttle(() => {
        callCount++;
      }, 50);
      
      // Act
      throttledFunc();
      throttledFunc();
      throttledFunc();
      
      // Assert
      expect(callCount).toBe(1);
      
      setTimeout(() => {
        throttledFunc();
        expect(callCount).toBe(2);
        done();
      }, 100);
    });
  });
});

describe('Observable', () => {
  let observable: Observable<string>;
  
  beforeEach(() => {
    observable = new Observable('initial');
  });
  
  describe('基础功能', () => {
    it('应该正确初始化值', () => {
      // Assert
      expect(observable.value).toBe('initial');
      expect(observable.getValue()).toBe('initial');
    });
    
    it('应该能够设置新值', () => {
      // Act
      observable.setValue('new value');
      
      // Assert
      expect(observable.value).toBe('new value');
    });
    
    it('应该避免设置相同值时的重复通知', () => {
      // Arrange
      let callCount = 0;
      observable.subscribe(() => callCount++);
      
      // Act
      observable.setValue('initial'); // 相同值
      observable.setValue('different'); // 不同值
      observable.setValue('different'); // 相同值
      
      // Assert
      expect(callCount).toBe(1);
    });
  });
  
  describe('订阅功能', () => {
    it('应该能够订阅值变化', () => {
      // Arrange
      let newValue: string | undefined;
      let oldValue: string | undefined;
      
      // Act
      observable.subscribe((newVal, oldVal) => {
        newValue = newVal;
        oldValue = oldVal;
      });
      
      observable.setValue('updated');
      
      // Assert
      expect(newValue).toBe('updated');
      expect(oldValue).toBe('initial');
    });
    
    it('应该能够取消订阅', () => {
      // Arrange
      let callCount = 0;
      const subscriptionId = observable.subscribe(() => callCount++);
      
      // Act
      observable.unsubscribe(subscriptionId);
      observable.setValue('new value');
      
      // Assert
      expect(callCount).toBe(0);
    });
  });
  
  describe('批处理功能', () => {
    it('应该支持批处理更新', () => {
      // Act
      observable.batchUpdate(current => current + ' updated');
      
      // Assert
      expect(observable.value).toBe('initial updated');
    });
  });
});

describe('StateManager', () => {
  let stateManager: StateManager;
  
  beforeEach(() => {
    stateManager = new StateManager();
  });
  
  describe('状态操作', () => {
    it('应该能够设置和获取状态', () => {
      // Act
      stateManager.setState('test', 'value');
      const result = stateManager.getState('test');
      
      // Assert
      expect(result).toBe('value');
    });
    
    it('应该能够观察状态变化', () => {
      // Arrange
      let newValue: string | undefined;
      
      // Act
      stateManager.observeState('test', (val) => {
        newValue = val;
      });
      stateManager.setState('test', 'observed');
      
      // Assert
      expect(newValue).toBe('observed');
    });
    
    it('应该能够获取所有状态', () => {
      // Arrange
      stateManager.setState('key1', 'value1');
      stateManager.setState('key2', 'value2');
      
      // Act
      const allStates = stateManager.getAllStates();
      
      // Assert
      expect(allStates.get('key1')).toBe('value1');
      expect(allStates.get('key2')).toBe('value2');
    });
  });
});

describe('MainViewModel', () => {
  let mainViewModel: MainViewModel;
  
  beforeEach(() => {
    mainViewModel = new MainViewModel();
  });
  
  afterEach(async () => {
    await mainViewModel.destroy();
  });
  
  describe('基础功能', () => {
    it('应该正确初始化默认状态', async () => {
      // Act
      await mainViewModel.initialize();
      
      // Assert
      expect(mainViewModel.selectedTab).toBe('vod');
      expect(mainViewModel.currentSite).toBe('默认片源');
    });
    
    it('应该能够切换标签页', () => {
      // Act
      mainViewModel.switchTab('live');
      
      // Assert
      expect(mainViewModel.selectedTab).toBe('live');
    });
    
    it('应该能够处理搜索', () => {
      // Act
      mainViewModel.searchContent('test query');
      
      // Assert
      expect(mainViewModel.searchQuery).toBe('test query');
      expect(mainViewModel.isSearching).toBe(true);
    });
  });
  
  describe('状态获取', () => {
    it('应该能够获取完整状态', async () => {
      // Arrange
      await mainViewModel.initialize();
      
      // Act
      const state = mainViewModel.getCurrentState();
      
      // Assert
      expect(state.selectedTab).toBe('vod');
      expect(state.isLoading).toBe(false);
      expect(Array.isArray(state.categories)).toBe(true);
    });
  });
});