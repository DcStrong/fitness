'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { FormEvent, useState } from 'react';
import { api } from '../../../lib/api/api';

export default function PlansPage() {
  const qc = useQueryClient();
  const plans = useQuery({ queryKey: ['plans'], queryFn: () => api.listPlans() });
  const tags = useQuery({ queryKey: ['tags'], queryFn: () => api.listTags() });

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [selected, setSelected] = useState<string[]>([]);
  const [editId, setEditId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const save = useMutation({
    mutationFn: async () => {
      if (editId) {
        return api.updatePlan(editId, {
          title: title.trim(),
          body,
          tagIds: selected,
        });
      }
      return api.createPlan({
        title: title.trim(),
        body,
        tagIds: selected,
      });
    },
    onSuccess: () => {
      setTitle('');
      setBody('');
      setSelected([]);
      setEditId(null);
      setError(null);
      qc.invalidateQueries({ queryKey: ['plans'] });
    },
    onError: (e: Error) => setError(e.message),
  });

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;
    save.mutate();
  }

  function startEdit(id: string) {
    const plan = (plans.data ?? []).find((p) => p.id === id);
    if (!plan) return;
    setEditId(plan.id);
    setTitle(plan.title);
    setBody(plan.body);
    setSelected(plan.tags.map((t) => t.id));
  }

  return (
    <div className="stack">
      <h1>Планы</h1>
      <form className="card stack" onSubmit={onSubmit}>
        <h2>{editId ? 'Редактировать план' : 'Новый план'}</h2>
        <input
          className="input"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Название"
          required
        />
        <textarea
          className="textarea"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Содержание"
        />
        <div className="row">
          {(tags.data ?? []).map((t) => {
            const on = selected.includes(t.id);
            return (
              <button
                key={t.id}
                type="button"
                className={on ? 'btn' : 'btnSecondary'}
                onClick={() =>
                  setSelected((prev) =>
                    on ? prev.filter((x) => x !== t.id) : [...prev, t.id],
                  )
                }
              >
                #{t.name}
              </button>
            );
          })}
        </div>
        {error ? <p className="error">{error}</p> : null}
        <div className="row">
          <button className="btn" type="submit" disabled={save.isPending}>
            Сохранить
          </button>
          {editId ? (
            <button
              type="button"
              className="btnSecondary"
              onClick={() => {
                setEditId(null);
                setTitle('');
                setBody('');
                setSelected([]);
              }}
            >
              Отмена
            </button>
          ) : null}
        </div>
      </form>

      {plans.isLoading ? <p>Загрузка…</p> : null}
      {(plans.data ?? []).map((p) => (
        <div key={p.id} className="card stack">
          <strong>{p.title}</strong>
          <div className="muted">
            {p.tags.map((t) => `#${t.name}`).join(' · ') || 'без тегов'}
          </div>
          <pre style={{ whiteSpace: 'pre-wrap', margin: 0, font: 'inherit' }}>
            {p.body || '—'}
          </pre>
          <button
            type="button"
            className="btnSecondary"
            onClick={() => startEdit(p.id)}
          >
            Редактировать
          </button>
        </div>
      ))}
    </div>
  );
}
