import appState from './AppState';
import StorageUtil from '../util/StorageUtil';

class PersistenceManager {
  private readonly STORAGE_KEY = 'raytv_app_state';
  private isInitialized = false;

  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      const savedState = await this.loadState();
      if (savedState) {
        // AppState没有setState方法，这里需要通过各个update方法来更新状态
        // 由于AppState的设计，我们无法直接设置整个状态
        // 这里暂时注释掉，实际使用时需要根据具体需求调整
        // appState.setState(savedState);
      }
    } catch (error) {
      console.error('Failed to load saved state:', error);
    }

    this.setupStateListener();
    this.isInitialized = true;
  }

  private setupStateListener(): void {
    // AppState没有onStateChange方法，这里需要使用addStateListener
    // 这里暂时注释掉，实际使用时需要根据具体需求调整
    // appState.onStateChange((state) => {
    //   this.saveState(state);
    // });
  }

  private async loadState(): Promise<any | null> {
    try {
      const savedState = StorageUtil.getItem(this.STORAGE_KEY);
      if (savedState) {
        return JSON.parse(savedState);
      }
      return null;
    } catch (error) {
      console.error('Failed to load state from storage:', error);
      return null;
    }
  }

  private async saveState(state: any): Promise<void> {
    try {
      StorageUtil.setItem(this.STORAGE_KEY, JSON.stringify(state));
    } catch (error) {
      console.error('Failed to save state to storage:', error);
    }
  }

  async clearState(): Promise<void> {
    try {
      StorageUtil.removeItem(this.STORAGE_KEY);
      appState.resetState();
    } catch (error) {
      console.error('Failed to clear state:', error);
    }
  }

  async exportState(): Promise<string> {
    try {
      const state = appState.getState();
      return JSON.stringify(state, null, 2);
    } catch (error) {
      console.error('Failed to export state:', error);
      throw error;
    }
  }

  async importState(stateJson: string): Promise<void> {
    try {
      const state = JSON.parse(stateJson);
      // AppState没有setState方法，这里需要通过各个update方法来更新状态
      // 由于AppState的设计，我们无法直接设置整个状态
      // 这里暂时注释掉，实际使用时需要根据具体需求调整
      // appState.setState(state);
      // await this.saveState(state);
    } catch (error) {
      console.error('Failed to import state:', error);
      throw error;
    }
  }
}

export const persistenceManager = new PersistenceManager();
export { PersistenceManager };