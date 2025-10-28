import React, { useState, useEffect, useRef } from 'react';
import { View, Text, Button, List, Input, Dialog, Tabs, TabBar, TabContent, Switch, Loading, Toast, ScrollView } from '@ray-js/components';
import { LineManager, LineItem, LineResponseResult, SourceResponseResult } from '../service/config/LineManager';
import Logger from '../common/util/Logger';
import styles from './LineManagerPageStyles';

const TAG = 'LineManagerPage';

const LineManagerPage: React.FC = () => {
  const lineManager = LineManager.getInstance();
  const [lines, setLines] = useState<LineItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showTestDialog, setShowTestDialog] = useState(false);
  const [showSourceTestDialog, setShowSourceTestDialog] = useState(false);
  const [currentTab, setCurrentTab] = useState(0);
  const [lineToTest, setLineToTest] = useState<LineItem | null>(null);
  const [testResults, setTestResults] = useState<LineResponseResult | null>(null);
  const [sourceTestResults, setSourceTestResults] = useState<SourceResponseResult[]>([]);
  const [testLoading, setTestLoading] = useState(false);
  const [sourceTestLoading, setSourceTestLoading] = useState(false);
  
  // 表单状态
  const [newLineName, setNewLineName] = useState('');
  const [newLineUrl, setNewLineUrl] = useState('');
  const [newLineDescription, setNewLineDescription] = useState('');
  const [newLineCacheTime, setNewLineCacheTime] = useState('24');
  const [testMultiThread, setTestMultiThread] = useState(false);
  const [sourceTestMultiThread, setSourceTestMultiThread] = useState(false);
  
  const [currentLine, setCurrentLine] = useState<LineItem | null>(null);
  const [hasLines, setHasLines] = useState(false);

  // 初始化页面数据
  useEffect(() => {
    initPage();
  }, []);

  // 初始化页面
  const initPage = async () => {
    try {
      setLoading(true);
      await loadLines();
    } catch (error) {
      Logger.error(TAG, `Failed to init page: ${error}`);
      Toast.show({ message: '页面初始化失败' });
    } finally {
      setLoading(false);
    }
  };

  // 加载线路列表
  const loadLines = async () => {
    try {
      const allLines = lineManager.getAllLines();
      setLines(allLines);
      setCurrentLine(lineManager.getCurrentLine() || null);
      setHasLines(lineManager.hasAvailableLines());
    } catch (error) {
      Logger.error(TAG, `Failed to load lines: ${error}`);
      throw error;
    }
  };

  // 添加线路
  const handleAddLine = async () => {
    try {
      if (!newLineName.trim()) {
        Toast.show({ message: '请输入线路名称' });
        return;
      }
      if (!newLineUrl.trim()) {
        Toast.show({ message: '请输入线路URL' });
        return;
      }

      const cacheTime = parseInt(newLineCacheTime);
      if (isNaN(cacheTime) || cacheTime < 24 || cacheTime > 72) {
        Toast.show({ message: '缓存时间必须在24-72小时之间' });
        return;
      }

      setLoading(true);
      const result = await lineManager.addLine(
        newLineName.trim(),
        newLineUrl.trim(),
        newLineDescription.trim(),
        cacheTime
      );

      if (result.success) {
        Toast.show({ message: result.message });
        setShowAddDialog(false);
        resetForm();
        await loadLines();
      } else {
        Toast.show({ message: result.message || '添加失败' });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to add line: ${error}`);
      Toast.show({ message: '添加线路失败' });
    } finally {
      setLoading(false);
    }
  };

  // 删除线路
  const handleDeleteLine = async (line: LineItem) => {
    try {
      Dialog.alert({
        title: '确认删除',
        message: `确定要删除线路"${line.name}"吗？`,
        confirmText: '删除',
        confirmTextStyle: { color: '#e74c3c' },
        onConfirm: async () => {
          setLoading(true);
          const result = await lineManager.deleteLine(line.id);
          if (result.success) {
            Toast.show({ message: '删除成功' });
            await loadLines();
          } else {
            Toast.show({ message: result.message || '删除失败' });
          }
          setLoading(false);
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to delete line: ${error}`);
      Toast.show({ message: '删除线路失败' });
    }
  };

  // 切换线路
  const handleSwitchLine = async (line: LineItem) => {
    try {
      setLoading(true);
      const result = await lineManager.switchToLine(line.id);
      if (result.success) {
        Toast.show({ message: result.message });
        await loadLines();
      } else {
        Toast.show({ message: result.message || '切换失败' });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to switch line: ${error}`);
      Toast.show({ message: '切换线路失败' });
    } finally {
      setLoading(false);
    }
  };

  // 刷新线路
  const handleRefreshLine = async (line: LineItem) => {
    try {
      setLoading(true);
      const result = await lineManager.refreshLine(line.id);
      if (result.success) {
        Toast.show({ message: result.message });
        await loadLines();
      } else {
        Toast.show({ message: result.message || '刷新失败' });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to refresh line: ${error}`);
      Toast.show({ message: '刷新线路失败' });
    } finally {
      setLoading(false);
    }
  };

  // 测试线路响应速度
  const handleTestLine = async (line: LineItem) => {
    try {
      setLineToTest(line);
      setTestResults(null);
      setTestLoading(true);
      setShowTestDialog(true);
      
      const result = await lineManager.testLineResponse(line.id, testMultiThread, 20000);
      setTestResults(result);
    } catch (error) {
      Logger.error(TAG, `Failed to test line: ${error}`);
      Toast.show({ message: '测试线路失败' });
    } finally {
      setTestLoading(false);
    }
  };

  // 测试片源响应速度
  const handleTestSources = async (line: LineItem) => {
    try {
      setLineToTest(line);
      setSourceTestResults([]);
      setSourceTestLoading(true);
      setShowSourceTestDialog(true);
      
      const results = await lineManager.testSourceResponses(line.id, sourceTestMultiThread, 15000);
      setSourceTestResults(results);
    } catch (error) {
      Logger.error(TAG, `Failed to test sources: ${error}`);
      Toast.show({ message: '测试片源失败' });
    } finally {
      setSourceTestLoading(false);
    }
  };

  // 更新线路缓存时间
  const handleUpdateCacheTime = async (line: LineItem, hours: number) => {
    try {
      if (hours < 24 || hours > 72) {
        Toast.show({ message: '缓存时间必须在24-72小时之间' });
        return;
      }
      
      setLoading(true);
      const result = await lineManager.updateLine(line.id, { cacheTime: hours });
      if (result.success) {
        Toast.show({ message: '缓存时间已更新' });
        await loadLines();
      } else {
        Toast.show({ message: result.message || '更新失败' });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update cache time: ${error}`);
      Toast.show({ message: '更新缓存时间失败' });
    } finally {
      setLoading(false);
    }
  };

  // 重置表单
  const resetForm = () => {
    setNewLineName('');
    setNewLineUrl('');
    setNewLineDescription('');
    setNewLineCacheTime('24');
  };

  // 格式化响应时间显示
  const formatResponseTime = (ms: number): string => {
    if (ms <= 0) return '未知';
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  };

  // 排序片源测试结果
  const sortSourceResults = (results: SourceResponseResult[]): SourceResponseResult[] => {
    return [...results].sort((a, b) => {
      // 成功的排在前面
      if (a.success !== b.success) return a.success ? -1 : 1;
      // 按响应时间升序排列
      return a.responseTime - b.responseTime;
    });
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>线路管理</Text>
        <Button
          type="primary"
          size="small"
          style={styles.addButton}
          onClick={() => setShowAddDialog(true)}
        >
          添加线路
        </Button>
      </View>

      {loading ? (
        <Loading size="large" style={styles.loading} />
      ) : (
        <View style={styles.content}>
          {!hasLines ? (
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyText}>暂无可用线路</Text>
              <Text style={styles.emptySubtext}>请添加线路以获取片源</Text>
              <Button
                type="primary"
                style={styles.emptyButton}
                onClick={() => setShowAddDialog(true)}
              >
                添加线路
              </Button>
            </View>
          ) : (
            <Tabs activeKey={currentTab.toString()} onChange={(e) => setCurrentTab(Number(e.key))}>
              <TabBar>
                <TabBar.Item key="0">线路列表</TabBar.Item>
                <TabBar.Item key="1">线路测试</TabBar.Item>
              </TabBar>
              <TabContent key="0">
                <List style={styles.lineList}>
                  {lines.map((line) => (
                    <List.Item
                      key={line.id}
                      style={[styles.lineItem, line.current && styles.currentLineItem]}
                      actions={[
                        <Button
                          key="test"
                          type="text"
                          size="small"
                          onClick={() => handleTestLine(line)}
                        >
                          测试
                        </Button>,
                        <Button
                          key="refresh"
                          type="text"
                          size="small"
                          onClick={() => handleRefreshLine(line)}
                        >
                          刷新
                        </Button>,
                        <Button
                          key="delete"
                          type="text"
                          size="small"
                          onClick={() => handleDeleteLine(line)}
                          style={{ color: '#e74c3c' }}
                        >
                          删除
                        </Button>
                      ]}
                    >
                      <View style={styles.lineContent}>
                        <View style={styles.lineHeader}>
                          <Text style={styles.lineName}>{line.name}</Text>
                          {line.current && (
                            <View style={styles.currentBadge}>
                              <Text style={styles.currentBadgeText}>当前</Text>
                            </View>
                          )}
                        </View>
                        <Text style={styles.lineUrl} numberOfLines={1}>{line.url}</Text>
                        <View style={styles.lineInfo}>
                          <Text style={styles.infoText}>片源数量: {line.sourceCount}</Text>
                          {line.responseTime && (
                            <Text style={styles.infoText}>响应时间: {formatResponseTime(line.responseTime)}</Text>
                          )}
                          <Text style={styles.infoText}>缓存时间: {line.cacheTime || 24}小时</Text>
                        </View>
                        {line.description && (
                          <Text style={styles.lineDescription}>{line.description}</Text>
                        )}
                        <View style={styles.lineActions}>
                          <Button
                            type={line.current ? 'warning' : 'primary'}
                            size="small"
                            disabled={line.current}
                            style={styles.switchButton}
                            onClick={() => handleSwitchLine(line)}
                          >
                            {line.current ? '当前线路' : '切换到'}
                          </Button>
                          <Button
                            type="primary"
                            size="small"
                            style={styles.testSourceButton}
                            onClick={() => handleTestSources(line)}
                          >
                            测试片源
                          </Button>
                        </View>
                      </View>
                    </List.Item>
                  ))}
                </List>
              </TabContent>
              <TabContent key="1">
                <View style={styles.testTabContent}>
                  <Text style={styles.testTips}>
                    提示：线路测试会尝试访问线路URL并计算响应时间，建议在网络良好的环境下进行。
                  </Text>
                  <List style={styles.testList}>
                    {lines.map((line) => (
                      <List.Item
                        key={line.id}
                        style={styles.testItem}
                        actions={[
                          <Button
                            type="primary"
                            size="small"
                            onClick={() => handleTestLine(line)}
                          >
                            测试
                          </Button>
                        ]}
                      >
                        <View style={styles.testItemContent}>
                          <Text style={styles.testLineName}>{line.name}</Text>
                          {line.responseTime && (
                            <View style={styles.responseTimeBadge}>
                              <Text style={styles.responseTimeText}>
                                {formatResponseTime(line.responseTime)}
                              </Text>
                            </View>
                          )}
                          <Text style={styles.testLineUrl} numberOfLines={1}>{line.url}</Text>
                        </View>
                      </List.Item>
                    ))}
                  </List>
                </View>
              </TabContent>
            </Tabs>
          )}
        </View>
      )}

      {/* 添加线路对话框 */}
      <Dialog
        title="添加线路"
        visible={showAddDialog}
        confirmText="添加"
        cancelText="取消"
        onConfirm={handleAddLine}
        onCancel={() => {
          setShowAddDialog(false);
          resetForm();
        }}
      >
        <View style={styles.dialogContent}>
          <View style={styles.formItem}>
            <Text style={styles.formLabel}>线路名称 *</Text>
            <Input
              placeholder="请输入线路名称"
              value={newLineName}
              onChange={(e) => setNewLineName(e.value)}
              style={styles.input}
            />
          </View>
          <View style={styles.formItem}>
            <Text style={styles.formLabel}>线路URL *</Text>
            <Input
              placeholder="请输入线路配置URL"
              value={newLineUrl}
              onChange={(e) => setNewLineUrl(e.value)}
              style={styles.input}
            />
          </View>
          <View style={styles.formItem}>
            <Text style={styles.formLabel}>线路描述</Text>
            <Input
              placeholder="请输入线路描述（可选）"
              value={newLineDescription}
              onChange={(e) => setNewLineDescription(e.value)}
              style={styles.input}
            />
          </View>
          <View style={styles.formItem}>
            <Text style={styles.formLabel}>缓存时间（小时） *</Text>
            <Input
              placeholder="24-72"
              value={newLineCacheTime}
              onChange={(e) => setNewLineCacheTime(e.value)}
              style={styles.input}
              keyboardType="number"
            />
            <Text style={styles.cacheHint}>推荐设置24小时</Text>
          </View>
        </View>
      </Dialog>

      {/* 线路测试对话框 */}
      <Dialog
        title="线路测试"
        visible={showTestDialog}
        confirmText="关闭"
        onCancel={() => setShowTestDialog(false)}
        onConfirm={() => setShowTestDialog(false)}
      >
        <View style={styles.testDialogContent}>
          {testLoading ? (
            <Loading size="small" style={styles.testLoading} />
          ) : lineToTest ? (
            <>
              <Text style={styles.testLineName}>{lineToTest.name}</Text>
              <Text style={styles.testLineUrl}>{lineToTest.url}</Text>
              <View style={styles.testOptions}>
                <Text style={styles.testOptionText}>多线程测试</Text>
                <Switch
                  checked={testMultiThread}
                  onChange={(checked) => setTestMultiThread(checked)}
                />
              </View>
              {testResults && (
                <View style={styles.testResult}>
                  {testResults.success ? (
                    <>
                      <View style={styles.resultItem}>
                        <Text style={styles.resultLabel}>测试结果：</Text>
                        <Text style={styles.successText}>成功</Text>
                      </View>
                      <View style={styles.resultItem}>
                        <Text style={styles.resultLabel}>响应时间：</Text>
                        <Text style={styles.responseTimeValue}>
                          {formatResponseTime(testResults.responseTime)}
                        </Text>
                      </View>
                    </>
                  ) : (
                    <>
                      <View style={styles.resultItem}>
                        <Text style={styles.resultLabel}>测试结果：</Text>
                        <Text style={styles.errorText}>失败</Text>
                      </View>
                      <Text style={styles.errorMessage}>{testResults.error || '未知错误'}</Text>
                    </>
                  )}
                </View>
              )}
            </>
          ) : null}
        </View>
      </Dialog>

      {/* 片源测试对话框 */}
      <Dialog
        title="片源响应测试"
        visible={showSourceTestDialog}
        confirmText="关闭"
        onCancel={() => setShowSourceTestDialog(false)}
        onConfirm={() => setShowSourceTestDialog(false)}
        style={styles.sourceTestDialog}
      >
        <View style={styles.sourceTestDialogContent}>
          {sourceTestLoading ? (
            <Loading size="small" style={styles.testLoading} />
          ) : lineToTest ? (
            <>
              <Text style={styles.testLineName}>{lineToTest.name}</Text>
              <View style={styles.testOptions}>
                <Text style={styles.testOptionText}>多线程测试</Text>
                <Switch
                  checked={sourceTestMultiThread}
                  onChange={(checked) => setSourceTestMultiThread(checked)}
                />
              </View>
              {sourceTestResults.length > 0 ? (
                <ScrollView style={styles.sourceTestResults}>
                  <List>
                    {sortSourceResults(sourceTestResults).map((result) => (
                      <List.Item key={result.sourceId} style={styles.sourceTestItem}>
                        <View style={styles.sourceTestItemContent}>
                          <Text style={styles.sourceName}>{result.sourceName}</Text>
                          <View style={[styles.sourceStatusBadge, result.success ? styles.successBadge : styles.errorBadge]}>
                            <Text style={styles.sourceStatusText}>
                              {result.success ? formatResponseTime(result.responseTime) : '失败'}
                            </Text>
                          </View>
                        </View>
                      </List.Item>
                    ))}
                  </List>
                </ScrollView>
              ) : (
                <Text style={styles.noResultsText}>暂无测试结果</Text>
              )}
            </>
          ) : null}
        </View>
      </Dialog>
    </View>
  );
};

export default LineManagerPage;
