'use client';

import { useRef, useState } from 'react';
import { Plus, Pencil, Trash2, Upload } from 'lucide-react';
import { useDeliveryProviders, useDeliveryProviderMutations } from '@aldiafa/shared/client';
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
import {
  money,
  deliveryDaysLabel,
  type DeliveryProvider,
  type UpsertDeliveryProviderInput,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const empty: UpsertDeliveryProviderInput = {
  name: '',
  deliveryFee: 0,
  estimatedDays: 2,
  phone: '',
  website: '',
  isActive: true,
};

export default function DeliveryCompaniesPage() {
  const { data, isLoading, isError, refetch } = useDeliveryProviders(true);
  const { create, update, remove, uploadLogo } = useDeliveryProviderMutations();
  const toast = useToast();

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<DeliveryProvider | null>(null);
  const [form, setForm] = useState<UpsertDeliveryProviderInput>(empty);
  const [toDelete, setToDelete] = useState<DeliveryProvider | null>(null);
  const [logoFor, setLogoFor] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const openNew = () => {
    setEditing(null);
    setForm(empty);
    setOpen(true);
  };
  const openEdit = (p: DeliveryProvider) => {
    setEditing(p);
    setForm({
      name: p.name,
      deliveryFee: Number(p.deliveryFee),
      estimatedDays: p.estimatedDays,
      phone: p.phone ?? '',
      website: p.website ?? '',
      isActive: p.isActive,
    });
    setOpen(true);
  };

  const save = async () => {
    try {
      if (editing) {
        await update.mutateAsync({ id: editing.id, input: form });
        toast.success('تم تحديث الشركة');
      } else {
        await create.mutateAsync(form);
        toast.success('تمت إضافة الشركة');
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
      toast.success('تم حذف الشركة');
      setToDelete(null);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحذف');
    }
  };

  const pickLogo = (id: string) => {
    setLogoFor(id);
    fileRef.current?.click();
  };
  const onLogoPicked = async (file: File | undefined) => {
    if (!file || !logoFor) return;
    try {
      await uploadLogo.mutateAsync({ id: logoFor, file });
      toast.success('تم رفع الشعار');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل رفع الشعار');
    } finally {
      setLogoFor(null);
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  return (
    <div>
      <PageHeader
        title="شركات التوصيل"
        subtitle="شركات الشحن المعروضة للعميل خارج نطاق التوصيل المجاني"
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" />
            شركة جديدة
          </Button>
        }
      />

      <input
        ref={fileRef}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        className="hidden"
        onChange={(e) => onLogoPicked(e.target.files?.[0])}
      />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.length === 0 ? (
            <EmptyState
              title="لا توجد شركات توصيل"
              action={<Button onClick={openNew}>إضافة شركة</Button>}
            />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>الشعار</TH>
                  <TH>الاسم</TH>
                  <TH>الرسوم</TH>
                  <TH>مدة التوصيل</TH>
                  <TH>الهاتف</TH>
                  <TH>الموقع</TH>
                  <TH>الحالة</TH>
                  <TH></TH>
                </TR>
              </THead>
              <TBody>
                {data.map((p) => (
                  <TR key={p.id}>
                    <TD>
                      {p.logo ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={p.logo}
                          alt={p.name}
                          className="h-10 w-10 rounded object-contain"
                        />
                      ) : (
                        <div className="h-10 w-10 rounded bg-gray-100" />
                      )}
                    </TD>
                    <TD className="font-medium text-gray-900">{p.name}</TD>
                    <TD className="font-semibold text-brand">{money(p.deliveryFee)}</TD>
                    <TD>{deliveryDaysLabel(p.estimatedDays)}</TD>
                    <TD dir="ltr" className="text-start">
                      {p.phone || '—'}
                    </TD>
                    <TD dir="ltr" className="text-start">
                      {p.website ? (
                        <a
                          href={p.website}
                          target="_blank"
                          rel="noreferrer"
                          className="text-brand hover:underline"
                        >
                          {p.website}
                        </a>
                      ) : (
                        '—'
                      )}
                    </TD>
                    <TD>
                      <Badge
                        tone={
                          p.isActive
                            ? 'bg-green-100 text-green-800'
                            : 'bg-gray-200 text-gray-600'
                        }
                      >
                        {p.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TD>
                    <TD>
                      <div className="flex gap-1">
                        <Button variant="ghost" size="icon" onClick={() => pickLogo(p.id)}>
                          <Upload className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => openEdit(p)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => setToDelete(p)}>
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
        title={editing ? 'تعديل الشركة' : 'شركة جديدة'}
        footer={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              إلغاء
            </Button>
            <Button
              loading={create.isPending || update.isPending}
              disabled={!form.name}
              onClick={save}
            >
              حفظ
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Field label="اسم الشركة">
            <Input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="مثال: SMSA Express"
            />
          </Field>
          <div className="grid grid-cols-2 gap-4">
            <Field label="الرسوم (ر.س)">
              <Input
                type="number"
                step="0.01"
                value={form.deliveryFee}
                onChange={(e) => setForm({ ...form, deliveryFee: Number(e.target.value) })}
              />
            </Field>
            <Field label="مدة التوصيل (أيام)">
              <Input
                type="number"
                min={1}
                value={form.estimatedDays}
                onChange={(e) => setForm({ ...form, estimatedDays: Number(e.target.value) })}
              />
            </Field>
          </div>
          <Field label="رقم الهاتف">
            <Input
              dir="ltr"
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              placeholder="+9665XXXXXXXX"
            />
          </Field>
          <Field label="الموقع الإلكتروني">
            <Input
              dir="ltr"
              value={form.website}
              onChange={(e) => setForm({ ...form, website: e.target.value })}
              placeholder="https://..."
            />
          </Field>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
            />
            شركة نشطة (تظهر للعميل عند الطلب)
          </label>
          {editing ? (
            <p className="text-xs text-gray-500">
              ارفع الشعار من زر الرفع بجانب الشركة في الجدول.
            </p>
          ) : null}
        </div>
      </Modal>

      <ConfirmDialog
        open={!!toDelete}
        onClose={() => setToDelete(null)}
        onConfirm={confirmDelete}
        title="حذف الشركة"
        message={`حذف "${toDelete?.name}"؟ الشركات المرتبطة بطلبات لا يمكن حذفها — عطّلها بدلاً من ذلك.`}
        confirmLabel="حذف"
        loading={remove.isPending}
        danger
      />
    </div>
  );
}
