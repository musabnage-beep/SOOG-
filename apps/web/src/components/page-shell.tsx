import type { ReactNode } from 'react';
import { SiteHeader } from './site-header';
import { SiteFooter } from './site-footer';

/** Header + titled content area + footer, shared by every secondary page. */
export function PageShell({
  title,
  intro,
  children,
}: {
  title: string;
  intro?: string;
  children: ReactNode;
}) {
  return (
    <main className="min-h-screen bg-white">
      <SiteHeader />

      <div className="bg-brand-muted">
        <div className="mx-auto max-w-3xl px-6 py-10">
          <h1 className="text-3xl font-bold text-brand-dark">{title}</h1>
          {intro ? <p className="mt-2 text-sm text-muted">{intro}</p> : null}
        </div>
      </div>

      <div className="mx-auto max-w-3xl px-6 py-10">{children}</div>

      <SiteFooter />
    </main>
  );
}

/** A titled block of policy copy. */
export function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="mb-8">
      <h2 className="mb-3 text-xl font-bold text-brand-dark">{title}</h2>
      <div className="space-y-3 text-[15px] leading-loose text-gray-700">{children}</div>
    </section>
  );
}

/** Bulleted list used inside policy sections. */
export function Bullets({ items }: { items: string[] }) {
  return (
    <ul className="list-disc space-y-2 pr-5">
      {items.map((item) => (
        <li key={item}>{item}</li>
      ))}
    </ul>
  );
}
