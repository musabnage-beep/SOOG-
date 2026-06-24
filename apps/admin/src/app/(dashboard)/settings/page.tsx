'use client';

import { useEffect, useState } from 'react';
import { useSettings, useUpdateSettings } from '@aldiafa/shared/client';
import {
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Input,
  Field,
  Button,
  Loading,
  ErrorState,
  useToast,
} from '@aldiafa/shared/ui';
import type { UpdateSettingsInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function SettingsPage() {
  const { data, isLoading, isError, refetch } = useSettings();
  const updateMut = useUpdateSettings();
  const toast = useToast();
  const [form, setForm] = useState<UpdateSettingsInput>({});

  useEffect(() => {
    if (data) {
      setForm({
        storeName: data.storeName,
        storeLatitude: data.storeLatitude,
        storeLongitude: data.storeLongitude,
        freeDeliveryRadiusM: data.freeDeliveryRadiusM,
        deliveryRadiusM: data.deliveryRadiusM,
        baseDeliveryFee: Number(data.baseDeliveryFee),
        currency: data.currency,
        avgSpeedKmh: data.avgSpeedKmh,
      });
    }
  }, [data]);

  if (isLoading) return <Loading label="جارٍ تحميل الإعدادات..." />;
  if (isError || !data) return <ErrorState onRetry={() => refetch()} />;

  const save = async () => {
    try {
      await updateMut.mutateAsync(form);
      toast.success('تم حفظ الإعدادات');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحفظ');
    }
  };

  const set = <K extends keyof UpdateSettingsInput>(k: K, v: UpdateSettingsInput[K]) =>
    setForm((f) => ({ ...f, [k]: v }));

  return (
    <div>
      <PageHeader title="الإعدادات" subtitle="إعدادات المتجر والتوصيل" />

      <div className="grid max-w-3xl grid-cols-1 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>معلومات المتجر</CardTitle>
          </CardHeader>
          <CardBody className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="اسم المتجر" className="sm:col-span-2">
              <Input value={form.storeName ?? ''} onChange={(e) => set('storeName', e.target.value)} />
            </Field>
            <Field label="خط العرض (Latitude)">
              <Input type="number" step="any" dir="ltr" value={form.storeLatitude ?? ''} onChange={(e) => set('storeLatitude', Number(e.target.value))} />
            </Field>
            <Field label="خط الطول (Longitude)">
              <Input type="number" step="any" dir="ltr" value={form.storeLongitude ?? ''} onChange={(e) => set('storeLongitude', Number(e.target.value))} />
            </Field>
            <Field label="العملة">
              <Input dir="ltr" value={form.currency ?? ''} onChange={(e) => set('currency', e.target.value)} />
            </Field>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>إعدادات التوصيل</CardTitle>
          </CardHeader>
          <CardBody className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="نطاق التوصيل المجاني (متر)">
              <Input type="number" value={form.freeDeliveryRadiusM ?? ''} onChange={(e) => set('freeDeliveryRadiusM', Number(e.target.value))} />
            </Field>
            <Field label="أقصى نطاق توصيل (متر)">
              <Input type="number" value={form.deliveryRadiusM ?? ''} onChange={(e) => set('deliveryRadiusM', Number(e.target.value))} />
            </Field>
            <Field label="رسوم التوصيل الأساسية (ر.س)">
              <Input type="number" step="0.01" value={form.baseDeliveryFee ?? ''} onChange={(e) => set('baseDeliveryFee', Number(e.target.value))} />
            </Field>
            <Field label="متوسط السرعة (كم/س)">
              <Input type="number" value={form.avgSpeedKmh ?? ''} onChange={(e) => set('avgSpeedKmh', Number(e.target.value))} />
            </Field>
          </CardBody>
        </Card>

        <div>
          <Button size="lg" loading={updateMut.isPending} onClick={save}>
            حفظ الإعدادات
          </Button>
        </div>
      </div>
    </div>
  );
}
