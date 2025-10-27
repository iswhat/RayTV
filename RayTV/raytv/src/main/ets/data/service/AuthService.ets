// AuthService - 认证服务类
import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import RepositoryFactory from '../repository/RepositoryFactory';
import { NetworkRepository } from '../repository/NetworkRepository';
import { DatabaseRepository } from '../repository/DatabaseRepository';

// 导入DTO
import { 
  LoginRequest, 
  RegisterRequest, 
  ForgotPasswordRequest, 
  ResetPasswordRequest,
  RefreshTokenRequest,
  LogoutRequest,
  CaptchaRequest,
  AuthResponseData,
  UserInfo,
  DeviceInfo
} from '../dto/UserDto';
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';

// 常量定义
const TAG = 'AuthService';
const STORAGE_KEYS = {
  AUTH_TOKEN: 'auth_token',
  REFRESH_TOKEN: 'refresh_token',
  USER_INFO: 'user_info',
  DEVICE_ID: 'device_id',
  SESSION_EXPIRY: 'session_expiry'
};

// 认证相关的API端点
const API_ENDPOINTS = {
  LOGIN: '/api/auth/login',
  REGISTER: '/api/auth/register',
  LOGOUT: '/api/auth/logout',
  REFRESH_TOKEN: '/api/auth/refresh',
  FORGOT_PASSWORD: '/api/auth/forgot-password',
  RESET_PASSWORD: '/api/auth/reset-password',
  VERIFY_EMAIL: '/api/auth/verify-email',
  VERIFY_PHONE: '/api/auth/verify-phone',
  SEND_CAPTCHA: '/api/auth/send-captcha',
  GET_CAPTCHA: '/api/auth/captcha',
  ME: '/api/auth/me',
  UPDATE_PROFILE: '/api/auth/profile',
  CHANGE_PASSWORD: '/api/auth/change-password'
};

/**
 * 认证服务类
 * 负责处理用户认证相关的业务逻辑
 */
