# RayTV NAS服务集成开发方案 V2

## 1. 需求概述

### 1.1 核心需求
1. 增加对局域网内NAS服务的识别和访问，尤其支持华为家庭存储
2. 对NAS设备中视频（影片）的目录浏览、索引建立
3. NAS设备属于一个线路（网络源），多个NAS设备应作为独立的网络源并列存在
4. 选择NAS作为源时，首页展示时做相应的目录作为分类进行列表
5. 对NAS内容支持播放，并可以很好地控制
6. 支持NAS设备的自动识别和手动添加（通过IP+端口形式）

### 1.2 关键特性
- 局域网设备自动发现
- **多品牌协议优化**：华为HiLink、极空间ZSpace、小米Mi Home优先实现
- **专业NAS优化**：群晖DSM、绿联UGREEN、威联通QTS专门优化
- 目录层级浏览
- 视频文件索引建立
- 与现有网络源架构集成
- 统一的播放控制
- 多NAS设备并列管理
- 支持手动添加NAS设备（IP+端口形式）
- 设备命名和识别

---

## 2. 中国NAS市场优化策略

### 2.1 品牌优先级矩阵

| 优先级 | 品牌 | 协议 | 优化重点 | 市场地位 |
|-------|------|------|---------|---------|
| P0 | 华为家庭存储 | HiLink | HarmonyOS生态、视频优化 | 中国第一 |
| P0 | 极空间NAS | ZSpace | 极影视、AI相册、内网穿透 | 国产专业NAS领导者 |
| P0 | 小米NAS | Mi Home | 米家生态、智能家居联动 | 米家生态用户多 |
| P1 | 群晖NAS | SMB/DLNA | Video Station、SMB 3.1 | 全球领导者 |
| P1 | 绿联NAS | UGreen | UGREEN OS、视频转码 | 性价比之王 |
| P1 | 威联通NAS | SMB/DLNA | QuVideo、硬件转码 | 专业用户多 |

### 2.2 协议优化路线图

#### 第一阶段：核心协议支持（P0）
1. **SMB/CIFS 3.1协议** - 通用协议，所有NAS支持
2. **DLNA/UPnP协议** - 媒体协议，视频播放标准
3. **WebDAV协议** - 远程访问，跨平台支持
4. **华为HiLink协议** - 华为独家，最高优先级
5. **极空间ZSpace协议** - 专业NAS，高优先级
6. **小米Mi Home协议** - 米家生态，高优先级

#### 第二阶段：品牌深度优化（P1）
1. **群晖DSM优化** - Video Station集成
2. **绿联UGREEN优化** - 视频转码优化
3. **威联通QTS优化** - QuVideo集成

---

## 3. 技术架构设计

### 3.1 整体架构（更新版）

```
┌─────────────────────────────────────────────────────────────┐
│                     RayTV 应用层                              │
├─────────────────────────────────────────────────────────────┤
│  HomePage      │  MediaDetailPage  │  LivePage  │  Settings │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   ContentAccessService                       │
│              (统一内容访问服务 - 已存在)                        │
├─────────────────────────────────────────────────────────────┤
│  SourcePoolManager  │  NetworkSourceManager                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   NAS 服务层 (新增)                           │
├─────────────────────────────────────────────────────────────┤
│  NASDiscoveryService  │  NASFileService  │  NASIndexService │
│  设备发现              │  文件访问          │  索引管理        │
├─────────────────────────────────────────────────────────────┤
│        品牌适配器层 (新增)                                    │
├─────────────────────────────────────────────────────────────┤
│ HuaweiAdapter│ZSpaceAdapter│MiHomeAdapter│SynologyAdapter  │
│ 华为HiLink    │ 极空间协议   │ 小米Mi Home │ 群晖DSM优化     │
│ UGreenAdapter │ QNAPAdapter  │ GenericAdapter                │
│ 绿联优化      │ 威联通优化    │ 通用SMB适配   │
├─────────────────────────────────────────────────────────────┤
│              协议适配器层 (新增)                              │
├─────────────────────────────────────────────────────────────┤
│  SMBAdapter│DLNAAdapter│WebDAVAdapter│NFSAdapter            │
│  SMB 3.1   │ UPnP       │ HTTP扩展    │ NFSv4               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   网络层                                     │
├─────────────────────────────────────────────────────────────┤
│  HTTP/HTTPS  │  Socket  │  mDNS/Bonjour  │  SSDP              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   NAS 设备 (局域网)                           │
│  华为家庭存储 │ 极空间 │ 小米 │ 群晖 │ 绿联 │ 威联通 │ 其他   │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. 品牌适配器详细设计

### 4.1 华为家庭存储适配器（P0 - 最高优先级）

#### 4.1.1 适配器接口

```typescript
/**
 * 华为家庭存储适配器
 * 优先级：P0（最高）
 * 协议：HiLink（华为私有）+ SMB + DLNA
 */
