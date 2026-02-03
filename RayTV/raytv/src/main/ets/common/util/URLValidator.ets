/**
 * URLValidator - URL安全验证工具
 * 防止开放重定向和SSRF攻击
 */

export class URLValidator {
  // 允许的协议
  private static readonly ALLOWED_PROTOCOLS: Set<string> = new Set([
    'http:',
    'https:'
  ]);

  // 阻止的主机名模式（内网地址）
  private static readonly BLOCKED_PATTERNS: RegExp[] = [
    /^localhost$/i,
    /^127\.\d+\.\d+\.\d+$/,
    /^10\.\d+\.\d+\.\d+$/,
    /^172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+$/,
    /^192\.168\.\d+\.\d+$/,
    /^0\.0\.0\.0$/,
    /^169\.254\.\d+\.\d+$/,  // 链路本地地址
    /^::1$/,                  // IPv6本地回环
    /^fd[0-9a-f]{2}:/i        // IPv6唯一本地地址
  ];

  // 允许的顶级域名列表
  private static readonly ALLOWED_TLDS: Set<string> = new Set([
    'com', 'org', 'net', 'edu', 'gov', 'mil', 'int',
    'cn', 'us', 'uk', 'jp', 'kr', 'de', 'fr', 'ru', 'br', 'in',
    'tv', 'io', 'co', 'ai', 'app', 'dev'
  ]);

  /**
   * 验证URL是否安全
   * @param url 要验证的URL
   * @throws {Error} 如果URL不安全
   */
  public static validateURL(url: string): void {
    if (!url || typeof url !== 'string') {
      throw new Error('URL must be a non-empty string');
    }

    try {
      const parsed = new URL(url);

      // 验证协议
      if (!this.ALLOWED_PROTOCOLS.has(parsed.protocol)) {
        throw new Error(`Unsupported protocol: ${parsed.protocol}`);
      }

      // 验证主机名
      this.validateHostname(parsed.hostname);

      // 验证端口（如果指定）
      if (parsed.port) {
        this.validatePort(parsed.port);
      }

      // 验证顶级域名
      this.validateTLD(parsed.hostname);

      // 验证路径（防止路径遍历）
      this.validatePath(parsed.pathname);

    } catch (error) {
      if (error instanceof Error) {
        throw error;
      }
      throw new Error(`Invalid URL: ${url}`);
    }
  }

  /**
   * 验证主机名
   * @param hostname 主机名
   * @throws {Error} 如果主机名被阻止
   */
  private static validateHostname(hostname: string): void {
    const lowerHostname = hostname.toLowerCase();

    for (const pattern of this.BLOCKED_PATTERNS) {
      if (pattern.test(lowerHostname)) {
        throw new Error(`Blocked internal address: ${hostname}`);
      }
    }

    // 检查IP地址格式
    const ipv4Pattern = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
    if (ipv4Pattern.test(hostname)) {
      const parts = hostname.split('.');
      for (const part of parts) {
        const num = parseInt(part, 10);
        if (num < 0 || num > 255) {
          throw new Error(`Invalid IP address: ${hostname}`);
        }
      }
    }
  }

  /**
   * 验证端口
   * @param port 端口号
   * @throws {Error} 如果端口无效或被阻止
   */
  private static validatePort(port: string): void {
    const portNum = parseInt(port, 10);

    if (isNaN(portNum) || portNum < 0 || portNum > 65535) {
      throw new Error(`Invalid port number: ${port}`);
    }

    // 阻止常见的内网服务端口
    const blockedPorts: Set<number> = new Set([
      22,   // SSH
      23,   // Telnet
      25,   // SMTP
      139,  // NetBIOS
      445,  // SMB
      3389, // RDP
      5900, // VNC
      6379, // Redis
      27017 // MongoDB
    ]);

    if (blockedPorts.has(portNum)) {
      throw new Error(`Blocked port: ${portNum}`);
    }
  }

  /**
   * 验证顶级域名
   * @param hostname 主机名
   * @throws {Error} 如果顶级域名无效
   */
  private static validateTLD(hostname: string): void {
    const parts = hostname.split('.');
    if (parts.length < 2) {
      throw new Error(`Invalid hostname: ${hostname}`);
    }

    const tld = parts[parts.length - 1].toLowerCase();
    // 如果不在白名单中，记录警告但不阻止（因为可能使用新的TLD）
    if (!this.ALLOWED_TLDS.has(tld)) {
      console.warn(`URLValidator: TLD not in whitelist: ${tld}`);
    }
  }

  /**
   * 验证路径
   * @param pathname 路径
   * @throws {Error} 如果路径包含危险内容
   */
  private static validatePath(pathname: string): void {
    if (!pathname) {
      return;
    }

    // 检查路径遍历
    const traversalPatterns = [
      /\.\./,           // 父目录
      /%2e%2e/i,       // URL编码的父目录
      /%252e/i         // 双重URL编码
    ];

    for (const pattern of traversalPatterns) {
      if (pattern.test(pathname)) {
        throw new Error(`Path traversal detected: ${pathname}`);
      }
    }
  }

  /**
   * 验证URL是否是绝对URL
   * @param url URL字符串
   * @returns 是否是绝对URL
   */
  public static isAbsoluteURL(url: string): boolean {
    try {
      const parsed = new URL(url);
      return parsed.protocol && parsed.hostname;
    } catch {
      return false;
    }
  }

  /**
   * 规范化URL
   * @param url URL字符串
   * @returns 规范化后的URL
   */
  public static normalizeURL(url: string): string {
    try {
      const parsed = new URL(url);
      return parsed.href;
    } catch {
      return url;
    }
  }

  /**
   * 从URL中提取域名
   * @param url URL字符串
   * @returns 域名
   */
  public static getDomain(url: string): string {
    try {
      const parsed = new URL(url);
      return parsed.hostname;
    } catch {
      return '';
    }
  }
}

export default URLValidator;
