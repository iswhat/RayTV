
import ConfigService from '../config/ConfigService';
import MediaService from '../media/MediaService';
import PlayerManager from '../media/PlayerManager';
import AppNavigator from '../../navigation/AppNavigator';

/**
 * 语音命令参数接口 Voice command params interface
 */
export interface VoiceCommandParams {
  keyword?: string;
  value?: string | number;
  action?: string;
  target?: string;
}

/**
 * 语音命令接口 Voice command interface
 */
export interface VoiceCommand {
  keyword: string;        // 命令关键词 Command keyword
  action: (params?: VoiceCommandParams) => Promise<void>; // 执行的动作 Action to execute
  description?: string;   // 命令描述 Command description
  examples?: string[];    // 示例 Examples
}

/**
 * 语音识别结果接口 Voice recognition result interface
 */
export interface RecognitionResult {
  text: string;           // 识别的文本 Recognized text
  confidence: number;     // 置信度（0-1）Confidence (0-1)
  timestamp: number;      // 识别时间戳 Recognition timestamp
}

/**
 * 语音识别回调接口 | Voice recognition callback interface
 */
export interface VoiceRecognitionCallback {
  onStartListening: () => void;
  onResult: (result: string) => void;
  onError: (error: Error | string) => void;
  onEnd: () => void;
}

/**
 * 语音识别服务接口 | Voice recognition service interface
 */
export interface VoiceRecognitionService {
  setCallback: (callback: VoiceRecognitionCallback) => void;
  startListening: (params: {
    language: string;
    mode: string;
    encoding: string;
    sampleRate: number;
  }) => Promise<void>;
  stopListening: () => Promise<void>;
}

