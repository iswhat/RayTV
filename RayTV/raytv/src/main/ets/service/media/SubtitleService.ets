// SubtitleService - 字幕服务类 Subtitle service class
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import FileUtil from '../../common/util/FileUtil';
import { SubtitleStyle, DEFAULT_SUBTITLE_STYLE } from '../player/PlayerService';
import { ResponseCode } from '../../common/constant/ResponseCode';

// API响应类 API response class
export class ApiResponse<T> {
  code: number;
  message: string;
  data?: T;
  
  constructor(code: number, message: string, data?: T) {
    this.code = code;
    this.message = message;
    this.data = data;
  }
  
  static success<T>(data: T, message: string = 'Success'): ApiResponse<T> {
    return new ApiResponse(200, message, data);
  }
  
  static error<T>(code: number, message: string): ApiResponse<T> {
    return new ApiResponse(code, message);
  }
  
  isSuccess(): boolean {
    return this.code === 200;
  }
}

// 常量定义 Constant definition
const TAG = 'SubtitleService';
const SUBTITLE_CACHE_DIR = 'subtitles';
const USER_SUBTITLE_DIR = 'user_subtitles';
const SUBTITLE_HISTORY_KEY = 'subtitle_history';
const SUBTITLE_STYLE_KEY = 'subtitle_style';

// 字幕类型枚举 Subtitle type enum
export enum SubtitleType {
  SRT = 'srt',       // SubRip格式 SubRip format
  VTT = 'vtt',       // WebVTT格式 WebVTT format
  ASS = 'ass',       // Advanced SubStation Alpha格式 Advanced SubStation Alpha format
  SSA = 'ssa',       // SubStation Alpha格式 SubStation Alpha format
  TTML = 'ttml',     // Timed Text Markup Language格式 Timed Text Markup Language format
  DFXP = 'dfxp',     // Distribution Format Exchange Profile格式 Distribution Format Exchange Profile format
  SBV = 'sbv',       // YouTube SBV格式 YouTube SBV format
  LRC = 'lrc',       // 歌词格式（用于歌曲）Lyrics format (for songs)
  CAP = 'cap',       // 自定义字幕格式 Custom subtitle format
  UNKNOWN = 'unknown' // 未知格式 Unknown format
}

// 字幕语言信息接口 Subtitle language information interface
export interface SubtitleLanguage {
  code: string;      // 语言代码 (ISO 639-1) Language code (ISO 639-1)
  name: string;      // 语言名称 Language name
  nativeName?: string; // 本地语言名称 Native language name
  flag?: string;     // 国旗图标 Flag icon
  isDefault?: boolean; // 是否默认 Whether default
}

// 字幕轨道接口 Subtitle track interface
export interface SubtitleTrack {
  id: string;        // 轨道ID Track ID
  name: string;      // 轨道名称 Track name
  language?: string; // 语言代码 Language code
  type: SubtitleType; // 字幕类型 Subtitle type
  url?: string;      // 字幕文件URL Subtitle file URL
  localPath?: string; // 本地文件路径 Local file path
  isExternal: boolean; // 是否外部字幕 Whether external subtitle
  isAuto?: boolean;  // 是否自动生成 Whether auto-generated
  isDefault: boolean; // 是否默认轨道 Whether default track
  isForced?: boolean; // 是否强制字幕 Whether forced subtitle
  encoding?: string; // 文件编码 File encoding
  downloadUrl?: string; // 下载链接（如果与播放URL不同）Download URL (if different from playback URL)
  score?: number;    // 匹配分数 Match score
  source?: string;   // 来源 Source
  size?: number;     // 文件大小（字节）File size (bytes)
}

// 字幕条目接口 Subtitle item interface
export interface SubtitleItem {
  startTime: number; // 开始时间（秒）Start time (seconds)
  endTime: number;   // 结束时间（秒）End time (seconds)
  text: string;      // 字幕文本 Subtitle text
  htmlText?: string; // 格式化后的HTML文本 Formatted HTML text
  styles?: Record<string, string>; // 样式属性 Style properties
  speaker?: string;  // 说话人（ASS/SSA格式）Speaker (ASS/SSA format)
  index: number;     // 字幕索引 Subtitle index
}

// 字幕搜索参数接口 Subtitle search parameters interface
export interface SubtitleSearchParams {
  movieId?: string;  // 电影/视频ID Movie/Video ID
  title: string;     // 标题 Title
  year?: string;     // 年份 Year
  season?: number;   // 季数（电视剧）Season (TV series)
  episode?: number;  // 集数（电视剧）Episode (TV series)
  languages?: string[]; // 语言代码列表 Language code list
  hearingImpaired?: boolean; // 是否包含听力障碍支持 Whether to include hearing impaired support
  hash?: string;     // 视频文件哈希值 Video file hash
  fileSize?: number; // 文件大小（字节）File size (bytes)
  limit?: number;    // 限制结果数量 Limit result count
  page?: number;     // 页码 Page number
  pageSize?: number; // 每页数量 Items per page
}

// 字幕提供商标识 Subtitle provider
export enum SubtitleProvider {
  OPENSUBTITLES = 'opensubtitles',
  SUBHD = 'subhd',
  ZIMU = 'zimu',
  SHOOTER = 'shooter',
  RENZHI = 'renzhi',
  LOCAL = 'local',
  AUTO = 'auto'
}

