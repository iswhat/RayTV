/**
 * LineManagerPage样式定义
 */
// 使用ArkTS样式系统
import FlexDirection from '@ohos.components';
import FlexAlign from '@ohos.components';
import ItemAlign from '@ohos.components';
import FontStyle from '@ohos.components';
import TextAlign from '@ohos.components';

export default {
  container: {
    .flexGrow: 1,
    .backgroundColor: '#f5f5f5',
  },
  header: {
    .flexDirection: FlexDirection.Row,
    .justifyContent: FlexAlign.SpaceBetween,
    .alignItems: ItemAlign.Center,
    .padding: 16,
    .backgroundColor: '#fff',
    .borderBottomWidth: 1,
    .borderBottomColor: '#e0e0e0',
  },
  title: {
    .fontSize: 20,
    .fontWeight: 700,
    .color: '#333',
  },
  addButton: {
    .paddingHorizontal: 16,
  },
  content: {
    .flexGrow: 1,
  },
  loading: {
    .flexGrow: 1,
    .justifyContent: FlexAlign.Center,
    .alignItems: ItemAlign.Center,
  },
  emptyContainer: {
    .flexGrow: 1,
    .justifyContent: FlexAlign.Center,
    .alignItems: ItemAlign.Center,
    .padding: 32,
  },
  emptyText: {
    .fontSize: 18,
    .color: '#666',
    .marginBottom: 8,
  },
  emptySubtext: {
    .fontSize: 14,
    .color: '#999',
    .marginBottom: 24,
  },
  emptyButton: {
    .paddingHorizontal: 24,
  },
  lineList: {
    .flexGrow: 1,
  },
  lineItem: {
    .backgroundColor: '#fff',
    .marginBottom: 12,
    .padding: 16,
    .borderRadius: 8,
    .marginHorizontal: 12,
  },
  currentLineItem: {
    .borderWidth: 2,
    .borderColor: '#4CAF50',
  },
  lineContent: {
    .flexGrow: 1,
  },
  lineHeader: {
    .flexDirection: FlexDirection.Row,
    .alignItems: ItemAlign.Center,
    .marginBottom: 8,
  },
  lineName: {
    .fontSize: 16,
    .fontWeight: 700,
    .color: '#333',
    .flexGrow: 1,
  },
  currentBadge: {
    .backgroundColor: '#4CAF50',
    .paddingHorizontal: 8,
    .paddingVertical: 4,
    .borderRadius: 4,
  },
  currentBadgeText: {
    .color: '#fff',
    .fontSize: 12,
    .fontWeight: 700,
  },
  lineUrl: {
    .fontSize: 14,
    .color: '#666',
    .marginBottom: 8,
  },
  lineInfo: {
    .flexDirection: FlexDirection.Row,
    .flexWrap: FlexWrap.Wrap,
    .marginBottom: 8,
  },
  infoText: {
    .fontSize: 12,
    .color: '#999',
    .marginRight: 12,
    .marginBottom: 4,
  },
  lineDescription: {
    .fontSize: 14,
    .color: '#666',
    .marginBottom: 12,
    .fontStyle: FontStyle.Italic,
  },
  lineActions: {
    .flexDirection: FlexDirection.Row,
    .marginTop: 8,
  },
  switchButton: {
    .marginRight: 12,
  },
  testSourceButton: {
    .flexGrow: 1,
  },
  testTabContent: {
    .flexGrow: 1,
    .padding: 16,
  },
  testTips: {
    .fontSize: 14,
    .color: '#666',
    .backgroundColor: '#fffde7',
    .padding: 12,
    .borderRadius: 8,
    .marginBottom: 16,
    .borderLeftWidth: 4,
    .borderLeftColor: '#ff9800',
  },
  testList: {
    .flexGrow: 1,
  },
  testItem: {
    .backgroundColor: '#fff',
    .marginBottom: 12,
    .padding: 16,
    .borderRadius: 8,
  },
  testItemContent: {
    .flexGrow: 1,
  },
  testLineName: {
    .fontSize: 16,
    .fontWeight: 700,
    .color: '#333',
    .marginBottom: 4,
  },
  testLineUrl: {
    .fontSize: 14,
    .color: '#666',
    .marginBottom: 4,
  },
  responseTimeBadge: {
    .backgroundColor: '#2196F3',
    .paddingHorizontal: 8,
    .paddingVertical: 4,
    .borderRadius: 4,
    .alignSelf: ItemAlign.Start,
    .marginBottom: 8,
  },
  responseTimeText: {
    .color: '#fff',
    .fontSize: 12,
    .fontWeight: 700,
  },
  dialogContent: {
    .paddingVertical: 16,
  },
  formItem: {
    .marginBottom: 16,
  },
  formLabel: {
    .fontSize: 14,
    .fontWeight: 500,
    .color: '#333',
    .marginBottom: 8,
  },
  input: {
    .backgroundColor: '#f5f5f5',
    .borderRadius: 4,
    .paddingHorizontal: 12,
    .paddingVertical: 8,
    .fontSize: 14,
  },
  cacheHint: {
    .fontSize: 12,
    .color: '#999',
    .marginTop: 4,
  },
  testDialogContent: {
    .padding: 16,
  },
  testLoading: {
    .paddingVertical: 32,
    .justifyContent: FlexAlign.Center,
    .alignItems: ItemAlign.Center,
  },
  testOptions: {
    .flexDirection: FlexDirection.Row,
    .justifyContent: FlexAlign.SpaceBetween,
    .alignItems: ItemAlign.Center,
    .marginVertical: 16,
    .paddingVertical: 8,
    .borderBottomWidth: 1,
    .borderBottomColor: '#e0e0e0',
  },
  testOptionText: {
    .fontSize: 14,
    .color: '#333',
  },
  testResult: {
    .marginTop: 16,
    .padding: 16,
    .backgroundColor: '#f9f9f9',
    .borderRadius: 8,
  },
  resultItem: {
    .flexDirection: FlexDirection.Row,
    .marginBottom: 8,
    .alignItems: ItemAlign.Center,
  },
  resultLabel: {
    .fontSize: 14,
    .color: '#666',
    .marginRight: 8,
  },
  successText: {
    .fontSize: 14,
    .color: '#4CAF50',
    .fontWeight: 700,
  },
  errorText: {
    .fontSize: 14,
    .color: '#f44336',
    .fontWeight: 700,
  },
  errorMessage: {
    .fontSize: 12,
    .color: '#999',
    .marginTop: 4,
  },
  responseTimeValue: {
    .fontSize: 16,
    .color: '#2196F3',
    .fontWeight: 700,
  },
  sourceTestDialog: {
    .width: '90%',
    .maxHeight: '80%',
  },
  sourceTestDialogContent: {
    .padding: 16,
  },
  sourceTestResults: {
    .maxHeight: 300,
    .marginTop: 16,
  },
  sourceTestItem: {
    .paddingVertical: 8,
    .borderBottomWidth: 1,
    .borderBottomColor: '#f0f0f0',
  },
  sourceTestItemContent: {
    .flexDirection: FlexDirection.Row,
    .justifyContent: FlexAlign.SpaceBetween,
    .alignItems: ItemAlign.Center,
  },
  sourceName: {
    .fontSize: 14,
    .color: '#333',
    .flexGrow: 1,
  },
  sourceStatusBadge: {
    .paddingHorizontal: 12,
    .paddingVertical: 4,
    .borderRadius: 4,
  },
  successBadge: {
    .backgroundColor: '#e8f5e9',
  },
  errorBadge: {
    .backgroundColor: '#ffebee',
  },
  sourceStatusText: {
    .fontSize: 12,
    .fontWeight: 700,
  },
  noResultsText: {
    .fontSize: 14,
    .color: '#999',
    .textAlign: TextAlign.Center,
    .paddingVertical: 32,
  },
}