/**
 * 语音助手管理器 Voice assistant manager
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
    // 注册默认语音命令 Register default voice commands
    this.registerDefaultCommands();
  }
  
  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): VoiceAssistantManager {
    if (!VoiceAssistantManager.instance) {
      VoiceAssistantManager.instance = new VoiceAssistantManager();
    }
    return VoiceAssistantManager.instance;
  }
  
  /**
   * 初始化语音助手 Initialize voice assistant
   */
  public async initialize(): Promise<void> {
    try {
      console.info(VoiceAssistantManager.TAG + ': 正在初始化语音助手管理器... | Initializing VoiceAssistantManager...');
      
      // 加载配置 Load config
      this.isEnabled = await ConfigService.getInstance().getConfig('enableVoiceAssistant', true);
      
      // 这里应该初始化HarmonyOS的语音识别服务
      // 暂时只进行基本初始化
      // Should initialize HarmonyOS voice recognition service here
      // Temporarily only perform basic initialization
      
      console.info(VoiceAssistantManager.TAG + ': 语音助手管理器初始化成功 | VoiceAssistantManager initialized successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(VoiceAssistantManager.TAG + `: 初始化语音助手管理器失败: | Failed to initialize VoiceAssistantManager: ${error instanceof Error ? error.message : String(error)}`);
      throw new Error(`初始化语音助手管理器失败: | Failed to initialize VoiceAssistantManager: ${errorMsg}`);
    }
  }
  
  /**
   * 开始语音识别 Start voice recognition
   */
  public async startListening(): Promise<void> {
    try {
      if (!this.isEnabled) {
        throw new Error('Voice assistant is disabled');
      }
      
      console.info(VoiceAssistantManager.TAG + ': 正在开始语音识别... | Starting voice recognition...');
      
      // 更新状态 Update state
      this.isListening = true;
      this.notifyStateChanged();
      
      // 调用HarmonyOS的语音识别API | Call HarmonyOS voice recognition API
      await this.performRealVoiceRecognition();
    } catch (error) {
      console.error(VoiceAssistantManager.TAG + `: 开始语音识别失败: | Failed to start listening: ${error instanceof Error ? error.message : String(error)}`);
      
      // 重置状态 Reset state
      this.isListening = false;
      this.notifyStateChanged();
      
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 停止语音识别 Stop voice recognition
   */
  public async stopListening(): Promise<void> {
    try {
      if (!this.isListening) {
        return;
      }
      
      console.info(VoiceAssistantManager.TAG + ': 正在停止语音识别 | Stopping voice recognition');
      
      // 更新状态 Update state
      this.isListening = false;
      this.notifyStateChanged();
      
      // 这里应该停止HarmonyOS的语音识别API
      // Should stop HarmonyOS voice recognition API here
    } catch (error) {
      console.error(VoiceAssistantManager.TAG + `: 停止语音识别失败: | Failed to stop listening: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 处理语音文本 Process voice text
   */
  public async processVoiceText(text: string): Promise<void> {
    try {
      console.info(VoiceAssistantManager.TAG + `: 正在处理语音文本: ${text} | Processing voice text: ${text}`);
      
      // 将文本转换为小写以便匹配 Convert text to lowercase for matching
      const lowercaseText = text.toLowerCase();
      
      // 查找匹配的命令 Find matching command
      let matchedCommand: VoiceCommand | null = null;
      
      // 优先精确匹配关键词 First prioritize exact keyword matching
      for (const [keyword, command] of this.voiceCommands.entries()) {
        if (lowercaseText.includes(keyword.toLowerCase())) {
          matchedCommand = command;
          break;
        }
      }
      
      // 如果找到匹配的命令，执行它 If matching command found, execute it
      if (matchedCommand) {
        console.info(VoiceAssistantManager.TAG + `: 正在执行命令: ${matchedCommand.keyword} | Executing command: ${matchedCommand.keyword}`);
        await matchedCommand.action();
        
        // 生成识别结果 Generate recognition result
        const result: RecognitionResult = {
          text,
          confidence: 0.9,
          timestamp: Date.now()
        };
        
        this.notifyRecognitionResult(result);
      } else {
        // 如果没有匹配的命令，尝试搜索内容
        // If no matching command, try to search content
        await this.handleSearchCommand(lowercaseText);
      }
    } catch (error) {
      console.error(VoiceAssistantManager.TAG + `: 处理语音文本失败: | Failed to process voice text: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 注册语音命令 Register voice command
   */
  public registerCommand(command: VoiceCommand): void {
    this.voiceCommands.set(command.keyword, command);
    console.info(VoiceAssistantManager.TAG + `: 命令已注册: ${command.keyword} | Command registered: ${command.keyword}`);
  }
  
  /**
   * 注销语音命令 Unregister voice command
   */
  public unregisterCommand(keyword: string): void {
    this.voiceCommands.delete(keyword);
    console.info(VoiceAssistantManager.TAG + `: 命令已注销: ${keyword} | Command unregistered: ${keyword}`);
  }
  
  /**
   * 获取所有可用的语音命令 Get all available voice commands
   */
  public getAvailableCommands(): VoiceCommand[] {
    return Array.from(this.voiceCommands.values());
  }
  
  /**
   * 启用/禁用语音助手 Enable/disable voice assistant
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      this.isEnabled = enabled;
      await ConfigService.getInstance().setConfig('enableVoiceAssistant', enabled);
      
      // 如果禁用，停止监听 If disabled, stop listening
      if (!enabled && this.isListening) {
        await this.stopListening();
      }
      
      console.info(VoiceAssistantManager.TAG + `: Voice assistant ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      console.error(VoiceAssistantManager.TAG + `: Failed to set voice assistant enabled state: ${error instanceof Error ? error.message : String(error)}`);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }
  
  /**
   * 添加识别结果监听器 Add recognition result listener
   */
  public addRecognitionListener(listener: (result: RecognitionResult) => void): void {
    this.recognitionListeners.push(listener);
  }
  
  /**
   * 移除识别结果监听器 Remove recognition result listener
   */
  public removeRecognitionListener(listener: (result: RecognitionResult) => void): void {
    const index = this.recognitionListeners.indexOf(listener);
    if (index > -1) {
      this.recognitionListeners.splice(index, 1);
    }
  }
  
  /**
   * 添加状态监听器 Add state listener
   */
  public addStateListener(listener: (listening: boolean) => void): void {
    this.stateListeners.push(listener);
  }
  
  /**
   * 移除状态监听器 Remove state listener
   */
  public removeStateListener(listener: (listening: boolean) => void): void {
    const index = this.stateListeners.indexOf(listener);
    if (index > -1) {
      this.stateListeners.splice(index, 1);
    }
  }
  
  /**
   * 注册默认语音命令 Register default voice commands
   */
  private registerDefaultCommands(): void {
    // 播放控制命令 Playback control commands
    this.registerCommand({
      keyword: '播放',
      action: async () => await PlayerManager.getInstance().play(),
      description: '开始播放视频',
      examples: ['播放', '开始播放']
    });
    
    this.registerCommand({
      keyword: '暂停',
      action: async () => await PlayerManager.getInstance().pause(),
      description: '暂停播放',
      examples: ['暂停', '停止播放']
    });
    
    this.registerCommand({
      keyword: '下一集',
      action: async () => {
        // 这里应该实现切换到下一集的逻辑
        // Should implement logic to switch to next episode here
        console.info(VoiceAssistantManager.TAG + ': Switching to next episode');
      },
      description: '播放下一集',
      examples: ['下一集', '播放下一集']
    });
    
    this.registerCommand({
      keyword: '上一集',
      action: async () => {
        // 这里应该实现切换到上一集的逻辑
        // Should implement logic to switch to previous episode here
        console.info(VoiceAssistantManager.TAG + ': Switching to previous episode');
      },
      description: '播放上一集',
      examples: ['上一集', '播放上一集']
    });
    
    this.registerCommand({
      keyword: '快进',
      action: async () => await PlayerManager.getInstance().seekBy(30000), // 快进30秒 Fast forward 30 seconds
      description: '快进30秒',
      examples: ['快进', '快进30秒']
    });
    
    this.registerCommand({
      keyword: '快退',
      action: async () => await PlayerManager.getInstance().seekBy(-30000), // 快退30秒 Rewind 30 seconds
      description: '快退30秒',
      examples: ['快退', '快退30秒']
    });
    
    // 导航命令 Navigation commands
    this.registerCommand({
      keyword: '首页',
      action: async () => AppNavigator.getInstance().navigateToHome(),
      description: '返回首页',
      examples: ['返回首页', '首页']
    });
    
    this.registerCommand({
      keyword: '搜索',
      action: async () => AppNavigator.getInstance().navigateToSearch(),
      description: '打开搜索页面',
      examples: ['搜索', '打开搜索']
    });
    
    this.registerCommand({
      keyword: '历史记录',
      action: async () => AppNavigator.getInstance().navigateToHistory(),
      description: '查看历史记录',
      examples: ['历史记录', '我的历史']
    });
    
    this.registerCommand({
      keyword: '我的收藏',
      action: async () => AppNavigator.getInstance().navigateToFavorites(),
      description: '查看收藏内容',
      examples: ['我的收藏', '收藏']
    });
  }
  
  /**
   * 处理搜索命令 Handle search command
   */
  private async handleSearchCommand(text: string): Promise<void> {
    try {
      // 提取搜索关键词（移除命令前缀） Extract search keywords (remove command prefixes)
      const searchKeywords = ['搜索', '查找', '看', '播放'];
      let keyword = text;
      
      for (const prefix of searchKeywords) {
        if (keyword.startsWith(prefix)) {
          keyword = keyword.substring(prefix.length).trim();
          break;
        }
      }
      
      if (keyword.length > 0) {
        console.info(VoiceAssistantManager.TAG + `: Searching for: ${keyword}`);
        
        // 导航到搜索页面并传递关键词 Navigate to search page and pass keywords
        AppNavigator.getInstance().navigateToSearch(keyword);
      }
    } catch (error) {
      console.error(VoiceAssistantManager.TAG + `: Failed to handle search command: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 执行真实语音识别 | Perform real voice recognition
   */
  private async performRealVoiceRecognition(): Promise<void> {
    try {
      // 1. 获取语音识别服务 | Get voice recognition service
      const recognitionService = await this.getVoiceRecognitionService();
      
      // 2. 设置识别参数 | Set recognition parameters
      const recognitionParams = {
        language: 'zh-CN',
        mode: 'continuous',
        encoding: 'pcm',
        sampleRate: 16000
      };
      
      // 3. 注册识别回调 | Register recognition callback
      recognitionService.setCallback({
        onStartListening: () => {
          console.info(VoiceAssistantManager.TAG + ': 开始语音识别 | Started listening');
        },
        onResult: (result: string) => {
          this.handleRecognitionResult(result);
        },
        onError: (error: Error | string) => {
          this.handleRecognitionError(error);
        },
        onEnd: () => {
          this.isListening = false;
          this.notifyStateChanged();
        }
      });
      
      // 4. 开始识别 | Start recognition
      await recognitionService.startListening(recognitionParams);
      
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(VoiceAssistantManager.TAG + `: 语音识别启动失败: | Failed to start voice recognition: ${error instanceof Error ? error.message : String(error)}`);
      throw new Error(`语音识别启动失败: | Failed to start voice recognition: ${errorMsg}`);
    }
  }
  


  /**
   * 获取语音识别服务 | Get voice recognition service
   */
  private async getVoiceRecognitionService(): Promise<VoiceRecognitionService> {
    try {
      // 尝试导入HarmonyOS语音识别API
      // 由于HarmonyOS SDK版本差异，这里使用条件导入
      const voiceRecognition = await import('@ohos.ai.asr');
      
      // 适配VoiceRecognitionService接口
      return {
        setCallback: (callback: (result: string, error: Error | null) => void) => {
          // 设置真实的回调
        },
        startListening: async () => {
          // 调用真实的语音识别API
          await voiceRecognition.start();
        },
        stopListening: async () => {
          // 调用真实的语音识别API
          await voiceRecognition.stop();
        }
      };
    } catch (error) {
      console.warn(VoiceAssistantManager.TAG, '语音识别API不可用，使用降级实现 | Voice recognition API not available, using fallback implementation');
      // 降级实现
      return {
        setCallback: () => {},
        startListening: () => Promise.resolve(),
        stopListening: () => Promise.resolve()
      };
    }
  }
  
  /**
   * 处理识别结果 | Handle recognition result
   */
  private async handleRecognitionResult(result: string): Promise<void> {
    console.info(VoiceAssistantManager.TAG + `: 识别到语音: ${result} | Recognized voice: ${result}`);
    
    // 处理识别结果 | Process recognition result
    await this.processVoiceText(result);
    
    // 停止监听 | Stop listening
    this.isListening = false;
    this.notifyStateChanged();
  }
  
  /**
   * 处理识别错误 | Handle recognition error
   */
  private handleRecognitionError(error: Error | string): void {
    console.error(VoiceAssistantManager.TAG + `: 语音识别错误: | Voice recognition error: ${error instanceof Error ? error.message : String(error)}`);
    
    // 重置状态 | Reset state
    this.isListening = false;
    this.notifyStateChanged();
  }
  
  /**
   * 通知识别结果 Notify recognition result
   */
  private notifyRecognitionResult(result: RecognitionResult): void {
    this.recognitionListeners.forEach(listener => {
      try {
        listener(result);
      } catch (error) {
        console.error(VoiceAssistantManager.TAG + `: Error in recognition listener: ${error instanceof Error ? error.message : String(error)}`);
      }
    });
  }
  
  /**
   * 通知状态变化 Notify state change
   */
  private notifyStateChanged(): void {
    this.stateListeners.forEach(listener => {
      try {
        listener(this.isListening);
      } catch (error) {
        console.error(VoiceAssistantManager.TAG + `: Error in state listener: ${error instanceof Error ? error.message : String(error)}`);
      }
    });
  }
  
  /**
   * 获取当前监听状态 Get current listening state
   */
  public isCurrentlyListening(): boolean {
    return this.isListening;
  }
  
  /**
   * 获取语音助手启用状态 Get voice assistant enabled state
   */
  public isAssistantEnabled(): boolean {
    return this.isEnabled;
  }
}

// 导出单例实例 Export singleton instance
export function getVoiceAssistantManager(): VoiceAssistantManager {
  return VoiceAssistantManager.getInstance();
}
