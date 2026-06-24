'use client';

import { useState } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { useZones, useZoneMutations } from '@aldiafa/shared/client';
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
import { money, num, type DeliveryZone, type UpsertDeliveryZoneInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const empty: UpsertDeliveryZoneInput = { name: '', minRadiusM: 0, maxRadiusM: 0, fee: 0, isActive: true };

export default function DeliveryPage() {
  const { data, isLoading, isError, refetch } = useZones();
  const { create, update, remove } = useZoneMutations();
  const toast = useToast();

  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<DeliveryZone | null>(null);
  const [form, setForm] = useState<UpsertDeliveryZoneInput>(empty);
  const [toDelete, setToDelete] = useState<DeliveryZone | null>(null);

  const openNew = () => {
    setEditing(null);
    setForm(empty);
    setOpen(true);
  };
  const openEdit = (z: DeliveryZone) => {
    setEditing(z);
    setForm({
      name: z.name,
      minRadiusM: z.minRadiusM,
      maxRadiusM: z.maxRadiusM,
      fee: Number(z.fee),
      isActive: z.isActive,
    });
    setOpen(true);
  };

  const save = async () => {
    try {
      if (editing) {
        await update.mutateAsync({ id: editing.id, input: form });
        toast.success('تم تحديث المنطقة');
      } else {
        await create.mutateAsync(form);
        toast.success('تم إنشاء المنطقة');
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
      toast.success('تم حذف المنطقة');
      setToDelete(null);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الحذف');
    }
  };

  return (
    <div>
      <PageHeader
        title="مناطق التوصيل"
        subtitle="إدارة رسوم التوصيل حسب المسافة"
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" />
            منطقة جديدة
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
            <EmptyState title="لا توجد مناطق توصيل" action={<Button onClick={openNew}>إضافة منطقة</Button>} />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>الاسم</TH>
                  <TH>من (متر)</TH>
                  <TH>إلى (متر)</TH>
                  <TH>الرسوم</TH>
                  <TH>الحالة</TH>
                  <TH></TH>
                </TR>
              </THead>
              <TBody>
                {data.map((z) => (
                  <TR key={z.id}>
                    <TD className="font-medium text-gray-900">{z.name}</TD>
                    <TD>{num(z.minRadiusM)}</TD>
                    <TD>{num(z.maxRadiusM)}</TD>
                    <TD className="font-semibold text-brand">{money(z.fee)}</TD>
                    <TD>
                      <Badge tone={z.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'}>
                        {z.isActive ? 'نشط' : 'غير نشط'}
                      </Badge>
                    </TD>
                    <TD>
                      <div className="flex gap-1">
                        <Button variant="ghost" size="icon" onClick={() => openEdit(z)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => setToDelete(z)}>
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
        title={editing ? 'تعديل المنطقة' : 'منطقة جديدة'}
        footer={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              إلغاء
            </Button>
            <Button loading={create.isPending || update.isPending} disabled={!form.name} onClick={save}>
              حفظ
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Field label="اسم المنطقة">
            <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </Field>
          <div className="grid grid-cols-2 gap-4">
            <Field label="الحد الأدنى (متر)">
              <Input type="number" value={form.minRadiusM} onChange={(e) => setForm({ ...form, minRadiusM: Number(e.target.value) })} />
            </Field>
            <Field label="الحد الأقصى (متر)">
              <Input type="number" value={form.maxRadiusM} onChange={(e) => setForm({ ...form, maxRadiusM: Number(e.target.value) })} />
            </Field>
          </div>
          <Field label="الرسوم (ر.س)">
            <Input type="number" step="0.01" value={form.fee} onChange={(e) => setForm({ ...form, fee: Number(e.target.value) })} />
          </Field>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} />
            منطقة نشطة
          </label>
        </div>
      </Modal>

      <ConfirmDialog
        open={!!toDelete}
        onClose={() => setToDelete(null)}
        onConfirm={confirmDelete}
        title="حذف المنطقة"
        message={`حذف "${toDelete?.name}"؟`}
        confirmLabel="حذف"
        loading={remove.isPending}
        danger
      />
    </div>
  );
}
