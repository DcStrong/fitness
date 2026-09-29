'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { FormEvent, useState } from 'react';
import { api } from '../../../lib/api/api';

export default function TagsPage() {
  const qc = useQueryClient();
  const [name, setName] = useState('');
  const [assignTagId, setAssignTagId] = useState('');
  const [studentId, setStudentId] = useState('');
  const [msg, setMsg] = useState<string | null>(null);

  const tags = useQuery({ queryKey: ['tags'], queryFn: () => api.listTags() });
  const rels = useQuery({
    queryKey: ['relationships'],
    queryFn: () => api.relationships(),
  });
  const students = (rels.data ?? []).filter((r) => r.roleForViewer === 'coach');

  const create = useMutation({
    mutationFn: () => api.createTag(name.trim()),
    onSuccess: () => {
      setName('');
      qc.invalidateQueries({ queryKey: ['tags'] });
    },
  });
  const remove = useMutation({
    mutationFn: (id: string) => api.deleteTag(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['tags'] }),
  });
  const assign = useMutation({
    mutationFn: () => api.assignTag(assignTagId, studentId),
    onSuccess: () => setMsg('Тег назначен'),
    onError: (e: Error) => setMsg(e.message),
  });

  function onCreate(e: FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    create.mutate();
  }

  return (
    <div className="stack">
      <h1>Теги</h1>
      <form className="card stack" onSubmit={onCreate}>
        <h2>Новый тег</h2>
        <input
          className="input"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Например: Ноги"
          required
        />
        <button className="btn" type="submit" disabled={create.isPending}>
          Создать
        </button>
      </form>

      <div className="card stack">
        <h2>Назначить ученику</h2>
        <select
          className="select"
          value={assignTagId}
          onChange={(e) => setAssignTagId(e.target.value)}
        >
          <option value="">Тег…</option>
          {(tags.data ?? []).map((t) => (
            <option key={t.id} value={t.id}>
              #{t.name}
            </option>
          ))}
        </select>
        <select
          className="select"
          value={studentId}
          onChange={(e) => setStudentId(e.target.value)}
        >
          <option value="">Ученик…</option>
          {students.map((s) => (
            <option key={s.studentId} value={s.studentId}>
              {s.studentEmail ?? s.studentId}
            </option>
          ))}
        </select>
        <button
          type="button"
          className="btn"
          disabled={!assignTagId || !studentId || assign.isPending}
          onClick={() => assign.mutate()}
        >
          Назначить
        </button>
        {msg ? <p className="muted">{msg}</p> : null}
      </div>

      {tags.isLoading ? <p>Загрузка…</p> : null}
      {(tags.data ?? []).map((t) => (
        <div key={t.id} className="card row">
          <span className="chip">#{t.name}</span>
          <button
            type="button"
            className="btnSecondary"
            onClick={() => remove.mutate(t.id)}
          >
            Удалить
          </button>
        </div>
      ))}
    </div>
  );
}
