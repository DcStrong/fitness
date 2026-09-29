'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { FormEvent, useState } from 'react';
import { api } from '../../../lib/api/api';

function toLocalInputValue(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

export default function SlotsPage() {
  const qc = useQueryClient();
  const { data, isLoading, error } = useQuery({
    queryKey: ['slots'],
    queryFn: () => api.listSlots(),
  });

  const startDefault = new Date();
  startDefault.setMinutes(0, 0, 0);
  startDefault.setHours(startDefault.getHours() + 2);
  const endDefault = new Date(startDefault.getTime() + 60 * 60 * 1000);

  const [startsAt, setStartsAt] = useState(toLocalInputValue(startDefault));
  const [endsAt, setEndsAt] = useState(toLocalInputValue(endDefault));
  const [formError, setFormError] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () =>
      api.createSlot({
        startsAt: new Date(startsAt).toISOString(),
        endsAt: new Date(endsAt).toISOString(),
        mode: 'offline',
      }),
    onSuccess: () => {
      setFormError(null);
      qc.invalidateQueries({ queryKey: ['slots'] });
    },
    onError: (e: Error) => setFormError(e.message),
  });

  const remove = useMutation({
    mutationFn: (id: string) => api.deleteSlot(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['slots'] }),
  });

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    create.mutate();
  }

  return (
    <div className="stack">
      <h1>Слоты</h1>
      <form className="card stack" onSubmit={onSubmit}>
        <h2>Новый слот</h2>
        <label>
          Начало
          <input
            className="input"
            type="datetime-local"
            value={startsAt}
            onChange={(e) => setStartsAt(e.target.value)}
            required
          />
        </label>
        <label>
          Конец
          <input
            className="input"
            type="datetime-local"
            value={endsAt}
            onChange={(e) => setEndsAt(e.target.value)}
            required
          />
        </label>
        {formError ? <p className="error">{formError}</p> : null}
        <button className="btn" type="submit" disabled={create.isPending}>
          Создать
        </button>
      </form>

      {isLoading ? <p>Загрузка…</p> : null}
      {error ? <p className="error">{(error as Error).message}</p> : null}
      {(data ?? []).map((slot) => (
        <div key={slot.id} className="card">
          <div>
            {new Date(slot.startsAt).toLocaleString()} —{' '}
            {new Date(slot.endsAt).toLocaleTimeString()}
          </div>
          <div className="muted">
            {slot.status} · {slot.mode}
          </div>
          {slot.status === 'open' ? (
            <button
              type="button"
              className="btnSecondary"
              onClick={() => remove.mutate(slot.id)}
              disabled={remove.isPending}
            >
              Удалить
            </button>
          ) : null}
        </div>
      ))}
    </div>
  );
}
