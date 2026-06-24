'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Search, Plus, Pencil, Trash2 } from 'lucide-react';
import { useProducts, useCategories, useProductMutations } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Input,
  Select,
  Badge,
  Button,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
  Loading,
  ErrorState,
  EmptyState,
  Pagination,
  ConfirmDialog,
  useToast,
} from '@aldiafa/shared/ui';
import {
  money,
  num,
  STOCK_STATUS_LABEL_AR,
  STOCK_STATUS_TONE,
  type Product,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function ProductsPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [toDelete, setToDelete] = useState<Product | null>(null);

  const categories = useCategories();
  const { remove } = useProductMutations();
  const toast = useToast();

  const { data, isLoading, isError, refetch } = useProducts({
    page,
    limit: 20,
    search: search || undefined,
    categoryId: categoryId || undefined,
  });

  const confirmDelete = async () => {
    if (!toDelete) return;
    try {
      await remove.mutateAsync(toDelete.id);
      toast.success('تم حذف المنتج');
      setToDelete(null);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحذف');
    }
  };

  return (
    <div>
      <PageHeader
        title="المنتجات"
        subtitle="إدارة كتالوج المنتجات"
        action={
          <Link href="/products/new">
            <Button>
              <Plus className="h-4 w-4" />
              منتج جديد
            </Button>
          </Link>
        }
      />

      <Card className="mb-4">
        <CardBody className="flex flex-wrap items-center gap-3">
          <div className="relative min-w-[220px] flex-1">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              className="pr-9"
              placeholder="بحث بالاسم أو SKU..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
          </div>
          <Select
            className="w-56"
            value={categoryId}
            onChange={(e) => {
              setCategoryId(e.target.value);
              setPage(1);
            }}
          >
            <option value="">كل التصنيفات</option>
            {categories.data?.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nameAr}
              </option>
            ))}
          </Select>
        </CardBody>
      </Card>

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState
              title="لا توجد منتجات"
              action={
                <Link href="/products/new">
                  <Button>إضافة منتج</Button>
                </Link>
              }
            />
          ) : (
            <>
              <Table>
                <THead>
                  <TR>
                    <TH>المنتج</TH>
                    <TH>SKU</TH>
                    <TH>السعر</TH>
                    <TH>المخزون</TH>
                    <TH>الحالة</TH>
                    <TH></TH>
                  </TR>
                </THead>
                <TBody>
                  {data.items.map((p) => {
                    const main = p.images?.find((i) => i.isMain) ?? p.images?.[0];
                    return (
                      <TR key={p.id}>
                        <TD>
                          <div className="flex items-center gap-3">
                            <div className="h-10 w-10 shrink-0 overflow-hidden rounded-lg bg-gray-100">
                              {main && (
                                // eslint-disable-next-line @next/next/no-img-element
                                <img src={main.url} alt="" className="h-full w-full object-cover" />
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="truncate font-medium text-gray-900">{p.nameAr}</p>
                              <p className="truncate text-xs text-gray-400">{p.category?.nameAr}</p>
                            </div>
                          </div>
                        </TD>
                        <TD className="text-xs" dir="ltr">{p.sku}</TD>
                        <TD className="font-semibold text-brand">{money(p.discountPrice ?? p.price)}</TD>
                        <TD>{num(p.quantity)}</TD>
                        <TD>
                          <Badge tone={STOCK_STATUS_TONE[p.stockStatus]}>
                            {STOCK_STATUS_LABEL_AR[p.stockStatus]}
                          </Badge>
                        </TD>
                        <TD>
                          <div className="flex gap-1">
                            <Link href={`/products/${p.id}`}>
                              <Button variant="ghost" size="icon">
                                <Pencil className="h-4 w-4" />
                              </Button>
                            </Link>
                            <Button variant="ghost" size="icon" onClick={() => setToDelete(p)}>
                              <Trash2 className="h-4 w-4 text-red-500" />
                            </Button>
                          </div>
                        </TD>
                      </TR>
                    );
                  })}
                </TBody>
              </Table>
              <Pagination page={page} totalPages={data.meta.totalPages} onChange={setPage} />
            </>
          )}
        </CardBody>
      </Card>

      <ConfirmDialog
        open={!!toDelete}
        onClose={() => setToDelete(null)}
        onConfirm={confirmDelete}
        title="حذف المنتج"
        message={`هل أنت متأكد من حذف "${toDelete?.nameAr}"؟`}
        confirmLabel="حذف"
        loading={remove.isPending}
        danger
      />
    </div>
  );
}
