// 手势服务 | Gesture service
// 基于HarmonyOS @ohos.multimodalInput.gesture API实现手势识别功能 | Based on HarmonyOS @ohos.multimodalInput.gesture API to implement gesture recognition functionality

import Logger from '../../common/util/Logger';
import gesture from '@ohos.multimodalInput.gesture';
import input from '@ohos.multimodalInput.input';
import BusinessError from '@ohos.base';

/**
 * 手势原始事件接口 | Gesture raw event interface
 */
export interface GestureRawEvent {
  type: string;
  x?: number;
  y?: number;
  timestamp?: number;
  pointers?: Object;
  deviceId?: number;
  button?: number;
  direction?: string;
  distance?: number;
  velocity?: number;
  scale?: number;
  rotation?: number;
}

/**
 * 手势类型枚举 | Gesture type enumeration
 */
export enum GestureType {
  TAP = 'tap',
  DOUBLE_TAP = 'doubleTap',
  LONG_PRESS = 'longPress',
  SWIPE = 'swipe',
  PINCH = 'pinch',
  ROTATE = 'rotate',
  PAN = 'pan'
}

/**
 * 方向枚举 | Direction enumeration
 */
export enum Direction {
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right'
}

/**
 * 手势事件接口 | Gesture event interface
 */
export interface GestureEvent {
  type: GestureType;
  x: number;
  y: number;
  timestamp: number;
  direction?: Direction;
  distance?: number;
  velocity?: number;
  scale?: number;
  rotation?: number;
  duration?: number;
  deltaX?: number;
  deltaY?: number;
}

/**
 * 手势配置接口 | Gesture config interface
 */
export interface GestureConfig {
  enableTap?: boolean;
  enableDoubleTap?: boolean;
  enableLongPress?: boolean;
  enableSwipe?: boolean;
  enablePinch?: boolean;
  enableRotate?: boolean;
  enablePan?: boolean;
  swipeThreshold?: number; // 滑动阈值 | Swipe threshold
  longPressDuration?: number; // 长按持续时间 | Long press duration
}

/**
 * 手势服务接口 | Gesture service interface
 */
export interface GestureService {
  // 初始化手势识别 | Initialize gesture recognition
  init(config?: GestureConfig): Promise<void>;
  
  // 设置手势监听 | Set gesture listening
  onGesture(callback: (event: GestureEvent) => void): void;
  
  // 设置指定类型手势监听 | Set specific type gesture listening
  on(type: GestureType, callback: (event: GestureEvent) => void): void;
  
  // 取消指定类型手势监听 | Cancel specific type gesture listening
  off(type: GestureType): void;
  
  // 取消所有手势监听 | Cancel all gesture listening
  offAll(): void;
  
  // 销毁手势服务 | Destroy gesture service
  destroy(): void;
}

/**
 * 手势服务实现类 | Gesture service implementation class
 * 基于HarmonyOS @ohos.multimodalInput.gesture API实现手势识别功能 | Based on HarmonyOS @ohos.multimodalInput.gesture API to implement gesture recognition functionality
 */
export class GestureServiceImpl implements GestureService {
  private readonly TAG: string = 'GestureServiceImpl';
  private isInitialized: boolean = false;
  private gestureManager: gesture.GestureManager | null = null;
  private config: GestureConfig = {};
  private globalCallback?: (event: GestureEvent) => void;
  private gestureCallbacks: Map<GestureType, (event: GestureEvent) => void> = new Map();
  private subscription: number = -1;
  
