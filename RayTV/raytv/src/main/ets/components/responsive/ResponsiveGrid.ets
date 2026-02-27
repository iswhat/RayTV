import { Component, State, Property, EventEmitter } from '@ohos/harmonyos';
import { designSystem } from '../../design/DesignSystem';
import { breakpointManager } from '../../common/layout/BreakpointManager';

interface ResponsiveGridItem {
  id: string;
  content: JSX.Element;
}

interface ResponsiveGridProps {
  items: ResponsiveGridItem[];
  columns?: {
    small?: number;
    medium?: number;
    large?: number;
    xlarge?: number;
  };
  spacing?: number;
  onItemClick?: (id: string) => void;
}

@Component
class ResponsiveGrid {
  @Property items: ResponsiveGridItem[] = [];
  @Property columns: {
    small?: number;
    medium?: number;
    large?: number;
    xlarge?: number;
  } = {};
  @Property spacing: number = designSystem.spacing.md;
  @Event onItemClick: (id: string) => void = () => {};

  @State currentColumns: number = 2;
  @State currentBreakpoint: string = 'medium';

  aboutToAppear() {
    this.updateColumns();
    // Listen for breakpoint changes
    breakpointManager.addBreakpointListener(() => {
      this.updateColumns();
    });
  }

  updateColumns() {
    const breakpoint = breakpointManager.getCurrentBreakpoint();
    this.currentBreakpoint = breakpoint;
    
    switch (breakpoint) {
      case 'small':
        this.currentColumns = this.columns.small || 1;
        break;
      case 'medium':
        this.currentColumns = this.columns.medium || 2;
        break;
      case 'large':
        this.currentColumns = this.columns.large || 3;
        break;
      case 'xlarge':
        this.currentColumns = this.columns.xlarge || 4;
        break;
    }
  }

  build() {
    return (
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${this.currentColumns}, 1fr)`,
          gap: this.spacing,
          width: '100%'
        }}
      >
        {this.items.map((item) => (
          <div
            key={item.id}
            style={{
              padding: this.spacing / 2,
              cursor: 'pointer',
              transition: 'transform 0.2s'
            }}
            onClick={() => this.onItemClick(item.id)}
          >
            {item.content}
          </div>
        ))}
      </div>
    );
  }
}

export default ResponsiveGrid;