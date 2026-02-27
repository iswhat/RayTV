interface ColorPalette {
  primary: string;
  secondary: string;
  background: string;
  surface: string;
  text: string;
  textSecondary: string;
  error: string;
  success: string;
  warning: string;
  info: string;
  border: string;
  disabled: string;
}

interface Typography {
  fontFamily: string;
  fontSize: {
    small: number;
    medium: number;
    large: number;
    xlarge: number;
    xxlarge: number;
  };
  fontWeight: {
    regular: number;
    medium: number;
    bold: number;
  };
  lineHeight: {
    small: number;
    medium: number;
    large: number;
  };
}

interface Spacing {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
}

interface BorderRadius {
  small: number;
  medium: number;
  large: number;
  round: number;
}

interface Shadow {
  small: string;
  medium: string;
  large: string;
}

interface DesignSystem {
  colors: ColorPalette;
  typography: Typography;
  spacing: Spacing;
  borderRadius: BorderRadius;
  shadow: Shadow;
  breakpoints: {
    xs: number;
    sm: number;
    md: number;
    lg: number;
    xl: number;
    xxl: number;
  };
}

const designSystem: DesignSystem = {
  colors: {
    primary: '#1E88E5',
    secondary: '#FF9800',
    background: '#121212',
    surface: '#1E1E1E',
    text: '#FFFFFF',
    textSecondary: '#B0B0B0',
    error: '#F44336',
    success: '#4CAF50',
    warning: '#FFC107',
    info: '#2196F3',
    border: '#333333',
    disabled: '#666666'
  },
  typography: {
    fontFamily: 'Roboto, sans-serif',
    fontSize: {
      small: 12,
      medium: 14,
      large: 16,
      xlarge: 20,
      xxlarge: 24
    },
    fontWeight: {
      regular: 400,
      medium: 500,
      bold: 700
    },
    lineHeight: {
      small: 1.4,
      medium: 1.5,
      large: 1.6
    }
  },
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48
  },
  borderRadius: {
    small: 4,
    medium: 8,
    large: 12,
    round: 9999
  },
  shadow: {
    small: '0 2px 4px rgba(0, 0, 0, 0.2)',
    medium: '0 4px 8px rgba(0, 0, 0, 0.3)',
    large: '0 8px 16px rgba(0, 0, 0, 0.4)'
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

export { designSystem, DesignSystem };