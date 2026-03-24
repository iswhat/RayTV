import { responsiveSystem } from './ResponsiveSystem';

export interface BreakpointConfig {
  [key: string]: {
    gridColumns: number;
    spacing: number;
    fontSize: number;
    [key: string]: string;
  };
}

export class BreakpointManager {
  private config: BreakpointConfig;
  private currentConfig: Record<string, Object>;
  private listeners: Array<(config: Record<string, Object>) => void> = [];

  constructor(config: BreakpointConfig) {
    this.config = config;
    this.currentConfig = this.getConfigForBreakpoint(responsiveSystem.getCurrentBreakpoint());
    this.init();
  }

  private init(): void {
    responsiveSystem.onBreakpointChange((breakpoint) => {
      this.currentConfig = this.getConfigForBreakpoint(breakpoint);
      this.notifyListeners();
    });
  }

  private getConfigForBreakpoint(breakpoint: string): Record<string, Object> {
    return this.config[breakpoint] || this.config['md'] || {};
  }

  private notifyListeners(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      const listener = this.listeners[i];
      listener(this.currentConfig);
    }
  }

  getCurrentConfig(): Record<string, Object> {
    return this.currentConfig;
  }

  getConfig(breakpoint: string): Record<string, Object> {
    return this.getConfigForBreakpoint(breakpoint);
  }

  onConfigChange(listener: (config: Record<string, Object>) => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  getGridColumns(): number {
    return this.currentConfig.gridColumns || 1;
  }

  getSpacing(): number {
    return this.currentConfig.spacing || 8;
  }

  getFontSize(): number {
    return this.currentConfig.fontSize || 16;
  }
}

const defaultBreakpointConfig: BreakpointConfig = {
  xs: {
    gridColumns: 1,
    spacing: 4,
    fontSize: 14
  },
  sm: {
    gridColumns: 2,
    spacing: 8,
    fontSize: 14
  },
  md: {
    gridColumns: 3,
    spacing: 12,
    fontSize: 16
  },
  lg: {
    gridColumns: 4,
    spacing: 16,
    fontSize: 16
  },
  xl: {
    gridColumns: 5,
    spacing: 20,
    fontSize: 18
  },
  xxl: {
    gridColumns: 6,
    spacing: 24,
    fontSize: 18
  }
};

export const breakpointManager = new BreakpointManager(defaultBreakpointConfig);