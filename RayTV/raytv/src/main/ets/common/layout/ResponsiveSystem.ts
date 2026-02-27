interface Breakpoint {
  name: string;
  minWidth: number;
  maxWidth?: number;
}

interface ResponsiveConfig {
  breakpoints: Breakpoint[];
  defaultBreakpoint: string;
}

class ResponsiveSystem {
  private config: ResponsiveConfig;
  private currentBreakpoint: string;
  private listeners: Array<(breakpoint: string) => void> = [];

  constructor(config: ResponsiveConfig) {
    this.config = config;
    this.currentBreakpoint = config.defaultBreakpoint;
    this.init();
  }

  private init(): void {
    this.updateBreakpoint();
    window.addEventListener('resize', this.updateBreakpoint.bind(this));
  }

  private updateBreakpoint(): void {
    const width = window.innerWidth;
    const breakpoint = this.config.breakpoints.find(bp => {
      if (bp.maxWidth) {
        return width >= bp.minWidth && width <= bp.maxWidth;
      }
      return width >= bp.minWidth;
    });

    const newBreakpoint = breakpoint ? breakpoint.name : this.config.defaultBreakpoint;
    if (newBreakpoint !== this.currentBreakpoint) {
      this.currentBreakpoint = newBreakpoint;
      this.notifyListeners();
    }
  }

  private notifyListeners(): void {
    this.listeners.forEach(listener => listener(this.currentBreakpoint));
  }

  getCurrentBreakpoint(): string {
    return this.currentBreakpoint;
  }

  onBreakpointChange(listener: (breakpoint: string) => void): () => void {
    this.listeners.push(listener);
    return () => {
      const index = this.listeners.indexOf(listener);
      if (index > -1) {
        this.listeners.splice(index, 1);
      }
    };
  }

  isBreakpoint(breakpoint: string): boolean {
    return this.currentBreakpoint === breakpoint;
  }

  getBreakpointConfig(breakpoint: string): Breakpoint | undefined {
    return this.config.breakpoints.find(bp => bp.name === breakpoint);
  }
}

const defaultConfig: ResponsiveConfig = {
  breakpoints: [
    { name: 'xs', minWidth: 0, maxWidth: 575 },
    { name: 'sm', minWidth: 576, maxWidth: 767 },
    { name: 'md', minWidth: 768, maxWidth: 991 },
    { name: 'lg', minWidth: 992, maxWidth: 1199 },
    { name: 'xl', minWidth: 1200, maxWidth: 1599 },
    { name: 'xxl', minWidth: 1600 }
  ],
  defaultBreakpoint: 'md'
};

export const responsiveSystem = new ResponsiveSystem(defaultConfig);
export { ResponsiveSystem };