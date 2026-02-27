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
