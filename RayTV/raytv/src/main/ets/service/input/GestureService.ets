import Logger from '../../common/util/Logger';
import gesture from '@ohos.multimodalInput.gesture';
import input from '@ohos.multimodalInput.input';
import BusinessError from '@ohos.base';

/**
 * 手势原始事件接口
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
 * 手势类型枚举
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
 * 方向枚举
 */
export enum Direction {
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right'
}

/**
 * 手势事件接口
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
}

/**
 * 手势配置接口
 */
export interface GestureConfig {
  enableTap?: boolean;
  enableDoubleTap?: boolean;
  enableLongPress?: boolean;
  enableSwipe?: boolean;
  enablePinch?: boolean;
  enableRotate?: boolean;
  enablePan?: boolean;
  swipeThreshold?: number; // 滑动阈�?  longPressDuration?: number; // 长按持续时间
}

/**
 * 手势服务接口
 */
export interface GestureService {
  // 初始化手势识�?  init(config?: GestureConfig): Promise<void>;
  
  // 设置手势监听
  onGesture(callback: (event: GestureEvent) => void): void;
  
  // 设置特定类型手势监听
  on(type: GestureType, callback: (event: GestureEvent) => void): void;
  
  // 取消特定类型手势监听
  off(type: GestureType): void;
  
  // 取消所有手势监�?  offAll(): void;
  
  // 销毁手势服�?  destroy(): void;
}

/**
 * 手势服务实现�? * 基于HarmonyOS @ohos.multimodalInput.gesture API实现手势识别功能
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
   * 初始化手势识�?   */
  async init(config?: GestureConfig): Promise<void> {
    try {
      if (this.isInitialized) {
        Logger.warn(this.TAG, 'Gesture service already initialized');
        return;
      }
      
      // 合并配置
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
      
      // 创建手势管理�?      this.gestureManager = await gesture.createGestureManager();
      
      // 订阅手势事件
      this.subscribeToGestureEvents();
      
      this.isInitialized = true;
      Logger.info(this.TAG, 'Gesture service initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize gesture service: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置全局手势监听
   */
  onGesture(callback: (event: GestureEvent) => void): void {
    this.globalCallback = callback;
    Logger.info(this.TAG, 'Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set' : new Error(String('Global gesture callback set' instanceof Error ? 'Global gesture callback set' : new Error(String('Global gesture callback set')))))));
  }
  
  /**
   * 设置特定类型手势监听
   */
  on(type: GestureType, callback: (event: GestureEvent) => void): void {
    this.gestureCallbacks.set(type, callback);
    Logger.info(this.TAG, `Gesture callback set for type: ${type}`);
  }
  
  /**
   * 取消特定类型手势监听
   */
  off(type: GestureType): void {
    this.gestureCallbacks.delete(type);
    Logger.info(this.TAG, `Gesture callback removed for type: ${type}`);
  }
  
  /**
   * 取消所有手势监�?   */
  offAll(): void {
    this.globalCallback = undefined;
    this.gestureCallbacks.clear();
    Logger.info(this.TAG, 'All gesture callbacks removed');
  }
  
  /**
   * 销毁手势服�?   */
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
   * 订阅手势事件
   */
  subscribeToGestureEvents(): void {
    try {
      this.subscription = input.on('multimodalGesture', (event instanceof Error ? (event : new Error(String((event instanceof Error ? (event instanceof Error ? (event : new Error(String((event : new Error(String((event instanceof Error ? (event : new Error(String((event instanceof Error ? (event instanceof Error ? (event : new Error(String((event instanceof Error ? (event instanceof Error ? (event : new Error(String((event : new Error(String((event instanceof Error ? (event : new Error(String((event : new Error(String((event instanceof Error ? (event : new Error(String((event instanceof Error ? (event instanceof Error ? (event : new Error(String((event : new Error(String((event instanceof Error ? (event : new Error(String((event))))))) => {
        this.handleGestureEvent(event);
      });
      
      Logger.info(this.TAG, 'Gesture events subscribed');
    } catch (error) {
      Logger.error(this.TAG, `Failed to subscribe to gesture events: ${error}`);
    }
  }
  
  /**
   * 处理手势事件
   */
  handleGestureEvent(event: GestureRawEvent): void {
    try {
      // 构建标准化的手势事件
      const gestureEvent: GestureEvent = this.buildGestureEvent(event);
      if (!gestureEvent) return;
      
      // 触发全局回调
      if (this.globalCallback) {
        this.globalCallback(gestureEvent);
      }
      
      // 触发特定类型回调
      const specificCallback = this.gestureCallbacks.get(gestureEvent.type);
      if (specificCallback) {
        specificCallback(gestureEvent);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}` instanceof Error ? `Failed to handle gesture event: ${error}` : new Error(String(`Failed to handle gesture event: ${error}`)))))));
    }
  }
  
  /**
   * 构建标准化的手势事件
   */
  buildGestureEvent(event: GestureRawEvent): GestureEvent | null {
    try {
      // 根据事件类型转换为标准手势事�?      switch (event.type) {
        case 'tap':
          if (!this.config.enableTap) return null;
          return {
            type: GestureType.TAP,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp
          };
          
        case 'doubleTap':
          if (!this.config.enableDoubleTap) return null;
          return {
            type: GestureType.DOUBLE_TAP,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp
          };
          
        case 'longPress':
          if (!this.config.enableLongPress) return null;
          return {
            type: GestureType.LONG_PRESS,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp,
            duration: event.duration
          };
          
        case 'swipe':
          if (!this.config.enableSwipe) return null;
          // 检查滑动距离是否超过阈�?          if (Math.abs(event.distance) < this.config.swipeThreshold) return null;
          
          let direction: Direction;
          if (Math.abs(event.deltaX) > Math.abs(event.deltaY)) {
            direction = event.deltaX > 0 ? Direction.RIGHT : Direction.LEFT;
          } else {
            direction = event.deltaY > 0 ? Direction.DOWN : Direction.UP;
          }
          
          return {
            type: GestureType.SWIPE,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp,
            direction: direction,
            distance: event.distance,
            velocity: event.velocity
          };
          
        case 'pinch':
          if (!this.config.enablePinch) return null;
          return {
            type: GestureType.PINCH,
            x: event.x || 0,
            y: event.y || 0,
            timestamp: event.timestamp || 0,
            scale: event.scale || 1
          };
          
        case 'rotate':
          if (!this.config.enableRotate) return null;
          return {
            type: GestureType.ROTATE,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp,
            rotation: event.rotation
          };
          
        case 'pan':
          if (!this.config.enablePan) return null;
          return {
            type: GestureType.PAN,
            x: event.x,
            y: event.y,
            timestamp: event.timestamp,
            distance: Math.sqrt(event.deltaX * event.deltaX + event.deltaY * event.deltaY)
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
 * 手势服务单例
 */
export const GestureServiceInstance: GestureService = new GestureServiceImpl();


