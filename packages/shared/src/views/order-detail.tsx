'use client';

import { useState } from 'react';
import {
  ArrowRight,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  ClipboardCheck,
  MapPin,
  User,
  Phone,
} from 'lucide-react';
import { useOrder, useOrderActions } from '../client/hooks';
import {
  Card,
  CardHeader,
  CardTitle,
  CardBody,
  Badge,
  Button,
  Modal,
  Textarea,
  Loading,
  ErrorState,
  useToast,
  Table,
  THead,
  TBody,
  TR,
  TH,
  TD,
  PageHeader,
} from '../ui';
import { money, formatDateTime } from '../format';
import {
  ORDER_STATUS_LABEL_AR,
  ORDER_STATUS_TONE,
  FULFILLMENT_LABEL_AR,
  PAYMENT_METHOD_LABEL_AR,
  PAYMENT_STATUS_LABEL_AR,
  PAYMENT_STATUS_TONE,
  advanceTargets,
} from '../constants';
import type { Order, OrderStatus } from '../types';

type OrderActions = ReturnType<typeof useOrderActions>;

/** Runs a mutation and reports the outcome; never rejects, so callers can
 *  chain `.then()` to close a modal regardless of success or failure. */
type RunAction = (fn: () => Promise<unknown>, msg: string) => Promise<void>;

/**
 * Staff-facing order detail screen, shared by the admin and employee
 * dashboards. Routing is left to the host app via `onBack`.
 */
export function OrderDetailView({ orderId, onBack }: { orderId: string; onBack: () => void }) {
  const toast = useToast();
  const { data: order, isLoading, isError, refetch } = useOrder(orderId);
  const actions = useOrderActions(orderId);

  const [rejectOpen, setRejectOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);

  if (isLoading) return <Loading label="جارٍ تحميل الطلب..." />;
  if (isError || !order) return <ErrorState onRetry={() => refetch()} />;

  const run: RunAction = async (fn, msg) => {
    try {
      await fn();
      toast.success(msg);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشلت العملية');
    }
  };

  return (
    <div>
      <PageHeader
        title={`الطلب ${order.orderNumber}`}
        subtitle={formatDateTime(order.submittedAt)}
        action={
          <Button variant="outline" onClick={onBack}>
            <ArrowRight className="h-4 w-4" />
            رجوع
          </Button>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <StatusActionsCard
            status={order.status}
            actions={actions}
            run={run}
            onReject={() => setRejectOpen(true)}
            onRequestConfirmation={() => setConfirmOpen(true)}
          />
          <ItemsCard order={order} />
          <StatusTimelineCard order={order} />
        </div>

        <div className="space-y-6">
          <PaymentSummaryCard order={order} />
          <CustomerCard order={order} />
          <AddressCard order={order} />
          <NoteCard title="ملاحظة العميل" text={order.customerNote} className="text-gray-600" />
          <NoteCard title="سبب الرفض" text={order.rejectionReason} className="text-red-600" />
        </div>
      </div>

      <RejectModal
        open={rejectOpen}
        onClose={() => setRejectOpen(false)}
        actions={actions}
        run={run}
      />
      <RequestConfirmationModal
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        order={order}
        actions={actions}
        run={run}
      />
    </div>
  );
}

function StatusActionsCard({
  status,
  actions,
  run,
  onReject,
  onRequestConfirmation,
}: {
  status: OrderStatus;
  actions: OrderActions;
  run: RunAction;
  onReject: () => void;
  onRequestConfirmation: () => void;
}) {
  return (
    <Card>
      <CardBody className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <span className="text-sm text-gray-500">الحالة:</span>
          <Badge tone={ORDER_STATUS_TONE[status]}>{ORDER_STATUS_LABEL_AR[status]}</Badge>
        </div>
        <div className="flex flex-wrap gap-2">
          {status === 'SUBMITTED' && (
            <Button
              loading={actions.review.isPending}
              onClick={() => run(() => actions.review.mutateAsync(), 'تم بدء المراجعة')}
            >
              <ClipboardCheck className="h-4 w-4" />
              بدء المراجعة
            </Button>
          )}
          {(status === 'UNDER_REVIEW' || status === 'CONFIRMATION_REQUIRED') && (
            <>
              <Button
                loading={actions.approve.isPending}
                onClick={() => run(() => actions.approve.mutateAsync(), 'تمت الموافقة على الطلب')}
              >
                <CheckCircle2 className="h-4 w-4" />
                موافقة
              </Button>
              {status === 'UNDER_REVIEW' && (
                <Button variant="outline" onClick={onRequestConfirmation}>
                  <AlertTriangle className="h-4 w-4" />
                  طلب تأكيد العميل
                </Button>
              )}
              <Button variant="danger" onClick={onReject}>
                <XCircle className="h-4 w-4" />
                رفض
              </Button>
            </>
          )}
          {advanceTargets(status).map((t) => (
            <Button
              key={t}
              loading={actions.advance.isPending}
              onClick={() =>
                run(
                  () => actions.advance.mutateAsync({ status: t }),
                  `تم تحديث الحالة: ${ORDER_STATUS_LABEL_AR[t]}`,
                )
              }
            >
              {ORDER_STATUS_LABEL_AR[t as OrderStatus]}
            </Button>
          ))}
        </div>
      </CardBody>
    </Card>
  );
}

function ItemsCard({ order }: { order: Order }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>عناصر الطلب ({order.items.length})</CardTitle>
      </CardHeader>
      <CardBody className="p-0">
        <Table>
          <THead>
            <TR>
              <TH>المنتج</TH>
              <TH>السعر</TH>
              <TH>الكمية</TH>
              <TH>الإجمالي</TH>
              <TH>الحالة</TH>
            </TR>
          </THead>
          <TBody>
            {order.items.map((it) => (
              <TR key={it.id}>
                <TD className="font-medium text-gray-900">{it.nameAr}</TD>
                <TD>{money(it.unitPrice)}</TD>
                <TD>{it.quantity}</TD>
                <TD className="font-semibold">{money(it.lineTotal)}</TD>
                <TD>
                  {it.availability === 'UNAVAILABLE' ? (
                    <Badge tone="bg-red-100 text-red-800">غير متوفر</Badge>
                  ) : (
                    <Badge tone="bg-green-100 text-green-800">متوفر</Badge>
                  )}
                </TD>
              </TR>
            ))}
          </TBody>
        </Table>
      </CardBody>
    </Card>
  );
}

