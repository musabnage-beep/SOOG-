'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useCategories } from '@aldiafa/shared/client';
import { Card, CardBody, CardHeader, CardTitle, Input, Textarea, Select, Field, Button } from '@aldiafa/shared/ui';
import type { CreateProductInput, Product } from '@aldiafa/shared';

const schema = z.object({
  nameAr: z.string().min(1, 'الاسم بالعربية مطلوب'),
  nameEn: z.string().min(1, 'الاسم بالإنجليزية مطلوب'),
  descriptionAr: z.string().optional(),
  descriptionEn: z.string().optional(),
  categoryId: z.string().uuid('اختر تصنيفاً'),
  price: z.coerce.number().min(0, 'السعر غير صالح'),
  discountPrice: z.coerce.number().min(0).optional().or(z.literal('').transform(() => undefined)),
  sku: z.string().min(1, 'SKU مطلوب'),
  barcode: z.string().optional(),
  weightGrams: z.coerce.number().min(0).optional().or(z.literal('').transform(() => undefined)),
  quantity: z.coerce.number().min(0).optional(),
  lowStockThreshold: z.coerce.number().min(0).optional(),
  isActive: z.coerce.boolean().optional(),
});

type FormValues = z.input<typeof schema>;

export function ProductForm({
  initial,
  submitting,
  submitLabel,
  onSubmit,
}: {
  initial?: Product;
  submitting?: boolean;
  submitLabel: string;
  onSubmit: (data: CreateProductInput) => void;
}) {
  const categories = useCategories();
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: initial
      ? {
          nameAr: initial.nameAr,
          nameEn: initial.nameEn,
          descriptionAr: initial.descriptionAr ?? '',
          descriptionEn: initial.descriptionEn ?? '',
          categoryId: initial.categoryId ?? initial.category?.id,
          price: Number(initial.price),
          discountPrice: initial.discountPrice ? Number(initial.discountPrice) : undefined,
          sku: initial.sku,
          barcode: initial.barcode ?? '',
          weightGrams: initial.weightGrams ?? undefined,
          quantity: initial.quantity,
          lowStockThreshold: initial.lowStockThreshold ?? 5,
          isActive: initial.isActive,
        }
      : { isActive: true, quantity: 0, lowStockThreshold: 5 },
  });

  const submit = handleSubmit((values) => {
    const parsed = schema.parse(values);
    onSubmit(parsed as CreateProductInput);
  });

  return (
    <form onSubmit={submit} className="grid grid-cols-1 gap-6 lg:grid-cols-3">
      <div className="space-y-6 lg:col-span-2">
        <Card>
          <CardHeader>
            <CardTitle>المعلومات الأساسية</CardTitle>
          </CardHeader>
          <CardBody className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="الاسم (عربي)" error={errors.nameAr?.message}>
              <Input {...register('nameAr')} />
            </Field>
            <Field label="الاسم (إنجليزي)" error={errors.nameEn?.message}>
              <Input dir="ltr" {...register('nameEn')} />
            </Field>
            <Field label="الوصف (عربي)" className="sm:col-span-2">
              <Textarea {...register('descriptionAr')} />
            </Field>
            <Field label="الوصف (إنجليزي)" className="sm:col-span-2">
              <Textarea dir="ltr" {...register('descriptionEn')} />
            </Field>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>التسعير والمخزون</CardTitle>
          </CardHeader>
          <CardBody className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="السعر (ر.س)" error={errors.price?.message}>
              <Input type="number" step="0.01" {...register('price')} />
            </Field>
            <Field label="سعر الخصم (اختياري)" error={errors.discountPrice?.message}>
              <Input type="number" step="0.01" {...register('discountPrice')} />
            </Field>
            <Field label="الكمية" error={errors.quantity?.message}>
              <Input type="number" {...register('quantity')} />
            </Field>
            <Field label="حد المخزون المنخفض" error={errors.lowStockThreshold?.message}>
              <Input type="number" {...register('lowStockThreshold')} />
            </Field>
          </CardBody>
        </Card>
      </div>

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>التنظيم</CardTitle>
          </CardHeader>
          <CardBody className="space-y-4">
            <Field label="التصنيف" error={errors.categoryId?.message}>
              <Select {...register('categoryId')}>
                <option value="">اختر تصنيفاً</option>
                {categories.data?.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nameAr}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="SKU" error={errors.sku?.message}>
              <Input dir="ltr" {...register('sku')} />
            </Field>
            <Field label="الباركود (اختياري)">
              <Input dir="ltr" {...register('barcode')} />
            </Field>
            <Field label="الوزن (جرام)">
              <Input type="number" {...register('weightGrams')} />
            </Field>
            <label className="flex items-center gap-2 text-sm text-gray-700">
              <input type="checkbox" {...register('isActive')} />
              منتج نشط
            </label>
          </CardBody>
        </Card>

        <Button type="submit" size="lg" loading={submitting} className="w-full">
          {submitLabel}
        </Button>
      </div>
    </form>
  );
}
