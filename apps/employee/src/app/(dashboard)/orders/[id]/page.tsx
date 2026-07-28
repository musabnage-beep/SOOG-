'use client';

import { use, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowRight,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  ClipboardCheck,
  MapPin,
  User,
  Phone,
  Building2,
  Globe,
} from 'lucide-react';
import { useOrder, useOrderActions } from '@aldiafa/shared/client';
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
} from '@aldiafa/shared/ui';
import {
  money,
  formatDateTime,
  ORDER_STATUS_LABEL_AR,
  ORDER_STATUS_TONE,
  FULFILLMENT_LABEL_AR,
  PAYMENT_METHOD_LABEL_AR,
  PAYMENT_STATUS_LABEL_AR,
  PAYMENT_STATUS_TONE,
  advanceTargets,
  type OrderStatus,
} from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

export default function OrderDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const router = useRouter();
  const toast = useToast();
  const { data: order, isLoading, isError, refetch } = useOrder(id);
  const actions = useOrderActions(id);

  const [rejectOpen, setRejectOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [unavailable, setUnavailable] = useState<Set<string>>(new Set());
  const [confirmNote, setConfirmNote] = useState('');

  if (isLoading) return <Loading label="جارٍ تحميل الطلب..." />;
  if (isError || !order) return <ErrorState onRetry={() => refetch()} />;

  const status = order.status;
  const nextTargets = advanceTargets(status, order.deliveryMethod);
  const provider = order.deliveryMethod === 'THIRD_PARTY' ? order.deliveryProvider : null;

  const run = async (fn: () => Promise<unknown>, msg: string) => {
    try {
      await fn();
      toast.success(msg);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشلت العملية');
    }
  };

  const toggleUnavailable = (itemId: string) => {
    setUnavailable((prev) => {
      const next = new Set(prev);
      next.has(itemId) ? next.delete(itemId) : next.add(itemId);
      return next;
    });
  };

  return (
    <div>
      <PageHeader
        title={`الطلب ${order.orderNumber}`}
        subtitle={formatDateTime(order.submittedAt)}
        action={
          <Button variant="outline" onClick={() => router.push('/orders')}>
            <ArrowRight className="h-4 w-4" />
            رجوع
          </Button>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          {/* status + actions */}
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
                      <Button variant="outline" onClick={() => setConfirmOpen(true)}>
                        <AlertTriangle className="h-4 w-4" />
                        طلب تأكيد العميل
                      </Button>
                    )}
                    <Button variant="danger" onClick={() => setRejectOpen(true)}>
                      <XCircle className="h-4 w-4" />
                      رفض
                    </Button>
                  </>
                )}
                {nextTargets.map((t) => (
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

          {/* items */}
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

          {/* timeline */}
          {order.statusHistory && order.statusHistory.length > 0 && (
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
                        <Badge tone={ORDER_STATUS_TONE[h.status]}>
                          {ORDER_STATUS_LABEL_AR[h.status]}
                        </Badge>
                        <span className="text-xs text-gray-400">{formatDateTime(h.createdAt)}</span>
                      </div>
                      {h.note && <p className="mt-1 text-sm text-gray-600">{h.note}</p>}
                    </li>
                  ))}
                </ol>
              </CardBody>
            </Card>
          )}
        </div>

        {/* sidebar */}
        <div className="space-y-6">
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

          {order.address && (
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
          )}

          {provider && (
            <Card>
              <CardHeader>
                <CardTitle>الشحن عبر شركة توصيل</CardTitle>
              </CardHeader>
              <CardBody className="space-y-3 text-sm text-gray-700">
                <div className="flex items-center gap-3">
                  {provider.logo ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={provider.logo}
                      alt={provider.name}
                      className="h-10 w-10 rounded object-contain"
                    />
                  ) : (
                    <Building2 className="h-8 w-8 text-gray-400" />
                  )}
                  <div>
                    <p className="font-semibold text-gray-900">{provider.name}</p>
                    <p className="text-xs text-gray-500">
                      {money(provider.deliveryFee)} · خلال {provider.estimatedDays} أيام
                    </p>
                  </div>
                </div>

                {provider.phone && (
                  <a
                    href={`tel:${provider.phone}`}
                    className="flex items-center gap-2 text-brand hover:underline"
                    dir="ltr"
                  >
                    <Phone className="h-4 w-4" />
                    {provider.phone}
                  </a>
                )}
                {provider.website && (
                  <a
                    href={provider.website}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center gap-2 text-brand hover:underline"
                    dir="ltr"
                  >
                    <Globe className="h-4 w-4" />
                    {provider.website}
                  </a>
                )}

                <div className="space-y-1 border-t border-gray-100 pt-3">
                  <p className="text-xs font-medium text-gray-500">بيانات الشحنة للشركة</p>
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
                  {order.address && (
                    <p className="flex items-start gap-2">
                      <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-gray-400" />
                      <span>
                        {order.address.city}، {order.address.district}
                        <br />
                        {order.address.street}
                      </span>
                    </p>
                  )}
                </div>

                {order.address && (
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${order.address.latitude},${order.address.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    <Button variant="outline" className="w-full">
                      <MapPin className="h-4 w-4" />
                      فتح في خرائط جوجل
                    </Button>
                  </a>
                )}
              </CardBody>
            </Card>
          )}

          {order.customerNote && (
            <Card>
              <CardHeader>
                <CardTitle>ملاحظة العميل</CardTitle>
              </CardHeader>
              <CardBody>
                <p className="text-sm text-gray-600">{order.customerNote}</p>
              </CardBody>
            </Card>
          )}

          {order.rejectionReason && (
            <Card>
              <CardHeader>
                <CardTitle>سبب الرفض</CardTitle>
              </CardHeader>
              <CardBody>
                <p className="text-sm text-red-600">{order.rejectionReason}</p>
              </CardBody>
            </Card>
          )}
        </div>
      </div>

      {/* reject modal */}
      <Modal
        open={rejectOpen}
        onClose={() => setRejectOpen(false)}
        title="رفض الطلب"
        footer={
          <>
            <Button variant="ghost" onClick={() => setRejectOpen(false)}>
              إلغاء
            </Button>
            <Button
              variant="danger"
              loading={actions.reject.isPending}
              disabled={!rejectReason.trim()}
              onClick={() =>
                run(() => actions.reject.mutateAsync(rejectReason.trim()), 'تم رفض الطلب').then(() =>
                  setRejectOpen(false),
                )
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
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
        />
      </Modal>

      {/* request confirmation modal */}
      <Modal
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        title="طلب تأكيد العميل"
        footer={
          <>
            <Button variant="ghost" onClick={() => setConfirmOpen(false)}>
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
                      note: confirmNote.trim() || undefined,
                    }),
                  'تم إرسال طلب التأكيد للعميل',
                ).then(() => setConfirmOpen(false))
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
              <input
                type="checkbox"
                checked={unavailable.has(it.id)}
                onChange={() => toggleUnavailable(it.id)}
              />
              <span className="flex-1">{it.nameAr}</span>
              <span className="text-gray-400">×{it.quantity}</span>
            </label>
          ))}
        </div>
        <Textarea
          className="mt-3"
          placeholder="ملاحظة للعميل (اختياري)..."
          value={confirmNote}
          onChange={(e) => setConfirmNote(e.target.value)}
        />
      </Modal>
    </div>
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