function StatusTimelineCard({ order }: { order: Order }) {
  if (!order.statusHistory || order.statusHistory.length === 0) return null;
  return (
    <Card>
      <CardHeader>
        <CardTitle>سجل الحالة</CardTitle>
      </CardHeader>
      <CardBody>
        <ol className="relative space-y-4 border-r border-gray-200 pr-4">
          {order.statusHistory.map((h) => (
            <li key={h.id} className="relative">
              <span className="absolute -right-[22px] top-1 h-3 w-3 rounded-full bg-brand" />
              <div className="flex items-center justify-between gap-2">
                <Badge tone={ORDER_STATUS_TONE[h.status]}>{ORDER_STATUS_LABEL_AR[h.status]}</Badge>
                <span className="text-xs text-gray-400">{formatDateTime(h.createdAt)}</span>
              </div>
              {h.note && <p className="mt-1 text-sm text-gray-600">{h.note}</p>}
            </li>
          ))}
        </ol>
      </CardBody>
    </Card>
  );
}

function PaymentSummaryCard({ order }: { order: Order }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>ملخص الدفع</CardTitle>
      </CardHeader>
      <CardBody className="space-y-2 text-sm">
        <Row label="المجموع الفرعي" value={money(order.subtotal)} />
        <Row label="رسوم التوصيل" value={money(order.deliveryFee)} />
        <Row label="الخصم" value={money(order.discountTotal)} />
        <div className="my-2 border-t border-gray-100" />
        <Row label="الإجمالي" value={money(order.total)} bold />
        <div className="mt-3 flex items-center gap-2 text-gray-500">
          <span>طريقة الاستلام:</span>
          <Badge>{FULFILLMENT_LABEL_AR[order.fulfillmentType]}</Badge>
        </div>
        <div className="mt-2 flex items-center gap-2 text-gray-500">
          <span>طريقة الدفع:</span>
          <Badge>{PAYMENT_METHOD_LABEL_AR[order.paymentMethod]}</Badge>
        </div>
        <div className="mt-2 flex items-center gap-2 text-gray-500">
          <span>حالة الدفع:</span>
          <Badge tone={PAYMENT_STATUS_TONE[order.paymentStatus]}>
            {PAYMENT_STATUS_LABEL_AR[order.paymentStatus]}
          </Badge>
        </div>
      </CardBody>
    </Card>
  );
}

