/**
 * ResponsiveLayoutSystem.ets
 * 响应式布局系统 - 实现断点管理、网格布局和自适应设计
 */

import { Component, State, Prop, Builder, AboutToAppear } from '@ohos/arkui'
import Logger from '../util/Logger'

// ==================== 类型定义 ====================

export type Breakpoint = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl'
export type GridColumns = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12
export type ContainerType = 'fixed' | 'fluid' | 'boxed'

export interface BreakpointConfig {
  minWidth: number
  maxWidth?: number
  columns: GridColumns
  gutter: number
  margin: number
}

export interface ResponsiveContainerProps {
  type?: ContainerType
  maxWidth?: number
  fluidBreakpoint?: Breakpoint
  className?: string
  customStyle?: Record<string, any>
}

export interface ResponsiveGridProps {
  columns?: GridColumns | Partial<Record<Breakpoint, GridColumns>>
  gap?: number | Partial<Record<Breakpoint, number>>
  responsive?: boolean
  className?: string
  customStyle?: Record<string, any>
}

export interface ResponsiveItemProps {
  span?: number | Partial<Record<Breakpoint, number>>
  offset?: number | Partial<Record<Breakpoint, number>>
  order?: number | Partial<Record<Breakpoint, number>>
  className?: string
  customStyle?: Record<string, any>
}

// ==================== 断点配置 ====================

const BREAKPOINT_CONFIGS: Record<Breakpoint, BreakpointConfig> = {
  xs: { minWidth: 0, maxWidth: 575, columns: 4, gutter: 8, margin: 16 },
  sm: { minWidth: 576, maxWidth: 767, columns: 8, gutter: 12, margin: 20 },
  md: { minWidth: 768, maxWidth: 991, columns: 12, gutter: 16, margin: 24 },
  lg: { minWidth: 992, maxWidth: 1199, columns: 12, gutter: 20, margin: 32 },
  xl: { minWidth: 1200, maxWidth: 1599, columns: 12, gutter: 24, margin: 40 },
  xxl: { minWidth: 1600, columns: 12, gutter: 32, margin: 48 }
}

const CONTAINER_MAX_WIDTHS: Record<Breakpoint, number> = {
  xs: 540,
  sm: 720,
  md: 960,
  lg: 1140,
  xl: 1320,
  xxl: 1540
}

// ==================== 响应式布局系统 ====================

export class ResponsiveLayoutSystem {
  private static instance: ResponsiveLayoutSystem
  private logger: Logger
  private currentBreakpoint: Breakpoint = 'md'
  private screenWidth: number = 1024
  private listeners: Array<(breakpoint: Breakpoint) => void> = []
  
  private constructor() {
    this.logger = new Logger('ResponsiveLayoutSystem')
    this.detectBreakpoint()
  }
  
  public static getInstance(): ResponsiveLayoutSystem {
    if (!ResponsiveLayoutSystem.instance) {
      ResponsiveLayoutSystem.instance = new ResponsiveLayoutSystem()
    }
    return ResponsiveLayoutSystem.instance
  }
  
  /**
   * 检测当前断点
   */
  private detectBreakpoint(): void {
    const breakpoints = Object.entries(BREAKPOINT_CONFIGS) as [Breakpoint, BreakpointConfig][]
    
    for (const [breakpoint, config] of breakpoints) {
      if (this.screenWidth >= config.minWidth) {
        if (!config.maxWidth || this.screenWidth <= config.maxWidth) {
          this.currentBreakpoint = breakpoint
          break
        }
      }
    }
    
    this.logger.info(`Detected breakpoint: ${this.currentBreakpoint} (${this.screenWidth}px)`)
  }
  
  /**
   * 更新屏幕宽度
   */
  public updateScreenWidth(width: number): void {
    const oldBreakpoint = this.currentBreakpoint
    this.screenWidth = width
    this.detectBreakpoint()
    
    if (this.currentBreakpoint !== oldBreakpoint) {
      this.notifyListeners()
    }
  }
  
  /**
   * 获取当前断点
   */
  public getCurrentBreakpoint(): Breakpoint {
    return this.currentBreakpoint
  }
  
  /**
   * 获取断点配置
   */
  public getBreakpointConfig(breakpoint?: Breakpoint): BreakpointConfig {
    return BREAKPOINT_CONFIGS[breakpoint || this.currentBreakpoint]
  }
  
