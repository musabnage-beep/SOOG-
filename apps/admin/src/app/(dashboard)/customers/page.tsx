'use client';

import { useState } from 'react';
import { Search } from 'lucide-react';
import { useCustomers, useUserMutations } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Input,
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
  useToast,
} from '@aldiafa/shared/ui';
import { formatDate } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function CustomersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const { data, isLoading, isError, refetch } = useCustomers({
    page,
    limit: 20,
    search: search || undefined,
  });
  const { setStatus } = useUserMutations();
  const toast = useToast();

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
      <PageHeader title="العملاء" subtitle="إدارة حسابات العملاء" />

      <Card className="mb-4">
        <CardBody>
          <div className="relative max-w-md">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              className="pr-9"
              placeholder="بحث بالاسم أو البريد أو الجوال..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
            />
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.items.length === 0 ? (
            <EmptyState title="لا يوجد عملاء" />
          ) : (
            <>
              <Table>
                <THead>
                  <TR>
                    <TH>الاسم</TH>
                    <TH>البريد</TH>
                    <TH>الجوال</TH>
                    <TH>الطلبات</TH>
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
                      <TD>{u._count?.orders ?? 0}</TD>
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
    </div>
  );
}
