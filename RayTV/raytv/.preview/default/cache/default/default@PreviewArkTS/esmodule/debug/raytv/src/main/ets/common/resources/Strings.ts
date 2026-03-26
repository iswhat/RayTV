/**
 * 应用字符串资源文件
 * 集中管理所有错误消息、提示文本等
 */
export const Strings = {
    // 通用错误消息
    common: {
        error: '操作失败',
        loading: '加载中...',
        retry: '重试',
        back: '返回',
        confirm: '确认',
        cancel: '取消',
        success: '操作成功',
        failed: '操作失败'
    },
    // MainPage 相关
    mainPage: {
        appTitle: 'RayTV',
        loadingContent: '正在加载推荐内容...',
        loadFailed: '推荐内容加载失败',
        noData: '暂无数据，请在设置中配置网络源',
        categories: {
            all: '全部',
            featured: '为你推荐',
            popular: '热门内容',
            new: '最新上线'
        },
        tabs: {
            vod: '点播',
            live: '直播',
            search: '搜索',
            history: '历史',
            settings: '设置'
        }
    },
    // LivePage 相关
    livePage: {
        loading: '正在加载直播内容...',
        noData: '未配置直播源，请在设置中添加网络源',
        loadingFailed: '加载失败',
        reconnecting: '正在重连...',
        playing: '直播中',
        buffering: '缓冲中...',
        error: '播放错误',
        back: '返回',
        categories: {
            all: '全部'
        },
        playback: {
            volume: '音量',
            brightness: '亮度',
            speed: '播放速度'
        },
        errorMessages: {
            network: '网络连接失败',
            decode: '视频解码失败',
            source: '源地址失效或权限不足',
            unknown: '播放错误'
        },
        errorActions: {
            retry: '重试',
            retryConnection: '重试连接',
            switchLine: '切换线路',
            switchSource: '切换源'
        }
    },
    // SettingsPage 相关
    settingsPage: {
        title: '设置',
        reset: '重置',
        loading: '加载中...',
        loadingFailed: '加载失败',
        networkSources: '网络源管理',
        vodSites: '点播站点配置',
        liveChannels: '直播频道配置',
        wallpapers: '壁纸设置',
        advanced: '高级设置',
        healthCheck: '源健康检查',
        checkAll: '检查全部',
        adBlock: '广告过滤',
        dataSync: '数据同步',
        voiceAssistant: '语音助手',
        gestureControl: '手势控制',
        deviceFlow: '设备流转',
        cache: '缓存管理',
        deviceInfo: '设备信息',
        version: '版本信息',
        addSource: '+ 添加网络源',
        sourceTest: '正在测试源...',
        sourceAccessible: '源可访问',
        sourceNotAccessible: '源无法访问，请检查URL是否正确',
        sourceAdded: '源添加成功',
        sourceAddFailed: '添加源失败',
        validation: {
            nameRequired: '请输入源名称',
            nameLength: '源名称长度应在2-50个字符之间',
            urlRequired: '请输入源URL',
            urlProtocol: '只支持http和https协议的URL',
            urlFormat: 'URL格式不正确'
        },
        cacheItems: {
            video: '视频缓存',
            image: '图片缓存',
            config: '配置缓存',
            selectAll: '全选',
            clear: '清理',
            noItems: '请选择要清理的缓存项'
        },
        sync: {
            status: '同步状态',
            lastSync: '上次同步',
            syncing: '同步中...',
            success: '同步成功',
            failed: '同步失败',
            notSynced: '未同步',
            never: '从未'
        },
        deviceFlowConfig: {
            status: '设备流转状态',
            devices: '可用设备',
            noDevices: '未发现设备',
            loadingFailed: '加载失败'
        },
        voiceAssistantConfig: {
            status: '语音助手状态',
            notInitialized: '未初始化'
        },
        gestureControlConfig: {
            status: '手势控制状态',
            notInitialized: '未初始化'
        }
    },
    // 服务相关
    services: {
        initializationFailed: '服务初始化失败',
        networkError: '网络错误',
        timeout: '连接超时',
        notFound: '资源未找到',
        unauthorized: '权限不足',
        forbidden: '访问被禁止'
    }
};
export default Strings;
