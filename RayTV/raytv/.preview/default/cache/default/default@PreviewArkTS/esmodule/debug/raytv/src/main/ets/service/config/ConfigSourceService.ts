import Logger from "@bundle:com.raytv.app/raytv/ets/common/util/Logger";
import { HttpService } from "@bundle:com.raytv.app/raytv/ets/service/HttpService";
import type { ConfigSource, ParsedConfig } from '../interfaces/IConfigSourceService';
export type { ConfigSource } from '../interfaces/IConfigSourceService';
const TAG = 'ConfigSourceService';
/**
 * 配置源服务 | Config source service
 * 管理所有网络配置源，支持加载和解析配置 | Manages all network config sources, supports loading and parsing configs
 */
export class ConfigSourceService {
    private static instance: ConfigSourceService;
    private sources: ConfigSource[] = [];
    private parsedConfigCache: Map<string, ParsedConfig> = new Map();
    private isInitialized: boolean = false;
    private constructor() { }
    /**
     * 获取单例实例 | Get singleton instance
     */
    public static getInstance(): ConfigSourceService {
        if (!ConfigSourceService.instance) {
            ConfigSourceService.instance = new ConfigSourceService();
        }
        return ConfigSourceService.instance;
    }
    /**
     * 初始化服务 | Initialize service
     */
    public async initialize(): Promise<void> {
        if (this.isInitialized) {
            return;
        }
        try {
            Logger.info(TAG, 'ConfigSourceService initializing');
            this.isInitialized = true;
            Logger.info(TAG, 'ConfigSourceService initialized successfully');
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            Logger.error(TAG, 'Failed to initialize ConfigSourceService', err);
            throw err;
        }
    }
    /**
     * 获取所有配置源 | Get all config sources
     */
    public async getAllSources(): Promise<ConfigSource[]> {
        return this.sources;
    }
    /**
     * 添加配置源 | Add config source
     */
    public addSource(source: ConfigSource): void {
        const index = this.sources.findIndex(s => s.id === source.id);
        if (index >= 0) {
            this.sources[index] = source;
        }
        else {
            this.sources.push(source);
        }
    }
    /**
     * 移除配置源 | Remove config source
     */
    public removeSource(id: string): void {
        this.sources = this.sources.filter(s => s.id !== id);
        this.parsedConfigCache.delete(id);
    }
    /**
     * 根据URL获取解析后的配置 | Get parsed config by URL
     */
    public async getParsedConfig(url: string): Promise<ParsedConfig | null> {
        if (this.parsedConfigCache.has(url)) {
            return this.parsedConfigCache.get(url) || null;
        }
        try {
            const httpService = HttpService.getInstance();
            const response = await httpService.get<string>(url);
            if (!response || !response.data) {
                return null;
            }
            const content = response.data as string;
            const parsed = this.parseConfigContent(content);
            this.parsedConfigCache.set(url, parsed);
            return parsed;
        }
        catch (error) {
            const err = error instanceof Error ? error : new Error(String(error));
            Logger.error(TAG, `Failed to get parsed config for url: ${url}`, err);
            return null;
        }
    }
    /**
     * 解析配置内容 | Parse config content
     */
    private parseConfigContent(content: string): ParsedConfig {
        try {
            const json = JSON.parse(content) as Record<string, object[]>;
            const result: ParsedConfig = {
                sites: Array.isArray(json['sites']) ? json['sites'] as never[] : [],
                parsers: Array.isArray(json['parses']) ? json['parses'] as never[] : [],
                rules: Array.isArray(json['rules']) ? json['rules'] as never[] : [],
                wallpapers: Array.isArray(json['wallpapers']) ? json['wallpapers'] as never[] : [],
                lives: Array.isArray(json['lives']) ? json['lives'] as never[] : []
            };
            return result;
        }
        catch (error) {
            Logger.warn(TAG, 'Failed to parse config content, returning empty config');
            return {
                sites: [],
                parsers: [],
                rules: [],
                wallpapers: [],
                lives: []
            };
        }
    }
    /**
     * 清除解析缓存 | Clear parsed cache
     */
    public clearCache(): void {
        this.parsedConfigCache.clear();
    }
}
export default ConfigSourceService;
