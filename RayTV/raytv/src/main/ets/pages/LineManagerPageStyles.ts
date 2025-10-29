/**
 * LineManagerPage样式定义
 */
// 使用ArkTS样式系统，不需要StyleSheet

export default StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  addButton: {
    paddingHorizontal: 16,
  },
  content: {
    flex: 1,
  },
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#999',
    marginBottom: 24,
  },
  emptyButton: {
    paddingHorizontal: 24,
  },
  lineList: {
    flex: 1,
  },
  lineItem: {
    backgroundColor: '#fff',
    marginBottom: 12,
    padding: 16,
    borderRadius: 8,
    marginHorizontal: 12,
  },
  currentLineItem: {
    borderWidth: 2,
    borderColor: '#4CAF50',
  },
  lineContent: {
    flex: 1,
  },
  lineHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  lineName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    flex: 1,
  },
  currentBadge: {
    backgroundColor: '#4CAF50',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  currentBadgeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  lineUrl: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  lineInfo: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 8,
  },
  infoText: {
    fontSize: 12,
    color: '#999',
    marginRight: 12,
    marginBottom: 4,
  },
  lineDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 12,
    fontStyle: 'italic',
  },
  lineActions: {
    flexDirection: 'row',
    marginTop: 8,
  },
  switchButton: {
    marginRight: 12,
  },
  testSourceButton: {
    flex: 1,
  },
  testTabContent: {
    flex: 1,
    padding: 16,
  },
  testTips: {
    fontSize: 14,
    color: '#666',
    backgroundColor: '#fffde7',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
    borderLeftWidth: 4,
    borderLeftColor: '#ff9800',
  },
  testList: {
    flex: 1,
  },
  testItem: {
    backgroundColor: '#fff',
    marginBottom: 12,
    padding: 16,
    borderRadius: 8,
  },
  testItemContent: {
    flex: 1,
  },
  testLineName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 4,
  },
  testLineUrl: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  responseTimeBadge: {
    backgroundColor: '#2196F3',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    alignSelf: 'flex-start',
    marginBottom: 8,
  },
  responseTimeText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: 'bold',
  },
  dialogContent: {
    paddingVertical: 16,
  },
  formItem: {
    marginBottom: 16,
  },
  formLabel: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f5f5f5',
    borderRadius: 4,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
  },
  cacheHint: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
  },
  testDialogContent: {
    padding: 16,
  },
  testLoading: {
    paddingVertical: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  testOptions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginVertical: 16,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  testOptionText: {
    fontSize: 14,
    color: '#333',
  },
  testResult: {
    marginTop: 16,
    padding: 16,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
  },
  resultItem: {
    flexDirection: 'row',
    marginBottom: 8,
    alignItems: 'center',
  },
  resultLabel: {
    fontSize: 14,
    color: '#666',
    marginRight: 8,
  },
  successText: {
    fontSize: 14,
    color: '#4CAF50',
    fontWeight: 'bold',
  },
  errorText: {
    fontSize: 14,
    color: '#f44336',
    fontWeight: 'bold',
  },
  errorMessage: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
  },
  responseTimeValue: {
    fontSize: 16,
    color: '#2196F3',
    fontWeight: 'bold',
  },
  sourceTestDialog: {
    width: '90%',
    maxHeight: '80%',
  },
  sourceTestDialogContent: {
    padding: 16,
  },
  sourceTestResults: {
    maxHeight: 300,
    marginTop: 16,
  },
  sourceTestItem: {
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  sourceTestItemContent: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  sourceName: {
    fontSize: 14,
    color: '#333',
    flex: 1,
  },
  sourceStatusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 4,
  },
  successBadge: {
    backgroundColor: '#e8f5e9',
  },
  errorBadge: {
    backgroundColor: '#ffebee',
  },
  sourceStatusText: {
    fontSize: 12,
    fontWeight: 'bold',
  },
  noResultsText: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    paddingVertical: 32,
  },
});
