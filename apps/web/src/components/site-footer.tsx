import Link from 'next/link';
import { BUSINESS, LEGAL_LINKS } from '@/lib/business';

/**
 * Site-wide footer. Carries the legal identity, contact details and links to
 * every policy page — the set of information a payment gateway checks before
 * activating a merchant account.
 */
export function SiteFooter() {
  return (
    <footer className="mt-10 bg-brand-dark text-white">
      <div className="mx-auto grid max-w-7xl gap-8 px-6 py-12 sm:grid-cols-2 lg:grid-cols-3">
        <div>
          <h3 className="text-lg font-bold">{BUSINESS.nameAr}</h3>
          <p className="mt-3 text-sm leading-relaxed text-white/70">
            متجر {BUSINESS.nameAr} لبيع الحلويات والمواد الغذائية بجودة عالية
            وأسعار مناسبة، مع خدمة توصيل سريعة وإمكانية الاستلام من المتجر.
          </p>
        </div>

        <nav aria-label="روابط مهمة">
          <h3 className="text-lg font-bold">روابط مهمة</h3>
          <ul className="mt-3 space-y-2 text-sm">
            {LEGAL_LINKS.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className="text-white/70 transition-colors hover:text-brand-goldLight"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>

        <div>
          <h3 className="text-lg font-bold">تواصل معنا</h3>
          <ul className="mt-3 space-y-2 text-sm text-white/70">
            <li>
              <a href={`tel:${BUSINESS.phone}`} dir="ltr" className="hover:text-brand-goldLight">
                {BUSINESS.phone}
              </a>
            </li>
            <li>
              <a href={`mailto:${BUSINESS.email}`} className="hover:text-brand-goldLight">
                {BUSINESS.email}
              </a>
            </li>
            <li>{BUSINESS.addressAr}</li>
            <li>{BUSINESS.hoursAr}</li>
          </ul>
        </div>
      </div>

      <div className="border-t border-white/10">
        <div className="mx-auto flex max-w-7xl flex-col gap-2 px-6 py-5 text-[13px] text-white/55 sm:flex-row sm:items-center sm:justify-between">
          <span>
            © {new Date().getFullYear()} {BUSINESS.legalNameAr} — جميع الحقوق محفوظة
          </span>
          <span>
            سجل تجاري رقم {BUSINESS.commercialRegistration}
            {BUSINESS.vatNumber ? ` — الرقم الضريبي ${BUSINESS.vatNumber}` : ''}
          </span>
        </div>
      </div>
    </footer>
  );
}
