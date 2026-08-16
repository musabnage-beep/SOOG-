import { API_URL, API_ORIGIN, MEDIA_PREFIX } from './config';

export interface Category {
  id: string;
  slug: string;
  nameAr: string;
  nameEn: string;
  icon?: string;
  isActive?: boolean;
  sortOrder?: number;
}

/**
 * Canonical category list (mirrors the backend seed). Used as a resilient
 * fallback so the storefront always renders the full strip even before the
 * API is reachable. When the live API responds, its data takes precedence.
 */
export const SEED_CATEGORIES: Category[] = [
  { id: 'canned-goods', slug: 'canned-goods', nameAr: 'معلبات', nameEn: 'Canned Goods' },
  { id: 'sweets', slug: 'sweets', nameAr: 'حلويات', nameEn: 'Sweets' },
  { id: 'chips', slug: 'chips', nameAr: 'شيبس', nameEn: 'Chips' },
  { id: 'chocolate', slug: 'chocolate', nameAr: 'شوكولاتة', nameEn: 'Chocolate' },
  { id: 'home-producers', slug: 'home-producers', nameAr: 'أسر منتجة', nameEn: 'Home Producers' },
  { id: 'spices-herbs', slug: 'spices-herbs', nameAr: 'عطارة وتوابل', nameEn: 'Spices & Herbs' },
  { id: 'tea', slug: 'tea', nameAr: 'شاهي', nameEn: 'Tea' },
  { id: 'soft-drinks', slug: 'soft-drinks', nameAr: 'مشروبات غازية', nameEn: 'Soft Drinks' },
  { id: 'dates', slug: 'dates', nameAr: 'تمر', nameEn: 'Dates' },
  { id: 'dairy-eggs', slug: 'dairy-eggs', nameAr: 'ألبان وبيض', nameEn: 'Dairy & Eggs' },
  { id: 'noodles', slug: 'noodles', nameAr: 'نودلز', nameEn: 'Noodles' },
  { id: 'organic', slug: 'organic', nameAr: 'منتجات عضوية', nameEn: 'Organic' },
  { id: 'bakery', slug: 'bakery', nameAr: 'الخبز والمخبوزات', nameEn: 'Bakery' },
  { id: 'frozen', slug: 'frozen', nameAr: 'المجمدات', nameEn: 'Frozen' },
  { id: 'ice-cream', slug: 'ice-cream', nameAr: 'الآيس كريم', nameEn: 'Ice Cream' },
  { id: 'plastics-cleaning', slug: 'plastics-cleaning', nameAr: 'البلاستيك والمنظفات', nameEn: 'Plastics & Cleaning' },
  { id: 'rice-grains', slug: 'rice-grains', nameAr: 'الرز والحبوب', nameEn: 'Rice & Grains' },
  { id: 'chilled-chicken', slug: 'chilled-chicken', nameAr: 'الدجاج المبرد', nameEn: 'Chilled Chicken' },
];

/** Fetch active categories from the public API, falling back to the seed list. */
export async function getCategories(): Promise<Category[]> {
  try {
    const res = await fetch(`${API_URL}/categories`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) return SEED_CATEGORIES;
    const json = await res.json();
    const data = (json?.data ?? json) as Category[];
    if (!Array.isArray(data) || data.length === 0) return SEED_CATEGORIES;
    return data;
  } catch {
    return SEED_CATEGORIES;
  }
}

export interface ProductImage {
  url: string;
  isMain: boolean;
}

export interface Product {
  id: string;
  nameAr: string;
  descriptionAr: string | null;
  price: string | number;
  discountPrice: string | number | null;
  images: ProductImage[];
  category?: { nameAr: string; slug: string };
}

/**
 * Fetch a page of active products from the public API. Returns an empty list on
 * any failure so the homepage still renders without the catalogue section.
 */
export async function getProducts(limit = 12): Promise<Product[]> {
  try {
    const res = await fetch(`${API_URL}/products?page=1&limit=${limit}`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) return [];
    const json = await res.json();
    const items = json?.data?.items ?? json?.items;
    return Array.isArray(items) ? (items as Product[]) : [];
  } catch {
    return [];
  }
}

/** Price actually charged today, i.e. the discount when one is set. */
export function effectivePrice(product: Product): number {
  const discount = Number(product.discountPrice ?? 0);
  return discount > 0 ? discount : Number(product.price);
}

/** Formats a number as an Arabic-localised amount, e.g. "12.50". */
export function formatPrice(value: number): string {
  return value.toFixed(2);
}

/**
 * Rewrites an absolute API image URL onto the same-origin media proxy so it is
 * not blocked as mixed content when the site is served over HTTPS. URLs on any
 * other origin (or already-relative ones) are returned untouched.
 */
export function mediaUrl(url: string): string {
  if (!url.startsWith(API_ORIGIN)) return url;
  return `${MEDIA_PREFIX}${url.slice(API_ORIGIN.length)}`;
}

/** Main product photo, or null when the product has no uploaded image. */
export function mainImage(product: Product): string | null {
  if (!product.images?.length) return null;
  const main = product.images.find((img) => img.isMain) ?? product.images[0];
  return main?.url ? mediaUrl(main.url) : null;
}
