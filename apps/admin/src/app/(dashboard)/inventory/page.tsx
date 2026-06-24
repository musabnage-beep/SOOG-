'use client';

import { useState } from 'react';
import { SlidersHorizontal, History } from 'lucide-react';
import { useLowStock, useAdjustStock, useInventoryHistory } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Button,
  Input,
  Select,
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
  useToast,
} from '@aldiafa/shared/ui';
import {
  num,
  formatDateTime,
  STOCK_STATUS_LABEL_AR,
  STOCK_STATUS_TONE,
  INVENTORY_TYPE_LABEL_AR,
  type Product,
  type InventoryLogType,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function InventoryPage() {
  const { data, isLoading, isError, refetch } = useLowStock();
  const adjust = useAdjustStock();
  const toast = useToast();

  const [adjustFor, setAdjustFor] = useState<Product | null>(null);
  const [type, setType] = useState<InventoryLogType>('STOCK_IN');
  const [qty, setQty] = useState(0);
  const [reason, setReason] = useState('');
  const [historyFor, setHistoryFor] = useState<Product | null>(null);

  const submit = async () => {
    if (!adjustFor) return;
    const delta = type === 'STOCK_OUT' || type === 'SOLD' ? -Math.abs(qty) : qty;
    try {
      await adjust.mutateAsync({
        productId: adjustFor.id,
        input: { type, quantityDelta: delta, reason: reason || undefined },
      });
      toast.success('تم تعديل المخزون');
      setAdjustFor(null);
      setQty(0);
      setReason('');
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل التعديل');
    }
  };

  return (
    <div>
      <PageHeader title="المخزون" subtitle="المنتجات منخفضة أو نافدة المخزون" />

      <Card>
        <CardBody className="p-0">
          {isLoading ? (
            <Loading />
          ) : isError ? (
            <ErrorState onRetry={() => refetch()} />
          ) : !data || data.length === 0 ? (
            <EmptyState title="المخزون جيد" subtitle="لا توجد منتجات منخفضة المخزون حالياً" />
          ) : (
            <Table>
              <THead>
                <TR>
                  <TH>المنتج</TH>
                  <TH>SKU</TH>
                  <TH>الكمية</TH>
                  <TH>الحالة</TH>
                  <TH></TH>
                </TR>
              </THead>
              <TBody>
                {data.map((p) => (
                  <TR key={p.id}>
                    <TD className="font-medium text-gray-900">{p.nameAr}</TD>
                    <TD className="text-xs" dir="ltr">{p.sku}</TD>
                    <TD className="font-semibold">{num(p.quantity)}</TD>
                    <TD>
                      <Badge tone={STOCK_STATUS_TONE[p.stockStatus]}>
                        {STOCK_STATUS_LABEL_AR[p.stockStatus]}
                      </Badge>
                    </TD>
                    <TD>
                      <div className="flex gap-1">
                        <Button variant="outline" size="sm" onClick={() => setAdjustFor(p)}>
                          <SlidersHorizontal className="h-4 w-4" />
                          تعديل
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => setHistoryFor(p)}>
                          <History className="h-4 w-4" />
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

      {/* adjust modal */}
      <Modal
        open={!!adjustFor}
        onClose={() => setAdjustFor(null)}
        title={`تعديل مخزون: ${adjustFor?.nameAr ?? ''}`}
        footer={
          <>
            <Button variant="ghost" onClick={() => setAdjustFor(null)}>
              إلغاء
            </Button>
            <Button loading={adjust.isPending} disabled={qty <= 0} onClick={submit}>
              تأكيد
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <Field label="نوع الحركة">
            <Select value={type} onChange={(e) => setType(e.target.value as InventoryLogType)}>
              {(['STOCK_IN', 'STOCK_OUT', 'ADJUST', 'SOLD'] as InventoryLogType[]).map((t) => (
                <option key={t} value={t}>
                  {INVENTORY_TYPE_LABEL_AR[t]}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="الكمية">
            <Input type="number" min={1} value={qty} onChange={(e) => setQty(Number(e.target.value))} />
          </Field>
          <Field label="السبب (اختياري)">
            <Input value={reason} onChange={(e) => setReason(e.target.value)} />
          </Field>
        </div>
      </Modal>

      {/* history modal */}
      <Modal
        open={!!historyFor}
        onClose={() => setHistoryFor(null)}
        title={`سجل المخزون: ${historyFor?.nameAr ?? ''}`}
        className="max-w-2xl"
      >
        {historyFor && <HistoryList productId={historyFor.id} />}
      </Modal>
    </div>
  );
}

function HistoryList({ productId }: { productId: string }) {
  const { data, isLoading, isError } = useInventoryHistory(productId);
  if (isLoading) return <Loading />;
  if (isError) return <ErrorState />;
  if (!data || data.length === 0) return <EmptyState title="لا يوجد سجل" />;
  return (
    <Table>
      <THead>
        <TR>
          <TH>النوع</TH>
          <TH>التغيير</TH>
          <TH>قبل</TH>
          <TH>بعد</TH>
          <TH>التاريخ</TH>
        </TR>
      </THead>
      <TBody>
        {data.map((log) => (
          <TR key={log.id}>
            <TD>{INVENTORY_TYPE_LABEL_AR[log.type]}</TD>
            <TD className={log.quantityDelta < 0 ? 'text-red-600' : 'text-green-600'}>
              {log.quantityDelta > 0 ? `+${log.quantityDelta}` : log.quantityDelta}
            </TD>
            <TD>{log.quantityBefore}</TD>
            <TD>{log.quantityAfter}</TD>
            <TD className="text-xs text-gray-500">{formatDateTime(log.createdAt)}</TD>
          </TR>
        ))}
      </TBody>
    </Table>
  );
}
