import { IconArrowLeft } from './icons';
import { SafeImage } from './safe-image';

export function Hero() {
  return (
    <section className="mx-auto max-w-7xl px-6 pt-6">
      <div
        className="relative overflow-hidden rounded-3xl shadow-card"
        style={{
          background:
            'radial-gradient(120% 150% at 34% 55%, #0C3A1C 0%, #06280F 46%, #031608 74%, #020A05 100%)',
        }}
      >
        <div className="relative flex flex-col items-center lg:flex-row lg:items-stretch">
          {/* Text block (right in RTL) */}
          <div className="relative z-10 w-full px-8 pb-2 pt-9 text-center lg:w-[46%] lg:px-12 lg:py-14 lg:text-right">
            <h1 className="text-[34px] font-black leading-[1.2] lg:text-[46px]">
              <span className="text-white">كل احتياجاتك</span>
              <br />
              <span className="text-brand-bright">في مكان واحد</span>
            </h1>
            <p className="mt-4 text-[14px] font-semibold text-brand-gold lg:text-[15px]">
              جودة عالية · أسعار مناسبة · توصيل سريع
            </p>
            <button className="mt-7 inline-flex items-center gap-2 rounded-full bg-white px-8 py-3 text-[15px] font-bold text-brand-dark shadow-lg shadow-black/20 transition-colors hover:bg-white/90">
              تسوق الآن
              <IconArrowLeft size={16} />
            </button>
          </div>

          {/* Basket scene (left in RTL) — one composed shot: basket + floating products */}
          <div className="relative flex min-h-[220px] w-full items-end justify-center lg:min-h-[360px] lg:w-[54%]">
            <SafeImage
              src="/backgrounds/hero-basket.png"
              alt="سلة تسوق ممتلئة بالمنتجات"
              className="relative z-10 h-full w-full object-contain object-bottom lg:object-center"
            />
          </div>
        </div>

        {/* carousel dots */}
        <div className="absolute bottom-4 left-1/2 z-20 flex -translate-x-1/2 items-center gap-2">
          <span className="h-1.5 w-5 rounded-full bg-white" />
          <span className="h-1.5 w-1.5 rounded-full bg-white/35" />
          <span className="h-1.5 w-1.5 rounded-full bg-white/35" />
        </div>
      </div>
    </section>
  );
}
