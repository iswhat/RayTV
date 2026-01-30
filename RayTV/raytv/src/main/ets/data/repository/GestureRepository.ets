/**
 * GestureRepository - 手势数据仓储接口 | Gesture data repository interface
 * 负责手势数据的存储和检索 | Responsible for gesture data storage and retrieval
 */
import StorageUtil from '../../common/util/StorageUtil';
import Logger from '../../common/util/Logger';
import { GestureType, Direction, GestureEvent } from '../../service/input/GestureService';

const TAG = 'GestureRepository';
const GESTURE_STORAGE_KEY = 'gesture_settings';
const GESTURE_HISTORY_KEY = 'gesture_history';
const GESTURE_CONFIG_KEY = 'gesture_config';

/**
 * 手势配置接口 | Gesture configuration interface
 */
export interface GestureSettings {
  enableTap: boolean; // 是否启用点击手势 | Whether to enable tap gesture
  enableDoubleTap: boolean; // 是否启用双击手势 | Whether to enable double tap gesture
  enableLongPress: boolean; // 是否启用长按手势 | Whether to enable long press gesture
  enableSwipe: boolean; // 是否启用滑动手势 | Whether to enable swipe gesture
  enablePinch: boolean; // 是否启用捏合手势 | Whether to enable pinch gesture
  enableRotate: boolean; // 是否启用旋转手势 | Whether to enable rotate gesture
  enablePan: boolean; // 是否启用平移手势 | Whether to enable pan gesture
  swipeThreshold: number; // 滑动阈值 | Swipe threshold
  longPressDuration: number; // 长按持续时间 | Long press duration
  gestureMappings: Record<string, string>; // 手势到操作的映射 | Gesture to operation mapping
}

/**
 * 手势历史记录接口 | Gesture history record interface
 */
export interface GestureHistoryRecord {
  id: string; // 记录ID | Record ID
  gestureType: GestureType; // 手势类型 | Gesture type
  direction?: Direction; // 方向 | Direction
  timestamp: number; // 时间戳 | Timestamp
  x: number; // X坐标 | X coordinate
  y: number; // Y坐标 | Y coordinate
  distance?: number; // 距离 | Distance
  velocity?: number; // 速度 | Velocity
  scale?: number; // 缩放 | Scale
  rotation?: number; // 旋转 | Rotation
  action?: string; // 触发的操作 | Triggered action
}

/**
 * 手势响应结果接口 | Gesture response result interface
 */
export interface GestureResult<T> {
  success: boolean; // 是否成功 | Whether successful
  data?: T; // 数据 | Data
  error?: Error; // 错误 | Error
  message?: string; // 消息 | Message
}

/**
 * 手势仓储接口 | Gesture repository interface
 */
export interface GestureRepository {
  /**
   * 初始化手势仓储 | Initialize gesture repository
   * @returns 初始化结果 | Initialization result
   */
  initialize(): Promise<GestureResult<void>>;

  /**
   * 保存手势设置 | Save gesture settings
   * @param settings 手势设置 | Gesture settings
   * @returns 保存结果 | Save result
   */
  saveGestureSettings(settings: GestureSettings): Promise<GestureResult<boolean>>;

  /**
   * 获取手势设置 | Get gesture settings
   * @returns 手势设置 | Gesture settings
   */
  getGestureSettings(): Promise<GestureResult<GestureSettings>>;

  /**
   * 保存手势历史记录 | Save gesture history record
   * @param record 手势历史记录 | Gesture history record
   * @returns 保存结果 | Save result
   */
  saveGestureHistory(record: GestureHistoryRecord): Promise<GestureResult<boolean>>;

  /**
   * 获取手势历史记录 | Get gesture history records
   * @param limit 限制数量 | Limit count
   * @returns 手势历史记录列表 | Gesture history record list
   */
  getGestureHistory(limit: number = 100): Promise<GestureResult<GestureHistoryRecord[]>>;

  /**
   * 清除手势历史记录 | Clear gesture history records
   * @returns 清除结果 | Clear result
   */
  clearGestureHistory(): Promise<GestureResult<boolean>>;

  /**
   * 保存手势配置 | Save gesture configuration
   * @param config 手势配置 | Gesture configuration
   * @returns 保存结果 | Save result
   */
  saveGestureConfig(config: Record<string, any>): Promise<GestureResult<boolean>>;

  /**
   * 获取手势配置 | Get gesture configuration
   * @returns 手势配置 | Gesture configuration
   */
  getGestureConfig(): Promise<GestureResult<Record<string, any>>>;

