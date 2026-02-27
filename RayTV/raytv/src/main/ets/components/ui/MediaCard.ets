import { Component, State, Property, EventEmitter } from '@ohos/harmonyos';
import { designSystem } from '../../design/DesignSystem';

interface MediaCardProps {
  id: string;
  title: string;
  description: string;
  thumbnail?: string;
  duration?: number;
  source: string;
  category: string;
  isFocused?: boolean;
  onClick?: (id: string) => void;
}

@Component
class MediaCard {
  @Property id: string = '';
  @Property title: string = '';
  @Property description: string = '';
  @Property thumbnail?: string;
  @Property duration?: number;
  @Property source: string = '';
  @Property category: string = '';
  @Property isFocused: boolean = false;
  @Event onClick: (id: string) => void = () => {};

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
      <div
        style={{
          backgroundColor: designSystem.colors.surface,
          borderRadius: designSystem.borderRadius.large,
          padding: designSystem.spacing.md,
          border: `1px solid ${this.isFocused ? designSystem.colors.primary : designSystem.colors.border}`,
          aspectRatio: '3/4',
          display: 'flex',
          flexDirection: 'column',
          cursor: 'pointer',
          transition: 'transform 0.2s, box-shadow 0.2s, border-color 0.2s',
          transform: this.isFocused ? 'scale(1.05)' : 'scale(1)',
          boxShadow: this.isFocused ? designSystem.shadow.large : 'none'
        }}
        onClick={() => this.onClick(this.id)}
      >
        <div style={{
          flex: 1,
          backgroundColor: designSystem.colors.border,
          borderRadius: designSystem.borderRadius.medium,
          marginBottom: designSystem.spacing.sm,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          position: 'relative',
          overflow: 'hidden'
        }}>
          {this.thumbnail ? (
            <image
              src={this.thumbnail}
              style={{
                width: '100%',
                height: '100%',
                borderRadius: designSystem.borderRadius.medium,
                transition: 'transform 0.3s'
              }}
            />
          ) : (
            <text style={{
              color: designSystem.colors.textSecondary,
              fontSize: designSystem.typography.fontSize.small
            }}>封面</text>
          )}
          {this.duration && (
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
              }}>{this.formatDuration(this.duration)}</text>
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
        }}>{this.title}</text>
        <text style={{
          color: designSystem.colors.textSecondary,
          fontSize: designSystem.typography.fontSize.small,
          flex: 1,
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          display: '-webkit-box',
          WebkitLineClamp: 2,
          WebkitBoxOrient: 'vertical'
        }}>{this.description}</text>
        <div style={{
          marginTop: designSystem.spacing.xs,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <text style={{
            color: designSystem.colors.primary,
            fontSize: designSystem.typography.fontSize.small
          }}>{this.source}</text>
          <text style={{
            color: designSystem.colors.textSecondary,
            fontSize: designSystem.typography.fontSize.small
          }}>{this.category}</text>
        </div>
      </div>
    );
  }
}

export default MediaCard;