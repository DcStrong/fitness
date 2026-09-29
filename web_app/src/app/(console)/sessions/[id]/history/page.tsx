'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { use } from 'react';
import { api } from '../../../../../lib/api/api';

const STATUS_RU: Record<string, string> = {
  booked: 'Запланирована',
  completed: 'Проведена',
  cancelled: 'Отменена',
  no_show: 'Неявка',
};

export default function SessionHistoryPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const { data, isLoading, error } = useQuery({
    queryKey: ['session-history', id],
    queryFn: () => api.sessionHistory(id),
  });

  return (
    <div className="stack">
      <div className="row">
        <h1>История занятия</h1>
        <Link className="btnSecondary" href="/sessions">
          Назад
        </Link>
      </div>
      {isLoading ? <p>Загрузка…</p> : null}
      {error ? <p className="error">{(error as Error).message}</p> : null}
      {!isLoading && (data ?? []).length === 0 ? (
        <p className="muted">Пока нет событий</p>
      ) : null}
      {(data ?? []).map((e) => (
        <div key={e.id} className="card">
          <strong>
            {STATUS_RU[e.fromStatus] ?? e.fromStatus} →{' '}
            {STATUS_RU[e.toStatus] ?? e.toStatus}
          </strong>
          <div className="muted">
            {new Date(e.createdAt).toLocaleString()} · {e.actorEmail ?? '—'}
            {e.note ? ` · ${e.note}` : ''}
          </div>
        </div>
      ))}
    </div>
  );
}
