import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Button, ScrollView, List, Switch, AlertDialog, Toast } from '@ray-js/components';
import { SubscriptionManager, SubscriptionItem } from '../../service/config/SubscriptionManager';
import Logger from '../../common/util/Logger';
import { Loading } from '../../components/Loading';
import { Icon } from '../../components/Icon';
import { formatDateTime } from '../../common/util/DateUtils';

const TAG = 'SubscriptionManagerPage';

/**
 * 订阅管理页面
 */
const SubscriptionManagerPage = () => {
  const [subscriptions, setSubscriptions] = useState<SubscriptionItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [urlInput, setUrlInput] = useState<string>('');
  const [nameInput, setNameInput] = useState<string>('');
  const [showAddDialog, setShowAddDialog] = useState<boolean>(false);
  const [selectedSubscription, setSelectedSubscription] = useState<SubscriptionItem | null>(null);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  // 示例配置URL列表
  const defaultUrls = [
    'https://list.eoeoo.com/base2/a.json',
    'https://q.uoouo.com/dianshi.json',
    'https://q.uoouo.com/jsm.json'
  ];

  // 初始化加载订阅列表
  useEffect(() => {
    loadSubscriptions();
  }, []);

  // 加载订阅列表
  const loadSubscriptions = async () => {
    try {
      setLoading(true);
      const subs = await SubscriptionManager.getInstance().getAllSubscriptions();
      setSubscriptions(subs);
      Logger.info(TAG, `Loaded ${subs.length} subscriptions`);
    } catch (error) {
      Logger.error(TAG, `Failed to load subscriptions: ${error}`);
      Toast.show('加载订阅列表失败');
    } finally {
      setLoading(false);
    }
  };

  // 添加订阅
  const handleAddSubscription = async () => {
    if (!urlInput.trim()) {
      Toast.show('请输入配置URL');
      return;
    }

    try {
      setActionLoading(true);
      const name = nameInput.trim() || extractNameFromUrl(urlInput);
      const result = await SubscriptionManager.getInstance().addSubscription(urlInput, name);
      
      if (result.success) {
        Toast.show('添加订阅成功');
        setShowAddDialog(false);
        setUrlInput('');
        setNameInput('');
        await loadSubscriptions();
        
        // 如果是第一个订阅，自动设为当前
        const currentSubscriptions = await SubscriptionManager.getInstance().getAllSubscriptions();
        if (currentSubscriptions.length === 1) {
          await handleSwitchSubscription(result.subscription!.id);
        }
      } else {
        Toast.show(result.message || '添加订阅失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to add subscription: ${error}`);
      Toast.show('添加订阅失败');
    } finally {
      setActionLoading(false);
    }
  };

  // 从URL提取名称
  const extractNameFromUrl = (url: string): string => {
    try {
      const urlObj = new URL(url);
      const pathname = urlObj.pathname;
      const filename = pathname.substring(pathname.lastIndexOf('/') + 1);
      return filename.replace(/\.[^/.]+$/, '') || '未命名订阅';
    } catch {
      return '未命名订阅';
    }
  };

  // 删除订阅
  const handleDeleteSubscription = async (subscription: SubscriptionItem) => {
    const isCurrent = subscription.current;
    
    try {
      setActionLoading(true);
      await SubscriptionManager.getInstance().deleteSubscription(subscription.id);
      Toast.show('删除订阅成功');
      
      // 如果删除的是当前订阅，需要选择新的当前订阅
      if (isCurrent) {
        const remainingSubscriptions = await SubscriptionManager.getInstance().getAllSubscriptions();
        if (remainingSubscriptions.length > 0) {
          await handleSwitchSubscription(remainingSubscriptions[0].id);
        }
      }
      
      await loadSubscriptions();
    } catch (error) {
      Logger.error(TAG, `Failed to delete subscription: ${error}`);
      Toast.show('删除订阅失败');
    } finally {
      setActionLoading(false);
    }
  };

  // 切换当前订阅
  const handleSwitchSubscription = async (id: string) => {
    try {
      setActionLoading(true);
      await SubscriptionManager.getInstance().switchSubscription(id);
      Toast.show('切换订阅成功');
      await loadSubscriptions();
    } catch (error) {
      Logger.error(TAG, `Failed to switch subscription: ${error}`);
      Toast.show('切换订阅失败');
    } finally {
      setActionLoading(false);
    }
  };

  // 刷新订阅
  const handleRefreshSubscription = async (subscription: SubscriptionItem) => {
    try {
      setRefreshing(true);
      const result = await SubscriptionManager.getInstance().refreshSubscription(subscription.id);
      
      if (result.success) {
        Toast.show('刷新订阅成功');
        await loadSubscriptions();
      } else {
        Toast.show(result.message || '刷新订阅失败');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to refresh subscription: ${error}`);
      Toast.show('刷新订阅失败');
    } finally {
      setRefreshing(false);
    }
  };

  // 切换启用状态
  const handleToggleEnabled = async (subscription: SubscriptionItem, enabled: boolean) => {
    try {
      await SubscriptionManager.getInstance().updateSubscriptionEnabled(subscription.id, enabled);
      
      // 如果禁用的是当前订阅，需要选择新的当前订阅
      if (!enabled && subscription.current) {
        const remainingSubscriptions = await SubscriptionManager.getInstance().getAllSubscriptions();
        const enabledSubscriptions = remainingSubscriptions.filter(s => s.id !== subscription.id && s.enabled);
        if (enabledSubscriptions.length > 0) {
          await handleSwitchSubscription(enabledSubscriptions[0].id);
        }
      }
      
      await loadSubscriptions();
    } catch (error) {
      Logger.error(TAG, `Failed to toggle subscription enabled: ${error}`);
      Toast.show('更新订阅状态失败');
    }
  };

  // 显示删除确认对话框
  const showDeleteConfirm = (subscription: SubscriptionItem) => {
    setSelectedSubscription(subscription);
  };

  // 渲染订阅项
  const renderSubscriptionItem = (subscription: SubscriptionItem) => {
    return (
      <View className="subscription-item" key={subscription.id}>
        <View className="subscription-main">
          <View className="subscription-info">
            <Text className="subscription-name">
              {subscription.name}
              {subscription.current && <Text className="current-tag"> [当前]</Text>}
            </Text>
            <Text className="subscription-url">{subscription.url}</Text>
            <View className="subscription-meta">
              <Text className="meta-item">站点数: {subscription.siteCount}</Text>
              <Text className="meta-item">更新: {formatDateTime(subscription.updateTime)}</Text>
            </View>
          </View>
          <View className="subscription-actions">
            <Switch
              checked={subscription.enabled}
              onChange={(checked) => handleToggleEnabled(subscription, checked)}
            />
          </View>
        </View>
        <View className="subscription-controls">
          <Button
            type="text"
            size="small"
            onClick={() => handleRefreshSubscription(subscription)}
            loading={refreshing}
          >
            刷新
          </Button>
          <Button
            type="text"
            size="small"
            onClick={() => handleSwitchSubscription(subscription.id)}
            disabled={subscription.current || !subscription.enabled}
          >
            {subscription.current ? '当前使用' : '设为当前'}
          </Button>
          <Button
            type="text"
            size="small"
            onClick={() => showDeleteConfirm(subscription)}
            danger
          >
            删除
          </Button>
        </View>
      </View>
    );
  };

  // 渲染默认URL选项
  const renderDefaultUrlOptions = () => {
    return (
      <View className="default-urls">
        <Text className="section-title">推荐配置源</Text>
        <View className="url-options">
          {defaultUrls.map((url, index) => (
            <Button
              key={index}
              type="text"
              size="small"
              onClick={() => {
                setUrlInput(url);
                setNameInput(extractNameFromUrl(url));
              }}
            >
              {extractNameFromUrl(url)}
            </Button>
          ))}
        </View>
      </View>
    );
  };

  if (loading) {
    return <Loading text="加载中..." />;
  }

  return (
    <View className="subscription-manager-page">
      <View className="header">
        <Text className="title">配置源管理</Text>
      </View>
      
      <ScrollView className="content">
        {renderDefaultUrlOptions()}
        
        <Button
          type="primary"
          onClick={() => setShowAddDialog(true)}
          className="add-button"
        >
          添加配置源
        </Button>
        
        <View className="subscription-list">
          <Text className="section-title">已添加的配置源</Text>
          {subscriptions.length > 0 ? (
            subscriptions.map(subscription => renderSubscriptionItem(subscription))
          ) : (
            <View className="empty-state">
              <Text>暂无配置源，请点击上方按钮添加</Text>
            </View>
          )}
        </View>
      </ScrollView>
      
      {/* 添加订阅对话框 */}
      <AlertDialog
        title="添加配置源"
        show={showAddDialog}
        onCancel={() => setShowAddDialog(false)}
        onOk={handleAddSubscription}
        okText="添加"
        cancelText="取消"
        okLoading={actionLoading}
      >
        <View className="add-dialog-content">
          <Text className="dialog-label">配置名称</Text>
          <TextInput
            className="input"
            value={nameInput}
            onChange={(e) => setNameInput(e.value)}
            placeholder="可选，不填将自动生成"
          />
          <Text className="dialog-label">配置URL</Text>
          <TextInput
            className="input"
            value={urlInput}
            onChange={(e) => setUrlInput(e.value)}
            placeholder="请输入配置文件URL"
          />
        </View>
      </AlertDialog>
      
      {/* 删除确认对话框 */}
      <AlertDialog
        title="确认删除"
        show={!!selectedSubscription}
        onCancel={() => setSelectedSubscription(null)}
        onOk={async () => {
          if (selectedSubscription) {
            await handleDeleteSubscription(selectedSubscription);
            setSelectedSubscription(null);
          }
        }}
        okText="删除"
        cancelText="取消"
        okLoading={actionLoading}
        okType="danger"
      >
        <Text>确定要删除配置源 "{selectedSubscription?.name}" 吗？</Text>
      </AlertDialog>
      
      <style>
        {
          `.subscription-manager-page {
            flex: 1;
            padding: 20px;
            background-color: #f5f5f5;
          }
          
          .header {
            margin-bottom: 20px;
          }
          
          .title {
            font-size: 24px;
            font-weight: bold;
            color: #333;
          }
          
          .content {
            flex: 1;
          }
          
          .add-button {
            margin: 20px 0;
            padding: 15px;
          }
          
          .default-urls {
            background-color: #fff;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
          }
          
          .section-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
          }
          
          .url-options {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
          }
          
          .subscription-list {
            background-color: #fff;
            padding: 15px;
            border-radius: 8px;
          }
          
          .subscription-item {
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
            background-color: #fafafa;
          }
          
          .subscription-main {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 10px;
          }
          
          .subscription-info {
            flex: 1;
          }
          
          .subscription-name {
            font-size: 16px;
            font-weight: bold;
            color: #333;
            margin-bottom: 5px;
          }
          
          .current-tag {
            color: #07c160;
            font-weight: normal;
          }
          
          .subscription-url {
            font-size: 14px;
            color: #666;
            margin-bottom: 8px;
            word-break: break-all;
          }
          
          .subscription-meta {
            display: flex;
            gap: 15px;
          }
          
          .meta-item {
            font-size: 12px;
            color: #999;
          }
          
          .subscription-actions {
            margin-left: 15px;
          }
          
          .subscription-controls {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
          }
          
          .empty-state {
            text-align: center;
            padding: 40px 0;
            color: #999;
          }
          
          .add-dialog-content {
            padding: 10px 0;
          }
          
          .dialog-label {
            font-size: 14px;
            color: #333;
            margin-bottom: 5px;
            margin-top: 10px;
          }
          
          .input {
            border: 1px solid #e0e0e0;
            border-radius: 4px;
            padding: 8px 12px;
            font-size: 14px;
            width: 100%;
            margin-bottom: 10px;
          }
          `
        }
      </style>
    </View>
  );
};

export default SubscriptionManagerPage;
