import { appState, AppState } from './AppState';
import { StorageUtil } from '../../common/util/StorageUtil';

class PersistenceManager {
  private readonly STORAGE_KEY = 'raytv_app_state';
  private isInitialized = false;

  async initialize(): Promise<void> {
    if (this.isInitialized) return;

    try {
      const savedState = await this.loadState();
      if (savedState) {
        appState.setState(savedState);
      }
    } catch (error) {
      console.error('Failed to load saved state:', error);
    }

    this.setupStateListener();
    this.isInitialized = true;
  }

  private setupStateListener(): void {
    appState.onStateChange((state) => {
      this.saveState(state);
    });
  }

  private async loadState(): Promise<AppState | null> {
    try {
      const savedState = await StorageUtil.get(this.STORAGE_KEY);
      if (savedState) {
        return JSON.parse(savedState) as AppState;
      }
      return null;
    } catch (error) {
      console.error('Failed to load state from storage:', error);
      return null;
    }
  }

  private async saveState(state: AppState): Promise<void> {
    try {
      await StorageUtil.set(this.STORAGE_KEY, JSON.stringify(state));
    } catch (error) {
      console.error('Failed to save state to storage:', error);
    }
  }

  async clearState(): Promise<void> {
    try {
      await StorageUtil.remove(this.STORAGE_KEY);
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
      const state = JSON.parse(stateJson) as AppState;
      appState.setState(state);
      await this.saveState(state);
    } catch (error) {
      console.error('Failed to import state:', error);
      throw error;
    }
  }
}

export const persistenceManager = new PersistenceManager();
export { PersistenceManager };