// 字幕评分接口 Subtitle rating interface
export interface SubtitleRating {
  provider: SubtitleProvider;
  rating: number;    // 评分（0-10）Rating (0-10)
  voteCount: number; // 投票数 Vote count
  downloadCount: number; // 下载次数 Download count
  uploadDate: number; // 上传时间 Upload time
  uploader?: string; // 上传者 Uploader
}

// 字幕下载状态枚举 Subtitle download status enum
export enum SubtitleDownloadStatus {
  IDLE = 'idle',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELED = 'canceled'
}

// 字幕下载任务接口 Subtitle download task interface
export interface SubtitleDownloadTask {
  id: string;        // 任务ID Task ID
  track: SubtitleTrack; // 字幕轨道 Subtitle track
  status: SubtitleDownloadStatus; // 下载状态 Download status
  progress: number;  // 下载进度（0-100）Download progress (0-100)
  startTime: number; // 开始时间 Start time
  endTime?: number;  // 结束时间 End time
  error?: string;    // 错误信息 Error message
  localPath?: string; // 下载后的本地路径 Local path after download
}

// 字幕历史记录接口 Subtitle history interface
export interface SubtitleHistory {
  contentId: string; // 内容ID Content ID
  subtitleId: string; // 字幕ID Subtitle ID
  track: SubtitleTrack; // 字幕轨道 Subtitle track
  selectedAt: number; // 选择时间 Selection time
  duration?: number; // 观看时长 Viewing duration
  language: string; // 语言 Language
  type: SubtitleType; // 类型 Type
}

/**
 * 字幕服务类 Subtitle service class
 * 负责管理视频字幕相关功能 Responsible for managing video subtitle-related functions
 */
export default class SubtitleService {
  private static instance: SubtitleService;
  
  private subtitleStyle: SubtitleStyle = { ...DEFAULT_SUBTITLE_STYLE };
  private subtitleHistory: SubtitleHistory[] = [];
  private downloadTasks: Map<string, SubtitleDownloadTask> = new Map();
  private isInitialized: boolean = false;
  
  // 已加载的字幕缓存 Loaded subtitle cache
  private loadedSubtitles: Map<string, SubtitleItem[]> = new Map();
  
  // 支持的语言列表 Supported language list
  private supportedLanguages: SubtitleLanguage[] = [
    { code: 'zh', name: 'Chinese', nativeName: '中文', flag: '馃嚚馃嚦' },
    { code: 'en', name: 'English', nativeName: 'English', flag: '馃嚞馃嚙', isDefault: true },
    { code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '馃嚡馃嚨' },
    { code: 'ko', name: 'Korean', nativeName: '한국어', flag: '馃嚢馃嚪' },
    { code: 'fr', name: 'French', nativeName: 'Français', flag: '馃嚝馃嚪' },
    { code: 'de', name: 'German', nativeName: 'Deutsch', flag: '馃嚛馃嚜' },
    { code: 'es', name: 'Spanish', nativeName: 'Español', flag: '馃嚜馃嚫' },
    { code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '馃嚪馃嚭' },
    { code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '馃嚨馃嚬' },
    { code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '馃嚠馃嚬' },
    { code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '馃嚫馃嚘' },
    { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '馃嚠馃嚦' },
    { code: 'th', name: 'Thai', nativeName: 'ไทย', flag: '馃嚬馃嚟' },
    { code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '馃嚮馃嚦' },
    { code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu', flag: '馃嚥馃嚲' },
    { code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '馃嚠馃嚛' },
    { code: 'tl', name: 'Tagalog', nativeName: 'Tagalog', flag: '馃嚨馃嚟' }
  ];
  
  // 监听器 Listeners
  private styleListeners: Array<(style: SubtitleStyle) => void> = [];
  private downloadListeners: Map<string, Array<(task: SubtitleDownloadTask) => void>> = new Map();
  private parseListeners: Map<string, Array<(subtitles: SubtitleItem[], error?: string) => void>> = new Map();

  /**
   * 构造函数（私有，防止外部实例化）Constructor (private, prevent external instantiation)
   */
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): SubtitleService {
    if (!SubtitleService.instance) {
      SubtitleService.instance = new SubtitleService();
    }
    return SubtitleService.instance;
  }

  /**
   * 初始化字幕服务 Initialize subtitle service
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing subtitle service...');
      
      // 创建字幕缓存目录 Create subtitle cache directory
      await FileUtil.ensureDirectory(SUBTITLE_CACHE_DIR);
      await FileUtil.ensureDirectory(USER_SUBTITLE_DIR);
      
      // 加载字幕样式设置 Load subtitle style settings
      const savedStyle = await StorageUtil.getObject<SubtitleStyle>(SUBTITLE_STYLE_KEY);
      if (savedStyle) {
        this.subtitleStyle = { ...DEFAULT_SUBTITLE_STYLE, ...savedStyle };
      }
      
      // 加载字幕历史记录 Load subtitle history
      const savedHistory = await StorageUtil.getObject<SubtitleHistory[]>(SUBTITLE_HISTORY_KEY);
      if (savedHistory) {
        this.subtitleHistory = savedHistory;
        // 只保留最近100条记录 Only keep latest 100 records
        if (this.subtitleHistory.length > 100) {
          this.subtitleHistory = this.subtitleHistory.slice(-100);
        }
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Subtitle service initialized successfully');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to initialize subtitle service', errorObj);
    }
  }

  /**
   * 保存字幕样式设置 Save subtitle style settings
   */
  private async saveSubtitleStyle(): Promise<void> {
    try {
      await StorageUtil.setObject(SUBTITLE_STYLE_KEY, this.subtitleStyle);
      Logger.debug(TAG, 'Saved subtitle style settings');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to save subtitle style settings', errorObj);
    }
  }

