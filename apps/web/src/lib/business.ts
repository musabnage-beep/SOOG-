/**
 * Single source of truth for the legal / contact details shown across the
 * storefront (footer, contact page and the policy pages).
 *
 * Payment gateways review these pages before activating a merchant account, so
 * every value here must match the commercial registration exactly. Fields
 * marked TODO are placeholders and must be replaced with the real data before
 * the site is submitted for review.
 */
export const BUSINESS = {
  /** Trading name shown to customers. */
  nameAr: 'الضيافة',
  nameEn: 'Aldiafah',

  /** Legal entity name exactly as printed on the commercial registration. */
  legalNameAr: 'مؤسسة أسرة الضيافة للتجارة',

  /** Commercial registration number (الرقم الوطني الموحد). */
  commercialRegistration: '7017180105',

  /** VAT registration number, or null if the store is not VAT registered. */
  vatNumber: '310698841900003' as string | null,

  /** National address / street address of the store. */
  addressAr: 'حي الخالدية، طريق الملك سلمان، الدوادمي',

  /** Customer-facing phone in international format. */
  phone: '+966544818511',

  /** Customer-facing support mailbox. */
  email: 'support@aldiafah.org',

  /** Working hours copy shown on the contact page. */
  hoursAr: 'يومياً من ٩ صباحاً حتى ١١ مساءً',

  /** Store coordinates used for the delivery radius (matches backend settings). */
  location: { lat: 24.5249853, lng: 44.3978595 },

  /** Currency label used next to every price. */
  currencyAr: 'ر.س',
} as const;

/** Date shown at the top of each policy page. */
export const POLICY_LAST_UPDATED = '2026-08-16';

/** Footer + policy navigation, kept in one list so the two stay in sync. */
export const LEGAL_LINKS = [
  { label: 'من نحن', href: '/about' },
  { label: 'تواصل معنا', href: '/contact' },
  { label: 'الشروط والأحكام', href: '/terms' },
  { label: 'سياسة الخصوصية', href: '/privacy' },
  { label: 'سياسة الاستبدال والاسترجاع', href: '/refund' },
] as const;
