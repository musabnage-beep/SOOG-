'use client';

import { useRouter } from 'next/navigation';
import { ArrowRight } from 'lucide-react';
import { useProductMutations } from '@aldiafa/shared/client';
import { Button, useToast } from '@aldiafa/shared/ui';
import type { CreateProductInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';
import { ProductForm } from '@/components/product-form';

export default function NewProductPage() {
  const router = useRouter();
  const toast = useToast();
  const { create } = useProductMutations();

  const submit = async (data: CreateProductInput) => {
    try {
      const product = await create.mutateAsync(data);
      toast.success('تم إنشاء المنتج');
      router.push(`/products/${product.id}`);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل إنشاء المنتج');
    }
  };

  return (
    <div>
      <PageHeader
        title="منتج جديد"
        action={
          <Button variant="outline" onClick={() => router.push('/products')}>
            <ArrowRight className="h-4 w-4" />
            رجوع
          </Button>
        }
      />
      <ProductForm submitLabel="إنشاء المنتج" submitting={create.isPending} onSubmit={submit} />
    </div>
  );
}