  /**
   * 保存字幕历史记录 Save subtitle history
   */
  private async saveSubtitleHistory(): Promise<void> {
    try {
      await StorageUtil.setObject(SUBTITLE_HISTORY_KEY, this.subtitleHistory);
      Logger.debug(TAG, 'Saved subtitle history');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to save subtitle history', errorObj);
    }
  }

  /**
   * 设置字幕样式 Set subtitle style
   */
  public async setSubtitleStyle(style: Partial<SubtitleStyle>): Promise<SubtitleStyle> {
    try {
      // 更新字幕样式 Update subtitle style
      this.subtitleStyle = {
        ...this.subtitleStyle,
        ...style
      };
      
      // 保存样式 Save style
      await this.saveSubtitleStyle();
      
      // 通知监听器 Notify listeners
      this.notifyStyleChanged();
      
      Logger.info(TAG, 'Updated subtitle style');
      return { ...this.subtitleStyle };
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to update subtitle style', errorObj);
      return { ...this.subtitleStyle };
    }
  }

  /**
   * 获取字幕样式 Get subtitle style
   */
  public getSubtitleStyle(): SubtitleStyle {
    return { ...this.subtitleStyle };
  }

  /**
   * 重置字幕样式为默认值 Reset subtitle style to default
   */
  public async resetSubtitleStyle(): Promise<SubtitleStyle> {
    try {
      this.subtitleStyle = { ...DEFAULT_SUBTITLE_STYLE };
      
      // 保存样式 Save style
      await this.saveSubtitleStyle();
      
      // 通知监听器 Notify listeners
      this.notifyStyleChanged();
      
      Logger.info(TAG, 'Reset subtitle style to default');
      return { ...this.subtitleStyle };
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to reset subtitle style', errorObj);
      return { ...this.subtitleStyle };
    }
  }

