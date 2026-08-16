import type { Metadata } from 'next';
import { PageShell, Section } from '@/components/page-shell';
import { BUSINESS } from '@/lib/business';

export const metadata: Metadata = {
  title: `تواصل معنا | ${BUSINESS.nameAr}`,
  description: `بيانات التواصل مع متجر ${BUSINESS.nameAr}.`,
};

const CHANNELS = [
  { label: 'الهاتف / واتساب', value: BUSINESS.phone, href: `tel:${BUSINESS.phone}`, ltr: true },
  { label: 'البريد الإلكتروني', value: BUSINESS.email, href: `mailto:${BUSINESS.email}`, ltr: true },
  { label: 'العنوان', value: BUSINESS.addressAr, href: null, ltr: false },
  { label: 'أوقات العمل', value: BUSINESS.hoursAr, href: null, ltr: false },
];

export default function ContactPage() {
  return (
    <PageShell
      title="تواصل معنا"
      intro="نسعد بخدمتك والرد على استفساراتك خلال أوقات العمل"
    >
      <Section title="قنوات التواصل">
        <dl className="grid gap-4 sm:grid-cols-2">
          {CHANNELS.map((channel) => (
            <div
              key={channel.label}
              className="rounded-2xl border border-black/5 bg-brand-muted p-5"
            >
              <dt className="text-[13px] font-bold text-muted">{channel.label}</dt>
              <dd
                className="mt-1 text-[15px] font-bold text-brand-dark"
                dir={channel.ltr ? 'ltr' : undefined}
              >
                {channel.href ? (
                  <a href={channel.href} className="hover:text-brand">
                    {channel.value}
                  </a>
                ) : (
                  channel.value
                )}
              </dd>
            </div>
          ))}
        </dl>
      </Section>

      <Section title="بيانات المنشأة">
        <p>
          الاسم النظامي: {BUSINESS.legalNameAr}
          <br />
          السجل التجاري: {BUSINESS.commercialRegistration}
          {BUSINESS.vatNumber ? (
            <>
              <br />
              الرقم الضريبي: {BUSINESS.vatNumber}
            </>
          ) : null}
        </p>
      </Section>

      <Section title="الشكاوى والملاحظات">
        <p>
          في حال وجود شكوى بخصوص طلب أو خدمة، تواصل معنا على{' '}
          <a href={`mailto:${BUSINESS.email}`} className="font-bold text-brand">
            {BUSINESS.email}
          </a>{' '}
          مرفقاً برقم الطلب، وسيتم الرد خلال يومي عمل كحد أقصى.
        </p>
      </Section>
    </PageShell>
  );
}
