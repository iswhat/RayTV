if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ImageLazyLoader_Params {
    isLoading?: boolean;
    isError?: boolean;
    isLoaded?: boolean;
    currentSrc?: string;
    cacheManager?: ImageCacheManager;
    retryCount?: number;
    maxRetries?: number;
    src?: string;
    placeholder?: string;
    errorPlaceholder?: string;
    lazyStrategy?: LazyLoadStrategy;
    threshold?: number;
    rootMargin?: string;
    enableCache?: boolean;
    cacheKey?: string;
    imgWidth?: string | number;
    imgHeight?: string | number;
    imgRadius?: string | number;
    onLoad?: (src: string) => void;
    onError?: (error: Error) => void;
}
import { ImageCacheManager } from "@bundle:com.raytv.app/raytv/ets/utils/ImageCacheManager";
import { LazyLoadStrategy } from "@bundle:com.raytv.app/raytv/ets/types/LazyLoadTypes";
export class ImageLazyLoader extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isLoading = new ObservedPropertySimplePU(false, this, "isLoading");
        this.__isError = new ObservedPropertySimplePU(false, this, "isError");
        this.__isLoaded = new ObservedPropertySimplePU(false, this, "isLoaded");
        this.__currentSrc = new ObservedPropertySimplePU('', this, "currentSrc");
        this.cacheManager = ImageCacheManager.getInstance();
        this.retryCount = 0;
        this.maxRetries = 3;
        this.__src = new SynchedPropertySimpleOneWayPU(params.src, this, "src");
        this.__placeholder = new SynchedPropertySimpleOneWayPU(params.placeholder, this, "placeholder");
        this.__errorPlaceholder = new SynchedPropertySimpleOneWayPU(params.errorPlaceholder, this, "errorPlaceholder");
        this.__lazyStrategy = new SynchedPropertySimpleOneWayPU(params.lazyStrategy, this, "lazyStrategy");
        this.__threshold = new SynchedPropertySimpleOneWayPU(params.threshold, this, "threshold");
        this.__rootMargin = new SynchedPropertySimpleOneWayPU(params.rootMargin, this, "rootMargin");
        this.__enableCache = new SynchedPropertySimpleOneWayPU(params.enableCache, this, "enableCache");
        this.__cacheKey = new SynchedPropertySimpleOneWayPU(params.cacheKey, this, "cacheKey");
        this.__imgWidth = new SynchedPropertySimpleOneWayPU(params.imgWidth, this, "imgWidth");
        this.__imgHeight = new SynchedPropertySimpleOneWayPU(params.imgHeight, this, "imgHeight");
        this.__imgRadius = new SynchedPropertySimpleOneWayPU(params.imgRadius, this, "imgRadius");
        this.__onLoad = new SynchedPropertyObjectOneWayPU(params.onLoad, this, "onLoad");
        this.__onError = new SynchedPropertyObjectOneWayPU(params.onError, this, "onError");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ImageLazyLoader_Params) {
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
        if (params.isError !== undefined) {
            this.isError = params.isError;
        }
        if (params.isLoaded !== undefined) {
            this.isLoaded = params.isLoaded;
        }
        if (params.currentSrc !== undefined) {
            this.currentSrc = params.currentSrc;
        }
        if (params.cacheManager !== undefined) {
            this.cacheManager = params.cacheManager;
        }
        if (params.retryCount !== undefined) {
            this.retryCount = params.retryCount;
        }
        if (params.maxRetries !== undefined) {
            this.maxRetries = params.maxRetries;
        }
        if (params.src === undefined) {
            this.__src.set('');
        }
        if (params.placeholder === undefined) {
            this.__placeholder.set('');
        }
        if (params.errorPlaceholder === undefined) {
            this.__errorPlaceholder.set('');
        }
        if (params.lazyStrategy === undefined) {
            this.__lazyStrategy.set(LazyLoadStrategy.INTERSECTION);
        }
        if (params.threshold === undefined) {
            this.__threshold.set(0.1);
        }
        if (params.rootMargin === undefined) {
            this.__rootMargin.set('50px');
        }
        if (params.enableCache === undefined) {
            this.__enableCache.set(true);
        }
        if (params.cacheKey === undefined) {
            this.__cacheKey.set('');
        }
        if (params.imgWidth === undefined) {
            this.__imgWidth.set('100%');
        }
        if (params.imgHeight === undefined) {
            this.__imgHeight.set('auto');
        }
        if (params.imgRadius === undefined) {
            this.__imgRadius.set(0);
        }
    }
    updateStateVars(params: ImageLazyLoader_Params) {
        this.__src.reset(params.src);
        this.__placeholder.reset(params.placeholder);
        this.__errorPlaceholder.reset(params.errorPlaceholder);
        this.__lazyStrategy.reset(params.lazyStrategy);
        this.__threshold.reset(params.threshold);
        this.__rootMargin.reset(params.rootMargin);
        this.__enableCache.reset(params.enableCache);
        this.__cacheKey.reset(params.cacheKey);
        this.__imgWidth.reset(params.imgWidth);
        this.__imgHeight.reset(params.imgHeight);
        this.__imgRadius.reset(params.imgRadius);
        this.__onLoad.reset(params.onLoad);
        this.__onError.reset(params.onError);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__isError.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoaded.purgeDependencyOnElmtId(rmElmtId);
        this.__currentSrc.purgeDependencyOnElmtId(rmElmtId);
        this.__src.purgeDependencyOnElmtId(rmElmtId);
        this.__placeholder.purgeDependencyOnElmtId(rmElmtId);
        this.__errorPlaceholder.purgeDependencyOnElmtId(rmElmtId);
        this.__lazyStrategy.purgeDependencyOnElmtId(rmElmtId);
        this.__threshold.purgeDependencyOnElmtId(rmElmtId);
        this.__rootMargin.purgeDependencyOnElmtId(rmElmtId);
        this.__enableCache.purgeDependencyOnElmtId(rmElmtId);
        this.__cacheKey.purgeDependencyOnElmtId(rmElmtId);
        this.__imgWidth.purgeDependencyOnElmtId(rmElmtId);
        this.__imgHeight.purgeDependencyOnElmtId(rmElmtId);
        this.__imgRadius.purgeDependencyOnElmtId(rmElmtId);
        this.__onLoad.purgeDependencyOnElmtId(rmElmtId);
        this.__onError.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isLoading.aboutToBeDeleted();
        this.__isError.aboutToBeDeleted();
        this.__isLoaded.aboutToBeDeleted();
        this.__currentSrc.aboutToBeDeleted();
        this.__src.aboutToBeDeleted();
        this.__placeholder.aboutToBeDeleted();
        this.__errorPlaceholder.aboutToBeDeleted();
        this.__lazyStrategy.aboutToBeDeleted();
        this.__threshold.aboutToBeDeleted();
        this.__rootMargin.aboutToBeDeleted();
        this.__enableCache.aboutToBeDeleted();
        this.__cacheKey.aboutToBeDeleted();
        this.__imgWidth.aboutToBeDeleted();
        this.__imgHeight.aboutToBeDeleted();
        this.__imgRadius.aboutToBeDeleted();
        this.__onLoad.aboutToBeDeleted();
        this.__onError.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __isError: ObservedPropertySimplePU<boolean>;
    get isError() {
        return this.__isError.get();
    }
    set isError(newValue: boolean) {
        this.__isError.set(newValue);
    }
    private __isLoaded: ObservedPropertySimplePU<boolean>;
    get isLoaded() {
        return this.__isLoaded.get();
    }
    set isLoaded(newValue: boolean) {
        this.__isLoaded.set(newValue);
    }
    private __currentSrc: ObservedPropertySimplePU<string>;
    get currentSrc() {
        return this.__currentSrc.get();
    }
    set currentSrc(newValue: string) {
        this.__currentSrc.set(newValue);
    }
    private cacheManager: ImageCacheManager;
    private retryCount: number;
    private maxRetries: number;
    // 组件属性 - 使用自定义名称避免与内置属性冲突
    private __src: SynchedPropertySimpleOneWayPU<string>;
    get src() {
        return this.__src.get();
    }
    set src(newValue: string) {
        this.__src.set(newValue);
    }
    private __placeholder: SynchedPropertySimpleOneWayPU<string>;
    get placeholder() {
        return this.__placeholder.get();
    }
    set placeholder(newValue: string) {
        this.__placeholder.set(newValue);
    }
    private __errorPlaceholder: SynchedPropertySimpleOneWayPU<string>;
    get errorPlaceholder() {
        return this.__errorPlaceholder.get();
    }
    set errorPlaceholder(newValue: string) {
        this.__errorPlaceholder.set(newValue);
    }
    private __lazyStrategy: SynchedPropertySimpleOneWayPU<LazyLoadStrategy>;
    get lazyStrategy() {
        return this.__lazyStrategy.get();
    }
    set lazyStrategy(newValue: LazyLoadStrategy) {
        this.__lazyStrategy.set(newValue);
    }
    private __threshold: SynchedPropertySimpleOneWayPU<number>;
    get threshold() {
        return this.__threshold.get();
    }
    set threshold(newValue: number) {
        this.__threshold.set(newValue);
    }
    private __rootMargin: SynchedPropertySimpleOneWayPU<string>;
    get rootMargin() {
        return this.__rootMargin.get();
    }
    set rootMargin(newValue: string) {
        this.__rootMargin.set(newValue);
    }
    private __enableCache: SynchedPropertySimpleOneWayPU<boolean>;
    get enableCache() {
        return this.__enableCache.get();
    }
    set enableCache(newValue: boolean) {
        this.__enableCache.set(newValue);
    }
    private __cacheKey: SynchedPropertySimpleOneWayPU<string>;
    get cacheKey() {
        return this.__cacheKey.get();
    }
    set cacheKey(newValue: string) {
        this.__cacheKey.set(newValue);
    }
    private __imgWidth: SynchedPropertySimpleOneWayPU<string | number>;
    get imgWidth() {
        return this.__imgWidth.get();
    }
    set imgWidth(newValue: string | number) {
        this.__imgWidth.set(newValue);
    }
    private __imgHeight: SynchedPropertySimpleOneWayPU<string | number>;
    get imgHeight() {
        return this.__imgHeight.get();
    }
    set imgHeight(newValue: string | number) {
        this.__imgHeight.set(newValue);
    }
    private __imgRadius: SynchedPropertySimpleOneWayPU<string | number>;
    get imgRadius() {
        return this.__imgRadius.get();
    }
    set imgRadius(newValue: string | number) {
        this.__imgRadius.set(newValue);
    }
    private __onLoad?: SynchedPropertySimpleOneWayPU<(src: string) => void>;
    get onLoad() {
        return this.__onLoad.get();
    }
    set onLoad(newValue: (src: string) => void) {
        this.__onLoad.set(newValue);
    }
    private __onError?: SynchedPropertySimpleOneWayPU<(error: Error) => void>;
    get onError() {
        return this.__onError.get();
    }
    set onError(newValue: (error: Error) => void) {
        this.__onError.set(newValue);
    }
    aboutToAppear(): void {
        this.initializeLazyLoading();
    }
    aboutToDisappear(): void {
        this.cleanup();
    }
    private initializeLazyLoading(): void {
        if (!this.src)
            return;
        const cacheKey = this.cacheKey || this.src;
        // 检查缓存
        if (this.enableCache && this.cacheManager.has(cacheKey)) {
            const cachedData = this.cacheManager.get(cacheKey);
            if (cachedData && !cachedData.error) {
                this.currentSrc = cachedData.data;
                this.isLoaded = true;
                this.onLoad?.(this.currentSrc);
                return;
            }
        }
        switch (this.lazyStrategy) {
            case LazyLoadStrategy.INTERSECTION:
                this.setupIntersectionObserver();
                break;
            case LazyLoadStrategy.SCROLL:
                this.setupScrollListener();
                break;
            case LazyLoadStrategy.VISIBLE:
                this.loadImmediately();
                break;
            case LazyLoadStrategy.DELAYED:
                this.loadWithDelay();
                break;
        }
    }
    private setupIntersectionObserver(): void {
        // 模拟交叉观察器实现
        // 在实际HarmonyOS环境中需要使用原生API
        setTimeout(() => {
            if (Math.random() > 0.3) { // 模拟元素进入视口
                this.loadImage();
            }
        }, 1000 + Math.random() * 2000);
    }
    private setupScrollListener(): void {
        // 监听滚动事件
        // 这里简化实现，在实际应用中需要监听具体的滚动容器
        setTimeout(() => {
            this.loadImage();
        }, 500);
    }
    private loadImmediately(): void {
        this.loadImage();
    }
    private loadWithDelay(): void {
        setTimeout(() => {
            this.loadImage();
        }, 1000);
    }
    private async loadImage(): Promise<void> {
        if (this.isLoading || this.isLoaded)
            return;
        this.isLoading = true;
        this.isError = false;
        try {
            const cacheKey = this.cacheKey || this.src;
            // 先检查缓存
            if (this.enableCache && this.cacheManager.has(cacheKey)) {
                const cachedData = this.cacheManager.get(cacheKey);
                if (cachedData && !cachedData.error) {
                    this.currentSrc = cachedData.data;
                    this.isLoaded = true;
                    this.isLoading = false;
                    this.onLoad?.(this.currentSrc);
                    return;
                }
            }
            // 网络加载
            const imageData = await this.fetchImage(this.src);
            // 缓存图片数据
            if (this.enableCache) {
                this.cacheManager.set(cacheKey, imageData);
            }
            this.currentSrc = imageData;
            this.isLoaded = true;
            this.onLoad?.(imageData);
        }
        catch (error) {
            console.error('Image loading failed:', error);
            this.handleError(error);
        }
        finally {
            this.isLoading = false;
        }
    }
    private async fetchImage(url: string): Promise<string> {
        return new Promise((resolve, reject) => {
            // 模拟网络请求
            setTimeout(() => {
                if (Math.random() > 0.1) { // 90%成功率
                    // 模拟返回图片数据
                    resolve(`data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/${encodeURIComponent(url)}`);
                }
                else {
                    reject(new Error('Network error'));
                }
            }, 200 + Math.random() * 800);
        });
    }
    private handleError(error: Error): void {
        this.isError = true;
        this.onError?.(error);
        // 自动重试机制
        if (this.retryCount < this.maxRetries) {
            this.retryCount++;
            setTimeout(() => {
                this.loadImage();
            }, 1000 * this.retryCount);
        }
    }
    private cleanup(): void {
        // cleanup: no observer to disconnect
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(175:5)", "raytv");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.isError && this.errorPlaceholder) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create(this.errorPlaceholder);
                        Image.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(177:9)", "raytv");
                        Image.width(this.imgWidth);
                        Image.height(this.imgHeight);
                        Image.borderRadius(this.imgRadius);
                        Image.onTouch(() => {
                            this.retryCount = 0;
                            this.loadImage();
                        });
                    }, Image);
                });
            }
            else if (this.isLoading && this.placeholder) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create(this.placeholder);
                        Image.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(186:9)", "raytv");
                        Image.width(this.imgWidth);
                        Image.height(this.imgHeight);
                        Image.borderRadius(this.imgRadius);
                    }, Image);
                });
            }
            else if (this.isLoaded && this.currentSrc) {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create(this.currentSrc);
                        Image.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(191:9)", "raytv");
                        Image.width(this.imgWidth);
                        Image.height(this.imgHeight);
                        Image.borderRadius(this.imgRadius);
                        Image.onComplete(() => {
                            console.log('Image loaded successfully');
                        });
                        Image.onError(() => {
                            this.isError = true;
                        });
                    }, Image);
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 默认占位符
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(203:9)", "raytv");
                        // 默认占位符
                        Row.width(this.imgWidth);
                        // 默认占位符
                        Row.height(this.imgHeight);
                        // 默认占位符
                        Row.borderRadius(this.imgRadius);
                        // 默认占位符
                        Row.backgroundColor('#f0f0f0');
                        // 默认占位符
                        Row.justifyContent(FlexAlign.Center);
                        // 默认占位符
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('[ ]');
                        Text.debugLine("raytv/src/main/ets/components/ImageLazyLoader.ets(204:11)", "raytv");
                        Text.fontSize(24);
                    }, Text);
                    Text.pop();
                    // 默认占位符
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
