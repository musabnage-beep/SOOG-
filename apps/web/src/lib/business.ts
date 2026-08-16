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

  /** TODO: legal entity name exactly as printed on the commercial registration. */
  legalNameAr: 'مؤسسة الضيافة للتجارة',

  /** TODO: commercial registration number (رقم السجل التجاري). */
  commercialRegistration: '0000000000',

  /** TODO: VAT registration number, or null if the store is not VAT registered. */
  vatNumber: null as string | null,

  /** TODO: national address / street address of the store. */
  addressAr: 'المملكة العربية السعودية',

  /** TODO: customer-facing phone in international format. */
  phone: '+966500000000',

  /** TODO: customer-facing support mailbox. */
  email: 'support@aldiafah.com',

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