  /**
   * 初始化手势识别 | Initialize gesture recognition
   */
  async init(config?: GestureConfig): Promise<void> {
    try {
      if (this.isInitialized) {
        Logger.warn(this.TAG, 'Gesture service already initialized');
        return;
      }
      
      // 合并配置 | Merge configuration
      this.config = {
        enableTap: true,
        enableDoubleTap: true,
        enableLongPress: true,
        enableSwipe: true,
        enablePinch: true,
        enableRotate: true,
        enablePan: true,
        swipeThreshold: 50,
        longPressDuration: 500,
        ...config
      };
      
      // 创建手势管理器 | Create gesture manager
      this.gestureManager = await gesture.createGestureManager();
      
      // 订阅手势事件 | Subscribe to gesture events
      this.subscribeToGestureEvents();
      
      this.isInitialized = true;
      Logger.info(this.TAG, 'Gesture service initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize gesture service: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置全局手势监听 | Set global gesture listening
   */
  onGesture(callback: (event: GestureEvent) => void): void {
    this.globalCallback = callback;
    Logger.info(this.TAG, 'Global gesture callback set');
  }
  
  /**
   * 设置指定类型手势监听 | Set specific type gesture listening
   */
  on(type: GestureType, callback: (event: GestureEvent) => void): void {
    this.gestureCallbacks.set(type, callback);
    Logger.info(this.TAG, `Gesture callback set for type: ${type}`);
  }
  
  /**
   * 取消指定类型手势监听 | Cancel specific type gesture listening
   */
  off(type: GestureType): void {
    this.gestureCallbacks.delete(type);
    Logger.info(this.TAG, `Gesture callback removed for type: ${type}`);
  }
  
  /**
   * 取消所有手势监听 | Cancel all gesture listening
   */
  offAll(): void {
    this.globalCallback = undefined;
    this.gestureCallbacks.clear();
    Logger.info(this.TAG, 'All gesture callbacks removed');
  }
  
  /**
   * 销毁手势服务 | Destroy gesture service
   */
  destroy(): void {
    try {
      if (this.subscription >= 0) {
        input.off(this.subscription);
        this.subscription = -1;
      }
      
      this.globalCallback = undefined;
      this.gestureCallbacks.clear();
      this.isInitialized = false;
      
      Logger.info(this.TAG, 'Gesture service destroyed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to destroy gesture service: ${error}`);
    }
  }
  
  /**
   * 订阅手势事件 | Subscribe to gesture events
   */
  subscribeToGestureEvents(): void {
    try {
      this.subscription = input.on('multimodalGesture', (event) => {
        this.handleGestureEvent(event);
      });
      
      Logger.info(this.TAG, 'Gesture events subscribed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to subscribe to gesture events: ${error}`);
    }
  }
  
  /**
   * 处理手势事件 | Handle gesture event
   */
  handleGestureEvent(event: GestureRawEvent): void {
    try {
      // 构建标准化的手势事件 | Build standardized gesture event
      const gestureEvent: GestureEvent | null = this.buildGestureEvent(event);
      if (!gestureEvent) return;
      
      // 触发全局回调 | Trigger global callback
      if (this.globalCallback) {
        this.globalCallback(gestureEvent);
      }
      
      // 触发指定类型回调 | Trigger specific type callback
      const specificCallback = this.gestureCallbacks.get(gestureEvent.type);
      if (specificCallback) {
        specificCallback(gestureEvent);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle gesture event: ${error}`);
    }
  }
  
  /**
   * 构建标准化的手势事件 | Build standardized gesture event
   */
  buildGestureEvent(event: GestureRawEvent): GestureEvent | null {
    try {
      // 根据事件类型转换为标准手势事件 | Convert to standard gesture event based on event type
      switch (event.type) {
        case 'tap':
          if (!this.config.enableTap) return null;
          return {
            type: GestureType.TAP,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now()
          };
          
        case 'doubleTap':
          if (!this.config.enableDoubleTap) return null;
          return {
            type: GestureType.DOUBLE_TAP,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now()
          };
          
        case 'longPress':
          if (!this.config.enableLongPress) return null;
          return {
            type: GestureType.LONG_PRESS,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now()
          };
          
        case 'swipe':
          if (!this.config.enableSwipe) return null;
          // 检查滑动距离是否超过阈值 | Check if swipe distance exceeds threshold
          if (Math.abs(event.distance || 0) < (this.config.swipeThreshold || 50)) return null;
          
          let direction: Direction = Direction.UP;
          const deltaX = (event as any).deltaX || 0;
          const deltaY = (event as any).deltaY || 0;
          
          if (Math.abs(deltaX) > Math.abs(deltaY)) {
            direction = deltaX > 0 ? Direction.RIGHT : Direction.LEFT;
          } else {
            direction = deltaY > 0 ? Direction.DOWN : Direction.UP;
          }
          
          return {
            type: GestureType.SWIPE,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now(),
            direction: direction,
            distance: event.distance,
            velocity: event.velocity,
            deltaX: deltaX,
            deltaY: deltaY
          };
          
        case 'pinch':
          if (!this.config.enablePinch) return null;
          return {
            type: GestureType.PINCH,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now(),
            scale: event.scale || 1
          };
          
        case 'rotate':
          if (!this.config.enableRotate) return null;
          return {
            type: GestureType.ROTATE,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now(),
            rotation: event.rotation
          };
          
        case 'pan':
          if (!this.config.enablePan) return null;
          const panDeltaX = (event as any).deltaX || 0;
          const panDeltaY = (event as any).deltaY || 0;
          return {
            type: GestureType.PAN,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || Date.now(),
            distance: Math.sqrt(panDeltaX * panDeltaX + panDeltaY * panDeltaY),
            deltaX: panDeltaX,
            deltaY: panDeltaY
          };
          
        default:
          return null;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to build gesture event: ${error}`);
      return null;
    }
  }
}

/**
 * 手势服务单例 | Gesture service singleton
 */
export const GestureServiceInstance: GestureService = new GestureServiceImpl();
