// 解析线路 | Parse line
export interface ParseLine {
  id: string;
  name: string;
  selected: boolean;
}

// 媒体信息接口 | Media info interface
export interface MediaInfo {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  episodes: Array<{
    id: string;
    title: string;
    episode: number;
    duration?: string;
    played?: boolean;
  }>;
  parseLines: Array<{
    id: string;
    name: string;
  }>;
  type: string;
  siteKey: string;
  rating?: string;
  year?: string;
  region?: string;
  director?: string;
  actor?: string;
}

// 音频轨道接口 | Audio track interface
export interface AudioTrack {
  id: string;
  name: string;
  language?: string;
  selected?: boolean;
}

// 字幕样式接口 | Subtitle style interface
export interface SubtitleStyle {
  fontSize: number;
  fontFamily: string;
  fontWeight: string;
  color: string;
  backgroundColor: string;
  opacity: number;
  borderWidth: number;
  borderColor: string;
}

// 播放设置接口 | Playback settings interface
export interface PlaybackSettings {
  playbackSpeed: number;
  subtitleStyle: SubtitleStyle;
  selectedSubtitleId?: string;
  selectedAudioTrackId?: string;
  skipOpening: boolean;
  skipEnding: boolean;
}

// 剧集接口 | Episode interface
export interface Episode {
  id: string;
  title: string;
  episode: number;
  duration?: string;
  played?: boolean;
  current?: boolean;
}

// 可焦点元素接口 | Focusable element interface
export interface FocusableElement {
  id: string;
  type: string;
  focus(): void;
  blur(): void;
}

// 播放初始化参数接口 | Playback init params interface
export interface PlaybackInitParams {
  episode: Episode;
  line: ParseLine;
  mediaInfo: MediaInfo | null;
}

// 字幕搜索参数接口 | Subtitle search params interface
export interface SubtitleSearchParams {
  title: string;
  year?: string;
  languages: string[];
}

// 焦点样式接口 | Focus style interface
export interface FocusStyle {
  border: {
    width: number;
    color: string;
    radius: number;
  };
  shadow: {
    color: string;
    radius: number;
    offsetX: number;
    offsetY: number;
  };
}

// 播放状态接口 | Playback state interface
export interface PlaybackState {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  playbackSpeed: number;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  hasResumePoint: boolean;
  resumeMessage: string;
}

// UI状态接口 | UI state interface
export interface UiState {
  isLandscape: boolean;
  screenWidth: number;
  screenHeight: number;
  showControls: boolean;
  showEpisodeList: boolean;
  showMoreOptions: boolean;
  showSubtitleOptions: boolean;
  showAudioTrackOptions: boolean;
  showSkipOptions: boolean;
  videoPlayerHeight: number;
  controlHideTimer: number | null;
  currentFocusElement: string;
  showResumeDialog: boolean;
}

// 字幕状态接口 | Subtitle state interface
export interface SubtitleState {
  tracks: SubtitleTrack[];
  selectedTrack: SubtitleTrack | null;
  languages: string[];
  isSearching: boolean;
}

// 音轨状态接口 | Audio state interface
export interface AudioState {
  tracks: AudioTrack[];
  selectedTrack: AudioTrack | null;
}

// 跳过设置状态接口 | Skip state interface
export interface SkipState {
  skipOpeningTime: number;
  skipEndingTime: number;
  isSkipOpeningEnabled: boolean;
  isSkipEndingEnabled: boolean;
}

// 直播状态接口 | Live state interface
export interface LiveState {
  isLiveMode: boolean;
  showChannelList: boolean;
  showSettings: boolean;
}

// 媒体状态接口 | Media state interface
export interface MediaState {
  info: MediaInfo | null;
  episodes: Episode[];
  parseLines: ParseLine[];
  selectedEpisode: Episode | null;
  selectedLine: ParseLine | null;
}

// 播放状态回调接口 | Playback state callback interface
export interface PlaybackStateCallback {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  audioTracks?: AudioTrack[];
}

// 字幕轨道接口 | Subtitle track interface
export interface SubtitleTrack {
  id: string;
  name: string;
  language?: string;
  selected?: boolean;
  url?: string;
  format?: string;
}

// 字幕语言接口 | Subtitle language interface
export interface SubtitleLanguage {
  code: string;
  name: string;
  nativeName?: string;
}

// 路由参数接口 | Route params interface
export interface PlaybackRouteParams {
  id?: string;
  siteKey?: string;
  type?: string;
  url?: string;
  title?: string;
}

// 播放历史记录接口 | Playback history interface
export interface PlaybackHistory {
  mediaId: string;
  episodeId: string;
  siteKey: string;
  title: string;
  episodeTitle: string;
  currentTime: number;
  duration: number;
  lastPlayedAt: number;
  cover?: string;
}

// 播放进度接口 | Playback progress interface
export interface PlaybackProgress {
  mediaId: string;
  episodeId: string;
  currentTime: number;
  duration: number;
  updatedAt: number;
}