export class HuaweiStorageAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'HuaweiStorageAdapter';
  private authToken: string = '';
  private deviceId: string = '';
  private hiLinkClient: HiLinkClient | null = null;
  
  // HiLink API 端点
  private readonly API_BASE = '/api/v1';
  private readonly AUTH_ENDPOINT = '/api/v1/auth/login';
  private readonly DEVICE_INFO_ENDPOINT = '/api/v1/device/info';
  private readonly STORAGE_INFO_ENDPOINT = '/api/v1/storage/info';
  private readonly FILES_LIST_ENDPOINT = '/api/v1/files/list';
  private readonly FILES_DOWNLOAD_ENDPOINT = '/api/v1/files/download';
  private readonly FILES_THUMBNAIL_ENDPOINT = '/api/v1/files/thumbnail';
  private readonly MEDIA_VIDEOS_ENDPOINT = '/api/v1/media/videos';
  private readonly MEDIA_IMAGES_ENDPOINT = '/api/v1/media/images';
  private readonly FAMILY_MEMBERS_ENDPOINT = '/api/v1/family/members';
  private readonly FAMILY_SHARES_ENDPOINT = '/api/v1/family/shares';
  
  /**
   * 连接华为家庭存储
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to Huawei storage: ${device.name}`);
      
      // 1. 创建HiLink客户端
      this.hiLinkClient = new HiLinkClient(device.ip, device.port);
      
      // 2. 测试连接
      const pingResult = await this.hiLinkClient.ping();
      if (!pingResult.success) {
        throw new Error('Failed to ping device');
      }
      
      // 3. 获取设备信息
      const deviceInfo = await this.hiLinkClient.getDeviceInfo();
      this.deviceId = deviceInfo.deviceId;
      
      // 4. 认证（如果需要）
      if (device.authConfig?.enableAuth) {
        this.authToken = await this.authenticate(
          device.authConfig.username,
          device.authConfig.password
        );
        this.hiLinkClient.setAuthToken(this.authToken);
      }
      
      // 5. 验证设备是华为家庭存储
      if (!deviceInfo.manufacturer.includes('Huawei')) {
        throw new Error('Device is not Huawei storage');
      }
      
      Logger.info(this.TAG, 'Connected to Huawei storage successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to Huawei storage', error as Error);
      return false;
    }
  }
  
  /**
   * HiLink认证
   */
  private async authenticate(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with HiLink...');
      
      // 1. 获取挑战码
      const challenge = await this.hiLinkClient.getChallenge();
      
      // 2. 生成认证令牌
      const authRequest = {
        username: username,
        password: this.hashPassword(password, challenge),
        deviceId: this.generateDeviceId()
      };
      
      const response = await this.hiLinkClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('Authentication failed');
      }
      
      this.authToken = response.data.token;
      Logger.info(this.TAG, 'HiLink authentication successful');
      return this.authToken;
    } catch (error) {
      Logger.error(this.TAG, 'HiLink authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 列出目录内容（华为优化版）
   * 支持华为特有的快速索引和缓存
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      // 1. 尝试使用华为的快速索引API
      const cachedIndex = await this.getHuaweiDirectoryCache(path);
      if (cachedIndex) {
        Logger.debug(this.TAG, `Using cached index for: ${path}`);
        return cachedIndex;
      }
      
      // 2. 调用HiLink API获取文件列表
      const response = await this.hiLinkClient.get(
        this.FILES_LIST_ENDPOINT,
        { path }
      );
      
      if (!response.success) {
        throw new Error('Failed to list directory');
      }
      
      // 3. 解析文件列表
      const files = this.parseHuaweiFileList(response.data.files);
      
      // 4. 缓存索引（华为的优化特性）
      await this.setHuaweiDirectoryCache(path, files);
      
      return files;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  /**
   * 解析华为文件列表
   */
  private parseHuaweiFileList(huaweiFiles: any[]): NASFileItem[] {
    return huaweiFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isDirectory ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.modifiedTime,
      mimeType: file.mimeType,
      thumbnailUrl: file.thumbnailUrl,
      duration: file.duration,  // 华为预提取的视频时长
      resolution: file.resolution,  // 华为预提取的视频分辨率
      isVideo: file.isVideo,
      isAudio: file.isAudio,
      isImage: file.isImage
    }));
  }
  
  /**
   * 获取文件URL（华为优化版）
   * 支持华为的视频优化功能
   */
  getFileUrl(path: string, options?: VideoOptions): string {
    const encodedPath = encodeURIComponent(path);
    const params = new URLSearchParams();
    params.append('path', encodedPath);
    params.append('token', this.authToken);
    
    // 华为视频优化参数
    if (options?.enableOptimization) {
      params.append('optimize', 'true');
      if (options.maxBitrate) {
        params.append('maxBitrate', options.maxBitrate.toString());
      }
      if (options.codec) {
        params.append('codec', options.codec);
      }
    }
    
    return `http://${this.hiLinkClient.ip}:${this.hiLinkClient.port}${this.FILES_DOWNLOAD_ENDPOINT}?${params.toString()}`;
  }
  
  /**
   * 获取缩略图（华为优化版）
   * 华为预生成缩略图，性能更优
   */
  async getThumbnail(path: string): Promise<string> {
    const encodedPath = encodeURIComponent(path);
    const params = new URLSearchParams();
    params.append('path', encodedPath);
    params.append('token', this.authToken);
    
    // 华为缩略图尺寸选项
    params.append('size', 'large');  // small, medium, large
    
    return `http://${this.hiLinkClient.ip}:${this.hiLinkClient.port}${this.FILES_THUMBNAIL_ENDPOINT}?${params.toString()}`;
  }
  
  /**
   * 华为特有功能：获取视频库
   * 华为预先整理好的视频分类
   */
  async getVideoLibrary(): Promise<VideoLibrary> {
    try {
      const response = await this.hiLinkClient.get(this.MEDIA_VIDEOS_ENDPOINT);
      
      return {
        movies: response.data.movies || [],
        tvSeries: response.data.tvSeries || [],
        documentaries: response.data.documentaries || [],
        animations: response.data.animations || [],
        total: response.data.total || 0
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get video library', error as Error);
      return {
        movies: [],
        tvSeries: [],
        documentaries: [],
        animations: [],
        total: 0
      };
    }
  }
  
  /**
   * 华为特有功能：家庭共享
   */
  async getFamilyMembers(): Promise<FamilyMember[]> {
    try {
      const response = await this.hiLinkClient.get(this.FAMILY_MEMBERS_ENDPOINT);
      return response.data.members || [];
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get family members', error as Error);
      return [];
    }
  }
  
  async getFamilyShares(): Promise<FamilyShare[]> {
    try {
      const response = await this.hiLinkClient.get(this.FAMILY_SHARES_ENDPOINT);
      return response.data.shares || [];
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get family shares', error as Error);
      return [];
    }
  }
  
  /**
   * 华为特有功能：HarmonyOS分布式存储
   */
  async enableHarmonyOSDistributedStorage(enable: boolean): Promise<void> {
    try {
      await this.hiLinkClient.post('/api/v1/harmony/distributed', {
        enable: enable
      });
      Logger.info(this.TAG, `HarmonyOS distributed storage ${enable ? 'enabled' : 'disabled'}`);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to toggle HarmonyOS distributed storage', error as Error);
    }
  }
  
  /**
   * 华为特有功能：智能相册
   */
  async getSmartGallery(): Promise<SmartGallery> {
    try {
      const response = await this.hiLinkClient.get(this.MEDIA_IMAGES_ENDPOINT);
      
      return {
        all: response.data.all || [],
        favorites: response.data.favorites || [],
        recentlyAdded: response.data.recentlyAdded || [],
        aiCategories: response.data.aiCategories || {
          landscapes: [],
          portraits: [],
          food: [],
          travel: []
        }
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get smart gallery', error as Error);
      return {
        all: [],
        favorites: [],
        recentlyAdded: [],
        aiCategories: {
          landscapes: [],
          portraits: [],
          food: [],
          travel: []
        }
      };
    }
  }
  
  /**
   * 华为目录缓存（华为性能优化）
   */
  private async getHuaweiDirectoryCache(path: string): Promise<NASFileItem[] | null> {
    try {
      const cacheKey = `huawei_cache_${this.deviceId}_${path}`;
      const cached = await this.storageService.get<NASFileItem[]>(cacheKey);
      
      if (cached && Date.now() - cached.timestamp < 300000) { // 5分钟缓存
        return cached.data;
      }
      
      return null;
    } catch (error) {
      return null;
    }
  }
  
  private async setHuaweiDirectoryCache(path: string, files: NASFileItem[]): Promise<void> {
    try {
      const cacheKey = `huawei_cache_${this.deviceId}_${path}`;
      await this.storageService.set(cacheKey, {
        data: files,
        timestamp: Date.now()
      });
    } catch (error) {
      Logger.warn(this.TAG, 'Failed to cache directory', error);
    }
  }
  
  /**
   * 密码哈希（华为算法）
   */
  private hashPassword(password: string, challenge: string): string {
    // 华为特定的密码哈希算法
    // 实际实现需要根据华为协议文档
    return this.sha256(challenge + password);
  }
  
  private sha256(input: string): string {
    // SHA-256实现
    return CryptoJS.SHA256(input).toString();
  }
  
  private generateDeviceId(): string {
    // 生成唯一设备ID
    return `raytv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.hiLinkClient) {
      this.hiLinkClient.disconnect();
      this.hiLinkClient = null;
    }
    this.authToken = '';
    this.deviceId = '';
  }
}
```

#### 4.1.2 HiLink客户端实现

```typescript
/**
 * HiLink协议客户端
 */
class HiLinkClient {
  private ip: string;
  private port: number;
  private authToken: string = '';
  private socket: TCPSocket | null = null;
  
  constructor(ip: string, port: number) {
    this.ip = ip;
    this.port = port;
  }
  
  async ping(): Promise<{ success: boolean }> {
    try {
      const response = await this.get('/api/ping');
      return { success: response.code === 200 };
    } catch (error) {
      return { success: false };
    }
  }
  
  async getDeviceInfo(): Promise<DeviceInfo> {
    return await this.get<DeviceInfo>(this.DEVICE_INFO_ENDPOINT);
  }
  
  async getChallenge(): Promise<string> {
    const response = await this.get('/api/v1/auth/challenge');
    return response.data.challenge;
  }
  
  async get<T>(endpoint: string, params?: Record<string, string>): Promise<any> {
    // 实现HTTP GET请求
    // 支持HiLink认证
  }
  
  async post<T>(endpoint: string, data: any): Promise<any> {
    // 实现HTTP POST请求
    // 支持HiLink认证
  }
  
  setAuthToken(token: string): void {
    this.authToken = token;
  }
  
  disconnect(): void {
    if (this.socket) {
      this.socket.close();
      this.socket = null;
    }
  }
}
```

---

### 4.2 极空间NAS适配器（P0 - 最高优先级）

#### 4.2.1 适配器接口

```typescript
/**
 * 极空间NAS适配器
 * 优先级：P0（最高）
 * 协议：ZSpace（极空间私有）+ SMB + DLNA
 */
export class ZSpaceAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'ZSpaceAdapter';
  private authToken: string = '';
  private deviceId: string = '';
  private zSpaceClient: ZSpaceClient | null = null;
  
  // ZSpace API 端点
  private readonly API_BASE = '/zapi/v1';
  private readonly AUTH_ENDPOINT = '/zapi/v1/auth/login';
  private readonly DEVICE_INFO_ENDPOINT = '/zapi/v1/device/info';
  private readonly ZVIDEO_ENDPOINT = '/zapi/v1/zvideo';
  private readonly ZGALLERY_ENDPOINT = '/zapi/v1/zgallery';
  private readonly FILES_ENDPOINT = '/zapi/v1/files';
  private readonly THUMBNAIL_ENDPOINT = '/zapi/v1/thumbnails';
  private readonly TUNNEL_ENDPOINT = '/zapi/v1/tunnel';  // 内网穿透
  
  /**
   * 连接极空间NAS
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to ZSpace NAS: ${device.name}`);
      
      // 1. 创建ZSpace客户端
      this.zSpaceClient = new ZSpaceClient(device.ip, device.port);
      
      // 2. 测试连接
      const pingResult = await this.zSpaceClient.ping();
      if (!pingResult.success) {
        throw new Error('Failed to ping device');
      }
      
      // 3. 获取设备信息
      const deviceInfo = await this.zSpaceClient.getDeviceInfo();
      this.deviceId = deviceInfo.deviceId;
      
      // 4. 验证是极空间设备
      if (!deviceInfo.manufacturer.includes('ZSPACE') && !deviceInfo.manufacturer.includes('极空间')) {
        throw new Error('Device is not ZSpace NAS');
      }
      
      // 5. 认证
      if (device.authConfig?.enableAuth) {
        this.authToken = await this.authenticate(
          device.authConfig.username,
          device.authConfig.password
        );
        this.zSpaceClient.setAuthToken(this.authToken);
      }
      
      Logger.info(this.TAG, 'Connected to ZSpace NAS successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to ZSpace NAS', error as Error);
      return false;
    }
  }
  
  /**
   * ZSpace认证
   */
  private async authenticate(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with ZSpace...');
      
      const authRequest = {
        username: username,
        password: this.md5Hash(password),
        appId: 'raytv',
        appVersion: '1.0.0'
      };
      
      const response = await this.zSpaceClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('ZSpace authentication failed');
      }
      
      this.authToken = response.data.token;
      Logger.info(this.TAG, 'ZSpace authentication successful');
      return this.authToken;
    } catch (error) {
      Logger.error(this.TAG, 'ZSpace authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 列出目录内容（极空间优化版）
   * 支持极空间的快速索引
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      // 1. 尝试使用极空间的快速索引
      const cachedIndex = await this.getZSpaceDirectoryCache(path);
      if (cachedIndex) {
        Logger.debug(this.TAG, `Using cached index for: ${path}`);
        return cachedIndex;
      }
      
      // 2. 调用ZSpace API
      const response = await this.zSpaceClient.get(this.FILES_ENDPOINT, {
        path: path
      });
      
      if (!response.success) {
        throw new Error('Failed to list directory');
      }
      
      // 3. 解析文件列表
      const files = this.parseZSpaceFileList(response.data.files);
      
      // 4. 缓存索引
      await this.setZSpaceDirectoryCache(path, files);
      
      return files;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  /**
   * 解析极空间文件列表
   * 极空间提供了丰富的元数据
   */
  private parseZSpaceFileList(zspaceFiles: any[]): NASFileItem[] {
    return zspaceFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isDirectory ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.modifiedTime,
      mimeType: file.mimeType,
      thumbnailUrl: file.thumbnailUrl,
      duration: file.duration,  // 极空间预提取的视频时长
      resolution: file.resolution,  // 极空间预提取的视频分辨率
      codec: file.codec,  // 极空间提取的编码格式
      bitrate: file.bitrate,  // 极空间提取的码率
      isVideo: file.isVideo,
      isAudio: file.isAudio,
      isImage: file.isImage
    }));
  }
  
  /**
   * 极空间特有功能：极影视（ZVideo）
   */
  async getZVideoLibrary(): Promise<ZVideoLibrary> {
    try {
      const response = await this.zSpaceClient.get(this.ZVIDEO_ENDPOINT);
      
      return {
        movies: response.data.movies || [],
        tvSeries: response.data.tvSeries || [],
        anime: response.data.anime || [],
        variety: response.data.variety || [],
        documentary: response.data.documentary || [],
        recentlyAdded: response.data.recentlyAdded || [],
        continueWatching: response.data.continueWatching || [],
        recommended: response.data.recommended || [],  // AI推荐
        total: response.data.total || 0
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get ZVideo library', error as Error);
      return {
        movies: [],
        tvSeries: [],
        anime: [],
        variety: [],
        documentary: [],
        recentlyAdded: [],
        continueWatching: [],
        recommended: [],
        total: 0
      };
    }
  }
  
  /**
   * 极空间特有功能：获取视频详情（极影视增强）
   */
  async getZVideoDetail(videoId: string): Promise<ZVideoDetail> {
    try {
      const response = await this.zSpaceClient.get(`${this.ZVIDEO_ENDPOINT}/detail`, {
        videoId: videoId
      });
      
      return {
        id: response.data.id,
        title: response.data.title,
        type: response.data.type,
        year: response.data.year,
        genre: response.data.genre || [],
        actors: response.data.actors || [],
        director: response.data.director,
        description: response.data.description,
        poster: response.data.poster,
        backdrop: response.data.backdrop,
        rating: response.data.rating,
        duration: response.data.duration,
        resolution: response.data.resolution,
        codec: response.data.codec,
        bitrate: response.data.bitrate,
        filePath: response.data.filePath,
        fileSize: response.data.fileSize,
        thumbnailPath: response.data.thumbnailPath,
        watchedProgress: response.data.watchedProgress || 0,
        lastWatched: response.data.lastWatched,
        isFavorite: response.data.isFavorite || false,
        addedDate: response.data.addedDate
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get ZVideo detail', error as Error);
      throw error;
    }
  }
  
  /**
   * 极空间特有功能：极相册（ZGallery）
   */
  async getZGallery(): Promise<ZGallery> {
    try {
      const response = await this.zSpaceClient.get(this.ZGALLERY_ENDPOINT);
      
      return {
        all: response.data.all || [],
        favorites: response.data.favorites || [],
        recentlyAdded: response.data.recentlyAdded || [],
        aiCategories: response.data.aiCategories || {
          landscapes: [],
          portraits: [],
          food: [],
          travel: [],
          pets: [],
          documents: []
        }
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get ZGallery', error as Error);
      return {
        all: [],
        favorites: [],
        recentlyAdded: [],
        aiCategories: {
          landscapes: [],
          portraits: [],
          food: [],
          travel: [],
          pets: [],
          documents: []
        }
      };
    }
  }
  
  /**
   * 极空间特有功能：内网穿透
   * 极空间提供免费的内网穿透服务
   */
  async enableTunnel(enable: boolean): Promise<TunnelInfo | null> {
    try {
      const response = await this.zSpaceClient.post(this.TUNNEL_ENDPOINT, {
        enable: enable
      });
      
      if (enable && response.success) {
        return {
          enabled: true,
          tunnelUrl: response.data.tunnelUrl,
          tunnelPort: response.data.tunnelPort,
          expiration: response.data.expiration
        };
      }
      
      return null;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to enable tunnel', error as Error);
      return null;
    }
  }
  
  /**
   * 极空间特有功能：AI推荐
   */
  async getAIRecommendations(limit: number = 20): Promise<ZVideoItem[]> {
    try {
      const response = await this.zSpaceClient.get(`${this.ZVIDEO_ENDPOINT}/recommendations`, {
        limit: limit
      });
      
      return response.data.recommendations || [];
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get AI recommendations', error as Error);
      return [];
    }
  }
  
  /**
   * 获取文件URL（极空间优化版）
   */
  getFileUrl(path: string, options?: VideoOptions): string {
    const encodedPath = encodeURIComponent(path);
    const params = new URLSearchParams();
    params.append('path', encodedPath);
    params.append('token', this.authToken);
    
    // 极空间视频优化
    if (options?.enableOptimization) {
      params.append('optimize', 'true');
    }
    
    // 支持内网穿透
    const tunnel = this.getZSpaceTunnelUrl();
    if (tunnel) {
      return `${tunnel}${this.FILES_ENDPOINT}?${params.toString()}`;
    }
    
    return `http://${this.zSpaceClient.ip}:${this.zSpaceClient.port}${this.FILES_ENDPOINT}?${params.toString()}`;
  }
  
  /**
   * 获取缩略图（极空间优化版）
   * 极空间提供多尺寸缩略图
   */
  async getThumbnail(path: string, size: 'small' | 'medium' | 'large' = 'large'): Promise<string> {
    const encodedPath = encodeURIComponent(path);
    const params = new URLSearchParams();
    params.append('path', encodedPath);
    params.append('token', this.authToken);
    params.append('size', size);
    
    const tunnel = this.getZSpaceTunnelUrl();
    if (tunnel) {
      return `${tunnel}${this.THUMBNAIL_ENDPOINT}?${params.toString()}`;
    }
    
    return `http://${this.zSpaceClient.ip}:${this.zSpaceClient.port}${this.THUMBNAIL_ENDPOINT}?${params.toString()}`;
  }
  
  /**
   * 极空间目录缓存
   */
  private async getZSpaceDirectoryCache(path: string): Promise<NASFileItem[] | null> {
    try {
      const cacheKey = `zspace_cache_${this.deviceId}_${path}`;
      const cached = await this.storageService.get<NASFileItem[]>(cacheKey);
      
      if (cached && Date.now() - cached.timestamp < 300000) {
        return cached.data;
      }
      
      return null;
    } catch (error) {
      return null;
    }
  }
  
  private async setZSpaceDirectoryCache(path: string, files: NASFileItem[]): Promise<void> {
    try {
      const cacheKey = `zspace_cache_${this.deviceId}_${path}`;
      await this.storageService.set(cacheKey, {
        data: files,
        timestamp: Date.now()
      });
    } catch (error) {
      Logger.warn(this.TAG, 'Failed to cache directory', error);
    }
  }
  
  private getZSpaceTunnelUrl(): string | null {
    // 获取极空间内网穿透URL
    return this.tunnelInfo?.tunnelUrl || null;
  }
  
  private md5Hash(input: string): string {
    // MD5实现
    return CryptoJS.MD5(input).toString();
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.zSpaceClient) {
      this.zSpaceClient.disconnect();
      this.zSpaceClient = null;
    }
    this.authToken = '';
    this.deviceId = '';
  }
}
```

---

### 4.3 小米NAS适配器（P0 - 最高优先级）

```typescript
/**
 * 小米NAS适配器
 * 优先级：P0（最高）
 * 协议：Mi Home（小米私有）+ SMB + DLNA
 */
export class MiHomeAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'MiHomeAdapter';
  private authToken: string = '';
  private deviceId: string = '';
  private miHomeClient: MiHomeClient | null = null;
  
  // Mi Home API 端点
  private readonly API_BASE = '/mapi/v1';
  private readonly AUTH_ENDPOINT = '/mapi/v1/auth/login';
  private readonly DEVICE_INFO_ENDPOINT = '/mapi/v1/device/info';
  private readonly FILES_ENDPOINT = '/mapi/v1/files';
  private readonly MI_PHOTOS_ENDPOINT = '/mapi/v1/miphotos';
  private readonly SMART_HOME_ENDPOINT = '/mapi/v1/smarthome';
  
  /**
   * 连接小米NAS
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to Xiaomi NAS: ${device.name}`);
      
      this.miHomeClient = new MiHomeClient(device.ip, device.port);
      
      // 1. 测试连接
      const pingResult = await this.miHomeClient.ping();
      if (!pingResult.success) {
        throw new Error('Failed to ping device');
      }
      
      // 2. 获取设备信息
      const deviceInfo = await this.miHomeClient.getDeviceInfo();
      this.deviceId = deviceInfo.deviceId;
      
      // 3. 验证是小米设备
      if (!deviceInfo.manufacturer.includes('Xiaomi') && !deviceInfo.manufacturer.includes('小米')) {
        throw new Error('Device is not Xiaomi NAS');
      }
      
      // 4. 认证
      if (device.authConfig?.enableAuth) {
        this.authToken = await this.authenticate(
          device.authConfig.username,
          device.authConfig.password
        );
        this.miHomeClient.setAuthToken(this.authToken);
      }
      
      Logger.info(this.TAG, 'Connected to Xiaomi NAS successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to Xiaomi NAS', error as Error);
      return false;
    }
  }
  
  /**
   * Mi Home认证
   */
  private async authenticate(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with Mi Home...');
      
      const authRequest = {
        username: username,
        password: password,
        deviceId: this.generateDeviceId(),
        appVersion: '1.0.0'
      };
      
      const response = await this.miHomeClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('Mi Home authentication failed');
      }
      
      this.authToken = response.data.token;
      Logger.info(this.TAG, 'Mi Home authentication successful');
      return this.authToken;
    } catch (error) {
      Logger.error(this.TAG, 'Mi Home authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 小米特有功能：小米相册
   */
  async getMiPhotos(): Promise<MiPhotos> {
    try {
      const response = await this.miHomeClient.get(this.MI_PHOTOS_ENDPOINT);
      
      return {
        all: response.data.all || [],
        albums: response.data.albums || [],
        favorites: response.data.favorites || [],
        recentlyAdded: response.data.recentlyAdded || [],
        aiSorted: response.data.aiSorted || {
          landscapes: [],
          portraits: [],
          food: [],
          travel: []
        }
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get Mi Photos', error as Error);
      return {
        all: [],
        albums: [],
        favorites: [],
        recentlyAdded: [],
        aiSorted: {
          landscapes: [],
          portraits: [],
          food: [],
          travel: []
        }
      };
    }
  }
  
  /**
   * 小米特有功能：智能家居联动
   */
  async getSmartHomeDevices(): Promise<SmartHomeDevice[]> {
    try {
      const response = await this.miHomeClient.get(this.SMART_HOME_ENDPOINT);
      return response.data.devices || [];
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get smart home devices', error as Error);
      return [];
    }
  }
  
  /**
   * 列出目录内容
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      const response = await this.miHomeClient.get(this.FILES_ENDPOINT, {
        path: path
      });
      
      return this.parseMiHomeFileList(response.data.files);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  private parseMiHomeFileList(miHomeFiles: any[]): NASFileItem[] {
    return miHomeFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isDirectory ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.modifiedTime,
      mimeType: file.mimeType,
      isVideo: file.isVideo,
      isAudio: file.isAudio,
      isImage: file.isImage
    }));
  }
  
  /**
   * 获取文件URL
   */
  getFileUrl(path: string): string {
    const encodedPath = encodeURIComponent(path);
    return `http://${this.miHomeClient.ip}:${this.miHomeClient.port}${this.FILES_ENDPOINT}?path=${encodedPath}&token=${this.authToken}`;
  }
  
  /**
   * 获取缩略图
   */
  async getThumbnail(path: string): Promise<string> {
    const encodedPath = encodeURIComponent(path);
    return `http://${this.miHomeClient.ip}:${this.miHomeClient.port}/mapi/v1/thumbnail?path=${encodedPath}&token=${this.authToken}`;
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.miHomeClient) {
      this.miHomeClient.disconnect();
      this.miHomeClient = null;
    }
    this.authToken = '';
    this.deviceId = '';
  }
}
```

---

### 4.4 群晖NAS适配器（P1 - 重要优化）

```typescript
/**
 * 群晖NAS适配器
 * 优先级：P1（重要）
 * 协议：SMB 3.1 + DLNA + WebDAV
 * 优化：Video Station集成、SMB 3.1加密
 */
export class SynologyAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'SynologyAdapter';
  private authToken: string = '';
  private sessionId: string = '';
  private dsmClient: DSMClient | null = null;
  
  // DSM API 端点
  private readonly API_BASE = '/webapi';
  private readonly AUTH_ENDPOINT = '/webapi/auth.cgi';
  private readonly FILE_STATION_ENDPOINT = '/webapi/entry.cgi';
  private readonly VIDEO_STATION_ENDPOINT = '/webapi/entry.cgi';
  
  /**
   * 连接群晖NAS
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to Synology NAS: ${device.name}`);
      
      this.dsmClient = new DSMClient(device.ip, device.port);
      
      // 1. 使用SMB 3.1连接（优先）或WebDAV
      const connectResult = await this.dsmClient.connectSMB31(
        device.authConfig?.username || 'guest',
        device.authConfig?.password || '',
        device.nasConfig?.sharePath || 'homes'
      );
      
      if (!connectResult) {
        throw new Error('Failed to connect via SMB 3.1');
      }
      
      // 2. DSM Web API认证
      if (device.authConfig?.enableAuth) {
        this.authToken = await this.authenticateDSM(
          device.authConfig.username,
          device.authConfig.password
        );
        this.sessionId = await this.getSessionId();
      }
      
      // 3. 验证是群晖设备
      const deviceInfo = await this.getDSMInfo();
      if (!deviceInfo.manufacturer.includes('Synology') && !deviceInfo.manufacturer.includes('群晖')) {
        throw new Error('Device is not Synology NAS');
      }
      
      Logger.info(this.TAG, 'Connected to Synology NAS successfully via SMB 3.1');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to Synology NAS', error as Error);
      return false;
    }
  }
  
  /**
   * DSM Web API认证
   */
  private async authenticateDSM(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with DSM Web API...');
      
      const authRequest = {
        api: 'SYNO.API.Auth',
        method: 'Login',
        version: 3,
        params: {
          account: username,
          passwd: password,
          session_name: 'RayTV',
          format: 'sid'
        }
      };
      
      const response = await this.dsmClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('DSM authentication failed');
      }
      
      this.sessionId = response.data.sid;
      Logger.info(this.TAG, 'DSM authentication successful');
      return this.sessionId;
    } catch (error) {
      Logger.error(this.TAG, 'DSM authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 群晖特有功能：Video Station集成
   */
  async getVideoStationLibrary(): Promise<VideoStationLibrary> {
    try {
      const response = await this.dsmClient.get(this.VIDEO_STATION_ENDPOINT, {
        api: 'SYNO.VideoStation.Library',
        method: 'list',
        version: 1,
        _sid: this.sessionId
      });
      
      return {
        libraries: response.data.libraries || [],
        movies: response.data.movies || [],
        tvShows: response.data.tvShows || [],
        homeVideos: response.data.homeVideos || [],
        total: response.data.total || 0
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get Video Station library', error as Error);
      return {
        libraries: [],
        movies: [],
        tvShows: [],
        homeVideos: [],
        total: 0
      };
    }
  }
  
  /**
   * 群晖特有功能：获取视频详情（Video Station增强）
   */
  async getVideoStationVideo(videoId: string): Promise<VideoStationVideo> {
    try {
      const response = await this.dsmClient.get(this.VIDEO_STATION_ENDPOINT, {
        api: 'SYNO.VideoStation.Video',
        method: 'getinfo',
        version: 2,
        id: videoId,
        _sid: this.sessionId
      });
      
      return {
        id: response.data.id,
        title: response.data.title,
        type: response.data.type,
        libraryId: response.data.library_id,
        filePath: response.data.file_path,
        duration: response.data.duration,
        resolution: response.data.resolution,
        bitrate: response.data.bitrate,
        codec: response.data.codec,
        container: response.data.container,
        summary: response.data.summary,
        actors: response.data.actors || [],
        director: response.data.director,
        year: response.data.year,
        posterUrl: response.data.poster_url,
        backdropUrl: response.data.backdrop_url,
        rating: response.data.rating,
        tags: response.data.tags || [],
        watched: response.data.watched || false,
        watchedProgress: response.data.watched_progress || 0,
        lastWatched: response.data.last_watched
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get Video Station video', error as Error);
      throw error;
    }
  }
  
  /**
   * 群晖特有功能：File Station优化
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      // 使用SMB 3.1优先，WebDAV作为备选
      const files = await this.dsmClient.listDirectorySMB31(path);
      
      return this.parseDSMFileList(files);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  /**
   * 群晖特有功能：File Station搜索
   */
  async searchFiles(keyword: string, path?: string): Promise<NASFileItem[]> {
    try {
      const response = await this.dsmClient.get(this.FILE_STATION_ENDPOINT, {
        api: 'SYNO.FileStation.Search',
        method: 'list',
        version: 2,
        keyword: keyword,
        folder_path: path || '',
        _sid: this.sessionId
      });
      
      return this.parseDSMFileList(response.data.files || []);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to search files', error as Error);
      return [];
    }
  }
  
  private parseDSMFileList(dsmFiles: any[]): NASFileItem[] {
    return dsmFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isdir ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.additional?.atime * 1000 || 0,
      mimeType: file.additional?.mime_type,
      isVideo: file.additional?.is_video || false,
      isAudio: file.additional?.is_audio || false,
      isImage: file.additional?.is_image || false
    }));
  }
  
  /**
   * 获取文件URL（群晖优化版）
   * 支持SMB 3.1加密传输
   */
  getFileUrl(path: string): string {
    // 优先使用SMB 3.1 URL
    const smbUrl = this.dsmClient.getSMB31Url(path);
    
    // WebDAV作为备选
    const webdavUrl = this.dsmClient.getWebDAVUrl(path);
    
    // 返回SMB 3.1 URL
    return smbUrl;
  }
  
  /**
   * 获取缩略图（群晖优化版）
   */
  async getThumbnail(path: string): Promise<string> {
    try {
      const response = await this.dsmClient.get(this.FILE_STATION_ENDPOINT, {
        api: 'SYNO.FileStation.Thumbnail',
        method: 'get',
        version: 2,
        path: path,
        size: 'large',
        _sid: this.sessionId
      });
      
      return response.data.url;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get thumbnail', error as Error);
      return '';
    }
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.dsmClient) {
      this.dsmClient.disconnect();
      this.dsmClient = null;
    }
    this.authToken = '';
    this.sessionId = '';
  }
}
```

---

### 4.5 绿联NAS适配器（P1 - 重要优化）

```typescript
/**
 * 绿联NAS适配器
 * 优先级：P1（重要）
 * 协议：SMB + DLNA + WebDAV
 * 优化：UGREEN OS集成、视频转码优化
 */
