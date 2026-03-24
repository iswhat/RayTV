/**
 * ArkTS module declaration
 * This file tells TypeScript how to resolve .ets files
 */

declare module '*.ets' {
  import { FC } from '@ohos.arkui';
  const Component: FC<any>;
  export default Component;
  export { };
}

// HarmonyOS API declarations for development type checking
declare module '@ohos.hilog' {
  const hilog: {
    debug(domain: number, tag: string, format: string, ...args: any[]): void;
    info(domain: number, tag: string, format: string, ...args: any[]): void;
    warn(domain: number, tag: string, format: string, ...args: any[]): void;
    error(domain: number, tag: string, format: string, ...args: any[]): void;
    fatal(domain: number, tag: string, format: string, ...args: any[]): void;
    debug0(tag: string, format: string): void;
    info0(tag: string, format: string): void;
    warn0(tag: string, format: string): void;
    error0(tag: string, format: string): void;
  };
  export default hilog;
}

declare module '@ohos.router' {
  interface RouterOptions {
    uri: string;
    params?: Record<string, any>;
  }
  interface PushOptions extends RouterOptions {
    params?: Record<string, any>;
  }
  interface ReplaceOptions extends RouterOptions {
    params?: Record<string, any>;
  }
  export function push(options: PushOptions): void;
  export function replace(options: ReplaceOptions): void;
  export function back(): void;
  export function getParams(): Record<string, any>;
}

declare module '@ohos.data.preferences' {
  interface Preferences {
    get(key: string, defaultValue: any): Promise<any>;
    put(key: string, value: any): Promise<void>;
    delete(key: string): Promise<void>;
    flush(): Promise<void>;
  }
  interface GetOptions {
    name: string;
  }
  export function getPreferences(context: any, options: GetOptions): Promise<Preferences>;
}

declare module '@ohos.storage' {
  const persistentStorage: {
    get(key: string): any;
    set(key: string, value: any): void;
    delete(key: string): void;
    clear(): void;
  };
  export { persistentStorage };
}

declare module '@ohos.http' {
  interface HttpRequest {
    request(url: string, options: any): Promise<any>;
    on(type: 'headerReceive', callback: (data: object) => void): void;
    off(type: 'headerReceive', callback?: (data: object) => void): void;
    destroy(): void;
  }
  interface HttpOptions {
    method?: string;
    header?: Record<string, string>;
    extraData?: string | object;
    connectTimeout?: number;
    readTimeout?: number;
  }
  export function createHttp(): HttpRequest;
}