  /**
   * 处理手势事件 | Process gesture event
   * @param event 手势事件 | Gesture event
   * @returns 处理结果 | Process result
   */
  processGestureEvent(event: GestureEvent): Promise<GestureResult<string>>;

  /**
   * 获取手势到操作的映射 | Get gesture to operation mapping
   * @returns 手势到操作的映射 | Gesture to operation mapping
   */
  getGestureMappings(): Promise<GestureResult<Record<string, string>>>;

  /**
   * 更新手势到操作的映射 | Update gesture to operation mapping
   * @param mappings 手势到操作的映射 | Gesture to operation mapping
   * @returns 更新结果 | Update result
   */
  updateGestureMappings(mappings: Record<string, string>): Promise<GestureResult<boolean>>;
}

/**
 * 手势仓储实现类 | Gesture repository implementation class
 * 基于StorageUtil实现手势数据的存储和检索 | Based on StorageUtil to implement gesture data storage and retrieval
 */
export class GestureRepositoryImpl implements GestureRepository {
  /**
   * 初始化手势仓储 | Initialize gesture repository
   * @returns 初始化结果 | Initialization result
   */
  async initialize(): Promise<GestureResult<void>> {
    try {
      Logger.info(TAG, 'Initializing gesture repository...');
      
      // 检查是否存在手势设置，如果不存在则创建默认设置 | Check if gesture settings exist, create default settings if not
      const existingSettings = await StorageUtil.getString(GESTURE_STORAGE_KEY);
      if (!existingSettings) {
        const defaultSettings: GestureSettings = {
          enableTap: true,
          enableDoubleTap: true,
          enableLongPress: true,
          enableSwipe: true,
          enablePinch: true,
          enableRotate: true,
          enablePan: true,
          swipeThreshold: 50,
          longPressDuration: 500,
          gestureMappings: {
            'tap': 'select',
            'doubleTap': 'playPause',
            'longPress': 'contextMenu',
            'swipe_up': 'volumeUp',
            'swipe_down': 'volumeDown',
            'swipe_left': 'previous',
            'swipe_right': 'next',
            'pinch_in': 'zoomOut',
            'pinch_out': 'zoomIn',
            'rotate': 'rotate'
          }
        };
        await StorageUtil.putString(GESTURE_STORAGE_KEY, JSON.stringify(defaultSettings));
        Logger.info(TAG, 'Default gesture settings created');
      }
      
      // 检查是否存在手势历史，如果不存在则创建空数组 | Check if gesture history exists, create empty array if not
      const existingHistory = await StorageUtil.getString(GESTURE_HISTORY_KEY);
      if (!existingHistory) {
        await StorageUtil.putString(GESTURE_HISTORY_KEY, JSON.stringify([]));
        Logger.info(TAG, 'Gesture history initialized');
      }
      
      // 检查是否存在手势配置，如果不存在则创建默认配置 | Check if gesture config exists, create default config if not
      const existingConfig = await StorageUtil.getString(GESTURE_CONFIG_KEY);
      if (!existingConfig) {
        const defaultConfig = {
          version: '1.0',
          lastUpdated: Date.now(),
          enabled: true
        };
        await StorageUtil.putString(GESTURE_CONFIG_KEY, JSON.stringify(defaultConfig));
        Logger.info(TAG, 'Default gesture config created');
      }
      
      Logger.info(TAG, 'Gesture repository initialized successfully');
      return { success: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to initialize gesture repository: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to initialize gesture repository'
      };
    }
  }

  /**
   * 保存手势设置 | Save gesture settings
   * @param settings 手势设置 | Gesture settings
   * @returns 保存结果 | Save result
   */
  async saveGestureSettings(settings: GestureSettings): Promise<GestureResult<boolean>> {
    try {
      await StorageUtil.putString(GESTURE_STORAGE_KEY, JSON.stringify(settings));
      Logger.info(TAG, 'Gesture settings saved successfully');
      return { success: true, data: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save gesture settings: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to save gesture settings'
      };
    }
  }

