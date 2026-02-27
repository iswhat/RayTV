interface SettingsDTO {
  theme: 'light' | 'dark' | 'system';
  language: string;
  autoPlay: boolean;
  notifications: boolean;
  quality: 'low' | 'medium' | 'high' | 'auto';
}

export { SettingsDTO };