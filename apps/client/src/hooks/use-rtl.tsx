import { useTranslation } from 'react-i18next';
import { useEffect, useState } from 'react';

// RTL languages list - focused on Persian and English only
const RTL_LANGUAGES = ['fa', 'fa-IR'];

// Text direction detection utilities
const TEXT_DIRECTION_PATTERNS = {
  // Persian/Farsi script range
  persian: /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/,
  // Latin script range (for English)
  latin: /[\u0020-\u007F\u00A0-\u00FF\u0100-\u017F\u0180-\u024F]/,
};

export interface RTLUtils {
  isRTL: boolean;
  direction: 'ltr' | 'rtl';
  textAlign: 'left' | 'right';
  float: 'left' | 'right';
  marginStart: string;
  marginEnd: string;
  paddingStart: string;
  paddingEnd: string;
  borderStart: string;
  borderEnd: string;
  directionClass: string;
  detectTextDirection: (text: string) => 'ltr' | 'rtl';
  getInputDirection: (value: string) => 'ltr' | 'rtl' | 'auto';
  applyRTLStyles: (styles: React.CSSProperties) => React.CSSProperties;
  setDocumentDirection: (dir: 'ltr' | 'rtl') => void;
}

export function useRTL(): RTLUtils {
  const { i18n } = useTranslation();
  const [isRTL, setIsRTL] = useState(false);

  // Detect if current language is RTL
  useEffect(() => {
    const currentLanguage = i18n.language || 'en-US';
    const langCode = currentLanguage.split('-')[0].toLowerCase();
    const isCurrentRTL = RTL_LANGUAGES.includes(currentLanguage) || RTL_LANGUAGES.includes(langCode);
    
    setIsRTL(isCurrentRTL);
    
    // Set document direction
    setDocumentDirection(isCurrentRTL ? 'rtl' : 'ltr');
  }, [i18n.language]);

  const setDocumentDirection = (dir: 'ltr' | 'rtl') => {
    document.documentElement.dir = dir;
    document.documentElement.lang = i18n.language || 'en-US';
  };

  const detectTextDirection = (text: string): 'ltr' | 'rtl' => {
    if (!text || text.trim().length === 0) return isRTL ? 'rtl' : 'ltr';
    
    // Count Persian and Latin characters
    const persianMatches = text.match(TEXT_DIRECTION_PATTERNS.persian) || [];
    const latinMatches = text.match(TEXT_DIRECTION_PATTERNS.latin) || [];
    
    // If we have Persian characters, it's RTL
    if (persianMatches.length > 0) return 'rtl';
    
    // If we have Latin characters, it's LTR
    if (latinMatches.length > 0) return 'ltr';
    
    // Default to current language direction
    return isRTL ? 'rtl' : 'ltr';
  };

  const getInputDirection = (value: string): 'ltr' | 'rtl' | 'auto' => {
    if (!value || value.trim().length === 0) return 'auto';
    
    const detectedDirection = detectTextDirection(value);
    return detectedDirection;
  };

  const applyRTLStyles = (styles: React.CSSProperties): React.CSSProperties => {
    if (!isRTL) return styles;
    
    const rtlStyles = { ...styles };
    
    // Swap margin properties
    if (styles.marginLeft) {
      rtlStyles.marginRight = styles.marginLeft;
      delete rtlStyles.marginLeft;
    }
    if (styles.marginRight) {
      rtlStyles.marginLeft = styles.marginRight;
      delete rtlStyles.marginRight;
    }
    
    // Swap padding properties
    if (styles.paddingLeft) {
      rtlStyles.paddingRight = styles.paddingLeft;
      delete rtlStyles.paddingLeft;
    }
    if (styles.paddingRight) {
      rtlStyles.paddingLeft = styles.paddingRight;
      delete rtlStyles.paddingRight;
    }
    
    // Swap float
    if (styles.float === 'left') rtlStyles.float = 'right';
    if (styles.float === 'right') rtlStyles.float = 'left';
    
    // Swap text align
    if (styles.textAlign === 'left') rtlStyles.textAlign = 'right';
    if (styles.textAlign === 'right') rtlStyles.textAlign = 'left';
    
    return rtlStyles;
  };

  return {
    isRTL,
    direction: isRTL ? 'rtl' : 'ltr',
    textAlign: isRTL ? 'right' : 'left',
    float: isRTL ? 'right' : 'left',
    marginStart: isRTL ? 'marginRight' : 'marginLeft',
    marginEnd: isRTL ? 'marginLeft' : 'marginRight',
    paddingStart: isRTL ? 'paddingRight' : 'paddingLeft',
    paddingEnd: isRTL ? 'paddingLeft' : 'paddingRight',
    borderStart: isRTL ? 'borderRight' : 'borderLeft',
    borderEnd: isRTL ? 'borderLeft' : 'borderRight',
    directionClass: isRTL ? 'rtl' : 'ltr',
    detectTextDirection,
    getInputDirection,
    applyRTLStyles,
    setDocumentDirection,
  };
} 