  /**
   * 获取手势设置 | Get gesture settings
   * @returns 手势设置 | Gesture settings
   */
  async getGestureSettings(): Promise<GestureResult<GestureSettings>> {
    try {
      const settingsStr = await StorageUtil.getString(GESTURE_STORAGE_KEY);
      if (settingsStr) {
        const settings = JSON.parse(settingsStr) as GestureSettings;
        Logger.info(TAG, 'Gesture settings retrieved successfully');
        return { success: true, data: settings };
      } else {
        // 返回默认设置 | Return default settings
        const defaultSettings: GestureSettings = {
          enableTap: true,
          enableDoubleTap: true,
          enableLongPress: true,
          enableSwipe: true,
          enablePinch: true,
          enableRotate: true,
          enablePan: true,
          swipeThreshold: 50,
          longPressDuration: 500,
          gestureMappings: {
            'tap': 'select',
            'doubleTap': 'playPause',
            'longPress': 'contextMenu',
            'swipe_up': 'volumeUp',
            'swipe_down': 'volumeDown',
            'swipe_left': 'previous',
            'swipe_right': 'next',
            'pinch_in': 'zoomOut',
            'pinch_out': 'zoomIn',
            'rotate': 'rotate'
          }
        };
        Logger.info(TAG, 'Using default gesture settings');
        return { success: true, data: defaultSettings };
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get gesture settings: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to get gesture settings'
      };
    }
  }

  /**
   * 保存手势历史记录 | Save gesture history record
   * @param record 手势历史记录 | Gesture history record
   * @returns 保存结果 | Save result
   */
  async saveGestureHistory(record: GestureHistoryRecord): Promise<GestureResult<boolean>> {
    try {
      // 获取现有历史记录 | Get existing history records
      const historyStr = await StorageUtil.getString(GESTURE_HISTORY_KEY);
      const history = historyStr ? JSON.parse(historyStr) as GestureHistoryRecord[] : [];
      
      // 添加新记录 | Add new record
      history.unshift(record);
      
      // 限制历史记录数量 | Limit history record count
      const maxHistoryCount = 1000;
      if (history.length > maxHistoryCount) {
        history.splice(maxHistoryCount);
      }
      
      // 保存更新后的历史记录 | Save updated history records
      await StorageUtil.putString(GESTURE_HISTORY_KEY, JSON.stringify(history));
      Logger.info(TAG, 'Gesture history record saved successfully');
      return { success: true, data: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save gesture history record: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to save gesture history record'
      };
    }
  }

