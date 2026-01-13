# RayTV UI Design Architecture

## Overview
This document outlines the complete UI redesign for RayTV, focusing on landscape orientation and remote control usability. The design will implement all requested features while integrating with existing services.

## Design Principles
1. **Landscape-First**: Optimized for horizontal screens, especially TVs
2. **Remote Control Friendly**: Large buttons, clear navigation paths, keyboard optimization
3. **Service Integration**: All UI connects to actual services, no mock data
4. **Responsive**: Adapts to different screen sizes while maintaining landscape focus
5. **Visual Hierarchy**: Clear content organization with proper spacing

## Page Structure

### 1. MainPage
**Layout**: Landscape orientation
- **Top Area**:
  - Site source selector (click to switch sources)
  - Main function menu (VOD, Live, Search, History, Config Source, Settings)
- **Category Area**:
  - Category tabs (when in VOD mode)
- **Content Area**:
  - Recommended content with covers and titles

### 2. LivePage
**Layout**: Full-screen landscape
- **Playback Area**:
  - Live video playback
  - Left click zone: Semi-transparent channel categories and channel list
  - Right click zone: Playback settings (volume, brightness, speed)
  - Long press: Playback progress bar (scrollable for supported sources)

### 3. SearchPage
**Layout**: Landscape
- **Search Box**:
  - Virtual keyboard (remote-friendly)
  - Pinyin initials recommendations
  - System keyboard integration
  - Full text search capability

### 4. SearchResultPage
**Layout**: Landscape
- **Filter Area**:
  - Source filtering options
- **Results Area**:
  - Media covers + titles
  - All sources or filtered results

### 5. PlaybackPage
**Layout**: Landscape
- **Video Player**:
  - Small window playback
- **Info Area**:
  - Content description
  - Parser lines
  - Episode sorting options
- **Episode List**:
  - Episode navigation
- **Quick Search**:
  - Other line quick search

### 6. HistoryPage
**Layout**: Landscape
- **History List**:
  - Reverse chronological order
  - Covers, titles, playback progress

### 7. ConfigSourceSwitcher
**Layout**: Modal popup
- **Source List**:
  - Quick switching between configured sources

### 8. SettingsPage
**Layout**: Modal dialogs
- **Config Source Management**:
  - Add, manage, switch config sources
- **Source Selection**:
  - Select sources based on config
- **Wallpaper Switching**:
  - Change app wallpaper
- **Live Source Settings**:
  - Switch live sources from all configs
- **Ad Blocking**:
  - Toggle ad filtering
- **Version Information**:
  - App version details

## Navigation Flow
- **MainPage** → [VOD] → **PlaybackPage**
- **MainPage** → [Live] → **LivePage**
- **MainPage** → [Search] → **SearchPage** → **SearchResultPage** → **PlaybackPage**
- **MainPage** → [History] → **HistoryPage** → **PlaybackPage**
- **MainPage** → [Config Source] → **ConfigSourceSwitcher**
- **MainPage** → [Settings] → **SettingsPage**

## Component Design

### Reusable Components
1. **SiteSelector**: Source switching dropdown
2. **CategoryTabs**: Horizontal scrollable category tabs
3. **ContentGrid**: Grid layout for media items
4. **RemoteKeyboard**: Virtual keyboard for remote control
5. **ControlPanel**: Semi-transparent control panels
6. **ProgressBar**: Playback progress indicator
7. **EpisodeList**: Episode selection component
8. **FilterChip**: Source filtering chips

### Service Integration
- **MediaService**: Fetch VOD content
- **LiveStreamService**: Fetch live channels and stream
- **SearchService**: Perform searches and get recommendations
- **HistoryService**: Manage and retrieve history
- **ConfigService**: Manage config sources and settings
- **PlaybackService**: Control playback (speed, skip, etc.)
- **AdBlockManager**: Handle ad filtering
- **WallManager**: Manage wallpaper settings

## Interaction Design
1. **Remote Control Navigation**:
   - Up/Down/Left/Right: Navigate between elements
   - OK/Enter: Select items
   - Back: Return to previous screen
   - Menu: Open context menus

2. **Touch Interaction**:
   - Tap: Select items
   - Swipe: Scroll content
   - Long press: Show additional options

3. **Playback Controls**:
   - Play/Pause: Toggle playback
   - Fast forward/rewind: Skip 10/30 seconds
   - Speed adjustment: 0.5x-2.0x
   - Volume/brightness: On-screen controls

## Visual Design
- **Color Scheme**:
  - Primary: #007AFF (blue)
  - Secondary: #34C759 (green)
  - Accent: #FF9500 (orange)
  - Background: #121212 (dark)
  - Text: #FFFFFF (white), #8E8E93 (light gray)

- **Typography**:
  - Title: 24sp, bold
  - Subtitle: 20sp, medium
  - Body: 16sp, regular
  - Small: 14sp, light

- **Spacing**:
  - Large: 24px
  - Medium: 16px
  - Small: 8px

## Implementation Plan
1. **MainPage**: Implement new landscape design
2. **LivePage**: Create full-screen live interface
3. **SearchPage**: Implement search with virtual keyboard
4. **SearchResultPage**: Create result display with filtering
5. **PlaybackPage**: Implement playback interface
6. **HistoryPage**: Update with reverse chronological order
7. **ConfigSourceSwitcher**: Create source switching popup
8. **SettingsPage**: Update with all required settings
9. **AppNavigator**: Update to support all new pages
10. **Service Integration**: Ensure all UI connects to actual services

## Testing Strategy
- Remote control navigation testing
- Service integration testing
- Responsive design testing
- Performance testing on target devices