  /**
   * 获取容器最大宽度
   */
  public getContainerMaxWidth(breakpoint?: Breakpoint): number {
    return CONTAINER_MAX_WIDTHS[breakpoint || this.currentBreakpoint]
  }
  
  /**
   * 计算列宽
   */
  public getColumnWidth(columns?: GridColumns, breakpoint?: Breakpoint): number {
    const config = this.getBreakpointConfig(breakpoint)
    const totalColumns = columns || config.columns
    const availableWidth = this.screenWidth - (config.margin * 2)
    const totalGutterWidth = config.gutter * (totalColumns - 1)
    const columnWidth = (availableWidth - totalGutterWidth) / totalColumns
    
    return Math.max(0, columnWidth)
  }
  
  /**
   * 添加断点变化监听器
   */
  public addBreakpointListener(listener: (breakpoint: Breakpoint) => void): void {
    this.listeners.push(listener)
  }
  
  /**
   * 移除断点变化监听器
   */
  public removeBreakpointListener(listener: (breakpoint: Breakpoint) => void): void {
    const index = this.listeners.indexOf(listener)
    if (index > -1) {
      this.listeners.splice(index, 1)
    }
  }
  
  /**
   * 通知监听器
   */
  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      try {
        listener(this.currentBreakpoint)
      } catch (error) {
        this.logger.error('Error in breakpoint listener:', error)
      }
    })
  }
  
  /**
   * 判断是否为移动设备
   */
  public isMobile(): boolean {
    return ['xs', 'sm'].includes(this.currentBreakpoint)
  }
  
  /**
   * 判断是否为平板设备
   */
  public isTablet(): boolean {
    return this.currentBreakpoint === 'md'
  }
  
  /**
   * 判断是否为桌面设备
   */
  public isDesktop(): boolean {
    return ['lg', 'xl', 'xxl'].includes(this.currentBreakpoint)
  }
  
  /**
   * 判断是否为TV设备
   */
  public isTV(): boolean {
    return ['xl', 'xxl'].includes(this.currentBreakpoint)
  }
}

// ==================== 响应式容器组件 ====================

@Component
export struct ResponsiveContainer {
  @Prop type: ContainerType = 'fixed'
  @Prop maxWidth: number = 0
  @Prop fluidBreakpoint: Breakpoint = 'lg'
  @Prop className: string = ''
  @Prop customStyle: Record<string, any> = {}
  
  @State currentBreakpoint: Breakpoint = 'md'
  private layoutSystem: ResponsiveLayoutSystem = ResponsiveLayoutSystem.getInstance()
  
  @AboutToAppear
  aboutToAppear(): void {
    this.currentBreakpoint = this.layoutSystem.getCurrentBreakpoint()
    this.layoutSystem.addBreakpointListener(this.handleBreakpointChange)
  }
  
  private handleBreakpointChange = (breakpoint: Breakpoint): void => {
    this.currentBreakpoint = breakpoint
  }
  
  private getContainerWidth(): string | number {
    if (this.type === 'fluid') {
      return '100%'
    }
    
    if (this.type === 'boxed') {
      return this.maxWidth || this.layoutSystem.getContainerMaxWidth()
    }
    
    // fixed类型 - 在大屏幕上居中
    const isFluid = this.currentBreakpoint >= this.fluidBreakpoint
    if (isFluid) {
      return '100%'
    }
    
    return this.maxWidth || this.layoutSystem.getContainerMaxWidth()
  }
  
  private getPadding(): string | number {
    const config = this.layoutSystem.getBreakpointConfig()
    return config.margin
  }
  
  build() {
    Column() {
      // 子内容将在这里渲染
      if (this.$$.children.length > 0) {
        this.renderChildren()
      }
    }
    .width(this.getContainerWidth())
    .padding({ 
      left: this.getPadding(), 
      right: this.getPadding() 
    })
    .attrs(this.customStyle)
  }
  
  @Builder
  private renderChildren(): void {
    // 渲染传入的子组件
  }
}

// ==================== 响应式网格组件 ====================

@Component
export struct ResponsiveGrid {
  @Prop columns: GridColumns | Partial<Record<Breakpoint, GridColumns>> = 12
  @Prop gap: number | Partial<Record<Breakpoint, number>> = 16
  @Prop responsive: boolean = true
  @Prop className: string = ''
  @Prop customStyle: Record<string, any> = {}
  