export default class AuthService {
  private static instance: AuthService;
  private networkRepo: NetworkRepository;
  private databaseRepo: DatabaseRepository;
  private deviceInfo: DeviceInfo | null = null;
  private tokenRefreshTimer: NodeJS.Timeout | null = null;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.initializeDeviceInfo();
    this.setupTokenRefresh();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }

  /**
   * 初始化设备信息
   */
  private async initializeDeviceInfo(): Promise<void> {
    try {
      // 尝试从存储中获取设备ID
      let deviceId = await StorageUtil.getString(STORAGE_KEYS.DEVICE_ID);
      
      if (!deviceId) {
        // 生成新的设备ID
        deviceId = this.generateDeviceId();
        await StorageUtil.setString(STORAGE_KEYS.DEVICE_ID, deviceId);
      }

      // 构建设备信息
      this.deviceInfo = {
        deviceId,
        deviceName: this.getDeviceName(),
        deviceType: this.getDeviceType(),
        os: this.getOSInfo(),
        osVersion: this.getOSVersion(),
        appVersion: this.getAppVersion(),
        screenWidth: this.getScreenWidth(),
        screenHeight: this.getScreenHeight(),
        userAgent: this.getUserAgent()
      };

      Logger.info(TAG, `Device initialized: ${JSON.stringify(this.deviceInfo)}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize device info', error);
    }
  }

  /**
   * 用户登录
   */
  public async login(request: LoginRequest): Promise<ApiResponse<AuthResponseData>> {
    try {
      Logger.info(TAG, 'Attempting login...', { username: request.username });

      // 添加设备信息
      const loginData = {
        ...request,
        deviceInfo: this.deviceInfo
      };

      // 调用登录API
      const response = await this.networkRepo.request<ApiResponse<AuthResponseData>>({
        url: API_ENDPOINTS.LOGIN,
        method: 'POST',
        data: loginData
      });

      if (response.isSuccess() && response.data) {
        // 保存认证信息
        await this.saveAuthData(response.data);
        // 设置令牌自动刷新
        this.setupTokenRefresh();
        // 同步用户信息到本地数据库
        if (response.data.user) {
          await this.syncUserInfo(response.data.user);
        }
        Logger.info(TAG, 'Login successful');
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Login failed', error);
      return ApiResponse.networkError<AuthResponseData>('登录失败，请检查网络连接或稍后重试');
    }
  }

  /**
   * 用户注册
   */
  public async register(request: RegisterRequest): Promise<ApiResponse<AuthResponseData>> {
    try {
      Logger.info(TAG, 'Attempting registration...', { username: request.username });

      // 验证密码是否匹配
      if (request.password !== request.confirmPassword) {
        return ApiResponse.validationError<AuthResponseData>([
          { field: 'confirmPassword', message: '两次输入的密码不一致' }
        ]);
      }

      // 调用注册API
      const response = await this.networkRepo.request<ApiResponse<AuthResponseData>>({
        url: API_ENDPOINTS.REGISTER,
        method: 'POST',
        data: request
      });

      if (response.isSuccess() && response.data) {
        // 保存认证信息
        await this.saveAuthData(response.data);
        // 设置令牌自动刷新
        this.setupTokenRefresh();
        Logger.info(TAG, 'Registration successful');
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Registration failed', error);
      return ApiResponse.networkError<AuthResponseData>('注册失败，请检查网络连接或稍后重试');
    }
  }

  /**
   * 用户登出
   */
  public async logout(allDevices: boolean = false): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Attempting logout...', { allDevices });

      // 获取当前令牌
      const token = await StorageUtil.getString(STORAGE_KEYS.AUTH_TOKEN);
      
      // 构建登出请求
      const logoutRequest: LogoutRequest = {
        token,
        deviceId: this.deviceInfo?.deviceId,
        allDevices
      };

      // 尝试调用登出API（即使失败也会清除本地数据）
      try {
        await this.networkRepo.request<ApiResponse<boolean>>({
          url: API_ENDPOINTS.LOGOUT,
          method: 'POST',
          data: logoutRequest,
          headers: {
            Authorization: `Bearer ${token}`
          }
        });
      } catch (apiError) {
        Logger.warn(TAG, 'Logout API call failed, proceeding with local cleanup', apiError);
      }

      // 清除本地认证数据
      await this.clearAuthData();
      // 清除令牌刷新定时器
      this.clearTokenRefreshTimer();
      // 清除本地数据库中的用户数据
      await this.clearLocalUserData();

      Logger.info(TAG, 'Logout successful');
      return ApiResponse.success(true, '登出成功');
    } catch (error) {
      Logger.error(TAG, 'Logout failed', error);
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '登出失败，请稍后重试');
    }
  }

  /**
   * 刷新令牌
   */
  public async refreshToken(): Promise<ApiResponse<AuthResponseData>> {
    try {
      // 获取刷新令牌
      const refreshToken = await StorageUtil.getString(STORAGE_KEYS.REFRESH_TOKEN);
      
      if (!refreshToken) {
        Logger.warn(TAG, 'No refresh token available');
        return ApiResponse.unauthorized<AuthResponseData>('认证已过期，请重新登录');
      }

      Logger.info(TAG, 'Attempting to refresh token...');

      // 构建刷新令牌请求
      const request: RefreshTokenRequest = {
        refreshToken,
        deviceId: this.deviceInfo?.deviceId
      };

      // 调用刷新令牌API
      const response = await this.networkRepo.request<ApiResponse<AuthResponseData>>({
        url: API_ENDPOINTS.REFRESH_TOKEN,
        method: 'POST',
        data: request
      });

      if (response.isSuccess() && response.data) {
        // 保存新的认证信息
        await this.saveAuthData(response.data);
        // 重新设置令牌刷新
        this.setupTokenRefresh();
        Logger.info(TAG, 'Token refreshed successfully');
      } else if (response.isAuthError()) {
        // 认证失败，清除本地数据
        await this.clearAuthData();
        this.clearTokenRefreshTimer();
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Token refresh failed', error);
      return ApiResponse.networkError<AuthResponseData>('令牌刷新失败');
    }
  }

  /**
   * 忘记密码
   */
  public async forgotPassword(request: ForgotPasswordRequest): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Processing forgot password request...');

      // 验证密码是否匹配
      if (request.newPassword !== request.confirmNewPassword) {
        return ApiResponse.validationError<boolean>([
          { field: 'confirmNewPassword', message: '两次输入的密码不一致' }
        ]);
      }

      // 调用忘记密码API
      const response = await this.networkRepo.request<ApiResponse<boolean>>({
        url: API_ENDPOINTS.FORGOT_PASSWORD,
        method: 'POST',
        data: request
      });

      if (response.isSuccess()) {
        Logger.info(TAG, 'Forgot password request processed successfully');
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Forgot password request failed', error);
      return ApiResponse.networkError<boolean>('密码重置失败，请稍后重试');
    }
  }

  /**
   * 重置密码
   */
  public async resetPassword(request: ResetPasswordRequest): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Processing reset password request...');

      // 验证密码是否匹配
      if (request.newPassword !== request.confirmNewPassword) {
        return ApiResponse.validationError<boolean>([
          { field: 'confirmNewPassword', message: '两次输入的密码不一致' }
        ]);
      }

      // 获取当前令牌
      const token = await StorageUtil.getString(STORAGE_KEYS.AUTH_TOKEN);

      // 调用重置密码API
      const response = await this.networkRepo.request<ApiResponse<boolean>>({
        url: API_ENDPOINTS.RESET_PASSWORD,
        method: 'POST',
        data: request,
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      if (response.isSuccess()) {
        Logger.info(TAG, 'Password reset successful');
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Password reset failed', error);
      return ApiResponse.networkError<boolean>('密码重置失败，请稍后重试');
    }
  }

  /**
   * 获取当前用户信息
   */
  public async getCurrentUserInfo(): Promise<ApiResponse<UserInfo>> {
    try {
      // 先从本地存储获取
      const storedUserInfo = await this.getStoredUserInfo();
      if (storedUserInfo) {
        return ApiResponse.success<UserInfo>(storedUserInfo);
      }

      // 如果本地没有，从服务器获取
      const token = await StorageUtil.getString(STORAGE_KEYS.AUTH_TOKEN);
      
      if (!token) {
        return ApiResponse.unauthorized<UserInfo>('未登录');
      }

      const response = await this.networkRepo.request<ApiResponse<UserInfo>>({
        url: API_ENDPOINTS.ME,
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      if (response.isSuccess() && response.data) {
        // 更新本地存储的用户信息
        await StorageUtil.setObject(STORAGE_KEYS.USER_INFO, response.data);
        // 同步到本地数据库
        await this.syncUserInfo(response.data);
      } else if (response.isAuthError()) {
        // 认证失败，清除本地数据
        await this.clearAuthData();
        this.clearTokenRefreshTimer();
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get current user info', error);
      return ApiResponse.networkError<UserInfo>('获取用户信息失败');
    }
  }

  /**
   * 发送验证码
   */
  public async sendCaptcha(request: CaptchaRequest): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Sending captcha...', { type: request.type });

      const response = await this.networkRepo.request<ApiResponse<boolean>>({
        url: API_ENDPOINTS.SEND_CAPTCHA,
        method: 'POST',
        data: request
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to send captcha', error);
      return ApiResponse.networkError<boolean>('发送验证码失败，请稍后重试');
    }
  }

  /**
   * 获取图形验证码
   */
  public async getCaptchaImage(request: Partial<CaptchaRequest> = {}): Promise<ApiResponse<{ key: string; image: string }>> {
    try {
      Logger.info(TAG, 'Getting captcha image...');

      const response = await this.networkRepo.request<ApiResponse<{ key: string; image: string }>>({
        url: API_ENDPOINTS.GET_CAPTCHA,
        method: 'GET',
        params: request
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get captcha image', error);
      return ApiResponse.networkError('获取验证码失败，请稍后重试');
    }
  }

  /**
   * 检查用户是否已登录
   */
  public async isLoggedIn(): Promise<boolean> {
    try {
      const token = await StorageUtil.getString(STORAGE_KEYS.AUTH_TOKEN);
      const expiry = await StorageUtil.getNumber(STORAGE_KEYS.SESSION_EXPIRY);
      
      if (!token || !expiry) {
        return false;
      }

      // 检查令牌是否过期
      const now = Date.now();
      return expiry > now;
    } catch (error) {
      Logger.error(TAG, 'Failed to check login status', error);
      return false;
    }
  }

  /**
   * 获取认证令牌
   */
  public async getAuthToken(): Promise<string | null> {
    try {
      const token = await StorageUtil.getString(STORAGE_KEYS.AUTH_TOKEN);
      const expiry = await StorageUtil.getNumber(STORAGE_KEYS.SESSION_EXPIRY);
      
      if (!token || !expiry) {
        return null;
      }

      // 检查令牌是否过期
      const now = Date.now();
      if (expiry <= now) {
        return null;
      }

      return token;
    } catch (error) {
      Logger.error(TAG, 'Failed to get auth token', error);
      return null;
    }
  }

  /**
   * 保存认证数据
   */
  private async saveAuthData(data: AuthResponseData): Promise<void> {
    try {
      // 保存令牌
      if (data.token) {
        await StorageUtil.setString(STORAGE_KEYS.AUTH_TOKEN, data.token);
      }

      // 保存刷新令牌
      if (data.refreshToken) {
        await StorageUtil.setString(STORAGE_KEYS.REFRESH_TOKEN, data.refreshToken);
      }

      // 保存用户信息
      if (data.user) {
        await StorageUtil.setObject(STORAGE_KEYS.USER_INFO, data.user);
      }

      // 计算并保存过期时间
      if (data.expiresIn) {
        const expiry = Date.now() + (data.expiresIn * 1000);
        await StorageUtil.setNumber(STORAGE_KEYS.SESSION_EXPIRY, expiry);
      }

      Logger.info(TAG, 'Auth data saved successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to save auth data', error);
    }
  }

  /**
   * 清除认证数据
   */
  private async clearAuthData(): Promise<void> {
    try {
      await StorageUtil.remove(STORAGE_KEYS.AUTH_TOKEN);
      await StorageUtil.remove(STORAGE_KEYS.REFRESH_TOKEN);
      await StorageUtil.remove(STORAGE_KEYS.USER_INFO);
      await StorageUtil.remove(STORAGE_KEYS.SESSION_EXPIRY);
      Logger.info(TAG, 'Auth data cleared successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to clear auth data', error);
    }
  }

  /**
   * 获取存储的用户信息
   */
  private async getStoredUserInfo(): Promise<UserInfo | null> {
    try {
      return await StorageUtil.getObject<UserInfo>(STORAGE_KEYS.USER_INFO);
    } catch (error) {
      Logger.error(TAG, 'Failed to get stored user info', error);
      return null;
    }
  }

  /**
   * 设置令牌自动刷新
   */
  private async setupTokenRefresh(): Promise<void> {
    // 清除之前的定时器
    this.clearTokenRefreshTimer();

    try {
      const expiry = await StorageUtil.getNumber(STORAGE_KEYS.SESSION_EXPIRY);
      
      if (!expiry) {
        return;
      }

      // 计算刷新时间（在过期前5分钟刷新）
      const now = Date.now();
      const refreshTime = expiry - (5 * 60 * 1000);
      const delay = refreshTime - now;

      if (delay > 0) {
        Logger.info(TAG, `Setting up token refresh in ${delay}ms`);
        
        this.tokenRefreshTimer = setTimeout(async () => {
          try {
            await this.refreshToken();
          } catch (error) {
            Logger.error(TAG, 'Scheduled token refresh failed', error);
          }
        }, delay);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to setup token refresh', error);
    }
  }

  /**
   * 清除令牌刷新定时器
   */
  private clearTokenRefreshTimer(): void {
    if (this.tokenRefreshTimer) {
      clearTimeout(this.tokenRefreshTimer);
      this.tokenRefreshTimer = null;
    }
  }

  /**
   * 同步用户信息到本地数据库
   */
  private async syncUserInfo(userInfo: UserInfo): Promise<void> {
    try {
      await this.databaseRepo.saveUser(userInfo);
    } catch (error) {
      Logger.error(TAG, 'Failed to sync user info to local database', error);
    }
  }

  /**
   * 清除本地数据库中的用户数据
   */
  private async clearLocalUserData(): Promise<void> {
    try {
      // 清除用户相关数据，但保留设置等非用户特定数据
      await this.databaseRepo.clearUserSpecificData();
    } catch (error) {
      Logger.error(TAG, 'Failed to clear local user data', error);
    }
  }

  // ========== 设备信息相关辅助方法 ==========

  /**
   * 生成设备ID
   */
  private generateDeviceId(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 10);
    return `device_${timestamp}_${random}`;
  }

  /**
   * 获取设备名称
   */
  private getDeviceName(): string {
    // 在实际应用中，这里应该调用HarmonyOS的API获取真实设备名称
    return 'RayTV Device';
  }

  /**
   * 获取设备类型
   */
  private getDeviceType(): 'phone' | 'tablet' | 'tv' | 'computer' | 'other' {
    // 在实际应用中，这里应该根据屏幕尺寸和系统特性判断
    return 'tv'; // 默认为TV设备
  }

  /**
   * 获取操作系统信息
   */
  private getOSInfo(): string {
    // 在实际应用中，这里应该调用HarmonyOS的API获取
    return 'HarmonyOS';
  }

  /**
   * 获取操作系统版本
   */
  private getOSVersion(): string {
    // 在实际应用中，这里应该调用HarmonyOS的API获取
    return '5.0';
  }

  /**
   * 获取应用版本
   */
  private getAppVersion(): string {
    // 在实际应用中，这里应该从应用配置中获取
    return '1.0.0';
  }

  /**
   * 获取屏幕宽度
   */
  private getScreenWidth(): number {
    // 在实际应用中，这里应该调用HarmonyOS的API获取
    return 1920;
  }

  /**
   * 获取屏幕高度
   */
  private getScreenHeight(): number {
    // 在实际应用中，这里应该调用HarmonyOS的API获取
    return 1080;
  }

  /**
   * 获取用户代理
   */
  private getUserAgent(): string {
    // 在实际应用中，这里应该根据设备信息构建
    return 'RayTV/1.0.0 (HarmonyOS 5.0; TV)';
  }
}