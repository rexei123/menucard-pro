'use client';

import { useEffect, useState } from 'react';

type User = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  name: string | null;
  role: 'OWNER' | 'ADMIN' | 'MANAGER' | 'EDITOR';
  isActive: boolean;
  lastLoginAt: string | null;
  createdAt: string;
  updatedAt: string;
};

type Props = {
  currentUserId: string;
  currentUserRole: string;
};

const ROLE_LABELS: Record<string, string> = {
  OWNER: 'Inhaber',
  ADMIN: 'Administrator',
  MANAGER: 'Manager',
  EDITOR: 'Redakteur',
};

const ROLE_COLORS: Record<string, { bg: string; fg: string }> = {
  OWNER: { bg: '#FDF2F5', fg: '#DD3C71' },
  ADMIN: { bg: '#DBEAFE', fg: '#2563EB' },
  MANAGER: { bg: '#ECFDF5', fg: '#22C55E' },
  EDITOR: { bg: '#F3F4F6', fg: '#565D6D' },
};

function formatDate(str: string | null): string {
  if (!str) return '—';
  try {
    return new Date(str).toLocaleDateString('de-AT', { day: '2-digit', month: '2-digit', year: 'numeric' });
  } catch { return str; }
}

export default function UsersAdmin({ currentUserId, currentUserRole }: Props) {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  const [form, setForm] = useState({
    email: '', firstName: '', lastName: '', password: '', role: 'EDITOR' as User['role'],
  });
  const [editForm, setEditForm] = useState({
    firstName: '', lastName: '', role: 'EDITOR' as User['role'], isActive: true, password: '',
  });
  const [busy, setBusy] = useState(false);

  const canManage = currentUserRole === 'OWNER' || currentUserRole === 'ADMIN';

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/v1/users');
      if (!res.ok) throw new Error(await res.text());
      setUsers(await res.json());
      setError(null);
    } catch (e: any) {
      setError(e.message || 'Fehler beim Laden');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async () => {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch('/api/v1/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Fehler' }));
        throw new Error(err.error || 'Fehler beim Anlegen');
      }
      setShowCreate(false);
      setForm({ email: '', firstName: '', lastName: '', password: '', role: 'EDITOR' });
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  const startEdit = (u: User) => {
    setEditingId(u.id);
    setEditForm({
      firstName: u.firstName,
      lastName: u.lastName,
      role: u.role,
      isActive: u.isActive,
      password: '',
    });
  };

  const handleSaveEdit = async () => {
    if (!editingId) return;
    setBusy(true);
    setError(null);
    try {
      const payload: any = {
        firstName: editForm.firstName,
        lastName: editForm.lastName,
        role: editForm.role,
        isActive: editForm.isActive,
      };
      if (editForm.password) payload.password = editForm.password;
      const res = await fetch(`/api/v1/users/${editingId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Fehler' }));
        throw new Error(err.error || 'Fehler beim Speichern');
      }
      setEditingId(null);
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Benutzer "${name}" wirklich loeschen?`)) return;
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/v1/users/${id}`, { method: 'DELETE' });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Fehler' }));
        throw new Error(err.error || 'Fehler beim Loeschen');
      }
      await load();
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return <div className="rounded-xl border bg-gray-50 px-6 py-12 text-center text-gray-400">Lade Benutzer…</div>;
  }

  return (
    <div className="space-y-4" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* Top-Bar */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-gray-500">{users.length} {users.length === 1 ? 'Benutzer' : 'Benutzer'}</div>
        {canManage && (
          <button
            onClick={() => { setShowCreate(true); setError(null); }}
            className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-white transition-colors"
            style={{ backgroundColor: '#22C55E' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>person_add</span>
            Neuer Benutzer
          </button>
        )}
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Create-Modal */}
      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={() => setShowCreate(false)}>
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl" onClick={e => e.stopPropagation()}>
            <h2 className="mb-4 text-lg font-bold">Neuer Benutzer</h2>
            <div className="space-y-3">
              <Field label="E-Mail" type="email" value={form.email} onChange={v => setForm({ ...form, email: v })} />
              <div className="grid grid-cols-2 gap-3">
                <Field label="Vorname" value={form.firstName} onChange={v => setForm({ ...form, firstName: v })} />
                <Field label="Nachname" value={form.lastName} onChange={v => setForm({ ...form, lastName: v })} />
              </div>
              <Field label="Passwort (min. 8 Zeichen)" type="password" value={form.password} onChange={v => setForm({ ...form, password: v })} />
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Rolle</label>
                <select
                  value={form.role}
                  onChange={e => setForm({ ...form, role: e.target.value as User['role'] })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
                >
                  <option value="EDITOR">Redakteur</option>
                  <option value="MANAGER">Manager</option>
                  <option value="ADMIN">Administrator</option>
                  {currentUserRole === 'OWNER' && <option value="OWNER">Inhaber</option>}
                </select>
              </div>
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={() => setShowCreate(false)}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Abbrechen
              </button>
              <button
                onClick={handleCreate}
                disabled={busy || !form.email || !form.firstName || !form.lastName || form.password.length < 8}
                className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
                style={{ backgroundColor: '#22C55E' }}
              >
                {busy ? 'Lege an…' : 'Anlegen'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Benutzer-Tabelle */}
      <div className="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase tracking-wide text-gray-500">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">E-Mail</th>
              <th className="px-4 py-3">Rolle</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Letzter Login</th>
              <th className="px-4 py-3 text-right">Aktionen</th>
            </tr>
          </thead>
          <tbody>
            {users.map(u => {
              const isSelf = u.id === currentUserId;
              const roleStyle = ROLE_COLORS[u.role] || ROLE_COLORS.EDITOR;
              return (
                <tr key={u.id} className="border-t border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="font-medium text-gray-900">
                      {u.firstName} {u.lastName}
                      {isSelf && <span className="ml-2 rounded bg-pink-50 px-1.5 py-0.5 text-xs font-normal text-pink-600">Sie</span>}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{u.email}</td>
                  <td className="px-4 py-3">
                    <span
                      className="rounded-full px-2 py-0.5 text-xs font-medium"
                      style={{ backgroundColor: roleStyle.bg, color: roleStyle.fg }}
                    >
                      {ROLE_LABELS[u.role] || u.role}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    {u.isActive
                      ? <span className="inline-flex items-center gap-1 text-xs font-medium text-green-600">
                          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>check_circle</span>
                          Aktiv
                        </span>
                      : <span className="inline-flex items-center gap-1 text-xs font-medium text-gray-400">
                          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>pause_circle</span>
                          Inaktiv
                        </span>
                    }
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">{formatDate(u.lastLoginAt)}</td>
                  <td className="px-4 py-3 text-right">
                    {canManage && (
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => startEdit(u)}
                          className="inline-flex items-center gap-1 rounded-md border border-gray-200 px-2 py-1 text-xs text-gray-700 hover:bg-gray-100"
                        >
                          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>edit</span>
                          Bearbeiten
                        </button>
                        {!isSelf && (
                          <button
                            onClick={() => handleDelete(u.id, `${u.firstName} ${u.lastName}`)}
                            className="inline-flex items-center gap-1 rounded-md border border-red-200 px-2 py-1 text-xs text-red-600 hover:bg-red-50"
                          >
                            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>delete</span>
                            Loeschen
                          </button>
                        )}
                      </div>
                    )}
                  </td>
                </tr>
              );
            })}
            {users.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-12 text-center text-gray-400">
                  Keine Benutzer vorhanden.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Edit-Modal */}
      {editingId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={() => setEditingId(null)}>
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl" onClick={e => e.stopPropagation()}>
            <h2 className="mb-4 text-lg font-bold">Benutzer bearbeiten</h2>
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <Field label="Vorname" value={editForm.firstName} onChange={v => setEditForm({ ...editForm, firstName: v })} />
                <Field label="Nachname" value={editForm.lastName} onChange={v => setEditForm({ ...editForm, lastName: v })} />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Rolle</label>
                <select
                  value={editForm.role}
                  onChange={e => setEditForm({ ...editForm, role: e.target.value as User['role'] })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
                >
                  <option value="EDITOR">Redakteur</option>
                  <option value="MANAGER">Manager</option>
                  <option value="ADMIN">Administrator</option>
                  {currentUserRole === 'OWNER' && <option value="OWNER">Inhaber</option>}
                </select>
              </div>
              <div className="flex items-center gap-2">
                <input
                  id="isActive"
                  type="checkbox"
                  checked={editForm.isActive}
                  disabled={editingId === currentUserId}
                  onChange={e => setEditForm({ ...editForm, isActive: e.target.checked })}
                  className="h-4 w-4 rounded border-gray-300"
                />
                <label htmlFor="isActive" className="text-sm text-gray-700">Aktiv</label>
              </div>
              <Field
                label="Neues Passwort (optional, min. 8 Zeichen)"
                type="password"
                value={editForm.password}
                onChange={v => setEditForm({ ...editForm, password: v })}
              />
            </div>
            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={() => setEditingId(null)}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Abbrechen
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={busy}
                className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
                style={{ backgroundColor: '#2563EB' }}
              >
                {busy ? 'Speichere…' : 'Speichern'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function Field({ label, value, onChange, type = 'text' }: { label: string; value: string; onChange: (v: string) => void; type?: string }) {
  return (
    <div>
      <label className="mb-1 block text-xs font-medium text-gray-600">{label}</label>
      <input
        type={type}
        value={value}
        onChange={e => onChange(e.target.value)}
        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
      />
    </div>
  );
}
