import { Component, State, Property, EventEmitter } from '@ohos/harmonyos';
import { designSystem } from '../../design/DesignSystem';
import { responsiveSystem } from '../../common/layout/ResponsiveSystem';

interface MediaItem {
  id: string;
  title: string;
  description: string;
  thumbnail?: string;
  duration?: number;
  source: string;
  category: string;
}

@Component
class MediaGrid {
  @Property items: MediaItem[] = [];
  @Property isLoading: boolean = false;
  @Property error: string | null = null;
  @Event onItemClick: (item: MediaItem) => void = () => {};

  @State currentBreakpoint: string = responsiveSystem.getCurrentBreakpoint();

  private subscription: () => void = () => {};

  aboutToAppear() {
    this.subscription = responsiveSystem.onBreakpointChange((breakpoint) => {
      this.currentBreakpoint = breakpoint;
    });
  }

  aboutToDisappear() {
    this.subscription();
  }

  getGridColumns(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 1;
      case 'sm':
        return 2;
      case 'md':
        return 3;
      case 'lg':
        return 4;
      case 'xl':
        return 5;
      case 'xxl':
        return 6;
      default:
        return 3;
    }
  }

  formatDuration(seconds?: number): string {
    if (!seconds) return '';
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    return (
      <div>
        {this.isLoading ? (
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '60vh',
            backgroundColor: designSystem.colors.surface,
            borderRadius: designSystem.borderRadius.large,
            border: `1px solid ${designSystem.colors.border}`
          }}>
            <text style={{
              color: designSystem.colors.textSecondary,
              fontSize: designSystem.typography.fontSize.large
            }}>加载中...</text>
          </div>
        ) : this.error ? (
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '60vh',
            backgroundColor: designSystem.colors.surface,
            borderRadius: designSystem.borderRadius.large,
            border: `1px solid ${designSystem.colors.border}`
          }}>
            <text style={{
              color: designSystem.colors.error,
              fontSize: designSystem.typography.fontSize.large
            }}>{this.error}</text>
          </div>
        ) : this.items.length === 0 ? (
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '60vh',
            backgroundColor: designSystem.colors.surface,
            borderRadius: designSystem.borderRadius.large,
            border: `1px solid ${designSystem.colors.border}`
          }}>
            <text style={{
              color: designSystem.colors.textSecondary,
              fontSize: designSystem.typography.fontSize.large
            }}>暂无内容</text>
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${this.getGridColumns()}, 1fr)`,
            gap: designSystem.spacing.md
          }}>
            {this.items.map((item) => (
              <div
                key={item.id}
                style={{
                  backgroundColor: designSystem.colors.surface,
                  borderRadius: designSystem.borderRadius.large,
                  padding: designSystem.spacing.md,
                  border: `1px solid ${designSystem.colors.border}`,
                  aspectRatio: '3/4',
                  display: 'flex',
                  flexDirection: 'column',
                  cursor: 'pointer',
                  transition: 'transform 0.2s, box-shadow 0.2s',
                  ':hover': {
                    transform: 'scale(1.02)',
                    boxShadow: designSystem.shadow.medium
                  }
                }}
                onClick={() => this.onItemClick(item)}
              >
                <div style={{
                  flex: 1,
                  backgroundColor: designSystem.colors.border,
                  borderRadius: designSystem.borderRadius.medium,
                  marginBottom: designSystem.spacing.sm,
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  position: 'relative'
                }}>
                  {item.thumbnail ? (
                    <image
                      src={item.thumbnail}
                      style={{
                        width: '100%',
                        height: '100%',
                        borderRadius: designSystem.borderRadius.medium
                      }}
                    />
                  ) : (
                    <text style={{
                      color: designSystem.colors.textSecondary,
                      fontSize: designSystem.typography.fontSize.small
                    }}>封面</text>
                  )}
                  {item.duration && (
                    <div style={{
                      position: 'absolute',
                      bottom: designSystem.spacing.sm,
                      right: designSystem.spacing.sm,
                      backgroundColor: 'rgba(0, 0, 0, 0.7)',
                      padding: `${designSystem.spacing.xs} ${designSystem.spacing.sm}`,
                      borderRadius: designSystem.borderRadius.small
                    }}>
                      <text style={{
                        color: designSystem.colors.text,
                        fontSize: designSystem.typography.fontSize.small
                      }}>{this.formatDuration(item.duration)}</text>
                    </div>
                  )}
                </div>
                <text style={{
                  color: designSystem.colors.text,
                  fontSize: designSystem.typography.fontSize.medium,
                  fontWeight: designSystem.typography.fontWeight.medium,
                  marginBottom: designSystem.spacing.xs,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap'
                }}>{item.title}</text>
                <text style={{
                  color: designSystem.colors.textSecondary,
                  fontSize: designSystem.typography.fontSize.small,
                  flex: 1,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  display: '-webkit-box',
                  WebkitLineClamp: 2,
                  WebkitBoxOrient: 'vertical'
                }}>{item.description}</text>
                <div style={{
                  marginTop: designSystem.spacing.xs,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <text style={{
                    color: designSystem.colors.primary,
                    fontSize: designSystem.typography.fontSize.small
                  }}>{item.source}</text>
                  <text style={{
                    color: designSystem.colors.textSecondary,
                    fontSize: designSystem.typography.fontSize.small
                  }}>{item.category}</text>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }
}

export default MediaGrid;
export { MediaItem };