  @State currentBreakpoint: Breakpoint = 'md'
  private layoutSystem: ResponsiveLayoutSystem = ResponsiveLayoutSystem.getInstance()
  
  @AboutToAppear
  aboutToAppear(): void {
    this.currentBreakpoint = this.layoutSystem.getCurrentBreakpoint()
    this.layoutSystem.addBreakpointListener(this.handleBreakpointChange)
  }
  
  private handleBreakpointChange = (breakpoint: Breakpoint): void => {
    this.currentBreakpoint = breakpoint
  }
  
  private getActualColumns(): GridColumns {
    if (typeof this.columns === 'number') {
      return this.columns
    }
    
    if (this.responsive) {
      return this.columns[this.currentBreakpoint] || 
             this.columns.md || 
             this.layoutSystem.getBreakpointConfig().columns
    }
    
    return this.layoutSystem.getBreakpointConfig().columns
  }
  
  private getActualGap(): number {
    if (typeof this.gap === 'number') {
      return this.gap
    }
    
    if (this.responsive) {
      return this.gap[this.currentBreakpoint] || 
             this.gap.md || 
             this.layoutSystem.getBreakpointConfig().gutter
    }
    
    return this.layoutSystem.getBreakpointConfig().gutter
  }
  
  build() {
    Grid() {
      // 子项将在这里渲染
      if (this.$$.children.length > 0) {
        this.renderChildren()
      }
    }
    .columnsTemplate(`repeat(${this.getActualColumns()}, 1fr)`)
    .columnsGap(this.getActualGap())
    .rowsGap(this.getActualGap())
    .attrs(this.customStyle)
  }
  
  @Builder
  private renderChildren(): void {
    // 渲染网格项
  }
}

// ==================== 响应式网格项组件 ====================

@Component
export struct ResponsiveGridItem {
  @Prop span: number | Partial<Record<Breakpoint, number>> = 1
  @Prop offset: number | Partial<Record<Breakpoint, number>> = 0
  @Prop order: number | Partial<Record<Breakpoint, number>> = 0
  @Prop className: string = ''
  @Prop customStyle: Record<string, any> = {}
  
  @State currentBreakpoint: Breakpoint = 'md'
  private layoutSystem: ResponsiveLayoutSystem = ResponsiveLayoutSystem.getInstance()
  
  @AboutToAppear
  aboutToAppear(): void {
    this.currentBreakpoint = this.layoutSystem.getCurrentBreakpoint()
    this.layoutSystem.addBreakpointListener(this.handleBreakpointChange)
  }
  
  private handleBreakpointChange = (breakpoint: Breakpoint): void => {
    this.currentBreakpoint = breakpoint
  }
  
  private getActualSpan(): number {
    if (typeof this.span === 'number') {
      return this.span
    }
    return this.span[this.currentBreakpoint] || this.span.md || 1
  }
  
  private getActualOffset(): number {
    if (typeof this.offset === 'number') {
      return this.offset
    }
    return this.offset[this.currentBreakpoint] || this.offset.md || 0
  }
  
  private getActualOrder(): number {
    if (typeof this.order === 'number') {
      return this.order
    }
    return this.order[this.currentBreakpoint] || this.order.md || 0
  }
  
  build() {
    GridItem() {
      // 子内容将在这里渲染
      if (this.$$.children.length > 0) {
        this.renderChildren()
      }
    }
    .gridColumnStart(this.getActualOffset() + 1)
    .gridColumnEnd(`span ${this.getActualSpan()}`)
    .gridRowOrder(this.getActualOrder())
    .attrs(this.customStyle)
  }
  
  @Builder
  private renderChildren(): void {
    // 渲染子组件
  }
}

// ==================== 便捷工厂方法 ====================

export const createResponsiveContainer = (props: ResponsiveContainerProps): ResponsiveContainer => {
  return new ResponsiveContainer(props)
}

export const createResponsiveGrid = (props: ResponsiveGridProps): ResponsiveGrid => {
  return new ResponsiveGrid(props)
}

export const createResponsiveGridItem = (props: ResponsiveItemProps): ResponsiveGridItem => {
  return new ResponsiveGridItem(props)
}

// ==================== 导出类型 ====================

export type { 
  Breakpoint, 
  GridColumns, 
  ContainerType,
  BreakpointConfig,
  ResponsiveContainerProps,
  ResponsiveGridProps,
  ResponsiveItemProps
}