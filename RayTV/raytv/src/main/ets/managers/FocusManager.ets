/**
 * 焦点管理器
 * 统一管理应用内的焦点状态和导航
 */

// 焦点动画配置接口
export interface FocusAnimationConfig {
  duration: number;
  curve: string;
  scale: number;
  opacity: number;
  borderColor: string;
  borderWidth: number;
  shadowColor: string;
  shadowRadius: number;
}

// 焦点元素位置接口
export interface FocusElementPosition {
  x: number;
  y: number;
  width: number;
  height: number;
}

// 焦点状态回调类型
type FocusChangeCallback = (oldElement: string | null, newElement: string | null) => void;

// 焦点方向枚举
export enum FocusDirection {
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right'
}

// 焦点组配置接口
export interface FocusGroupConfig {
  priority: number;
  navigationOrder: 'horizontal' | 'vertical' | 'custom';
  wrapAround: boolean;
}

export class FocusManager {
  private static instance: FocusManager;
  private focusedElement: string | null = null;
  private focusGroups: Map<string, { elements: string[]; config: FocusGroupConfig }> = new Map();
  private focusHistory: string[] = [];
  private maxHistorySize: number = 10;
  private elementPositions: Map<string, FocusElementPosition> = new Map();
  private focusCallbacks: FocusChangeCallback[] = [];
  private defaultAnimationConfig: FocusAnimationConfig = {
    duration: 200,
    curve: 'ease-in-out',
    scale: 1.05,
    opacity: 1,
    borderColor: '#4CAF50',
    borderWidth: 3,
    shadowColor: 'rgba(76, 175, 80, 0.5)',
    shadowRadius: 10
  };
  private elementAnimations: Map<string, FocusAnimationConfig> = new Map();

  private constructor() {}

  static getInstance(): FocusManager {
    if (!FocusManager.instance) {
      FocusManager.instance = new FocusManager();
    }
    return FocusManager.instance;
  }

  /**
   * 初始化焦点管理器
   */
  initialize(): void {
    this.focusedElement = null;
    this.focusHistory = [];
    this.elementPositions.clear();
    console.log('FocusManager initialized');
  }

  /**
   * 设置焦点元素
   */
  setFocusedElement(elementId: string): void {
    if (this.focusedElement === elementId) return;

    const oldFocus = this.focusedElement;
    this.focusedElement = elementId;

    // 更新历史记录
    this.addToHistory(elementId);

    // 触发焦点变化回调
    this.notifyFocusChange(oldFocus, elementId);

    console.log(`Focus changed from ${oldFocus} to ${elementId}`);
  }

  /**
   * 请求焦点
   */
  requestFocus(elementId: string): void {
    if (this.isValidFocusTarget(elementId)) {
      this.setFocusedElement(elementId);
    }
  }

  /**
   * 移除焦点
   */
  blur(): void {
    const oldFocus = this.focusedElement;
    this.focusedElement = null;
    this.notifyFocusChange(oldFocus, null);
  }

  /**
   * 获取当前焦点元素
   */
  getFocusedElement(): string | null {
    return this.focusedElement;
  }

  /**
   * 检查是否有焦点元素
   */
  hasFocusedElement(): boolean {
    return this.focusedElement !== null;
  }

  /**
   * 创建焦点组
   */
  createFocusGroup(groupId: string, config?: Partial<FocusGroupConfig>): void {
    const defaultConfig: FocusGroupConfig = {
      priority: 0,
      navigationOrder: 'horizontal',
      wrapAround: true
    };

    this.focusGroups.set(groupId, {
      elements: [],
      config: { ...defaultConfig, ...config }
    });
  }

  /**
   * 将元素添加到焦点组
   */
  addToFocusGroup(groupId: string, elementId: string, index?: number): void {
    if (!this.focusGroups.has(groupId)) {
      this.createFocusGroup(groupId);
    }

    const group = this.focusGroups.get(groupId);
    if (group && !group.elements.includes(elementId)) {
      if (index !== undefined && index >= 0 && index <= group.elements.length) {
        group.elements.splice(index, 0, elementId);
      } else {
        group.elements.push(elementId);
      }
    }
  }

