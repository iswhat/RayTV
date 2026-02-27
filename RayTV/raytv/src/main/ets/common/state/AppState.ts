interface AppState {
  user: {
    isLoggedIn: boolean;
    username: string | null;
  };
  settings: {
    theme: 'light' | 'dark' | 'system';
    language: string;
    autoPlay: boolean;
  };
  content: {
    isLoading: boolean;
    error: string | null;
    categories: string[];
    selectedCategory: string | null;
  };
  playback: {
    isPlaying: boolean;
    currentContent: any | null;
    volume: number;
  };
}

class AppStateManager {
  private state: AppState;
  private listeners: Array<(state: AppState) => void> = [];

  constructor(initialState: AppState) {
    this.state = initialState;
  }

  getState(): AppState {
    return { ...this.state };
  }

  setState(partialState: Partial<AppState>): void {
    this.state = { ...this.state, ...partialState };
    this.notifyListeners();
  }

  updateUser(userState: Partial<AppState['user']>): void {
    this.setState({ user: { ...this.state.user, ...userState } });
  }

  updateSettings(settingsState: Partial<AppState['settings']>): void {
    this.setState({ settings: { ...this.state.settings, ...settingsState } });
  }

  updateContent(contentState: Partial<AppState['content']>): void {
    this.setState({ content: { ...this.state.content, ...contentState } });
  }

  updatePlayback(playbackState: Partial<AppState['playback']>): void {
    this.setState({ playback: { ...this.state.playback, ...playbackState } });
  }

  onStateChange(listener: (state: AppState) => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => listener(this.getState()));
  }

  resetState(): void {
    this.state = {
      user: {
        isLoggedIn: false,
        username: null
      },
      settings: {
        theme: 'system',
        language: 'zh-CN',
        autoPlay: true
      },
      content: {
        isLoading: false,
        error: null,
        categories: [],
        selectedCategory: null
      },
      playback: {
        isPlaying: false,
        currentContent: null,
        volume: 80
      }
    };
    this.notifyListeners();
  }
}

const initialState: AppState = {
  user: {
    isLoggedIn: false,
    username: null
  },
  settings: {
    theme: 'system',
    language: 'zh-CN',
    autoPlay: true
  },
  content: {
    isLoading: false,
    error: null,
    categories: [],
    selectedCategory: null
  },
  playback: {
    isPlaying: false,
    currentContent: null,
    volume: 80
  }
};

export const appState = new AppStateManager(initialState);
export { AppStateManager, AppState };