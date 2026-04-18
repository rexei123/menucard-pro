// @ts-nocheck
'use client';
import { useState, useCallback } from 'react';
import { Icon } from '@/components/ui/icon';

const TYPE_LABELS = {
  CATEGORY: 'Kategorien',
  REGION: 'Regionen',
  GRAPE: 'Rebsorten',
  STYLE: 'Stil',
  CUISINE: 'Küche',
  DIET: 'Ernährung',
  OCCASION: 'Anlass',
  CUSTOM: 'Sonstige',
};

const TYPE_ICONS = {
  CATEGORY: 'category',
  REGION: 'public',
  GRAPE: 'eco',
  STYLE: 'tune',
  CUISINE: 'restaurant',
  DIET: 'spa',
  OCCASION: 'celebration',
  CUSTOM: 'label',
};

const TYPES = ['CATEGORY', 'REGION', 'GRAPE', 'STYLE', 'CUISINE', 'DIET'];

function getName(node) {
  const de = node.translations?.find((t) => t.language === 'de');
  return de?.name || node.name || '';
}

function countProducts(node) {
  let count = node._count?.products || 0;
  if (node.children) {
    for (const c of node.children) count += countProducts(c);
  }
  return count;
}

// === Tree Node Component ===
function TreeNode({ node, depth = 0, onEdit, onDelete, onAdd, onToggle, expanded, refreshTree }) {
  const isExpanded = expanded.has(node.id);
  const hasChildren = (node.children?.length || 0) > 0 || (node._count?.children || 0) > 0;
  const productCount = node._count?.products || 0;
  const totalProducts = countProducts(node);
  const [editing, setEditing] = useState(false);
  const [editName, setEditName] = useState('');

  const startEdit = () => {
    setEditName(getName(node));
    setEditing(true);
  };

  const saveEdit = async () => {
    if (!editName.trim() || editName === getName(node)) {
      setEditing(false);
      return;
    }
    await onEdit(node.id, editName.trim());
    setEditing(false);
  };

  return (
    <div>
      <div
        className="group flex items-center gap-1 py-1.5 px-2 rounded-lg hover:bg-gray-50 transition-colors"
        style={{ paddingLeft: `${depth * 24 + 8}px` }}
      >
        {/* Expand/Collapse */}
        <button
          onClick={() => hasChildren && onToggle(node.id)}
          className="w-5 h-5 flex items-center justify-center flex-shrink-0"
          style={{ visibility: hasChildren ? 'visible' : 'hidden' }}
        >
          <Icon name={isExpanded ? 'expand_more' : 'chevron_right'} size={18} className="text-gray-400" />
        </button>

        {/* Icon */}
        {node.icon && (
          <Icon name={node.icon} size={18} className="text-gray-400 flex-shrink-0" />
        )}

        {/* Name */}
        {editing ? (
          <input
            autoFocus
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
            onBlur={saveEdit}
            onKeyDown={(e) => { if (e.key === 'Enter') saveEdit(); if (e.key === 'Escape') setEditing(false); }}
            className="flex-1 text-sm border border-gray-300 rounded px-2 py-0.5 outline-none focus:border-pink-400"
            style={{ fontFamily: "'Roboto', sans-serif" }}
          />
        ) : (
          <span
            className={`flex-1 text-sm cursor-default ${depth === 0 ? 'font-semibold text-gray-800' : 'text-gray-700'}`}
            onDoubleClick={startEdit}
          >
            {getName(node)}
          </span>
        )}

        {/* Tax badge */}
        {node.taxLabel && (
          <span className="text-[10px] font-medium px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 border border-amber-200">
            {node.taxLabel}
          </span>
        )}

        {/* Product count */}
        {totalProducts > 0 && (
          <span className="text-[10px] font-medium text-gray-400 tabular-nums">
            {totalProducts} {totalProducts === 1 ? 'Produkt' : 'Produkte'}
          </span>
        )}

        {/* Actions (visible on hover) */}
        <div className="hidden group-hover:flex items-center gap-0.5">
          <button
            onClick={() => onAdd(node)}
            title="Unterknoten hinzufügen"
            className="p-1 rounded hover:bg-green-50 text-gray-400 hover:text-green-600 transition-colors"
          >
            <Icon name="add" size={16} />
          </button>
          <button
            onClick={startEdit}
            title="Bearbeiten"
            className="p-1 rounded hover:bg-blue-50 text-gray-400 hover:text-blue-600 transition-colors"
          >
            <Icon name="edit" size={16} />
          </button>
          <button
            onClick={() => onDelete(node)}
            title="Löschen"
            className="p-1 rounded hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors"
          >
            <Icon name="delete" size={16} />
          </button>
        </div>
      </div>

      {/* Children */}
      {isExpanded && node.children && node.children.length > 0 && (
        <div>
          {node.children.map((child) => (
            <TreeNode
              key={child.id}
              node={child}
              depth={depth + 1}
              onEdit={onEdit}
              onDelete={onDelete}
              onAdd={onAdd}
              onToggle={onToggle}
              expanded={expanded}
              refreshTree={refreshTree}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// === Add Node Dialog ===
function AddDialog({ parentNode, type, onClose, onSave }) {
  const [name, setName] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [icon, setIcon] = useState('');
  const [saving, setSaving] = useState(false);

  const save = async () => {
    if (!name.trim()) return;
    setSaving(true);
    const translations = [{ language: 'de', name: name.trim() }];
    if (nameEn.trim()) translations.push({ language: 'en', name: nameEn.trim() });
    await onSave({ name: name.trim(), type, parentId: parentNode?.id || null, icon: icon || null, translations });
    setSaving(false);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/30 flex items-center justify-center z-50" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <h3 className="text-lg font-semibold text-gray-900 mb-1">
          Neuen Eintrag anlegen
        </h3>
        {parentNode && (
          <p className="text-sm text-gray-500 mb-4">
            Unter: <span className="font-medium">{getName(parentNode)}</span>
          </p>
        )}
        {!parentNode && (
          <p className="text-sm text-gray-500 mb-4">
            Typ: <span className="font-medium">{TYPE_LABELS[type] || type}</span> (Root-Ebene)
          </p>
        )}

        <div className="space-y-3">
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Name (Deutsch) *</label>
            <input
              autoFocus
              value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && save()}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-gray-400"
              placeholder="z.B. Veltliner"
            />
          </div>
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Name (English)</label>
            <input
              value={nameEn}
              onChange={(e) => setNameEn(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-gray-400"
              placeholder="Optional"
            />
          </div>
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Icon (Material Symbol)</label>
            <input
              value={icon}
              onChange={(e) => setIcon(e.target.value)}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-gray-400"
              placeholder="z.B. wine_bar, eco, flag"
            />
            {icon && (
              <div className="mt-1 flex items-center gap-1 text-xs text-gray-400">
                <Icon name={icon} size={16} /> Vorschau
              </div>
            )}
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-5">
          <button
            onClick={onClose}
            className="rounded-lg border px-4 py-2 text-sm font-medium hover:bg-gray-50"
          >
            Abbrechen
          </button>
          <button
            onClick={save}
            disabled={!name.trim() || saving}
            className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50 transition-colors"
            style={{ backgroundColor: '#22C55E' }}
          >
            {saving ? 'Erstelle...' : 'Anlegen'}
          </button>
        </div>
      </div>
    </div>
  );
}

// === Main Component ===
export default function TaxonomyManager({ initialNodes }) {
  const [allNodes, setAllNodes] = useState(initialNodes);
  const [activeType, setActiveType] = useState('CATEGORY');
  const [expanded, setExpanded] = useState(new Set());
  const [addDialog, setAddDialog] = useState(null); // { parentNode, type }
  const [loading, setLoading] = useState(false);

  // Baum aus flacher Liste aufbauen
  const buildTree = useCallback((type) => {
    const typeNodes = allNodes.filter((n) => n.type === type);
    const rootNodes = typeNodes.filter((n) => !n.parentId);
    return rootNodes;
  }, [allNodes]);

  const roots = buildTree(activeType);

  // API-Aktionen
  const refreshTree = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/v1/taxonomy?tree=true', { credentials: 'include' });
      if (res.ok) {
        const data = await res.json();
        setAllNodes(data);
      }
    } catch {}
    setLoading(false);
  };

  const handleEdit = async (nodeId, newName) => {
    try {
      await fetch(`/api/v1/taxonomy/${nodeId}`, {
        method: 'PATCH',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: newName,
          translations: [{ language: 'de', name: newName }],
        }),
      });
      await refreshTree();
    } catch (e) {
      alert('Fehler beim Speichern: ' + e.message);
    }
  };

  const handleDelete = async (node) => {
    const total = countProducts(node);
    if (total > 0) {
      alert(`"${getName(node)}" kann nicht gelöscht werden — ${total} Produkte zugeordnet.`);
      return;
    }
    if ((node._count?.children || 0) > 0 || (node.children?.length || 0) > 0) {
      alert(`"${getName(node)}" kann nicht gelöscht werden — hat noch Untereinträge.`);
      return;
    }
    if (!confirm(`"${getName(node)}" wirklich löschen?`)) return;

    try {
      const res = await fetch(`/api/v1/taxonomy/${node.id}`, {
        method: 'DELETE',
        credentials: 'include',
      });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'Löschen fehlgeschlagen');
        return;
      }
      await refreshTree();
    } catch (e) {
      alert('Fehler: ' + e.message);
    }
  };

  const handleAdd = (parentNode) => {
    setAddDialog({ parentNode, type: parentNode?.type || activeType });
    // Eltern-Node aufklappen
    if (parentNode) {
      setExpanded((prev) => new Set(prev).add(parentNode.id));
    }
  };

  const handleCreate = async (data) => {
    try {
      const res = await fetch('/api/v1/taxonomy', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'Erstellen fehlgeschlagen');
        return;
      }
      await refreshTree();
    } catch (e) {
      alert('Fehler: ' + e.message);
    }
  };

  const toggleExpand = (nodeId) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(nodeId)) next.delete(nodeId);
      else next.add(nodeId);
      return next;
    });
  };

  const expandAll = () => {
    const ids = new Set();
    const collect = (nodes) => {
      for (const n of nodes) {
        if (n.children?.length > 0 || n._count?.children > 0) ids.add(n.id);
        if (n.children) collect(n.children);
      }
    };
    collect(roots);
    setExpanded(ids);
  };

  const collapseAll = () => setExpanded(new Set());

  return (
    <div className="space-y-6 max-w-4xl" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Klassifizierung verwalten</h1>
          <p className="text-sm text-gray-400 mt-0.5">Kategorien, Regionen, Rebsorten und mehr</p>
        </div>
      </div>

      {/* Type Tabs */}
      <div className="flex items-center gap-1 border-b border-gray-200 pb-0">
        {TYPES.map((type) => {
          const active = activeType === type;
          const count = allNodes.filter((n) => n.type === type).length;
          return (
            <button
              key={type}
              onClick={() => setActiveType(type)}
              className={`flex items-center gap-1.5 px-3 py-2 text-sm font-medium border-b-2 transition-colors ${
                active
                  ? 'border-pink-500 text-pink-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
              style={active ? { borderColor: '#DD3C71', color: '#DD3C71' } : {}}
            >
              <Icon name={TYPE_ICONS[type]} size={18} />
              {TYPE_LABELS[type]}
              <span className="text-xs text-gray-400 ml-0.5">({count})</span>
            </button>
          );
        })}
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={expandAll}
            className="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1"
          >
            <Icon name="unfold_more" size={14} /> Alle aufklappen
          </button>
          <button
            onClick={collapseAll}
            className="text-xs text-gray-500 hover:text-gray-700 flex items-center gap-1"
          >
            <Icon name="unfold_less" size={14} /> Alle zuklappen
          </button>
          {loading && <span className="text-xs text-gray-400">Laden...</span>}
        </div>
        <button
          onClick={() => handleAdd(null)}
          className="flex items-center gap-1 text-xs font-medium px-3 py-1.5 rounded-lg text-white"
          style={{ backgroundColor: '#22C55E' }}
        >
          <Icon name="add" size={14} />
          {TYPE_LABELS[activeType]?.replace(/n$/, '') || 'Eintrag'} hinzufügen
        </button>
      </div>

      {/* Tree */}
      <div className="rounded-xl border border-gray-200 bg-white">
        {roots.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <Icon name={TYPE_ICONS[activeType]} size={40} className="mx-auto mb-2 opacity-30" />
            <p className="text-sm">Noch keine {TYPE_LABELS[activeType]} vorhanden</p>
            <button
              onClick={() => handleAdd(null)}
              className="mt-3 text-sm font-medium px-4 py-2 rounded-lg text-white"
              style={{ backgroundColor: '#22C55E' }}
            >
              Ersten Eintrag anlegen
            </button>
          </div>
        ) : (
          <div className="py-2">
            {roots.map((node) => (
              <TreeNode
                key={node.id}
                node={node}
                depth={0}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onAdd={handleAdd}
                onToggle={toggleExpand}
                expanded={expanded}
                refreshTree={refreshTree}
              />
            ))}
          </div>
        )}
      </div>

      {/* Info */}
      <div className="text-xs text-gray-400 flex items-center gap-4">
        <span className="flex items-center gap-1"><Icon name="info" size={14} /> Doppelklick zum Bearbeiten</span>
        <span className="flex items-center gap-1"><Icon name="drag_indicator" size={14} /> Einträge über die Verwaltungs-API verschieben</span>
      </div>

      {/* Add Dialog */}
      {addDialog && (
        <AddDialog
          parentNode={addDialog.parentNode}
          type={addDialog.type}
          onClose={() => setAddDialog(null)}
          onSave={handleCreate}
        />
      )}
    </div>
  );
}
