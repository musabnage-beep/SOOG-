import { SafeImage } from './safe-image';
import { BUSINESS } from '@/lib/business';
import { effectivePrice, formatPrice, mainImage, type Product } from '@/lib/catalog';

/**
 * Catalogue preview on the homepage. Prices are rendered as plain text (not
 * behind a login) so a payment-gateway reviewer can confirm what is being sold
 * and at what price.
 */
export function ProductGrid({ products }: { products: Product[] }) {
  if (products.length === 0) return null;

  return (
    <section id="products" className="mx-auto max-w-7xl px-6 py-10">
      <div className="mb-6 flex items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-brand-dark">منتجاتنا</h2>
          <p className="mt-1 text-sm text-muted">
            أسعارنا شاملة ضريبة القيمة المضافة بالريال السعودي
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  );
}

function ProductCard({ product }: { product: Product }) {
  const image = mainImage(product);
  const price = effectivePrice(product);
  const hasDiscount = price < Number(product.price);

  return (
    <article className="flex flex-col overflow-hidden rounded-2xl border border-black/5 bg-white shadow-soft">
      <div className="flex aspect-square items-center justify-center bg-brand-muted">
        {image ? (
          <SafeImage
            src={image}
            alt={product.nameAr}
            className="h-full w-full object-cover"
          />
        ) : null}
      </div>

      <div className="flex flex-1 flex-col gap-2 p-4">
        <h3 className="line-clamp-2 text-[15px] font-bold text-brand-dark">
          {product.nameAr}
        </h3>
        {product.category ? (
          <span className="text-[12px] text-muted">{product.category.nameAr}</span>
        ) : null}

        <div className="mt-auto flex items-baseline gap-2 pt-2">
          <span className="text-lg font-bold text-brand">
            {formatPrice(price)} {BUSINESS.currencyAr}
          </span>
          {hasDiscount ? (
            <span className="text-[13px] text-muted line-through">
              {formatPrice(Number(product.price))}
            </span>
          ) : null}
        </div>
      </div>
    </article>
  );
}