  /**
   * 从焦点组移除元素
   */
  removeFromFocusGroup(groupId: string, elementId: string): boolean {
    const group = this.focusGroups.get(groupId);
    if (group) {
      const index = group.elements.indexOf(elementId);
      if (index !== -1) {
        group.elements.splice(index, 1);
        return true;
      }
    }
    return false;
  }

  /**
   * 获取焦点组中的下一个元素
   */
  getNextInGroup(groupId: string, currentElement?: string): string | null {
    const group = this.focusGroups.get(groupId);
    if (!group || group.elements.length === 0) return null;

    const elements = group.elements;
    if (!currentElement) {
      return elements[0];
    }

    const currentIndex = elements.indexOf(currentElement);
    if (currentIndex === -1) return elements[0];

    const nextIndex = (currentIndex + 1) % elements.length;
    return elements[nextIndex];
  }

  /**
   * 获取焦点组中的上一个元素
   */
  getPreviousInGroup(groupId: string, currentElement?: string): string | null {
    const group = this.focusGroups.get(groupId);
    if (!group || group.elements.length === 0) return null;

    const elements = group.elements;
    if (!currentElement) {
      return elements[elements.length - 1];
    }

    const currentIndex = elements.indexOf(currentElement);
    if (currentIndex === -1) return elements[elements.length - 1];

    const prevIndex = (currentIndex - 1 + elements.length) % elements.length;
    return elements[prevIndex];
  }

  /**
   * 根据方向导航焦点
   */
  navigate(direction: FocusDirection): string | null {
    if (!this.focusedElement) return null;

    // 1. 首先在当前焦点组内导航
    const currentGroup = this.findGroupContainingElement(this.focusedElement);
    if (currentGroup) {
      const nextElement = this.navigateInGroup(currentGroup, this.focusedElement, direction);
      if (nextElement) {
        this.requestFocus(nextElement);
        return nextElement;
      }
    }

    // 2. 如果组内导航失败，尝试跨组导航
    const crossGroupElement = this.navigateCrossGroup(direction);
    if (crossGroupElement) {
      this.requestFocus(crossGroupElement);
      return crossGroupElement;
    }

    return null;
  }

  /**
   * 在焦点组内导航
   */
  private navigateInGroup(groupId: string, currentElement: string, direction: FocusDirection): string | null {
    const group = this.focusGroups.get(groupId);
    if (!group || group.elements.length === 0) return null;

    const currentIndex = group.elements.indexOf(currentElement);
    if (currentIndex === -1) return null;

    let nextIndex = currentIndex;

    switch (direction) {
      case FocusDirection.LEFT:
      case FocusDirection.UP:
        nextIndex = currentIndex - 1;
        if (nextIndex < 0) {
          if (group.config.wrapAround) {
            nextIndex = group.elements.length - 1;
          } else {
            return null;
          }
        }
        break;
      case FocusDirection.RIGHT:
      case FocusDirection.DOWN:
        nextIndex = currentIndex + 1;
        if (nextIndex >= group.elements.length) {
          if (group.config.wrapAround) {
            nextIndex = 0;
          } else {
            return null;
          }
        }
        break;
    }

    return group.elements[nextIndex];
  }

  /**
   * 跨焦点组导航
   */
  private navigateCrossGroup(direction: FocusDirection): string | null {
    // 实现基于位置的跨组导航
    // 这里可以根据元素位置计算最近的焦点元素
    // 简化实现，返回第一个可用的焦点组的第一个元素
    for (const [groupId, group] of this.focusGroups.entries()) {
      if (group.elements.length > 0) {
        return group.elements[0];
      }
    }
    return null;
  }