  /**
   * 解析字幕文件 Parse subtitle file
   */
  public async parseSubtitle(
    track: SubtitleTrack,
    onProgress?: (progress: number) => void
  ): Promise<ApiResponse<SubtitleItem[]>> {
    try {
      // 检查缓存 Check cache
      const cacheKey = track.url || track.localPath || track.id;
      if (cacheKey && this.loadedSubtitles.has(cacheKey)) {
        Logger.debug(TAG, `Returning parsed subtitles from cache: ${cacheKey}`);
        return ApiResponse.success(this.loadedSubtitles.get(cacheKey)!, '字幕解析成功（缓存）');
      }
      
      // 通知解析开始 Notify parse start
      this.notifyParseStart(track.id);
      
      let subtitleContent: string;
      
      // 获取字幕内容 Get subtitle content
      if (track.localPath) {
        // 从本地文件读取 Read from local file
        Logger.debug(TAG, `Reading subtitle from local file: ${track.localPath}`);
        subtitleContent = await FileUtil.readFile(track.localPath, track.encoding || 'utf-8');
      } else if (track.url) {
        // 从URL下载 Download from URL
        Logger.debug(TAG, `Downloading subtitle from URL: ${track.url}`);
        const response = await NetworkUtil.downloadText(track.url, {
          encoding: track.encoding || 'utf-8',
          onProgress: (progress) => {
            if (onProgress) {
              onProgress(progress);
            }
          }
        });
        
        if (!response.success) {
          return ApiResponse.error(ResponseCode.NETWORK_ERROR, `下载字幕失败: ${response.error}`);
        }
        
        subtitleContent = response.data;
      } else {
        return ApiResponse.error(ResponseCode.INVALID_PARAMETER, '字幕文件路径或URL不能为空');
      }
      
      // 根据字幕类型解析 Parse according to subtitle type
      let subtitles: SubtitleItem[] = [];
      
      switch (track.type) {
        case SubtitleType.SRT:
          subtitles = this.parseSRT(subtitleContent);
          break;
        case SubtitleType.VTT:
          subtitles = this.parseVTT(subtitleContent);
          break;
        case SubtitleType.ASS:
        case SubtitleType.SSA:
          subtitles = this.parseASS(subtitleContent, track.type);
          break;
        case SubtitleType.TTML:
        case SubtitleType.DFXP:
          subtitles = this.parseTTML(subtitleContent);
          break;
        case SubtitleType.SBV:
          subtitles = this.parseSBV(subtitleContent);
          break;
        case SubtitleType.LRC:
          subtitles = this.parseLRC(subtitleContent);
          break;
        default:
          // 尝试自动检测格式 Try to auto-detect format
          if (subtitleContent.includes('WEBVTT')) {
            subtitles = this.parseVTT(subtitleContent);
          } else if (/(\d+)\s*\r?\n(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})/.test(subtitleContent)) {
            subtitles = this.parseSRT(subtitleContent);
          } else {
            return ApiResponse.error(ResponseCode.UNSUPPORTED_FORMAT, '不支持的字幕格式');
          }
      }
      
      // 缓存解析结果 Cache parse result
      if (cacheKey) {
        this.loadedSubtitles.set(cacheKey, subtitles);
      }
      
      // 通知解析完成 Notify parse complete
      this.notifyParseComplete(track.id, subtitles);
      
      Logger.info(TAG, `Successfully parsed ${subtitles.length} subtitles`);
      return ApiResponse.success(subtitles, '字幕解析成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to parse subtitle track: ${track.id}`, errorObj);
      
      // 通知解析错误 Notify parse error
      this.notifyParseError(track.id, String(error));
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `字幕解析失败: ${String(error)}`);
    }
  }

  /**
   * 解析SRT格式字幕 Parse SRT format subtitles
   */
  private parseSRT(content: string): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    // 分割字幕块 Split subtitle blocks
    const blocks = content.trim().split(/\r?\n\s*\r?\n/);
    
    blocks.forEach(block => {
      try {
        // 匹配时间戳和文本 Match timestamp and text
        const match = block.match(/(\d+)\s*\r?\n(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*\r?\n([\s\S]*)/);
        
        if (match) {
          // 解析时间戳 Parse timestamp
          const startTime = this.parseTime(match[2], match[3], match[4], match[5]);
          const endTime = this.parseTime(match[6], match[7], match[8], match[9]);
          
          // 解析文本（移除格式标记并处理换行）Parse text (remove format markers and handle newlines)
          let text = match[10].trim();
          // 替换HTML标签（保留简单的格式）Replace HTML tags (keep simple format)
          text = text.replace(/<\/?[ibu]>/g, '');
          text = text.replace(/<font[^>]*>/g, '');
          text = text.replace(/<\/font>/g, '');
          
          // 处理多行文本 Handle multi-line text
          text = text.replace(/\r?\n/g, '\n');
          
          // 创建字幕条目 Create subtitle item
          subtitles.push({
            startTime,
            endTime,
            text,
            htmlText: text.replace(/\n/g, '<br>'), // 转换为HTML格式 Convert to HTML format
            index: parseInt(match[1]) - 1
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to parse SRT block', error);
      }
    });
    
    // 按序号排序 Sort by index
    return subtitles.sort((a, b) => a.index - b.index);
  }

  /**
   * 解析VTT格式字幕 Parse VTT format subtitles
   */
  private parseVTT(content: string): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    // 移除WEBVTT头部 Remove WEBVTT header
    let cleanContent = content.replace(/^WEBVTT[\s\S]*?(?:\r?\n\r?\n|\Z)/, '');
    
    // 分割字幕块 Split subtitle blocks
    const blocks = cleanContent.trim().split(/\r?\n\s*\r?\n/);
    
    blocks.forEach((block, index) => {
      try {
        // 匹配时间戳和文本 Match timestamp and text
        const match = block.match(/^(?:[^\r\n]*\r?\n)?(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})(?:[^\r\n]*)\r?\n([\s\S]*)/);
        
        if (match) {
          // 解析时间戳 Parse timestamp
          const startTime = this.parseTime(match[1], match[2], match[3], match[4]);
          const endTime = this.parseTime(match[5], match[6], match[7], match[8]);
          
          // 解析文本 Parse text
          let text = match[9].trim();
          // 移除注释和格式标记 Remove comments and format markers
          text = text.replace(/<c[^>]*>/g, '');
          text = text.replace(/<\/c>/g, '');
          text = text.replace(/<\/?[ibu]>/g, '');
          text = text.replace(/<font[^>]*>/g, '');
          text = text.replace(/<\/font>/g, '');
          text = text.replace(/<u[^>]*>/g, '');
          text = text.replace(/<\/u>/g, '');
          text = text.replace(/<[^>]*>/g, ''); // 移除其他标签 Remove other tags
          
          // 处理多行文本 Handle multi-line text
          text = text.replace(/\r?\n/g, '\n');
          
          // 创建字幕条目 Create subtitle item
          subtitles.push({
            startTime,
            endTime,
            text,
            htmlText: text.replace(/\n/g, '<br>'),
            index
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to parse VTT block', error);
      }
    });
    
    return subtitles;
  }

  /**
   * 解析ASS/SSA格式字幕 Parse ASS/SSA format subtitles
   */
  private parseASS(content: string, type: SubtitleType): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    // 提取脚本信息和样式 Extract script information and styles
    const eventsMatch = content.match(/\[Events\][\s\S]*?(?=\[|$)/);
    
    if (eventsMatch) {
      const events = eventsMatch[0];
      // 提取对话行 Extract dialogue lines
      const dialogueLines = events.match(/^Dialogue:\s*.*/gm) || [];
      
      dialogueLines.forEach((line, index) => {
        try {
          // 分割对话行 Split dialogue line
          const parts = line.split(',');
          
          if (parts.length >= 10) {
            // 解析时间 Parse time
            const startTimeText = parts[1];
            const endTimeText = parts[2];
            
            const startTime = this.parseASSTime(startTimeText);
            const endTime = this.parseASSTime(endTimeText);
            
            // 获取说话人 Get speaker
            const speaker = parts[3];
            
            // 合并文本部分（ASS格式的文本可能包含逗号）Merge text parts (ASS format text may contain commas)
            const textParts = parts.slice(9);
            let text = textParts.join(',');
            
            // 移除ASS格式标签 Remove ASS format tags
            text = text.replace(/\{[^}]*\}/g, '');
            text = text.replace(/\\[Nn]/g, '\n');
            
            // 创建字幕条目 Create subtitle item
            subtitles.push({
              startTime,
              endTime,
              text: text.trim(),
              htmlText: text.trim().replace(/\n/g, '<br>'),
              speaker,
              index
            });
          }
        } catch (error) {
          Logger.warn(TAG, 'Failed to parse ASS/SSA dialogue line', error);
        }
      });
    }
    
    return subtitles;
  }

  /**
   * 解析TTML格式字幕 Parse TTML format subtitles
   */
  private parseTTML(content: string): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    try {
      // 使用正则表达式提取字幕信息 Extract subtitle information using regex
      const textElements = content.match(/<p\s[^>]*begin="([^"]*)"[^>]*end="([^"]*)"[^>]*>([\s\S]*?)<\/p>/g) || [];
      
      textElements.forEach((element, index) => {
        try {
          const beginMatch = element.match(/begin="([^"]*)"/);
          const endMatch = element.match(/end="([^"]*)"/);
          const textMatch = element.match(/<p[^>]*>([\s\S]*?)<\/p>/);
          
          if (beginMatch && endMatch && textMatch) {
            const startTime = this.parseTTMLTime(beginMatch[1]);
            const endTime = this.parseTTMLTime(endMatch[1]);
            
            // 提取文本并移除标记 Extract text and remove markers
            let text = textMatch[1];
            text = text.replace(/<[^>]*>/g, '');
            text = text.replace(/&lt;/g, '<');
            text = text.replace(/&gt;/g, '>');
            text = text.replace(/&amp;/g, '&');
            text = text.replace(/&quot;/g, '"');
            text = text.replace(/&#39;/g, '\'');
            text = text.replace(/\s+/g, ' ').trim();
            
            if (text) {
              subtitles.push({
                startTime,
                endTime,
                text,
                htmlText: text.replace(/\n/g, '<br>'),
                index
              });
            }
          }
        } catch (error) {
          Logger.warn(TAG, 'Failed to parse TTML element', error);
        }
      });
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to parse TTML content', errorObj);
    }
    
    return subtitles;
  }

  /**
   * 解析SBV格式字幕 Parse SBV format subtitles
   */
  private parseSBV(content: string): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    // 分割字幕块 Split subtitle blocks
    const blocks = content.trim().split(/\r?\n\s*\r?\n/);
    
    blocks.forEach((block, index) => {
      try {
        // 匹配时间戳和文本 Match timestamp and text
        const match = block.match(/(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*,\s*(\d{2}):(\d{2}):(\d{2})\.(\d{3})\s*\r?\n([\s\S]*)/);
        
        if (match) {
          // 解析时间戳 Parse timestamp
          const startTime = this.parseTime(match[1], match[2], match[3], match[4]);
          const endTime = this.parseTime(match[5], match[6], match[7], match[8]);
          
          // 解析文本 Parse text
          let text = match[9].trim();
          text = text.replace(/\r?\n/g, '\n');
          
          // 创建字幕条目 Create subtitle item
          subtitles.push({
            startTime,
            endTime,
            text,
            htmlText: text.replace(/\n/g, '<br>'),
            index
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to parse SBV block', error);
      }
    });
    
    return subtitles;
  }

  /**
   * 解析LRC格式歌词 Parse LRC format lyrics
   */
  private parseLRC(content: string): SubtitleItem[] {
    const subtitles: SubtitleItem[] = [];
    
    // 提取时间标记行 Extract time tag lines
    const timeLines = content.match(/\[\d{2}:\d{2}\.\d{2}\].*/g) || [];
    
    timeLines.forEach((line, index) => {
      try {
        // 提取所有时间标记 Extract all time tags
        const timeTags = line.match(/\[(\d{2}):(\d{2})\.(\d{2})\]/g) || [];
        const text = line.replace(/\[(\d{2}:\d{2}\.\d{2})\]/g, '').trim();
        
        timeTags.forEach(tag => {
          const match = tag.match(/\[(\d{2}):(\d{2})\.(\d{2})\]/);
          if (match) {
            const minutes = parseInt(match[1]);
            const seconds = parseInt(match[2]);
            const milliseconds = parseInt(match[3]) * 10; // LRC通常使用10ms精度 LRC usually uses 10ms precision
            
            const startTime = minutes * 60 + seconds + milliseconds / 1000;
            
            // LRC没有结束时间，假设为2秒 LRC has no end time, assume 2 seconds
            const endTime = startTime + 2;
            
            if (text) {
              subtitles.push({
                startTime,
                endTime,
                text,
                htmlText: text,
                index
              });
            }
          }
        });
      } catch (error) {
        Logger.warn(TAG, 'Failed to parse LRC line', error);
      }
    });
    
    // 按时间排序 Sort by time
    return subtitles.sort((a, b) => a.startTime - b.startTime);
  }

  /**
   * 解析时间格式（HH:MM:SS,mmm 或 HH:MM:SS.mmm）Parse time format (HH:MM:SS,mmm or HH:MM:SS.mmm)
   */
  private parseTime(hours: string, minutes: string, seconds: string, milliseconds: string): number {
    const h = parseInt(hours);
    const m = parseInt(minutes);
    const s = parseInt(seconds);
    const ms = parseInt(milliseconds);
    
    return h * 3600 + m * 60 + s + ms / 1000;
  }

  /**
   * 解析ASS/SSA时间格式 Parse ASS/SSA time format
   */
  private parseASSTime(timeText: string): number {
    const match = timeText.match(/(\d+):(\d+):(\d+)\.(\d+)/);
    if (match) {
      const h = parseInt(match[1]);
      const m = parseInt(match[2]);
      const s = parseInt(match[3]);
      const cs = parseInt(match[4]); // 厘秒 Centiseconds
      
      return h * 3600 + m * 60 + s + cs / 100;
    }
    return 0;
  }

  /**
   * 解析TTML时间格式 Parse TTML time format
   */
  private parseTTMLTime(timeText: string): number {
    // 处理小时:分钟:秒.毫秒 格式 Handle hour:minute:second.millisecond format
    const fullMatch = timeText.match(/^(\d+):(\d+):(\d+(?:\.\d+)?)$/);
    if (fullMatch) {
      const h = parseInt(fullMatch[1]);
      const m = parseInt(fullMatch[2]);
      const s = parseFloat(fullMatch[3]);
      
      return h * 3600 + m * 60 + s;
    }
    
    // 处理分钟:秒.毫秒 格式 Handle minute:second.millisecond format
    const shortMatch = timeText.match(/^(\d+):(\d+(?:\.\d+)?)$/);
    if (shortMatch) {
      const m = parseInt(shortMatch[1]);
      const s = parseFloat(shortMatch[2]);
      
      return m * 60 + s;
    }
    
    return 0;
  }

  /**
   * 下载字幕文件 Download subtitle file
   */
  public async downloadSubtitle(
    track: SubtitleTrack,
    onProgress?: (task: SubtitleDownloadTask) => void
  ): Promise<ApiResponse<SubtitleDownloadTask>> {
    try {
      if (!track.url && !track.downloadUrl) {
        return ApiResponse.error(ResponseCode.INVALID_PARAMETER, '字幕下载URL不能为空');
      }
      
      // 创建下载任务 Create download task
      const task: SubtitleDownloadTask = {
        id: `download_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        track,
        status: SubtitleDownloadStatus.IDLE,
        progress: 0,
        startTime: Date.now()
      };
      
      // 添加到任务列表 Add to task list
      this.downloadTasks.set(task.id, task);
      
      // 生成保存路径 Generate save path
      const fileName = `${track.id}_${Date.now()}.${track.type}`;
      const savePath = `${SUBTITLE_CACHE_DIR}/${fileName}`;
      
      // 更新任务状态 Update task status
      task.status = SubtitleDownloadStatus.DOWNLOADING;
      this.updateDownloadTask(task);
      if (onProgress) {
        onProgress({ ...task });
      }
      
      // 下载文件 Download file
      const downloadUrl = track.downloadUrl || track.url!;
      const response = await NetworkUtil.downloadFile(downloadUrl, savePath, {
        onProgress: (progress) => {
          task.progress = progress;
          this.updateDownloadTask(task);
          if (onProgress) {
            onProgress({ ...task });
          }
        }
      });
      
      if (response.success) {
        // 更新任务状态 Update task status
        task.status = SubtitleDownloadStatus.COMPLETED;
        task.progress = 100;
        task.endTime = Date.now();
        task.localPath = savePath;
        
        this.updateDownloadTask(task);
        
        // 删除任务（可选，保留一段时间以便查询）Delete task (optional, keep for a while for querying)
        setTimeout(() => {
          this.downloadTasks.delete(task.id);
        }, 300000); // 5分钟后删除 Delete after 5 minutes
        
        Logger.info(TAG, `Successfully downloaded subtitle: ${track.name} to ${savePath}`);
        return ApiResponse.success({ ...task }, '字幕下载成功');
      } else {
        // 更新任务状态 Update task status
        task.status = SubtitleDownloadStatus.FAILED;
        task.error = response.error;
        task.endTime = Date.now();
        
        this.updateDownloadTask(task);
        
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, `字幕下载失败: ${response.error}`);
      }
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to download subtitle: ${track.name}`, errorObj);
      
      // 如果有任务，更新状态 If there is a task, update status
      for (const [, task] of this.downloadTasks) {
        if (task.track.id === track.id && task.status === SubtitleDownloadStatus.DOWNLOADING) {
          task.status = SubtitleDownloadStatus.FAILED;
          task.error = String(error);
          task.endTime = Date.now();
          this.updateDownloadTask(task);
          break;
        }
      }
      
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `字幕下载失败: ${String(error)}`);
    }
  }

  /**
   * 取消字幕下载 Cancel subtitle download
   */
  public async cancelDownload(taskId: string): Promise<ApiResponse<boolean>> {
    try {
      const task = this.downloadTasks.get(taskId);
      if (!task) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存在');
      }
      
      if (task.status !== SubtitleDownloadStatus.DOWNLOADING) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '任务不在下载中');
      }
      
      // 更新任务状态 Update task status
      task.status = SubtitleDownloadStatus.CANCELED;
      task.endTime = Date.now();
      
      this.updateDownloadTask(task);
      
      // 删除任务 Delete task
      setTimeout(() => {
        this.downloadTasks.delete(taskId);
      }, 5000);
      
      Logger.info(TAG, `Canceled subtitle download task: ${taskId}`);
      return ApiResponse.success(true, '取消下载成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to cancel download task: ${taskId}`, errorObj);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '取消下载失败');
    }
  }

  /**
   * 获取所有下载任务 Get all download tasks
   */
  public getDownloadTasks(): SubtitleDownloadTask[] {
    return Array.from(this.downloadTasks.values());
  }

  /**
   * 获取下载任务 Get download task
   */
  public getDownloadTask(taskId: string): SubtitleDownloadTask | undefined {
    return this.downloadTasks.get(taskId);
  }

  /**
   * 更新下载任务状态 Update download task status
   */
  private updateDownloadTask(task: SubtitleDownloadTask): void {
    this.downloadTasks.set(task.id, { ...task });
    this.notifyDownloadTaskChanged(task);
  }

  /**
   * 搜索字幕 Search subtitles
   */
  public async searchSubtitles(
    params: SubtitleSearchParams,
    providers?: SubtitleProvider[]
  ): Promise<ApiResponse<Map<SubtitleProvider, SubtitleTrack[]>>> {
    try {
      const results = new Map<SubtitleProvider, SubtitleTrack[]>();
      
      // 这里应该调用各个字幕提供商的API
      // 为了演示，我们返回模拟数据
      // Here should call APIs of various subtitle providers
      // For demonstration, we return mock data
      
      // 模拟OpenSubtitles结果 Mock OpenSubtitles results
      results.set(SubtitleProvider.OPENSUBTITLES, [
        {
          id: 'opensub_1',
          name: 'English (US)',
          language: 'en',
          type: SubtitleType.SRT,
          url: 'https://example.com/subtitles/en.srt',
          isExternal: true,
          isDefault: true
        },
        {
          id: 'opensub_2',
          name: '简体中文',
          language: 'zh',
          type: SubtitleType.SRT,
          url: 'https://example.com/subtitles/zh.srt',
          isExternal: true,
          isDefault: false
        }
      ]);
      
      // 模拟SubHD结果 Mock SubHD results
      results.set(SubtitleProvider.SUBHD, [
        {
          id: 'subhd_1',
          name: '简体中文字幕',
          language: 'zh',
          type: SubtitleType.ASS,
          url: 'https://example.com/subtitles/subhd.ass',
          isExternal: true,
          isDefault: false
        }
      ]);
      
      Logger.info(TAG, `Search subtitles completed for: ${params.title}`);
      return ApiResponse.success(results, '字幕搜索成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to search subtitles', errorObj);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '字幕搜索失败');
    }
  }

  /**
   * 添加字幕到历史记录 Add subtitle to history
   */
  public async addToHistory(
    contentId: string,
    track: SubtitleTrack,
    duration?: number
  ): Promise<void> {
    try {
      const historyItem: SubtitleHistory = {
        contentId,
        subtitleId: track.id,
        track,
        selectedAt: Date.now(),
        duration,
        language: track.language || '',
        type: track.type
      };
      
      // 添加到历史记录（移除旧的相同项目）Add to history (remove old same items)
      this.subtitleHistory = this.subtitleHistory.filter(
        item => !(item.contentId === contentId && item.subtitleId === track.id)
      );
      
      // 添加到开头 Add to beginning
      this.subtitleHistory.unshift(historyItem);
      
      // 限制历史记录数量 Limit history record count
      if (this.subtitleHistory.length > 100) {
        this.subtitleHistory = this.subtitleHistory.slice(0, 100);
      }
      
      // 保存历史记录 Save history
      await this.saveSubtitleHistory();
      
      Logger.debug(TAG, `Added subtitle to history: ${track.name}`);
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to add subtitle to history', errorObj);
    }
  }

  /**
   * 获取历史记录 Get history
   */
  public getHistory(limit: number = 50): SubtitleHistory[] {
    return this.subtitleHistory.slice(0, limit);
  }

  /**
   * 获取内容的字幕历史 Get content's subtitle history
   */
  public getContentHistory(contentId: string): SubtitleHistory[] {
    return this.subtitleHistory.filter(item => item.contentId === contentId);
  }

  /**
   * 清除字幕历史记录 Clear subtitle history
   */
  public async clearHistory(): Promise<void> {
    try {
      this.subtitleHistory = [];
      await this.saveSubtitleHistory();
      Logger.info(TAG, 'Cleared subtitle history');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to clear subtitle history', errorObj);
    }
  }

  /**
   * 获取支持的语言列表 Get supported language list
   */
  public getSupportedLanguages(): SubtitleLanguage[] {
    return [...this.supportedLanguages];
  }

  /**
   * 根据语言代码获取语言信息 Get language information by language code
   */
  public getLanguageByCode(code: string): SubtitleLanguage | undefined {
    return this.supportedLanguages.find(lang => lang.code === code);
  }

  /**
   * 加载本地字幕文件 Load local subtitle file
   */
  public async loadLocalSubtitle(filePath: string): Promise<ApiResponse<SubtitleTrack>> {
    try {
      // 检查文件是否存在 Check if file exists
      const exists = await FileUtil.fileExists(filePath);
      if (!exists) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '字幕文件不存在');
      }
      
      // 获取文件扩展名 Get file extension
      const extension = FileUtil.getExtension(filePath).toLowerCase();
      
      // 确定字幕类型 Determine subtitle type
      let type: SubtitleType;
      switch (extension) {
        case 'srt':
          type = SubtitleType.SRT;
          break;
        case 'vtt':
          type = SubtitleType.VTT;
          break;
        case 'ass':
          type = SubtitleType.ASS;
          break;
        case 'ssa':
          type = SubtitleType.SSA;
          break;
        case 'ttml':
          type = SubtitleType.TTML;
          break;
        case 'dfxp':
          type = SubtitleType.DFXP;
          break;
        case 'sbv':
          type = SubtitleType.SBV;
          break;
        case 'lrc':
          type = SubtitleType.LRC;
          break;
        default:
          type = SubtitleType.UNKNOWN;
      }
      
      // 获取文件名作为标题 Get file name as title
      const fileName = FileUtil.getFileName(filePath);
      
      // 创建字幕轨道 Create subtitle track
      const track: SubtitleTrack = {
        id: `local_${Date.now()}`,
        name: fileName,
        language: 'unknown',
        type,
        localPath: filePath,
        isExternal: true,
        isDefault: false
      };
      
      // 尝试解析字幕以验证 Try to parse subtitle to verify
      const parseResult = await this.parseSubtitle(track);
      if (!parseResult.isSuccess()) {
        return ApiResponse.error(parseResult.code, `字幕文件格式无效: ${parseResult.message}`);
      }
      
      Logger.info(TAG, `Loaded local subtitle file: ${filePath}`);
      return ApiResponse.success(track, '加载本地字幕成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to load local subtitle file: ${filePath}`, errorObj);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, `加载本地字幕失败: ${String(error)}`);
    }
  }

  /**
   * 生成字幕预览（用于选择字幕）Generate subtitle preview (for selecting subtitles)
   */
  public async generateSubtitlePreview(
    track: SubtitleTrack,
    time: number,
    duration: number = 30
  ): Promise<ApiResponse<string>> {
    try {
      // 解析字幕 Parse subtitle
      const parseResult = await this.parseSubtitle(track);
      if (!parseResult.isSuccess() || !parseResult.data) {
        return ApiResponse.error(parseResult.code, parseResult.message || '字幕解析失败');
      }
      
      // 获取指定时间范围内的字幕 Get subtitles within specified time range
      const previewSubtitles = parseResult.data.filter(
        sub => sub.startTime >= time && sub.startTime <= time + duration
      ).slice(0, 10); // 最多10条 Max 10 items
      
      // 生成预览文本 Generate preview text
      const preview = previewSubtitles.map(sub => {
        const startTimeFormatted = this.formatTime(sub.startTime);
        return `[${startTimeFormatted}] ${sub.text}`;
      }).join('\n\n');
      
      return ApiResponse.success(preview, '生成字幕预览成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, `Failed to generate subtitle preview: ${track.id}`, errorObj);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '生成字幕预览失败');
    }
  }

  /**
   * 格式化时间为HH:MM:SS,mmm格式 Format time to HH:MM:SS,mmm format
   */
  private formatTime(seconds: number): string {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    const ms = Math.floor((seconds % 1) * 1000);
    
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')},${ms.toString().padStart(3, '0')}`;
  }

  /**
   * 清除字幕缓存 Clear subtitle cache
   */
  public async clearCache(): Promise<ApiResponse<boolean>> {
    try {
      // 清除内存缓存 Clear memory cache
      this.loadedSubtitles.clear();
      
      // 清除下载任务 Clear download tasks
      this.downloadTasks.clear();
      
      // 删除缓存文件 Delete cache files
      await FileUtil.deleteDirectory(SUBTITLE_CACHE_DIR);
      await FileUtil.ensureDirectory(SUBTITLE_CACHE_DIR);
      
      Logger.info(TAG, 'Cleared subtitle cache');
      return ApiResponse.success(true, '清除字幕缓存成功');
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      Logger.error(TAG, 'Failed to clear subtitle cache', errorObj);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '清除字幕缓存失败');
    }
  }

  /**
   * 通知样式变更 Notify style change
   */
  private notifyStyleChanged(): void {
    for (const listener of this.styleListeners) {
      try {
        listener({ ...this.subtitleStyle });
      } catch (error) {
        const errorObj = error instanceof Error ? error : new Error(String(error));
        Logger.error(TAG, 'Error in style listener', errorObj);
      }
    }
  }

  /**
   * 通知下载任务变更 Notify download task change
   */
  private notifyDownloadTaskChanged(task: SubtitleDownloadTask): void {
    if (!this.downloadListeners.has(task.id)) return;
    
    const listeners = this.downloadListeners.get(task.id)!;
    for (const listener of listeners) {
      try {
        listener({ ...task });
      } catch (error) {
        const errorObj = error instanceof Error ? error : new Error(String(error));
        Logger.error(TAG, `Error in download listener for task ${task.id}`, errorObj);
      }
    }
  }

  /**
   * 通知解析开始 Notify parse start
   */
  private notifyParseStart(trackId: string): void {
    if (!this.parseListeners.has(trackId)) return;
    
    const listeners = this.parseListeners.get(trackId)!;
    for (const listener of listeners) {
      try {
        listener([]);
      } catch (error) {
        const errorObj = error instanceof Error ? error : new Error(String(error));
        Logger.error(TAG, `Error in parse listener for track ${trackId}`, errorObj);
      }
    }
  }

  /**
   * 通知解析完成 Notify parse complete
   */
  private notifyParseComplete(trackId: string, subtitles: SubtitleItem[]): void {
    if (!this.parseListeners.has(trackId)) return;
    
    const listeners = this.parseListeners.get(trackId)!;
    for (const listener of listeners) {
      try {
        listener(subtitles);
      } catch (error) {
        const errorObj = error instanceof Error ? error : new Error(String(error));
        Logger.error(TAG, `Error in parse listener for track ${trackId}`, errorObj);
      }
    }
  }

  /**
   * 通知解析错误 Notify parse error
   */
  private notifyParseError(trackId: string, error: string): void {
    if (!this.parseListeners.has(trackId)) return;
    
    const listeners = this.parseListeners.get(trackId)!;
    for (const listener of listeners) {
      try {
        listener([], error);
      } catch (err) {
        const errorObj = err instanceof Error ? err : new Error(String(err));
        Logger.error(TAG, `Error in parse listener for track ${trackId}`, errorObj);
      }
    }
  }
}