  /**
   * 获取手势历史记录 | Get gesture history records
   * @param limit 限制数量 | Limit count
   * @returns 手势历史记录列表 | Gesture history record list
   */
  async getGestureHistory(limit: number = 100): Promise<GestureResult<GestureHistoryRecord[]>> {
    try {
      const historyStr = await StorageUtil.getString(GESTURE_HISTORY_KEY);
      const history = historyStr ? JSON.parse(historyStr) as GestureHistoryRecord[] : [];
      const limitedHistory = history.slice(0, limit);
      Logger.info(TAG, `Gesture history retrieved successfully, count: ${limitedHistory.length}`);
      return { success: true, data: limitedHistory };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get gesture history: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to get gesture history'
      };
    }
  }

  /**
   * 清除手势历史记录 | Clear gesture history records
   * @returns 清除结果 | Clear result
   */
  async clearGestureHistory(): Promise<GestureResult<boolean>> {
    try {
      await StorageUtil.putString(GESTURE_HISTORY_KEY, JSON.stringify([]));
      Logger.info(TAG, 'Gesture history cleared successfully');
      return { success: true, data: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear gesture history: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to clear gesture history'
      };
    }
  }

  /**
   * 保存手势配置 | Save gesture configuration
   * @param config 手势配置 | Gesture configuration
   * @returns 保存结果 | Save result
   */
  async saveGestureConfig(config: Record<string, string | number | boolean | object | null>): Promise<GestureResult<boolean>> {
    try {
      await StorageUtil.putString(GESTURE_CONFIG_KEY, JSON.stringify(config));
      Logger.info(TAG, 'Gesture config saved successfully');
      return { success: true, data: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to save gesture config: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to save gesture config'
      };
    }
  }

  /**
   * 获取手势配置 | Get gesture configuration
   * @returns 手势配置 | Gesture configuration
   */
  async getGestureConfig(): Promise<GestureResult<Record<string, string | number | boolean | object | null>>> {
    try {
      const configStr = await StorageUtil.getString(GESTURE_CONFIG_KEY);
      if (configStr) {
        const config = JSON.parse(configStr) as Record<string, string | number | boolean | object | null>;
        Logger.info(TAG, 'Gesture config retrieved successfully');
        return { success: true, data: config };
      } else {
        // 返回默认配置 | Return default configuration
        const defaultConfig = {
          version: '1.0',
          lastUpdated: Date.now(),
          enabled: true
        };
        Logger.info(TAG, 'Using default gesture config');
        return { success: true, data: defaultConfig };
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get gesture config: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to get gesture config'
      };
    }
  }

  /**
   * 处理手势事件 | Process gesture event
   * @param event 手势事件 | Gesture event
   * @returns 处理结果 | Process result
   */
  async processGestureEvent(event: GestureEvent): Promise<GestureResult<string>> {
    try {
      // 获取手势设置 | Get gesture settings
      const settingsResult = await this.getGestureSettings();
      if (!settingsResult.success || !settingsResult.data) {
        return {
          success: false,
          message: 'Failed to get gesture settings'
        };
      }
      
      const settings = settingsResult.data;
      
      // 检查手势是否启用 | Check if gesture is enabled
      let isEnabled = false;
      switch (event.type) {
        case GestureType.TAP:
          isEnabled = settings.enableTap;
          break;
        case GestureType.DOUBLE_TAP:
          isEnabled = settings.enableDoubleTap;
          break;
        case GestureType.LONG_PRESS:
          isEnabled = settings.enableLongPress;
          break;
        case GestureType.SWIPE:
          isEnabled = settings.enableSwipe;
          break;
        case GestureType.PINCH:
          isEnabled = settings.enablePinch;
          break;
        case GestureType.ROTATE:
          isEnabled = settings.enableRotate;
          break;
        case GestureType.PAN:
          isEnabled = settings.enablePan;
          break;
      }
      
      if (!isEnabled) {
        Logger.info(TAG, `Gesture ${event.type} is disabled`);
        return {
          success: false,
          message: `Gesture ${event.type} is disabled`
        };
      }
      
      // 生成手势键 | Generate gesture key
      let gestureKey = event.type;
      if (event.type === GestureType.SWIPE && event.direction) {
        gestureKey = `${event.type}_${event.direction.toLowerCase()}`;
      } else if (event.type === GestureType.PINCH && event.scale) {
        gestureKey = event.scale > 1 ? 'pinch_out' : 'pinch_in';
      }
      
      // 获取映射的操作 | Get mapped operation
      const action = settings.gestureMappings[gestureKey];
      
      if (action) {
        // 保存手势历史 | Save gesture history
        const historyRecord: GestureHistoryRecord = {
          id: `gesture_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
          gestureType: event.type,
          direction: event.direction,
          timestamp: event.timestamp,
          x: event.x,
          y: event.y,
          distance: event.distance,
          velocity: event.velocity,
          scale: event.scale,
          rotation: event.rotation,
          action: action
        };
        await this.saveGestureHistory(historyRecord);
        
        Logger.info(TAG, `Gesture ${gestureKey} mapped to action: ${action}`);
        return { success: true, data: action };
      } else {
        Logger.info(TAG, `No action mapped for gesture: ${gestureKey}`);
        return {
          success: false,
          message: `No action mapped for gesture: ${gestureKey}`
        };
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to process gesture event: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to process gesture event'
      };
    }
  }

  /**
   * 获取手势到操作的映射 | Get gesture to operation mapping
   * @returns 手势到操作的映射 | Gesture to operation mapping
   */
  async getGestureMappings(): Promise<GestureResult<Record<string, string>>> {
    try {
      const settingsResult = await this.getGestureSettings();
      if (!settingsResult.success || !settingsResult.data) {
        return {
          success: false,
          message: 'Failed to get gesture settings'
        };
      }
      
      Logger.info(TAG, 'Gesture mappings retrieved successfully');
      return { success: true, data: settingsResult.data.gestureMappings };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get gesture mappings: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to get gesture mappings'
      };
    }
  }

  /**
   * 更新手势到操作的映射 | Update gesture to operation mapping
   * @param mappings 手势到操作的映射 | Gesture to operation mapping
   * @returns 更新结果 | Update result
   */
  async updateGestureMappings(mappings: Record<string, string>): Promise<GestureResult<boolean>> {
    try {
      const settingsResult = await this.getGestureSettings();
      if (!settingsResult.success || !settingsResult.data) {
        return {
          success: false,
          message: 'Failed to get gesture settings'
        };
      }
      
      const settings = settingsResult.data;
      settings.gestureMappings = { ...settings.gestureMappings, ...mappings };
      
      await this.saveGestureSettings(settings);
      Logger.info(TAG, 'Gesture mappings updated successfully');
      return { success: true, data: true };
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to update gesture mappings: ${errorMsg}`);
      return {
        success: false,
        error: error instanceof Error ? error : new Error(errorMsg),
        message: 'Failed to update gesture mappings'
      };
    }
  }
}

/**
 * 手势仓储单例 | Gesture repository singleton
 */
export const GestureRepositoryInstance: GestureRepository = new GestureRepositoryImpl();
