// 模块声明文件，用于解决缺失的模块类型声明问题

// @ohos模块声明
declare module '@ohos.net.http' {
  export const createHttp: () => any;
}

declare module '@ohos.net.connection' {
  export const getNetCapabilities: (callback: Function) => any;
}

declare module '@ohos.base' {
  export interface Result {
    code: number;
    message: string;
  }
}

declare module '@ohos.file.fs' {
  export const readText: (path: string) => Promise<string>;
  export const writeText: (path: string, content: string) => Promise<void>;
  export const existsSync: (path: string) => boolean;
  export const mkdir: (path: string) => Promise<void>;
  export const rmdir: (path: string, options?: { recursive: boolean }) => Promise<void>;
  export const unlink: (path: string) => Promise<void>;
  export const rename: (oldPath: string, newPath: string) => Promise<void>;
}

declare module '@ohos.file.fileIO' {
  export const openSync: (path: string, mode: number) => number;
  export const readSync: (fd: number, buffer: ArrayBuffer, offset: number, length: number, position: number) => number;
  export const writeSync: (fd: number, buffer: ArrayBuffer, offset: number, length: number, position: number) => number;
  export const closeSync: (fd: number) => void;
}

declare module '@ohos.abilityAccessCtrl' {
  export const verifyAccessToken: (tokenID: number, permissionName: string) => Promise<{ result: number }>;
}

declare module '@ohos.app.ability.common' {
  export class Context {
    resourceManager: any;
    applicationContext: any;
  }
}

declare module '@ohos.app.ability.UIAbilityContext' {
  import { Context } from '@ohos.app.ability.common';
  export class UIAbilityContext extends Context {
    readonly area: number;
    readonly filesDir: string;
    readonly cacheDir: string;
    readonly tempDir: string;
    readonly distributedFilesDir: string;
  }
}

// Logger模块声明
declare module '../common/util/Logger' {
  export interface LoggerExtraData {
    [key: string]: any;
  }
  export default class Logger {
    static d(tag: string, message: string, extra?: LoggerExtraData): void;
    static i(tag: string, message: string, extra?: LoggerExtraData): void;
    static w(tag: string, message: string, extra?: LoggerExtraData): void;
    static e(tag: string, message: string | Error, extra?: LoggerExtraData): void;
  }
}

// Hvigor模块声明
declare module '@ohos/hvigor-ohos-plugin' {
  export class HvigorOhosPlugin {
    constructor(options?: any);
  }
}

// 其他基础类型声明
declare interface Window {
  URL: typeof URL;
}

declare class URL {
  constructor(url: string, base?: string);
  searchParams: URLSearchParams;
  toString(): string;
}

declare class URLSearchParams {
  append(name: string, value: string): void;
  toString(): string;
}