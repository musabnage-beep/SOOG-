import { SiteHeader } from '@/components/site-header';
import { SiteFooter } from '@/components/site-footer';
import { Hero } from '@/components/hero';
import { CategoryStrip } from '@/components/category-strip';
import { FeaturesBar } from '@/components/features-bar';
import { ProductGrid } from '@/components/product-grid';
import { getCategories, getProducts } from '@/lib/catalog';

export default async function HomePage() {
  const [categories, products] = await Promise.all([getCategories(), getProducts()]);
  return (
    <main className="min-h-screen bg-white">
      <SiteHeader />
      <Hero />
      <CategoryStrip categories={categories} />
      <ProductGrid products={products} />
      <FeaturesBar />
      <SiteFooter />
    </main>
  );
}
