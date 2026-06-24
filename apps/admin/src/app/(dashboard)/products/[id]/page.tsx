'use client';

import { use, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { ArrowRight, Upload, Star, Trash2 } from 'lucide-react';
import { useProduct, useProductMutations } from '@aldiafa/shared/client';
import {
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Button,
  Loading,
  ErrorState,
  useToast,
} from '@aldiafa/shared/ui';
import type { CreateProductInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';
import { ProductForm } from '@/components/product-form';

export default function EditProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const toast = useToast();
  const { data: product, isLoading, isError, refetch } = useProduct(id);
  const { update, uploadImages, setMainImage, deleteImage } = useProductMutations();
  const fileRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  if (isLoading) return <Loading label="جارٍ تحميل المنتج..." />;
  if (isError || !product) return <ErrorState onRetry={() => refetch()} />;

  const save = async (data: CreateProductInput) => {
    try {
      await update.mutateAsync({ id, input: data });
      toast.success('تم حفظ التغييرات');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحفظ');
    }
  };

  const onFiles = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setUploading(true);
    try {
      await uploadImages.mutateAsync({ productId: id, files: Array.from(files) });
      await refetch();
      toast.success('تم رفع الصور');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل رفع الصور');
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  const makeMain = async (imageId: string) => {
    await setMainImage.mutateAsync({ productId: id, imageId });
    await refetch();
  };
  const removeImg = async (imageId: string) => {
    await deleteImage.mutateAsync({ productId: id, imageId });
    await refetch();
  };

  return (
    <div>
      <PageHeader
        title={product.nameAr}
        subtitle="تعديل المنتج"
        action={
          <Button variant="outline" onClick={() => router.push('/products')}>
            <ArrowRight className="h-4 w-4" />
            رجوع
          </Button>
        }
      />

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>الصور</CardTitle>
        </CardHeader>
        <CardBody>
          <div className="flex flex-wrap gap-3">
            {product.images?.map((img) => (
              <div
                key={img.id}
                className="group relative h-28 w-28 overflow-hidden rounded-lg border border-gray-200 bg-gray-50"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.url} alt="" className="h-full w-full object-cover" />
                {img.isMain && (
                  <span className="absolute right-1 top-1 rounded bg-brand-gold px-1.5 py-0.5 text-[10px] font-bold text-brand-dark">
                    رئيسية
                  </span>
                )}
                <div className="absolute inset-0 flex items-center justify-center gap-1 bg-black/50 opacity-0 transition-opacity group-hover:opacity-100">
                  {!img.isMain && (
                    <button
                      onClick={() => makeMain(img.id)}
                      className="rounded-full bg-white/90 p-2 text-gray-700 hover:bg-white"
                      title="تعيين كرئيسية"
                    >
                      <Star className="h-4 w-4" />
                    </button>
                  )}
                  <button
                    onClick={() => removeImg(img.id)}
                    className="rounded-full bg-white/90 p-2 text-red-600 hover:bg-white"
                    title="حذف"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
            <button
              onClick={() => fileRef.current?.click()}
              disabled={uploading}
              className="flex h-28 w-28 flex-col items-center justify-center gap-1 rounded-lg border-2 border-dashed border-gray-300 text-gray-400 hover:border-brand hover:text-brand"
            >
              <Upload className="h-6 w-6" />
              <span className="text-xs">{uploading ? 'جارٍ الرفع...' : 'رفع صور'}</span>
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              multiple
              className="hidden"
              onChange={(e) => onFiles(e.target.files)}
            />
          </div>
        </CardBody>
      </Card>

      <ProductForm
        initial={product}
        submitLabel="حفظ التغييرات"
        submitting={update.isPending}
        onSubmit={save}
      />
    </div>
  );
}
