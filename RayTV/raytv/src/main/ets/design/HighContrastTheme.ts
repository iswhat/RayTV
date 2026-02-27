import { DesignSystem } from './DesignSystem';

const highContrastTheme: DesignSystem = {
  colors: {
    primary: '#0066FF',
    secondary: '#FF6600',
    background: '#000000',
    surface: '#1A1A1A',
    text: '#FFFFFF',
    textSecondary: '#CCCCCC',
    error: '#FF0000',
    success: '#00FF00',
    warning: '#FFFF00',
    info: '#00FFFF',
    border: '#666666',
    disabled: '#444444'
  },
  typography: {
    fontFamily: 'Roboto, sans-serif',
    fontSize: {
      small: 14,
      medium: 16,
      large: 18,
      xlarge: 22,
      xxlarge: 26
    },
    fontWeight: {
      regular: 400,
      medium: 600,
      bold: 800
    },
    lineHeight: {
      small: 1.5,
      medium: 1.6,
      large: 1.7
    }
  },
  spacing: {
    xs: 6,
    sm: 10,
    md: 18,
    lg: 26,
    xl: 34,
    xxl: 50
  },
  borderRadius: {
    small: 6,
    medium: 10,
    large: 14,
    round: 9999
  },
  shadow: {
    small: '0 2px 6px rgba(255, 255, 255, 0.3)',
    medium: '0 4px 10px rgba(255, 255, 255, 0.4)',
    large: '0 8px 16px rgba(255, 255, 255, 0.5)'
  },
  breakpoints: {
    xs: 0,
    sm: 576,
    md: 768,
    lg: 992,
    xl: 1200,
    xxl: 1600
  }
};

export { highContrastTheme };