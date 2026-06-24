'use client';

import { useState } from 'react';
import { Plus } from 'lucide-react';
import { useEmployees, useUserMutations } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Input,
  Field,
  Badge,
  Button,
  Modal,
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
  useToast,
} from '@aldiafa/shared/ui';
import { formatDate, type CreateEmployeeInput } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const empty: CreateEmployeeInput = { fullName: '', email: '', phone: '', password: '' };

export default function EmployeesPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading, isError, refetch } = useEmployees({ page, limit: 20 });
  const { createEmployee, setStatus } = useUserMutations();
  const toast = useToast();

  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<CreateEmployeeInput>(empty);

  const create = async () => {
    try {
      await createEmployee.mutateAsync({
        ...form,
        phone: form.phone || undefined,
      });
      toast.success('تم إنشاء حساب الموظف');
      setOpen(false);
      setForm(empty);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل الإنشاء');
    }
  };

  const toggle = async (id: string, isActive: boolean) => {
    try {
      await setStatus.mutateAsync({ id, isActive: !isActive });
      toast.success(isActive ? 'تم تعطيل الحساب' : 'تم تفعيل الحساب');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشلت العملية');
    }
  };

  return (
    <div>
      <PageHeader
        title="الموظفون"
        subtitle="إدارة حسابات الموظفين"
        action={
          <Button onClick={() => setOpen(true)}>
            <Plus className="h-4 w-4" />
            موظف جديد
          </Button>
        }
      />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState title="لا يوجد موظفون" action={<Button onClick={() => setOpen(true)}>إضافة موظف</Button>} />
          ) : (
            <>
              <Table>
                <THead>
                  <TR>
                    <TH>الاسم</TH>
                    <TH>البريد</TH>
                    <TH>الجوال</TH>
                    <TH>طلبات تمت مراجعتها</TH>
                    <TH>التسجيل</TH>
                    <TH>الحالة</TH>
                    <TH></TH>
                  </TR>
                </THead>
                <TBody>
                  {data.items.map((u) => (
                    <TR key={u.id}>
                      <TD className="font-medium text-gray-900">{u.fullName}</TD>
                      <TD className="text-xs text-gray-500" dir="ltr">{u.email ?? '—'}</TD>
                      <TD className="text-xs text-gray-500" dir="ltr">{u.phone ?? '—'}</TD>
                      <TD>{u._count?.reviewedOrders ?? 0}</TD>
                      <TD className="text-xs text-gray-500">{formatDate(u.createdAt)}</TD>
                      <TD>
                        <Badge tone={u.isActive ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'}>
                          {u.isActive ? 'نشط' : 'معطل'}
                        </Badge>
                      </TD>
                      <TD>
                        <Button
                          variant={u.isActive ? 'outline' : 'primary'}
                          size="sm"
                          onClick={() => toggle(u.id, u.isActive)}
                        >
                          {u.isActive ? 'تعطيل' : 'تفعيل'}
                        </Button>
                      </TD>
                    </TR>
                  ))}
                </TBody>
              </Table>
              <Pagination page={page} totalPages={data.meta.totalPages} onChange={setPage} />
            </>
          )}
        </CardBody>
      </Card>

      <Modal
        open={open}
        onClose={() => setOpen(false)}
        title="موظف جديد"
        footer={
          <>
            <Button variant="ghost" onClick={() => setOpen(false)}>
              إلغاء
            </Button>
            <Button
              loading={createEmployee.isPending}
              disabled={!form.fullName || !form.email || form.password.length < 8}
              onClick={create}
            >
              إنشاء
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Field label="الاسم الكامل">
            <Input value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} />
          </Field>
          <Field label="البريد الإلكتروني">
            <Input dir="ltr" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
          </Field>
          <Field label="رقم الجوال (اختياري)">
            <Input dir="ltr" placeholder="+9665XXXXXXXX" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
          </Field>
          <Field label="كلمة المرور" error={form.password && form.password.length < 8 ? '8 أحرف على الأقل' : undefined}>
            <Input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
          </Field>
        </div>
      </Modal>
    </div>
  );
}
