import type { ComponentType, SVGProps } from 'react';
import {
  IconFastDelivery,
  IconSecurePayment,
  IconHighQuality,
  IconExclusiveOffers,
  IconSupport247,
  IconEasyReturn,
} from './icons';

type Icon = ComponentType<SVGProps<SVGSVGElement> & { size?: number }>;

const FEATURES: { icon: Icon; title: string; subtitle: string }[] = [
  { icon: IconFastDelivery, title: 'توصيل سريع', subtitle: 'داخل وخارج المدينة' },
  { icon: IconSecurePayment, title: 'دفع آمن', subtitle: 'طرق دفع متعددة وآمنة' },
  { icon: IconHighQuality, title: 'جودة عالية', subtitle: 'منتجات أصلية 100%' },
  { icon: IconExclusiveOffers, title: 'عروض حصرية', subtitle: 'خصومات يومية' },
  { icon: IconSupport247, title: 'دعم 24/7', subtitle: 'خدمة عملاء على مدار الساعة' },
  { icon: IconEasyReturn, title: 'إرجاع سهل', subtitle: 'تسوق واستبدال بسيط' },
];

export function FeaturesBar() {
  return (
    <section className="mx-auto max-w-7xl px-6 py-4">
      <div className="rounded-3xl bg-brand-dark px-4 py-7">
        <div className="grid grid-cols-2 gap-y-6 divide-white/10 sm:grid-cols-3 lg:grid-cols-6 lg:divide-x lg:divide-x-reverse">
          {FEATURES.map((f) => (
            <div key={f.title} className="flex flex-col items-center px-3 text-center">
              <f.icon size={28} className="text-brand-gold" />
              <span className="mt-3 text-[15px] font-bold text-white">{f.title}</span>
              <span className="mt-1 text-[12px] leading-tight text-white/55">{f.subtitle}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
