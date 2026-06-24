'use client';

import { useState } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { useCategories, useCategoryMutations } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Button,
  Input,
  Field,
  Modal,
  Badge,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
  Loading,
  ErrorState,
  EmptyState,
  ConfirmDialog,
  useToast,
} from '@aldiafa/shared/ui';
import type { Category, CreateCategoryInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const empty: CreateCategoryInput = {
  nameAr: '',
  nameEn: '',
  slug: '',
  icon: '',
  sortOrder: 0,
  isActive: true,
};

export default function CategoriesPage() {
  const { data, isLoading, isError, refetch } = useCategories();
  const { create, update, remove } = useCategoryMutations();
  const toast = useToast();

  const [editing, setEditing] = useState<Category | null>(null);
  const [form, setForm] = useState<CreateCategoryInput>(empty);
  const [open, setOpen] = useState(false);
  const [toDelete, setToDelete] = useState<Category | null>(null);

  const openNew = () => {
    setEditing(null);
    setForm(empty);
    setOpen(true);
  };
  const openEdit = (c: Category) => {
    setEditing(c);
    setForm({
      nameAr: c.nameAr,
      nameEn: c.nameEn,
      slug: c.slug,
      icon: c.icon ?? '',
      sortOrder: c.sortOrder,
      isActive: c.isActive,
    });
    setOpen(true);
  };

  const save = async () => {
    try {
      if (editing) {
        await update.mutateAsync({ id: editing.id, input: form });
        toast.success('تم تحديث التصنيف');
      } else {
        await create.mutateAsync(form);
        toast.success('تم إنشاء التصنيف');
      }
      setOpen(false);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشلت العملية');
    }
  };

  const confirmDelete = async () => {
    if (!toDelete) return;
    try {
      await remove.mutateAsync(toDelete.id);
      toast.success('تم حذف التصنيف');
      setToDelete(null);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحذف');
    }
  };

  return (
    <div>
      <PageHeader
        title="التصنيفات"
        subtitle="تنظيم منتجات المتجر"
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" />
            تصنيف جديد
          </Button>
        }
      />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.length === 0 ? (
            <EmptyState title="لا توجد تصنيفات" action={<Button onClick={openNew}>إضافة تصنيف</Button>} />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>الأيقونة</TH>
                  <TH>الاسم</TH>
                  <TH>المعرّف</TH>
                  <TH>الترتيب</TH>
                  <TH>الحالة</TH>
                  <TH></TH>
                </TR>
              </THead>
              <TBody>
                {data.map((c) => (
                  <TR key={c.id}>
                    <TD className="text-xl">{c.icon || '🏷️'}</TD>
                    <TD className="font-medium text-gray-900">
                      {c.nameAr}
                      <span className="block text-xs text-gray-400" dir="ltr">
                        {c.nameEn}
                      </span>
                    </TD>
                    <TD className="text-xs text-gray-500" dir="ltr">{c.slug}</TD>
                    <TD>{c.sortOrder}</TD>
                    <TD>
                      <Badge tone={c.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'}>
                        {c.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TD>
                    <TD>
                      <div className="flex gap-1">
                        <Button variant="ghost" size="icon" onClick={() => openEdit(c)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => setToDelete(c)}>
                          <Trash2 className="h-4 w-4 text-red-500" />
                        </Button>
                      </div>
                    </TD>
                  </TR>
                ))}
              </TBody>
            </Table>
          )}
        </CardBody>
      </Card>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title={editing ? 'تعديل التصنيف' : 'تصنيف جديد'}
        footer={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              إلغاء
            </Button>
            <Button
              loading={create.isPending || update.isPending}
              disabled={!form.nameAr || !form.nameEn || !form.slug}
              onClick={save}
            >
              حفظ
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Field label="الاسم (عربي)">
            <Input value={form.nameAr} onChange={(e) => setForm({ ...form, nameAr: e.target.value })} />
          </Field>
          <Field label="الاسم (إنجليزي)">
            <Input dir="ltr" value={form.nameEn} onChange={(e) => setForm({ ...form, nameEn: e.target.value })} />
          </Field>
          <Field label="المعرّف (slug)">
            <Input
              dir="ltr"
              placeholder="dates-sweets"
              value={form.slug}
              onChange={(e) => setForm({ ...form, slug: e.target.value })}
            />
          </Field>
          <div className="grid grid-cols-2 gap-4">
            <Field label="الأيقونة (إيموجي)">
              <Input value={form.icon} onChange={(e) => setForm({ ...form, icon: e.target.value })} />
            </Field>
            <Field label="الترتيب">
              <Input
                type="number"
                value={form.sortOrder}
                onChange={(e) => setForm({ ...form, sortOrder: Number(e.target.value) })}
              />
            </Field>
          </div>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
            />
            تصنيف نشط
          </label>
        </div>
      </Modal>

      <ConfirmDialog
        open={!!toDelete}
        onClose={() => setToDelete(null)}
        onConfirm={confirmDelete}
        title="حذف التصنيف"
        message={`حذف "${toDelete?.nameAr}"؟`}
        confirmLabel="حذف"
        loading={remove.isPending}
        danger
      />
    </div>
  );
}
