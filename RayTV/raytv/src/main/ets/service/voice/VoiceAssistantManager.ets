import Logger from '../../common/util/Logger';
import { configService } from '../config/ConfigService';
import { mediaService } from '../media/MediaService';
import { playerManager } from '../media/PlayerManager';
import { Router } from '@ohos/router';

/**
 * 语音命令接口
 */
export interface VoiceCommand {
  keyword: string;        // 命令关键词
  action: (params?: unknown) => Promise<void>; // 执行的动作
  description?: string;   // 命令描述
  examples?: string[];    // 示例
}

/**
 * 语音识别结果接口
 */
export interface RecognitionResult {
  text: string;           // 识别的文本
  confidence: number;     // 置信度（0-1）
  timestamp: number;      // 识别时间戳
}

/**
 * 语音助手管理器
 */
export class VoiceAssistantManager {
  private static readonly TAG: string = 'VoiceAssistantManager';
  private static instance: VoiceAssistantManager;
  
  private isEnabled: boolean = false;
  private isListening: boolean = false;
  private voiceCommands: Map<string, VoiceCommand> = new Map();
  private recognitionListeners: Array<(result: RecognitionResult) => void> = [];
  private stateListeners: Array<(listening: boolean) => void> = [];
  
  private constructor() {
    // 注册默认语音命令
    this.registerDefaultCommands();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): VoiceAssistantManager {
    if (!VoiceAssistantManager.instance) {
      VoiceAssistantManager.instance = new VoiceAssistantManager();
    }
    return VoiceAssistantManager.instance;
  }
  
