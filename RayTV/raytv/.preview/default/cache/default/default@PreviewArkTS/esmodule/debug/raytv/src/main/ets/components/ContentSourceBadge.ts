if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SourceCard_Params {
    sourceName?: string;
    sourceId?: string;
    sourceUrl?: string;
    isActive?: boolean;
    healthStatus?: 'healthy' | 'degraded' | 'unreachable';
    priority?: number;
    tags?: string[];
    contentUsage?: Record<string, boolean>;
    onClick?: () => void;
    onToggle?: (isActive: boolean) => void;
}
interface MultiSourceBadge_Params {
    sources?: Array<SourceInfo>;
    style?: SourceBadgeStyle;
    maxShow?: number;
}
interface ContentSourceBadge_Params {
    sourceName?: string;
    sourceTags?: string[];
    sourcePriority?: number;
    style?: SourceBadgeStyle;
}
/**
 * Content Source Badge - 内容来源标识组件
 *
 * 用于在各个页面显示内容项的来源信息
 * 支持显示源名称、源标签、优先级等
 */
// ========================================
// Badge 样式配置
// ========================================
/**
 * 内边距配置接口
 */
export interface PaddingConfig {
    left: number;
    right: number;
    top: number;
    bottom: number;
}
export interface SourceBadgeStyle {
    showSourceName: boolean;
    showTags: boolean;
    showPriority: boolean;
    badgeColor: string;
    textColor: string;
    fontSize: number;
    padding: PaddingConfig;
    borderRadius: number;
}
const DEFAULT_PADDING: PaddingConfig = {
    left: 8,
    right: 8,
    top: 4,
    bottom: 4
};
const DEFAULT_STYLE: SourceBadgeStyle = {
    showSourceName: true,
    showTags: true,
    showPriority: false,
    badgeColor: '#E3F2FD',
    textColor: '#1976D2',
    fontSize: 12,
    padding: DEFAULT_PADDING,
    borderRadius: 4
};
export class ContentSourceBadge extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.sourceName = '';
        this.sourceTags = [];
        this.sourcePriority = 1;
        this.style = DEFAULT_STYLE;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ContentSourceBadge_Params) {
        if (params.sourceName !== undefined) {
            this.sourceName = params.sourceName;
        }
        if (params.sourceTags !== undefined) {
            this.sourceTags = params.sourceTags;
        }
        if (params.sourcePriority !== undefined) {
            this.sourcePriority = params.sourcePriority;
        }
        if (params.style !== undefined) {
            this.style = params.style;
        }
    }
    updateStateVars(params: ContentSourceBadge_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private sourceName: string;
    private sourceTags: string[];
    private sourcePriority: number;
    private style: SourceBadgeStyle;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.sourceName) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(63:7)", "raytv");
                        Row.padding({
                            left: this.style.padding.left,
                            right: this.style.padding.right,
                            top: this.style.padding.top,
                            bottom: this.style.padding.bottom
                        });
                        Row.backgroundColor(this.style.badgeColor);
                        Row.borderRadius(this.style.borderRadius);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 源名称
                        if (this.style.showSourceName) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.sourceName);
                                    Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(66:11)", "raytv");
                                    Text.fontSize(this.style.fontSize);
                                    Text.fontColor(this.style.textColor);
                                    Text.maxLines(1);
                                    Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                                }, Text);
                                Text.pop();
                            });
                        }
                        // 标签
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 标签
                        if (this.style.showTags && this.sourceTags.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = (_item, index: number) => {
                                        const tag = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(` ${tag}`);
                                            Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(76:13)", "raytv");
                                            Text.fontSize(this.style.fontSize - 1);
                                            Text.fontColor(this.style.textColor);
                                            Text.opacity(0.8);
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.sourceTags.slice(0, 2), forEachItemGenFunction, (tag: string, index: number) => `${tag}_${index}`, true, true);
                                }, ForEach);
                                ForEach.pop();
                            });
                        }
                        // 优先级
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 优先级
                        if (this.style.showPriority) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(` P${this.sourcePriority}`);
                                    Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(85:11)", "raytv");
                                    Text.fontSize(this.style.fontSize - 1);
                                    Text.fontColor(this.style.textColor);
                                    Text.opacity(0.6);
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
/**
 * 多源组合徽章组件
 *
/**
 * 源信息接口
 */
