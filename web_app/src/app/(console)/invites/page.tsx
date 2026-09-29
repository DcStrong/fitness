'use client';

import { useMutation } from '@tanstack/react-query';
import { useState } from 'react';
import { api } from '../../../lib/api/api';
import type { InvitationCreated } from '../../../lib/api/types';

export default function InvitesPage() {
  const [invite, setInvite] = useState<InvitationCreated | null>(null);
  const [error, setError] = useState<string | null>(null);

  const create = useMutation({
    mutationFn: () => api.createInvitation(),
    onSuccess: (data) => {
      setInvite(data);
      setError(null);
    },
    onError: (e: Error) => setError(e.message),
  });

  return (
    <div className="stack">
      <h1>Приглашения</h1>
      <p className="muted">
        Создайте ссылку для ученика (QR удобнее в мобильном приложении).
      </p>
      <button
        type="button"
        className="btn"
        disabled={create.isPending}
        onClick={() => create.mutate()}
      >
        Создать приглашение
      </button>
      {error ? <p className="error">{error}</p> : null}
      {invite ? (
        <div className="card stack">
          <div>
            <strong>Ссылка</strong>
            <div className="muted">{invite.inviteUrl}</div>
          </div>
          <div>
            <strong>Deep link</strong>
            <div className="muted">{invite.deepLink}</div>
          </div>
          <div className="muted">
            Истекает: {new Date(invite.expiresAt).toLocaleString()}
          </div>
        </div>
      ) : null}
    </div>
  );
}
