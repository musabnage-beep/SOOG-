import type { Metadata } from 'next';
import { PageShell, Section, Bullets } from '@/components/page-shell';
import { BUSINESS } from '@/lib/business';

export const metadata: Metadata = {
  title: `من نحن | ${BUSINESS.nameAr}`,
  description: `تعرّف على متجر ${BUSINESS.nameAr} وخدماته.`,
};

export default function AboutPage() {
  return (
    <PageShell title="من نحن" intro={`تعرّف على متجر ${BUSINESS.nameAr}`}>
      <Section title="عن المتجر">
        <p>
          {BUSINESS.nameAr} متجر سعودي متخصص في بيع الحلويات والمواد الغذائية
          والمنتجات الاستهلاكية. نوفّر تشكيلة واسعة من المنتجات الأصلية بأسعار
          مناسبة، مع خدمة توصيل داخل نطاق المتجر وإمكانية الاستلام المباشر من
          الفرع.
        </p>
        <p>
          نعمل تحت الاسم النظامي «{BUSINESS.legalNameAr}» بسجل تجاري رقم{' '}
          {BUSINESS.commercialRegistration}.
        </p>
      </Section>

      <Section title="ماذا نقدّم">
        <Bullets
          items={[
            'تشكيلة واسعة من الحلويات والمواد الغذائية والمنتجات المنزلية.',
            'منتجات أصلية 100% مع مراعاة تواريخ الصلاحية.',
            'توصيل سريع داخل نطاق الخدمة، أو استلام من المتجر بدون رسوم.',
            'فريق خدمة عملاء لمتابعة الطلبات والاستفسارات.',
          ]}
        />
      </Section>

      <Section title="كيف تطلب">
        <Bullets
          items={[
            'تصفّح الأقسام واختر المنتجات التي تحتاجها.',
            'أضف المنتجات إلى السلة وحدّد طريقة الاستلام: توصيل أو استلام من المتجر.',
            'أكمل الطلب واختر طريقة الدفع المتاحة.',
            'يصلك إشعار بحالة الطلب في كل مرحلة حتى التسليم.',
          ]}
        />
      </Section>

      <Section title="بيانات التواصل">
        <Bullets
          items={[
            `الهاتف: ${BUSINESS.phone}`,
            `البريد الإلكتروني: ${BUSINESS.email}`,
            `العنوان: ${BUSINESS.addressAr}`,
            `أوقات العمل: ${BUSINESS.hoursAr}`,
          ]}
        />
      </Section>
    </PageShell>
  );
}
