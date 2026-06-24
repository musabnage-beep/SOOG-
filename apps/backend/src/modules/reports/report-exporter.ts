import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import PDFDocument from 'pdfkit';
import { ReportDataset } from './reports.service';

export interface ExportedFile {
  buffer: Buffer;
  contentType: string;
  filename: string;
}

@Injectable()
export class ReportExporter {
  async toCsv(dataset: ReportDataset): Promise<ExportedFile> {
    const escape = (v: string | number) => {
      const s = String(v);
      return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const lines = [dataset.columns.map(escape).join(',')];
    for (const row of dataset.rows) lines.push(row.map(escape).join(','));
    return {
      buffer: Buffer.from('\uFEFF' + lines.join('\n'), 'utf8'), // BOM for Excel/Arabic
      contentType: 'text/csv; charset=utf-8',
      filename: `${this.slug(dataset.title)}.csv`,
    };
  }

  async toExcel(dataset: ReportDataset): Promise<ExportedFile> {
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet(dataset.title.slice(0, 31));
    ws.addRow(dataset.columns);
    ws.getRow(1).font = { bold: true };
    for (const row of dataset.rows) ws.addRow(row);
    ws.columns.forEach((col) => {
      col.width = 20;
    });
    const buffer = Buffer.from(await wb.xlsx.writeBuffer());
    return {
      buffer,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      filename: `${this.slug(dataset.title)}.xlsx`,
    };
  }

  async toPdf(dataset: ReportDataset): Promise<ExportedFile> {
    const doc = new PDFDocument({ margin: 36, size: 'A4', layout: 'landscape' });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(c as Buffer));

    const done = new Promise<Buffer>((resolve) => {
      doc.on('end', () => resolve(Buffer.concat(chunks)));
    });

    doc.fontSize(18).text(dataset.title, { align: 'center' });
    doc.moveDown(0.5);
    doc.fontSize(9).fillColor('#666').text(`Generated ${new Date().toISOString()}`, { align: 'center' });
    doc.moveDown();

    const colWidth = (doc.page.width - 72) / dataset.columns.length;
    doc.fillColor('#000').fontSize(10).font('Helvetica-Bold');
    dataset.columns.forEach((c, i) => {
      doc.text(c, 36 + i * colWidth, doc.y, { width: colWidth, continued: i < dataset.columns.length - 1 });
    });
    doc.moveDown(0.5).font('Helvetica').fontSize(9);

    for (const row of dataset.rows) {
      const y = doc.y;
      row.forEach((cell, i) => {
        doc.text(String(cell), 36 + i * colWidth, y, {
          width: colWidth,
          continued: i < row.length - 1,
        });
      });
      doc.moveDown(0.3);
      if (doc.y > doc.page.height - 50) doc.addPage();
    }

    doc.end();
    return {
      buffer: await done,
      contentType: 'application/pdf',
      filename: `${this.slug(dataset.title)}.pdf`,
    };
  }

  private slug(title: string): string {
    return title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  }
}