  /**
   * 初始化语音助手
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(VoiceAssistantManager.TAG, 'Initializing VoiceAssistantManager...');
      
      // 加载配置
      this.isEnabled = await configService.getConfig('enableVoiceAssistant', true);
      
      // 这里应该初始化HarmonyOS的语音识别服务
      // 暂时只进行基本初始化
      
      Logger.info(VoiceAssistantManager.TAG, 'VoiceAssistantManager initialized successfully');
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to initialize VoiceAssistantManager: ${error}`);
      throw error;
    }
  }
  
  /**
   * 开始语音识别
   */
  public async startListening(): Promise<void> {
    try {
      if (!this.isEnabled) {
        throw new Error('Voice assistant is disabled');
      }
      
      Logger.info(VoiceAssistantManager.TAG, 'Starting voice recognition...');
      
      // 更新状态
      this.isListening = true;
      this.notifyStateChanged();
      
      // 这里应该调用HarmonyOS的语音识别API
      // 暂时使用模拟识别
      await this.simulateVoiceRecognition();
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to start listening: ${error}`);
      
      // 重置状态
      this.isListening = false;
      this.notifyStateChanged();
      
      throw error;
    }
  }
  
  /**
   * 停止语音识别
   */
  public async stopListening(): Promise<void> {
    try {
      if (!this.isListening) {
        return;
      }
      
      Logger.info(VoiceAssistantManager.TAG, 'Stopping voice recognition');
      
      // 更新状态
      this.isListening = false;
      this.notifyStateChanged();
      
      // 这里应该停止HarmonyOS的语音识别API
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to stop listening: ${error}`);
      throw error;
    }
  }
  
  /**
   * 处理语音文本
   */
  public async processVoiceText(text: string): Promise<void> {
    try {
      Logger.info(VoiceAssistantManager.TAG, `Processing voice text: ${text}`);
      
      // 将文本转换为小写以便匹配
      const lowercaseText = text.toLowerCase();
      
      // 查找匹配的命令
      let matchedCommand: VoiceCommand | null = null;
      
      // 优先精确匹配关键词
      for (const [keyword, command] of this.voiceCommands.entries()) {
        if (lowercaseText.includes(keyword.toLowerCase())) {
          matchedCommand = command;
          break;
        }
      }
      
      // 如果找到匹配的命令，执行它
      if (matchedCommand) {
        Logger.info(VoiceAssistantManager.TAG, `Executing command: ${matchedCommand.keyword}`);
        await matchedCommand.action();
        
        // 生成识别结果
        const result: RecognitionResult = {
          text,
          confidence: 0.9,
          timestamp: Date.now()
        };
        
        this.notifyRecognitionResult(result);
      } else {
        // 如果没有匹配的命令，尝试搜索内容
        await this.handleSearchCommand(lowercaseText);
      }
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to process voice text: ${error}`);
      throw error;
    }
  }
  
  /**
   * 注册语音命令
   */
  public registerCommand(command: VoiceCommand): void {
    this.voiceCommands.set(command.keyword, command);
    Logger.info(VoiceAssistantManager.TAG, `Command registered: ${command.keyword}`);
  }
  
  /**
   * 注销语音命令
   */
  public unregisterCommand(keyword: string): void {
    this.voiceCommands.delete(keyword);
    Logger.info(VoiceAssistantManager.TAG, `Command unregistered: ${keyword}`);
  }
  
  /**
   * 获取所有可用的语音命令
   */
  public getAvailableCommands(): VoiceCommand[] {
    return Array.from(this.voiceCommands.values());
  }
  
  /**
   * 启用/禁用语音助手
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      this.isEnabled = enabled;
      await configService.setConfig('enableVoiceAssistant', enabled);
      
      // 如果禁用，停止监听
      if (!enabled && this.isListening) {
        await this.stopListening();
      }
      
      Logger.info(VoiceAssistantManager.TAG, `Voice assistant ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to set voice assistant enabled state: ${error}`);
      throw error;
    }
  }
  
  /**
   * 添加识别结果监听器
   */
  public addRecognitionListener(listener: (result: RecognitionResult) => void): void {
    this.recognitionListeners.push(listener);
  }
  
  /**
   * 移除识别结果监听器
   */
  public removeRecognitionListener(listener: (result: RecognitionResult) => void): void {
    const index = this.recognitionListeners.indexOf(listener);
    if (index > -1) {
      this.recognitionListeners.splice(index, 1);
    }
  }
  
  /**
   * 添加状态监听器
   */
  public addStateListener(listener: (listening: boolean) => void): void {
    this.stateListeners.push(listener);
  }
  
  /**
   * 移除状态监听器
   */
  public removeStateListener(listener: (listening: boolean) => void): void {
    const index = this.stateListeners.indexOf(listener);
    if (index > -1) {
      this.stateListeners.splice(index, 1);
    }
  }
  
  /**
   * 注册默认语音命令
   */
  private registerDefaultCommands(): void {
    // 播放控制命令
    this.registerCommand({
      keyword: '播放',
      action: async () => await playerManager.play(),
      description: '开始播放视频',
      examples: ['播放', '开始播放']
    });
    
    this.registerCommand({
      keyword: '暂停',
      action: async () => await playerManager.pause(),
      description: '暂停播放',
      examples: ['暂停', '停止播放']
    });
    
    this.registerCommand({
      keyword: '下一集',
      action: async () => {
        // 这里应该实现切换到下一集的逻辑
        Logger.info(VoiceAssistantManager.TAG, 'Switching to next episode');
      },
      description: '播放下一集',
      examples: ['下一集', '播放下一集']
    });
    
    this.registerCommand({
      keyword: '上一集',
      action: async () => {
        // 这里应该实现切换到上一集的逻辑
        Logger.info(VoiceAssistantManager.TAG, 'Switching to previous episode');
      },
      description: '播放上一集',
      examples: ['上一集', '播放上一集']
    });
    
    this.registerCommand({
      keyword: '快进',
      action: async () => await playerManager.seekBy(30000), // 快进30秒
      description: '快进30秒',
      examples: ['快进', '快进30秒']
    });
    
    this.registerCommand({
      keyword: '快退',
      action: async () => await playerManager.seekBy(-30000), // 快退30秒
      description: '快退30秒',
      examples: ['快退', '快退30秒']
    });
    
    // 导航命令
    this.registerCommand({
      keyword: '首页',
      action: async () => Router.pushUrl({ url: 'pages/HomePage' }),
      description: '返回首页',
      examples: ['返回首页', '首页']
    });
    
    this.registerCommand({
      keyword: '搜索',
      action: async () => Router.pushUrl({ url: 'pages/SearchPage' }),
      description: '打开搜索页面',
      examples: ['搜索', '打开搜索']
    });
    
    this.registerCommand({
      keyword: '历史记录',
      action: async () => Router.pushUrl({ url: 'pages/HistoryPage' }),
      description: '查看历史记录',
      examples: ['历史记录', '我的历史']
    });
    
    this.registerCommand({
      keyword: '我的收藏',
      action: async () => Router.pushUrl({ url: 'pages/FavoritePage' }),
      description: '查看收藏内容',
      examples: ['我的收藏', '收藏']
    });
  }
  
  /**
   * 处理搜索命令
   */
  private async handleSearchCommand(text: string): Promise<void> {
    try {
      // 提取搜索关键词（移除命令前缀）
      const searchKeywords = ['搜索', '查找', '找', '播放'];
      let keyword = text;
      
      for (const prefix of searchKeywords) {
        if (keyword.startsWith(prefix)) {
          keyword = keyword.substring(prefix.length).trim();
          break;
        }
      }
      
      if (keyword.length > 0) {
        Logger.info(VoiceAssistantManager.TAG, `Searching for: ${keyword}`);
        
        // 导航到搜索页面并传递关键词
        Router.pushUrl({
          url: 'pages/SearchPage',
          params: { keyword }
        });
      }
    } catch (error: Error) {
      Logger.error(VoiceAssistantManager.TAG, `Failed to handle search command: ${error}`);
    }
  }
  
  /**
   * 模拟语音识别（用于演示）
   */
  private async simulateVoiceRecognition(): Promise<void> {
    // 模拟识别延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 模拟识别结果
    const mockResults = [
      '播放',
      '暂停',
      '下一集',
      '快进',
      '返回首页',
      '搜索电影'
    ];
    
    // 随机选择一个结果
    const randomIndex = Math.floor(Math.random() * mockResults.length);
    const recognizedText = mockResults[randomIndex];
    
    // 处理识别结果
    await this.processVoiceText(recognizedText);
    
    // 停止监听
    this.isListening = false;
    this.notifyStateChanged();
  }
  
  /**
   * 通知识别结果
   */
  private notifyRecognitionResult(result: RecognitionResult): void {
    this.recognitionListeners.forEach(listener => {
      try {
        listener(result);
      } catch (error: Error) {
        Logger.error(VoiceAssistantManager.TAG, `Error in recognition listener: ${error}`);
      }
    });
  }
  
  /**
   * 通知状态变化
   */
  private notifyStateChanged(): void {
    this.stateListeners.forEach(listener => {
      try {
        listener(this.isListening);
      } catch (error) {
        Logger.error(VoiceAssistantManager.TAG, `Error in state listener: ${error}`);
      }
    });
  }
  
  /**
   * 获取当前监听状态
   */
  public isCurrentlyListening(): boolean {
    return this.isListening;
  }
  
  /**
   * 获取语音助手启用状态
   */
  public isAssistantEnabled(): boolean {
    return this.isEnabled;
  }
}

// 导出单例实例
export function getVoiceAssistantManager(): VoiceAssistantManager {
  return VoiceAssistantManager.getInstance();
}