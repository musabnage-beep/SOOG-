'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { FileText, FileSpreadsheet, FileDown } from 'lucide-react';
import { useApi } from '@aldiafa/shared/client';
import {
  Card,
  CardBody,
  Button,
  Input,
  Select,
  Field,
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
import { REPORT_TYPE_LABEL_AR, type ReportType, type ReportFormat } from '@aldiafa/shared';
import { PageHeader } from '@/components/page-header';

const TYPES: ReportType[] = ['SALES', 'ORDERS', 'INVENTORY', 'CUSTOMERS', 'EMPLOYEES'];

export default function ReportsPage() {
  const api = useApi();
  const toast = useToast();
  const [type, setType] = useState<ReportType>('SALES');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [downloading, setDownloading] = useState<ReportFormat | null>(null);

  const report = useQuery({
    queryKey: ['report', type, from, to],
    queryFn: () => api.reports.data(type, from || undefined, to || undefined),
  });

  const download = async (format: ReportFormat) => {
    setDownloading(format);
    try {
      const blob = await api.reports.exportBlob(type, format, from || undefined, to || undefined);
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      const ext = format === 'EXCEL' ? 'xlsx' : format.toLowerCase();
      a.href = url;
      a.download = `${type.toLowerCase()}-${Date.now()}.${ext}`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      toast.error(e instanceof Error ? e.message : 'فشل التصدير');
    } finally {
      setDownloading(null);
    }
  };

  return (
    <div>
      <PageHeader title="التقارير" subtitle="عرض وتصدير تقارير المتجر" />

      <Card className="mb-4">
        <CardBody className="flex flex-wrap items-end gap-3">
          <Field label="نوع التقرير" className="w-56">
            <Select value={type} onChange={(e) => setType(e.target.value as ReportType)}>
              {TYPES.map((t) => (
                <option key={t} value={t}>
                  {REPORT_TYPE_LABEL_AR[t]}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="من تاريخ" className="w-44">
            <Input type="date" dir="ltr" value={from} onChange={(e) => setFrom(e.target.value)} />
          </Field>
          <Field label="إلى تاريخ" className="w-44">
            <Input type="date" dir="ltr" value={to} onChange={(e) => setTo(e.target.value)} />
          </Field>
          <div className="flex gap-2">
            <Button variant="outline" loading={downloading === 'PDF'} onClick={() => download('PDF')}>
              <FileText className="h-4 w-4" />
              PDF
            </Button>
            <Button variant="outline" loading={downloading === 'EXCEL'} onClick={() => download('EXCEL')}>
              <FileSpreadsheet className="h-4 w-4" />
              Excel
            </Button>
            <Button variant="outline" loading={downloading === 'CSV'} onClick={() => download('CSV')}>
              <FileDown className="h-4 w-4" />
              CSV
            </Button>
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardBody className="p-0">
          {report.isLoading ? (
            <Loading />
          ) : report.isError ? (
            <ErrorState onRetry={() => report.refetch()} />
          ) : !report.data || report.data.rows.length === 0 ? (
            <EmptyState title="لا توجد بيانات" subtitle="لا توجد بيانات للفترة المحددة" />
          ) : (
            <Table>
              <THead>
                <TR>
                  {report.data.columns.map((c) => (
                    <TH key={c}>{c}</TH>
                  ))}
                </TR>
              </THead>
              <TBody>
                {report.data.rows.map((row, i) => (
                  <TR key={i}>
                    {row.map((cell, j) => (
                      <TD key={j}>{String(cell)}</TD>
                    ))}
                  </TR>
                ))}
              </TBody>
            </Table>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
