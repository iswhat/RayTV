/**
 * TV遥控器交互管理器
 * 负责处理遥控器按键事件、焦点管理和导航逻辑
 */
import { Component, State, Prop } from '@ohos/arkui'

export interface RemoteControlConfig {
  enableFocusManagement: boolean
  enableVoiceControl: boolean
  enableGestureNavigation: boolean
  focusAnimationDuration: number
  scrollStep: number
  longPressThreshold: number
}

export interface FocusableItem {
  id: string
  element: any
  rect: Rect
  focusable: boolean
  visible: boolean
}

export interface Rect {
  x: number
  y: number
  width: number
  height: number
}

export class RemoteControlManager {
  private static instance: RemoteControlManager
  private config: RemoteControlConfig
  private focusableItems: Map<string, FocusableItem> = new Map()
  private currentFocusId: string = ''
  private listeners: Map<string, Function[]> = new Map()
  
  private constructor() {
    this.config = {
      enableFocusManagement: true,
      enableVoiceControl: true,
      enableGestureNavigation: true,
      focusAnimationDuration: 200,
      scrollStep: 50,
      longPressThreshold: 1000
    }
  }
  
  public static getInstance(): RemoteControlManager {
    if (!RemoteControlManager.instance) {
      RemoteControlManager.instance = new RemoteControlManager()
    }
    return RemoteControlManager.instance
  }
  
  /**
   * 注册可聚焦元素
   */
  public registerFocusableItem(item: FocusableItem): void {
    this.focusableItems.set(item.id, item)
    if (!this.currentFocusId) {
      this.currentFocusId = item.id
      this.notifyFocusChange(item.id)
    }
  }
  
  /**
   * 注销可聚焦元素
   */
  public unregisterFocusableItem(id: string): void {
    this.focusableItems.delete(id)
    if (this.currentFocusId === id) {
      this.findNextFocusable()
    }
  }
  
  /**
   * 处理方向键事件
   */
  public handleDirectionKey(direction: 'up' | 'down' | 'left' | 'right'): boolean {
    if (!this.config.enableFocusManagement) return false
    
    const currentItem = this.focusableItems.get(this.currentFocusId)
    if (!currentItem) return false
    
    const nextItem = this.findNextItem(currentItem, direction)
    if (nextItem && nextItem.id !== this.currentFocusId) {
      this.setFocus(nextItem.id)
      return true
    }
    
    return false
  }
  
  /**
   * 处理确认键事件
   */
  public handleEnterKey(): boolean {
    const currentItem = this.focusableItems.get(this.currentFocusId)
    if (currentItem) {
      this.notifyItemClick(currentItem.id)
      return true
    }
    return false
  }
  
  /**
   * 处理返回键事件
   */
  public handleBackKey(): boolean {
    this.notifyBackAction()
    return true
  }
  
  /**
   * 设置焦点到指定元素
   */
  public setFocus(id: string): void {
    if (this.focusableItems.has(id)) {
      this.currentFocusId = id
      this.notifyFocusChange(id)
    }
  }
  
  /**
   * 获取当前焦点元素ID
   */
  public getCurrentFocusId(): string {
    return this.currentFocusId
  }
  
  /**
   * 查找下一个可聚焦元素
   */
  private findNextItem(currentItem: FocusableItem, direction: string): FocusableItem | null {
    const items = Array.from(this.focusableItems.values())
      .filter(item => item.focusable && item.visible && item.id !== currentItem.id)
    
    if (items.length === 0) return null
    
    // 简单的距离计算算法
    let bestItem: FocusableItem | null = null
    let minDistance = Infinity
    
    items.forEach(item => {
      const distance = this.calculateDistance(currentItem.rect, item.rect, direction)
      if (distance < minDistance) {
        minDistance = distance
        bestItem = item
      }
    })
    
    return bestItem
  }
  
  /**
   * 计算两个矩形在指定方向上的距离
   */
  private calculateDistance(rect1: Rect, rect2: Rect, direction: string): number {
    switch (direction) {
      case 'up':
        return Math.abs(rect1.y - (rect2.y + rect2.height))
      case 'down':
        return Math.abs((rect1.y + rect1.height) - rect2.y)
      case 'left':
        return Math.abs(rect1.x - (rect2.x + rect2.width))
      case 'right':
        return Math.abs((rect1.x + rect1.width) - rect2.x)
      default:
        return Infinity
    }
  }
  
  /**
   * 查找下一个可用的焦点元素
   */
  private findNextFocusable(): void {
    const items = Array.from(this.focusableItems.values())
      .filter(item => item.focusable && item.visible)
    
    if (items.length > 0) {
      this.currentFocusId = items[0].id
      this.notifyFocusChange(this.currentFocusId)
    } else {
      this.currentFocusId = ''
    }
  }
  
  /**
   * 通知焦点变化
   */
  private notifyFocusChange(id: string): void {
    const listeners = this.listeners.get('focusChange') || []
    listeners.forEach(listener => listener(id))
  }
  
  /**
   * 通知项目点击
   */
  private notifyItemClick(id: string): void {
    const listeners = this.listeners.get('itemClick') || []
    listeners.forEach(listener => listener(id))
  }
  
  /**
   * 通知返回操作
   */
  private notifyBackAction(): void {
    const listeners = this.listeners.get('backAction') || []
    listeners.forEach(listener => listener())
  }
  
  /**
   * 添加事件监听器
   */
  public addEventListener(event: string, listener: Function): void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, [])
    }
    this.listeners.get(event)!.push(listener)
  }
  
  /**
   * 移除事件监听器
   */
  public removeEventListener(event: string, listener: Function): void {
    const listeners = this.listeners.get(event) || []
    const index = listeners.indexOf(listener)
    if (index > -1) {
      listeners.splice(index, 1)
    }
  }
  
  /**
   * 更新配置
   */
  public updateConfig(config: Partial<RemoteControlConfig>): void {
    this.config = { ...this.config, ...config }
  }
  
  /**
   * 获取当前配置
   */
  public getConfig(): RemoteControlConfig {
    return { ...this.config }
  }
}