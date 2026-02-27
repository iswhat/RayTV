import { Component, State, Property, EventEmitter } from '@ohos/harmonyos';
import { designSystem } from '../design/DesignSystem';
import { responsiveSystem } from '../common/layout/ResponsiveSystem';
import { appState } from '../common/state/AppState';

@Component
class MainPageOptimized {
  @State currentBreakpoint: string = responsiveSystem.getCurrentBreakpoint();
  @State categories: string[] = [];
  @State selectedCategory: string | null = null;
  @State isLoading: boolean = false;
  @State error: string | null = null;

  private subscription: () => void = () => {};

  aboutToAppear() {
    this.subscription = responsiveSystem.onBreakpointChange((breakpoint) => {
      this.currentBreakpoint = breakpoint;
    });
    this.loadCategories();
  }

  aboutToDisappear() {
    this.subscription();
  }

  async loadCategories() {
    this.isLoading = true;
    try {
      // 模拟加载分类数据
      await new Promise(resolve => setTimeout(resolve, 1000));
      this.categories = ['电影', '电视剧', '综艺', '动漫', '体育'];
    } catch (error) {
      this.error = error instanceof Error ? error.message : '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  selectCategory(category: string) {
    this.selectedCategory = category === this.selectedCategory ? null : category;
    appState.updateContent({ selectedCategory: this.selectedCategory });
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

  build() {
    return (
      <div style={{
        width: '100%',
        height: '100%',
        backgroundColor: designSystem.colors.background,
        padding: designSystem.spacing.md
      }}>
        {/* 顶部导航栏 */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: designSystem.spacing.lg,
          paddingBottom: designSystem.spacing.md,
          borderBottom: `1px solid ${designSystem.colors.border}`
        }}>
          <text style={{
            fontSize: designSystem.typography.fontSize.xxlarge,
            fontWeight: designSystem.typography.fontWeight.bold,
            color: designSystem.colors.primary
          }}>RayTV</text>
          <div style={{
            display: 'flex',
            gap: designSystem.spacing.md
          }}>
            <button style={{
              padding: `${designSystem.spacing.sm} ${designSystem.spacing.md}`,
              backgroundColor: designSystem.colors.surface,
              borderRadius: designSystem.borderRadius.medium,
              border: `1px solid ${designSystem.colors.border}`
            }}>
              <text style={{
                color: designSystem.colors.text,
                fontSize: designSystem.typography.fontSize.medium
              }}>搜索</text>
            </button>
            <button style={{
              padding: `${designSystem.spacing.sm} ${designSystem.spacing.md}`,
              backgroundColor: designSystem.colors.surface,
              borderRadius: designSystem.borderRadius.medium,
              border: `1px solid ${designSystem.colors.border}`
            }}>
              <text style={{
                color: designSystem.colors.text,
                fontSize: designSystem.typography.fontSize.medium
              }}>设置</text>
            </button>
          </div>
        </div>

        {/* 分类导航 */}
        <div style={{
          marginBottom: designSystem.spacing.lg,
          overflowX: 'auto',
          paddingBottom: designSystem.spacing.sm
        }}>
          <div style={{
            display: 'flex',
            gap: designSystem.spacing.md,
            minWidth: 'max-content'
          }}>
            {this.categories.map((category) => (
              <button
                key={category}
                style={{
                  padding: `${designSystem.spacing.sm} ${designSystem.spacing.lg}`,
                  backgroundColor: this.selectedCategory === category 
                    ? designSystem.colors.primary 
                    : designSystem.colors.surface,
                  borderRadius: designSystem.borderRadius.medium,
                  border: `1px solid ${designSystem.colors.border}`
                }}
                onClick={() => this.selectCategory(category)}
              >
                <text style={{
                  color: this.selectedCategory === category 
                    ? designSystem.colors.text 
                    : designSystem.colors.textSecondary,
                  fontSize: designSystem.typography.fontSize.medium,
                  fontWeight: this.selectedCategory === category 
                    ? designSystem.typography.fontWeight.medium 
                    : designSystem.typography.fontWeight.regular
                }}>{category}</text>
              </button>
            ))}
          </div>
        </div>

        {/* 内容区域 */}
        {this.isLoading ? (
          <div style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: '60vh'
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
            height: '60vh'
          }}>
            <text style={{
              color: designSystem.colors.error,
              fontSize: designSystem.typography.fontSize.large
            }}>{this.error}</text>
          </div>
        ) : (
          <div style={{
            display: 'grid',
            gridTemplateColumns: `repeat(${this.getGridColumns()}, 1fr)`,
            gap: designSystem.spacing.md
          }}>
            {/* 内容卡片将在这里渲染 */}
            {Array.from({ length: 12 }).map((_, index) => (
              <div key={index} style={{
                backgroundColor: designSystem.colors.surface,
                borderRadius: designSystem.borderRadius.large,
                padding: designSystem.spacing.md,
                border: `1px solid ${designSystem.colors.border}`,
                aspectRatio: '3/4',
                display: 'flex',
                flexDirection: 'column'
              }}>
                <div style={{
                  flex: 1,
                  backgroundColor: designSystem.colors.border,
                  borderRadius: designSystem.borderRadius.medium,
                  marginBottom: designSystem.spacing.sm,
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center'
                }}>
                  <text style={{
                    color: designSystem.colors.textSecondary,
                    fontSize: designSystem.typography.fontSize.small
                  }}>封面</text>
                </div>
                <text style={{
                  color: designSystem.colors.text,
                  fontSize: designSystem.typography.fontSize.medium,
                  fontWeight: designSystem.typography.fontWeight.medium,
                  marginBottom: designSystem.spacing.xs
                }}>示例内容 {index + 1}</text>
                <text style={{
                  color: designSystem.colors.textSecondary,
                  fontSize: designSystem.typography.fontSize.small,
                  flex: 1
                }}>这是一个示例内容描述</text>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }
}

export default MainPageOptimized;