export class UGreenAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'UGreenAdapter';
  private authToken: string = '';
  private ugreenClient: UGreenClient | null = null;
  
  // UGREEN API 端点
  private readonly API_BASE = '/ugapi/v1';
  private readonly AUTH_ENDPOINT = '/ugapi/v1/auth/login';
  private readonly DEVICE_INFO_ENDPOINT = '/ugapi/v1/device/info';
  private readonly FILES_ENDPOINT = '/ugapi/v1/files';
  private readonly TRANSCODE_ENDPOINT = '/ugapi/v1/transcode';  // 视频转码
  
  /**
   * 连接绿联NAS
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to UGREEN NAS: ${device.name}`);
      
      this.ugreenClient = new UGreenClient(device.ip, device.port);
      
      // 1. SMB连接
      const connectResult = await this.ugreenClient.connectSMB(
        device.authConfig?.username || 'guest',
        device.authConfig?.password || '',
        device.nasConfig?.sharePath || 'homes'
      );
      
      if (!connectResult) {
        throw new Error('Failed to connect via SMB');
      }
      
      // 2. UGREEN OS Web API认证
      if (device.authConfig?.enableAuth) {
        this.authToken = await this.authenticateUGreenOS(
          device.authConfig.username,
          device.authConfig.password
        );
        this.ugreenClient.setAuthToken(this.authToken);
      }
      
      // 3. 验证是绿联设备
      const deviceInfo = await this.getUGreenDeviceInfo();
      if (!deviceInfo.manufacturer.includes('UGREEN') && !deviceInfo.manufacturer.includes('绿联')) {
        throw new Error('Device is not UGREEN NAS');
      }
      
      Logger.info(this.TAG, 'Connected to UGREEN NAS successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to UGREEN NAS', error as Error);
      return false;
    }
  }
  
  /**
   * UGREEN OS认证
   */
  private async authenticateUGreenOS(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with UGREEN OS...');
      
      const authRequest = {
        username: username,
        password: password
      };
      
      const response = await this.ugreenClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('UGREEN OS authentication failed');
      }
      
      this.authToken = response.data.token;
      Logger.info(this.TAG, 'UGREEN OS authentication successful');
      return this.authToken;
    } catch (error) {
      Logger.error(this.TAG, 'UGREEN OS authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 绿联特有功能：视频转码
   * 绿联提供强大的视频转码功能
   */
  async transcodeVideo(
    sourcePath: string,
    targetFormat: 'mp4' | 'webm' | 'mkv',
    options?: TranscodeOptions
  ): Promise<TranscodeTask> {
    try {
      const transcodeRequest = {
        sourcePath: sourcePath,
        targetFormat: targetFormat,
        resolution: options?.resolution || '1080p',
        bitrate: options?.bitrate || 5000000,
        codec: options?.codec || 'h264',
        enableAudio: options?.enableAudio !== false
      };
      
      const response = await this.ugreenClient.post(
        this.TRANSCODE_ENDPOINT,
        transcodeRequest
      );
      
      return {
        taskId: response.data.taskId,
        status: 'processing',
        progress: 0,
        sourcePath: sourcePath,
        targetPath: response.data.targetPath,
        startTime: Date.now()
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to start transcode', error as Error);
      throw error;
    }
  }
  
  /**
   * 获取转码任务状态
   */
  async getTranscodeTaskStatus(taskId: string): Promise<TranscodeTaskStatus> {
    try {
      const response = await this.ugreenClient.get(`${this.TRANSCODE_ENDPOINT}/status`, {
        taskId: taskId
      });
      
      return {
        taskId: taskId,
        status: response.data.status,
        progress: response.data.progress || 0,
        targetPath: response.data.targetPath,
        error: response.data.error
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get transcode task status', error as Error);
      throw error;
    }
  }
  
  /**
   * 列出目录内容
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      const files = await this.ugreenClient.listDirectorySMB(path);
      
      return this.parseUGreenFileList(files);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  private parseUGreenFileList(ugreenFiles: any[]): NASFileItem[] {
    return ugreenFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isDirectory ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.modifiedTime,
      isVideo: file.isVideo,
      isAudio: file.isAudio,
      isImage: file.isImage
    }));
  }
  
  /**
   * 获取文件URL
   */
  getFileUrl(path: string): string {
    return this.ugreenClient.getSMBUrl(path);
  }
  
  /**
   * 获取缩略图
   */
  async getThumbnail(path: string): Promise<string> {
    try {
      return await this.ugreenClient.getThumbnail(path);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get thumbnail', error as Error);
      return '';
    }
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.ugreenClient) {
      this.ugreenClient.disconnect();
      this.ugreenClient = null;
    }
    this.authToken = '';
  }
}
```

---

### 4.6 威联通NAS适配器（P1 - 重要优化）

```typescript
/**
 * 威联通NAS适配器
 * 优先级：P1（重要）
 * 协议：SMB + DLNA + WebDAV
 * 优化：QuVideo集成、硬件转码优化
 */
export class QNAPAdapter implements NASServiceAdapter {
  private readonly TAG: string = 'QNAPAdapter';
  private authToken: string = '';
  private sessionId: string = '';
  private qtsClient: QTSClient | null = null;
  
  // QTS API 端点
  private readonly API_BASE = '/cgi-bin';
  private readonly AUTH_ENDPOINT = '/cgi-bin/authLogin.cgi';
  private readonly FILE_STATION_ENDPOINT = '/cgi-bin/filemgr/fileShareUIReq.cgi';
  private readonly QUVIDEO_ENDPOINT = '/cgi-bin/quvideo/qvs/qvs_api.cgi';
  
  /**
   * 连接威联通NAS
   */
  async connect(device: NASDevice): Promise<boolean> {
    try {
      Logger.info(this.TAG, `Connecting to QNAP NAS: ${device.name}`);
      
      this.qtsClient = new QTSClient(device.ip, device.port);
      
      // 1. SMB 3.1连接
      const connectResult = await this.qtsClient.connectSMB31(
        device.authConfig?.username || 'guest',
        device.authConfig?.password || '',
        device.nasConfig?.sharePath || 'homes'
      );
      
      if (!connectResult) {
        throw new Error('Failed to connect via SMB 3.1');
      }
      
      // 2. QTS Web API认证
      if (device.authConfig?.enableAuth) {
        this.sessionId = await this.authenticateQTS(
          device.authConfig.username,
          device.authConfig.password
        );
      }
      
      // 3. 验证是威联通设备
      const deviceInfo = await this.getQTSInfo();
      if (!deviceInfo.manufacturer.includes('QNAP') && !deviceInfo.manufacturer.includes('威联通')) {
        throw new Error('Device is not QNAP NAS');
      }
      
      Logger.info(this.TAG, 'Connected to QNAP NAS successfully via SMB 3.1');
      return true;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to connect to QNAP NAS', error as Error);
      return false;
    }
  }
  
  /**
   * QTS Web API认证
   */
  private async authenticateQTS(username: string, password: string): Promise<string> {
    try {
      Logger.info(this.TAG, 'Authenticating with QTS Web API...');
      
      const authRequest = {
        user: username,
        pwd: password
      };
      
      const response = await this.qtsClient.post(
        this.AUTH_ENDPOINT,
        authRequest
      );
      
      if (!response.success) {
        throw new Error('QTS authentication failed');
      }
      
      this.sessionId = response.data.sid;
      Logger.info(this.TAG, 'QTS authentication successful');
      return this.sessionId;
    } catch (error) {
      Logger.error(this.TAG, 'QTS authentication failed', error as Error);
      throw error;
    }
  }
  
  /**
   * 威联通特有功能：QuVideo集成
   */
  async getQuVideoLibrary(): Promise<QuVideoLibrary> {
    try {
      const response = await this.qtsClient.get(this.QUVIDEO_ENDPOINT, {
        action: 'get_library',
        sid: this.sessionId
      });
      
      return {
        libraries: response.data.libraries || [],
        movies: response.data.movies || [],
        tvShows: response.data.tvShows || [],
        music: response.data.music || [],
        photos: response.data.photos || []
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get QuVideo library', error as Error);
      return {
        libraries: [],
        movies: [],
        tvShows: [],
        music: [],
        photos: []
      };
    }
  }
  
  /**
   * 威联通特有功能：硬件转码
   * 威联通提供强大的硬件转码能力
   */
  async enableHardwareTranscode(enable: boolean): Promise<boolean> {
    try {
      const response = await this.qtsClient.post(this.QUVIDEO_ENDPOINT, {
        action: 'enable_hardware_transcode',
        enable: enable,
        sid: this.sessionId
      });
      
      return response.success;
    } catch (error) {
      Logger.error(this.TAG, 'Failed to enable hardware transcode', error as Error);
      return false;
    }
  }
  
  /**
   * 获取转码能力
   */
  async getTranscodeCapabilities(): Promise<TranscodeCapabilities> {
    try {
      const response = await this.qtsClient.get(this.QUVIDEO_ENDPOINT, {
        action: 'get_transcode_capabilities',
        sid: this.sessionId
      });
      
      return {
        hardwareTranscode: response.data.hardware_transcode || false,
        supportedFormats: response.data.supported_formats || [],
        supportedResolutions: response.data.supported_resolutions || [],
        supportedCodecs: response.data.supported_codecs || []
      };
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get transcode capabilities', error as Error);
      return {
        hardwareTranscode: false,
        supportedFormats: [],
        supportedResolutions: [],
        supportedCodecs: []
      };
    }
  }
  
  /**
   * 列出目录内容
   */
  async listDirectory(path: string): Promise<NASFileItem[]> {
    try {
      const files = await this.qtsClient.listDirectorySMB31(path);
      
      return this.parseQTSFileList(files);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to list directory', error as Error);
      return [];
    }
  }
  
  private parseQTSFileList(qtsFiles: any[]): NASFileItem[] {
    return qtsFiles.map(file => ({
      id: file.id,
      name: file.name,
      path: file.path,
      type: file.isDirectory ? 'directory' : 'file',
      size: file.size,
      modifiedTime: file.modifiedTime,
      isVideo: file.isVideo,
      isAudio: file.isAudio,
      isImage: file.isImage
    }));
  }
  
  /**
   * 获取文件URL（威联通优化版）
   * 支持硬件转码
   */
  getFileUrl(path: string, options?: TranscodeOptions): string {
    const smbUrl = this.qtsClient.getSMB31Url(path);
    
    // 如果启用硬件转码
    if (options?.enableHardwareTranscode) {
      return this.qtsClient.getTranscodedUrl(path, options);
    }
    
    return smbUrl;
  }
  
  /**
   * 获取缩略图
   */
  async getThumbnail(path: string): Promise<string> {
    try {
      return await this.qtsClient.getThumbnail(path);
    } catch (error) {
      Logger.error(this.TAG, 'Failed to get thumbnail', error as Error);
      return '';
    }
  }
  
  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.qtsClient) {
      this.qtsClient.disconnect();
      this.qtsClient = null;
    }
    this.authToken = '';
    this.sessionId = '';
  }
}
```

---

## 5. 统一适配器工厂

### 5.1 适配器选择策略

```typescript
/**
 * NAS适配器工厂
 * 根据设备品牌和协议选择合适的适配器
 */
export class NASAdapterFactory {
  private static readonly adapters: Map<string, typeof NASServiceAdapter> = new Map([
    ['huawei', HuaweiStorageAdapter],
    ['华为', HuaweiStorageAdapter],
    ['zspace', ZSpaceAdapter],
    ['极空间', ZSpaceAdapter],
    ['xiaomi', MiHomeAdapter],
    ['小米', MiHomeAdapter],
    ['synology', SynologyAdapter],
    ['群晖', SynologyAdapter],
    ['ugreen', UGreenAdapter],
    ['绿联', UGreenAdapter],
    ['qnap', QNAPAdapter],
    ['威联通', QNAPAdapter],
    ['asustor', GenericSMBAdapter],
    ['asus', GenericSMBAdapter],
    ['wd', GenericSMBAdapter],
    ['seagate', GenericSMBAdapter]
  ]);
  
  /**
   * 创建适配器
   */
  public static createAdapter(device: NASDevice): NASServiceAdapter {
    // 1. 尝试根据品牌创建专用适配器
    const manufacturer = device.manufacturer.toLowerCase();
    
    for (const [key, adapterClass] of this.adapters.entries()) {
      if (manufacturer.includes(key)) {
        Logger.info(`Created ${key} adapter for device: ${device.name}`);
        return new adapterClass();
      }
    }
    
    // 2. 根据协议创建通用适配器
    const protocol = device.protocol;
    
    if (protocol === 'smb') {
      Logger.info(`Created generic SMB adapter for device: ${device.name}`);
      return new GenericSMBAdapter();
    }
    
    if (protocol === 'dlna') {
      Logger.info(`Created generic DLNA adapter for device: ${device.name}`);
      return new GenericDLNAAdapter();
    }
    
    if (protocol === 'webdav') {
      Logger.info(`Created generic WebDAV adapter for device: ${device.name}`);
      return new GenericWebDAVAdapter();
    }
    
    // 3. 默认使用SMB适配器
    Logger.warn(`Unknown device type, using generic SMB adapter: ${device.name}`);
    return new GenericSMBAdapter();
  }
  
  /**
   * 获取支持的设备品牌列表
   */
  public static getSupportedBrands(): string[] {
    return Array.from(this.adapters.keys());
  }
}
```

---

## 6. 数据模型更新

### 6.1 扩展网络源配置

```typescript
interface NetworkSourceConfig {
  id: string;
  name: string;
  url: string;
  type: 'json' | 'yaml' | 'txt' | 'nas';  // 新增 'nas' 类型
  version: string;
  isActive: boolean;
  contentUsage: {
    vodSites: boolean;
    liveChannels: boolean;
    wallpapers: boolean;
    adBlockRules: boolean;
    decoderConfigs: boolean;
    parserConfigs: boolean;
  };
  priority: number;
  tags?: string[];
  lastUpdated: number;
  healthStatus: 'healthy' | 'degraded' | 'unreachable';
  
  // NAS特定配置
  nasConfig?: NASConfig;
}

interface NASConfig {
  deviceId: string;
  deviceName: string;
  brand: 'huawei' | 'zspace' | 'xiaomi' | 'synology' | 'ugreen' | 'qnap' | 'other';
  protocol: 'smb' | 'dlna' | 'webdav' | 'huawei' | 'zspace' | 'mihome';
  ipAddress: string;
  port: number;
  sharePath?: string;
  username?: string;
  password?: string;
  enableAuth: boolean;
  
  // 华为特有配置
  huaweiConfig?: {
    enableHarmonyOSDistributed: boolean;
    enableFamilySharing: boolean;
  };
  
  // 极空间特有配置
  zspaceConfig?: {
    enableTunnel: boolean;
    enableAIRecommendation: boolean;
  };
  
  // 小米特有配置
  miHomeConfig?: {
    enableSmartHomeIntegration: boolean;
  };
  
  // 群晖特有配置
  synologyConfig?: {
    enableVideoStation: boolean;
    enablePhotoStation: boolean;
  };
  
  // 绿联特有配置
  ugreenConfig?: {
    enableHardwareTranscode: boolean;
  };
  
  // 威联通特有配置
  qnapConfig?: {
    enableHardwareTranscode: boolean;
    enableQuVideo: boolean;
  };
}
```

---

## 7. 实现阶段更新

### 7.1 第一阶段：基础架构和P0品牌（优先）

1. **创建NAS服务模块**
   - `NASDiscoveryService.ets`
   - `NASFileService.ets`
   - `NASIndexService.ets`
   - `NASAdapterFactory.ets`

2. **创建协议适配器**
   - `SMBAdapter.ets` - SMB 3.1支持
   - `DLNAAdapter.ets` - DLNA/UPnP支持
   - `WebDAVAdapter.ets` - WebDAV支持

3. **创建P0品牌适配器**
   - `HuaweiStorageAdapter.ets` - 华为HiLink协议
   - `ZSpaceAdapter.ets` - 极空间ZSpace协议
   - `MiHomeAdapter.ets` - 小米Mi Home协议

4. **扩展数据模型**
   - 更新`NetworkSourceConfig`，添加NAS类型
   - 创建NAS相关接口和类型定义

### 7.2 第二阶段：P1品牌优化（重要）

1. **创建P1品牌适配器**
   - `SynologyAdapter.ets` - 群晖DSM优化
   - `UGreenAdapter.ets` - 绿联UGREEN优化
   - `QNAPAdapter.ets` - 威联通QTS优化

2. **实现品牌特有功能**
   - 群晖：Video Station集成
   - 绿联：视频转码优化
   - 威联通：QuVideo集成、硬件转码

3. **UI集成**
   - NAS管理页面
   - 目录浏览页面
   - 首页NAS分类展示

---

## 8. 总结

### 8.1 优化重点

**P0（最高优先级）- 必须实现：**
1. ✅ 华为HiLink协议 - 中国市场第一，HarmonyOS生态
2. ✅ 极空间ZSpace协议 - 国产专业NAS领导者
3. ✅ 小米Mi Home协议 - 米家生态用户多
4. ✅ SMB 3.1协议 - 通用协议，所有NAS支持
5. ✅ DLNA/UPnP协议 - 媒体协议，视频播放标准

**P1（重要优先级）- 重要实现：**
1. ✅ 群晖DSM优化 - Video Station集成
2. ✅ 绿联UGREEN优化 - 视频转码优化
3. ✅ 威联通QTS优化 - QuVideo集成、硬件转码

### 8.2 品牌覆盖率

**P0覆盖：**
- 华为家庭存储 - 中国市场占有率第一
- 极空间NAS - 国产专业NAS领导者
- 小米NAS - 米家生态用户最多

**P1覆盖：**
- 群晖NAS - 全球领导者，中国专业用户多
- 绿联NAS - 性价比之王
- 威联通NAS - 企业用户多

**通用支持：**
- 通过SMB 3.1、DLNA、WebDAV协议，支持其他品牌（西部数据、希捷、华硕等）

### 8.3 中国特色功能

1. ✅ HarmonyOS生态集成（华为）
2. ✅ 米家生态集成（小米）
3. ✅ 内网穿透（极空间）
4. ✅ AI推荐（极空间、华为）
5. ✅ 家庭共享（华为）
6. ✅ 视频转码（绿联、威联通）
7. ✅ 硬件转码（威联通）

---

**方案制定时间：** 2026-03-03
**方案版本：** V2.0
**状态：** 待审核

本方案已融合中国NAS品牌调研报告，重点优化华为HiLink、极空间ZSpace、小米Mi Home协议（P0），并添加群晖DSM、绿联UGREEN、威联通QTS的专门优化（P1）。