export interface SourceInfo {
    name: string;
    tags?: string[];
}
export class MultiSourceBadge extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.sources = [];
        this.style = DEFAULT_STYLE;
        this.maxShow = 2;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MultiSourceBadge_Params) {
        if (params.sources !== undefined) {
            this.sources = params.sources;
        }
        if (params.style !== undefined) {
            this.style = params.style;
        }
        if (params.maxShow !== undefined) {
            this.maxShow = params.maxShow;
        }
    }
    updateStateVars(params: MultiSourceBadge_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private sources: Array<SourceInfo>;
    private style: SourceBadgeStyle;
    private maxShow: number;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(124:5)", "raytv");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 显示前 N 个源
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const source = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(127:9)", "raytv");
                    Row.padding({
                        left: this.style.padding.left,
                        right: this.style.padding.right,
                        top: this.style.padding.top,
                        bottom: this.style.padding.bottom
                    });
                    Row.backgroundColor(this.style.badgeColor);
                    Row.borderRadius(this.style.borderRadius);
                    Row.margin({ right: 6 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(source.name);
                    Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(128:11)", "raytv");
                    Text.fontSize(this.style.fontSize);
                    Text.fontColor(this.style.textColor);
                    Text.maxLines(1);
                    Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (source.tags && source.tags.length > 0) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(` ${source.tags[0]}`);
                                Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(135:13)", "raytv");
                                Text.fontSize(this.style.fontSize - 1);
                                Text.fontColor(this.style.textColor);
                                Text.opacity(0.8);
                            }, Text);
                            Text.pop();
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(1, () => {
                        });
                    }
                }, If);
                If.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.sources.slice(0, this.maxShow), forEachItemGenFunction, (source: SourceInfo, index: number) => `${source.name}_${index}`, true, true);
        }, ForEach);
        // 显示前 N 个源
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 如果还有更多源，显示"+N"
            if (this.sources.length > this.maxShow) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(154:9)", "raytv");
                        Row.padding({
                            left: this.style.padding.left,
                            right: this.style.padding.right,
                            top: this.style.padding.top,
                            bottom: this.style.padding.bottom
                        });
                        Row.backgroundColor(this.style.badgeColor);
                        Row.borderRadius(this.style.borderRadius);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`+${this.sources.length - this.maxShow}`);
                        Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(155:11)", "raytv");
                        Text.fontSize(this.style.fontSize);
                        Text.fontColor(this.style.textColor);
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export class SourceCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.sourceName = '';
        this.sourceId = '';
        this.sourceUrl = '';
        this.isActive = true;
        this.healthStatus = 'healthy';
        this.priority = 1;
        this.tags = [];
        this.contentUsage = {};
        this.onClick = undefined;
        this.onToggle = undefined;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SourceCard_Params) {
        if (params.sourceName !== undefined) {
            this.sourceName = params.sourceName;
        }
        if (params.sourceId !== undefined) {
            this.sourceId = params.sourceId;
        }
        if (params.sourceUrl !== undefined) {
            this.sourceUrl = params.sourceUrl;
        }
        if (params.isActive !== undefined) {
            this.isActive = params.isActive;
        }
        if (params.healthStatus !== undefined) {
            this.healthStatus = params.healthStatus;
        }
        if (params.priority !== undefined) {
            this.priority = params.priority;
        }
        if (params.tags !== undefined) {
            this.tags = params.tags;
        }
        if (params.contentUsage !== undefined) {
            this.contentUsage = params.contentUsage;
        }
        if (params.onClick !== undefined) {
            this.onClick = params.onClick;
        }
        if (params.onToggle !== undefined) {
            this.onToggle = params.onToggle;
        }
    }
    updateStateVars(params: SourceCard_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private sourceName: string;
    private sourceId: string;
    private sourceUrl: string;
    private isActive: boolean;
    private healthStatus: 'healthy' | 'degraded' | 'unreachable';
    private priority: number;
    private tags: string[];
    private contentUsage: Record<string, boolean>;
    private onClick?: () => void;
    private onToggle?: (isActive: boolean) => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(191:5)", "raytv");
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(12);
            Column.shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.08)', offsetY: 2 });
            Column.onClick(() => {
                if (this.onClick) {
                    this.onClick();
                }
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 源信息头部
            Row.create();
            Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(193:7)", "raytv");
            // 源信息头部
            Row.width('100%');
            // 源信息头部
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 状态指示灯
            Row.create();
            Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(195:9)", "raytv");
            // 状态指示灯
            Row.width(10);
            // 状态指示灯
            Row.height(10);
            // 状态指示灯
            Row.borderRadius(5);
            // 状态指示灯
            Row.backgroundColor(this.getHealthColor(this.healthStatus));
            // 状态指示灯
            Row.margin({ right: 12 });
        }, Row);
        // 状态指示灯
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 源名称
            Column.create();
            Column.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(203:9)", "raytv");
            // 源名称
            Column.layoutWeight(1);
            // 源名称
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.sourceName);
            Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(204:11)", "raytv");
            Text.fontSize(16);
            Text.fontWeight(600);
            Text.fontColor('#333333');
            Text.maxLines(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.sourceUrl);
            Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(210:11)", "raytv");
            Text.fontSize(12);
            Text.fontColor('#999999');
            Text.maxLines(1);
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        Text.pop();
        // 源名称
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 优先级
            if (this.priority > 1) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`P${this.priority}`);
                        Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(221:11)", "raytv");
                        Text.fontSize(14);
                        Text.fontColor('#666666');
                        Text.margin({ right: 12 });
                        Text.padding({ left: 6, right: 6, top: 3, bottom: 3 });
                        Text.backgroundColor('#E0E0E0');
                        Text.borderRadius(10);
                    }, Text);
                    Text.pop();
                });
            }
            // 开关
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 开关
            Button.createWithChild();
            Button.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(231:9)", "raytv");
            // 开关
            Button.width(44);
            // 开关
            Button.height(26);
            // 开关
            Button.backgroundColor(this.isActive ? '#4CAF50' : '#E0E0E0');
            // 开关
            Button.borderRadius(13);
            // 开关
            Button.onClick(() => {
                if (this.onToggle) {
                    this.onToggle(!this.isActive);
                }
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isActive ? '✓' : '');
            Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(232:11)", "raytv");
            Text.fontSize(16);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        // 开关
        Button.pop();
        // 源信息头部
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 内容使用开关
            Column.create();
            Column.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(250:7)", "raytv");
            // 内容使用开关
            Column.width('100%');
            // 内容使用开关
            Column.padding(12);
            // 内容使用开关
            Column.backgroundColor('#F5F5F5');
            // 内容使用开关
            Column.borderRadius(6);
            // 内容使用开关
            Column.margin({ bottom: 12 });
        }, Column);
        this.renderUsageItem.bind(this)('点播', 'vodSites');
        this.renderUsageItem.bind(this)('直播', 'liveChannels');
        this.renderUsageItem.bind(this)('壁纸', 'wallpapers');
        this.renderUsageItem.bind(this)('广告过滤', 'adBlockRules');
        this.renderUsageItem.bind(this)('解码', 'decoderConfigs');
        this.renderUsageItem.bind(this)('解析器', 'parserConfigs');
        // 内容使用开关
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 标签
            if (this.tags.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(266:9)", "raytv");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, index: number) => {
                            const tag = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(tag);
                                Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(268:13)", "raytv");
                                Text.fontSize(12);
                                Text.fontColor('#666666');
                                Text.margin({ right: 6 });
                                Text.padding({ left: 8, right: 8, top: 4, bottom: 4 });
                                Text.backgroundColor('#E8F5E9');
                                Text.borderRadius(12);
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.tags.slice(0, 4), forEachItemGenFunction, (tag: string, index: number) => `${tag}_${index}`, true, true);
                    }, ForEach);
                    ForEach.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    private renderUsageItem(label: string, key: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(294:5)", "raytv");
            Row.width('100%');
            Row.margin({ bottom: 6 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(295:7)", "raytv");
            Text.fontSize(13);
            Text.fontColor('#666666');
            Text.width(80);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.contentUsage[key]) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('✓');
                        Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(301:9)", "raytv");
                        Text.fontSize(14);
                        Text.fontColor('#4CAF50');
                        Text.width(20);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('✗');
                        Text.debugLine("raytv/src/main/ets/components/ContentSourceBadge.ets(306:9)", "raytv");
                        Text.fontSize(14);
                        Text.fontColor('#E0E0E0');
                        Text.width(20);
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        Row.pop();
    }
    private getHealthColor(status: string): string {
        switch (status) {
            case 'healthy':
                return '#4CAF50';
            case 'degraded':
                return '#FF9800';
            case 'unreachable':
                return '#F44336';
            default:
                return '#9E9E9E';
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
export default ContentSourceBadge;