  /**
   * 查找包含指定元素的焦点组
   */
  private findGroupContainingElement(elementId: string): string | null {
    for (const [groupId, group] of this.focusGroups.entries()) {
      if (group.elements.includes(elementId)) {
        return groupId;
      }
    }
    return null;
  }

  /**
   * 设置元素位置
   */
  setElementPosition(elementId: string, position: FocusElementPosition): void {
    this.elementPositions.set(elementId, position);
  }

  /**
   * 获取元素位置
   */
  getElementPosition(elementId: string): FocusElementPosition | undefined {
    return this.elementPositions.get(elementId);
  }

  /**
   * 设置元素焦点动画配置
   */
  setElementAnimation(elementId: string, animation: Partial<FocusAnimationConfig>): void {
    this.elementAnimations.set(elementId, {
      ...this.defaultAnimationConfig,
      ...animation
    });
  }

  /**
   * 获取元素焦点动画配置
   */
  getElementAnimation(elementId: string): FocusAnimationConfig {
    return this.elementAnimations.get(elementId) || this.defaultAnimationConfig;
  }

  /**
   * 设置默认焦点动画配置
   */
  setDefaultAnimation(animation: Partial<FocusAnimationConfig>): void {
    this.defaultAnimationConfig = {
      ...this.defaultAnimationConfig,
      ...animation
    };
  }

  /**
   * 添加焦点变化回调
   */
  addFocusChangeCallback(callback: FocusChangeCallback): void {
    if (!this.focusCallbacks.includes(callback)) {
      this.focusCallbacks.push(callback);
    }
  }

  /**
   * 移除焦点变化回调
   */
  removeFocusChangeCallback(callback: FocusChangeCallback): void {
    const index = this.focusCallbacks.indexOf(callback);
    if (index !== -1) {
      this.focusCallbacks.splice(index, 1);
    }
  }

  /**
   * 通知焦点变化
   */
  private notifyFocusChange(oldElement: string | null, newElement: string | null): void {
    for (const callback of this.focusCallbacks) {
      try {
        callback(oldElement, newElement);
      } catch (error) {
        console.error('Error in focus change callback:', error);
      }
    }
  }

  /**
   * 清空焦点组
   */
  clearFocusGroup(groupId: string): void {
    this.focusGroups.delete(groupId);
  }

  /**
   * 获取焦点历史
   */
  getFocusHistory(): string[] {
    return [...this.focusHistory];
  }

  /**
   * 返回上一个焦点
   */
  restorePreviousFocus(): string | null {
    if (this.focusHistory.length < 2) return null;

    this.focusHistory.pop(); // 移除当前焦点
    const previousFocus = this.focusHistory.pop(); // 获取上一个焦点

    if (previousFocus) {
      this.requestFocus(previousFocus);
    }

    return previousFocus;
  }

  /**
   * 清空焦点历史
   */
  clearFocusHistory(): void {
    this.focusHistory = [];
  }

  /**
   * 验证焦点元素是否存在
   */
  isValidFocusTarget(elementId: string): boolean {
    // 检查是否在任何焦点组中
    for (const group of this.focusGroups.values()) {
      if (group.elements.includes(elementId)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 获取所有焦点组
   */
  getFocusGroups(): string[] {
    return Array.from(this.focusGroups.keys());
  }

  /**
   * 获取焦点组元素
   */
  getGroupElements(groupId: string): string[] {
    const group = this.focusGroups.get(groupId);
    return group ? [...group.elements] : [];
  }

  private addToHistory(elementId: string): void {
    // 移除重复的历史记录
    const existingIndex = this.focusHistory.indexOf(elementId);
    if (existingIndex !== -1) {
      this.focusHistory.splice(existingIndex, 1);
    }

    // 添加到历史记录开头
    this.focusHistory.unshift(elementId);

    // 限制历史记录大小
    if (this.focusHistory.length > this.maxHistorySize) {
      this.focusHistory = this.focusHistory.slice(0, this.maxHistorySize);
    }
  }
}