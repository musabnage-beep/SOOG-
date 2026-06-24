'use client';

import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from './primitives';

export function Pagination({
  page,
  totalPages,
  onChange,
}: {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}) {
  if (totalPages <= 1) return null;
  return (
    <div className="flex items-center justify-center gap-2 py-4">
      <Button
        variant="outline"
        size="sm"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
      >
        <ChevronRight className="h-4 w-4" />
        السابق
      </Button>
      <span className="px-3 text-sm text-gray-600">
        صفحة {page} من {totalPages}
      </span>
      <Button
        variant="outline"
        size="sm"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
      >
        التالي
        <ChevronLeft className="h-4 w-4" />
      </Button>
    </div>
  );
}
