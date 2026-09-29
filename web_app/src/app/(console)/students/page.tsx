'use client';

import { useQuery } from '@tanstack/react-query';
import { api } from '../../../lib/api/api';

export default function StudentsPage() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['relationships'],
    queryFn: () => api.relationships(),
  });

  const students = (data ?? []).filter((r) => r.roleForViewer === 'coach');

  return (
    <div className="stack">
      <div className="row">
        <h1>Ученики</h1>
        <button type="button" className="btnSecondary" onClick={() => refetch()}>
          Обновить
        </button>
      </div>
      {isLoading ? <p>Загрузка…</p> : null}
      {error ? <p className="error">{(error as Error).message}</p> : null}
      {!isLoading && students.length === 0 ? (
        <p className="muted">Пока нет связанных учеников</p>
      ) : null}
      {students.map((s) => (
        <div key={s.id} className="card">
          <strong>{s.studentEmail ?? s.studentId}</strong>
          <div className="muted">id: {s.studentId}</div>
        </div>
      ))}
    </div>
  );
}