function CustomerCard({ order }: { order: Order }) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>العميل</CardTitle>
      </CardHeader>
      <CardBody className="space-y-2 text-sm text-gray-700">
        <p className="flex items-center gap-2">
          <User className="h-4 w-4 text-gray-400" />
          {order.user?.fullName ?? '—'}
        </p>
        {order.user?.phone && (
          <p className="flex items-center gap-2" dir="ltr">
            <Phone className="h-4 w-4 text-gray-400" />
            {order.user.phone}
          </p>
        )}
      </CardBody>
    </Card>
  );
}

function AddressCard({ order }: { order: Order }) {
  if (!order.address) return null;
  return (
    <Card>
      <CardHeader>
        <CardTitle>عنوان التوصيل</CardTitle>
      </CardHeader>
      <CardBody className="space-y-1 text-sm text-gray-700">
        <p className="flex items-start gap-2">
          <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-gray-400" />
          <span>
            {order.address.city}، {order.address.district}
            <br />
            {order.address.street}
          </span>
        </p>
        {order.distanceMeters != null && (
          <p className="text-xs text-gray-400">
            المسافة: {(order.distanceMeters / 1000).toFixed(1)} كم
            {order.etaMinutes != null && ` · ~${order.etaMinutes} دقيقة`}
          </p>
        )}
      </CardBody>
    </Card>
  );
}

function NoteCard({
  title,
  text,
  className,
}: {
  title: string;
  text: string | null;
  className: string;
}) {
  if (!text) return null;
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardBody>
        <p className={`text-sm ${className}`}>{text}</p>
      </CardBody>
    </Card>
  );
}

function RejectModal({
  open,
  onClose,
  actions,
  run,
}: {
  open: boolean;
  onClose: () => void;
  actions: OrderActions;
  run: RunAction;
}) {
  const [reason, setReason] = useState('');
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="رفض الطلب"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            إلغاء
          </Button>
          <Button
            variant="danger"
            loading={actions.reject.isPending}
            disabled={!reason.trim()}
            onClick={() =>
              run(() => actions.reject.mutateAsync(reason.trim()), 'تم رفض الطلب').then(onClose)
            }
          >
            تأكيد الرفض
          </Button>
        </>
      }
    >
      <p className="mb-2 text-sm text-gray-600">سيتم إرسال سبب الرفض إلى العميل.</p>
      <Textarea
        placeholder="اكتب سبب الرفض..."
        value={reason}
        onChange={(e) => setReason(e.target.value)}
      />
    </Modal>
  );
}

function RequestConfirmationModal({
  open,
  onClose,
  order,
  actions,
  run,
}: {
  open: boolean;
  onClose: () => void;
  order: Order;
  actions: OrderActions;
  run: RunAction;
}) {
  const [unavailable, setUnavailable] = useState<Set<string>>(new Set());
  const [note, setNote] = useState('');

  const toggle = (itemId: string) => {
    setUnavailable((prev) => {
      const next = new Set(prev);
      next.has(itemId) ? next.delete(itemId) : next.add(itemId);
      return next;
    });
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="طلب تأكيد العميل"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            إلغاء
          </Button>
          <Button
            loading={actions.requestConfirmation.isPending}
            disabled={unavailable.size === 0}
            onClick={() =>
              run(
                () =>
                  actions.requestConfirmation.mutateAsync({
                    unavailableItems: Array.from(unavailable).map((orderItemId) => ({ orderItemId })),
                    note: note.trim() || undefined,
                  }),
                'تم إرسال طلب التأكيد للعميل',
              ).then(onClose)
            }
          >
            إرسال
          </Button>
        </>
      }
    >
      <p className="mb-3 text-sm text-gray-600">حدد العناصر غير المتوفرة:</p>
      <div className="space-y-2">
        {order.items.map((it) => (
          <label
            key={it.id}
            className="flex cursor-pointer items-center gap-2 rounded-lg border border-gray-200 p-2 text-sm"
          >
            <input type="checkbox" checked={unavailable.has(it.id)} onChange={() => toggle(it.id)} />
            <span className="flex-1">{it.nameAr}</span>
            <span className="text-gray-400">×{it.quantity}</span>
          </label>
        ))}
      </div>
      <Textarea
        className="mt-3"
        placeholder="ملاحظة للعميل (اختياري)..."
        value={note}
        onChange={(e) => setNote(e.target.value)}
      />
    </Modal>
  );
}

function Row({ label, value, bold }: { label: string; value: string; bold?: boolean }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-gray-500">{label}</span>
      <span className={bold ? 'text-base font-bold text-brand' : 'font-medium text-gray-900'}>
        {value}
      </span>
    </div>
  );
}
