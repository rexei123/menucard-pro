#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Fixing Drag & Drop ==="

python3 << 'PYEOF'
content = open('src/components/admin/menu-editor.tsx').read()

# 1. Replace overSlot with overItem (calculates position from mouse Y)
content = content.replace(
    """const overSlot = (e: React.DragEvent, sid: string, idx: number) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setInsertAt({ sid, idx });
  };""",
    """const overItem = (e: React.DragEvent, sid: string, idx: number) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const insertIdx = e.clientY < rect.top + rect.height / 2 ? idx : idx + 1;
    setInsertAt({ sid, idx: insertIdx });
  };

  const overEmpty = (e: React.DragEvent, sid: string) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setInsertAt({ sid, idx: 0 });
  };"""
)

# 2. Replace dropSlot - use insertAt instead of params
old_drop = "const dropSlot = async (e: React.DragEvent, sid: string, idx: number) => {"
new_drop = "const dropAtInsert = async (e: React.DragEvent) => {"
content = content.replace(old_drop, new_drop)

# Fix the inside - use insertAt for sid/idx
content = content.replace(
    """e.preventDefault();
    const ins = insertAt;
    setInsertAt(null);""",
    """e.preventDefault();
    const ins = insertAt;
    setInsertAt(null);"""
)

# If the old version uses sid/idx directly, replace with ins
if "const { productId, fromSection } = drag;\n    const { sid, idx } = ins;" not in content:
    content = content.replace(
        """const drag = dragRef.current;
    if (!drag) return;
    const { productId, fromSection } = drag;""",
        """const drag = dragRef.current;
    if (!drag || !ins) return;
    const { productId, fromSection } = drag;
    const sid = ins.sid;
    const idx = ins.idx;"""
    )

# 3. Add onDragOver and onDrop to each item
content = content.replace(
    """onDragStart={e => startDrag(e, pl.productId, sec.id)}
                    onDragEnd={endDrag}
                    className=""",
    """onDragStart={e => startDrag(e, pl.productId, sec.id)}
                    onDragEnd={endDrag}
                    onDragOver={e => overItem(e, sec.id, i)}
                    onDrop={dropAtInsert}
                    className="""
)

# 4. Remove old h-0 drop zones before first item
content = content.replace(
    """              {/* Drop before first */}
              <div onDragOver={e => overSlot(e, sec.id, 0)} onDrop={e => dropSlot(e, sec.id, 0)}
                className={`transition-all duration-300 ease-out overflow-hidden ${insertAt?.sid === sec.id && insertAt?.idx === 0 ? 'h-10 bg-blue-50 border-b-2 border-dashed border-blue-300 flex items-center justify-center' : 'h-0'}`}>
                {insertAt?.sid === sec.id && insertAt?.idx === 0 && <span className="text-sm text-blue-400 font-medium">↓ Hier einfügen</span>}
              </div>

              {sec.placements.map""",
    """              {sec.placements.map"""
)

# 5. Remove old h-0 drop zones after each item
content = content.replace(
    """                  {/* Drop after item */}
                  <div onDragOver={e => overSlot(e, sec.id, i + 1)} onDrop={e => dropSlot(e, sec.id, i + 1)}
                    className={`transition-all duration-300 ease-out overflow-hidden ${insertAt?.sid === sec.id && insertAt?.idx === i + 1 ? 'h-10 bg-blue-50 border-y-2 border-dashed border-blue-300 flex items-center justify-center' : 'h-0'}`}>
                    {insertAt?.sid === sec.id && insertAt?.idx === i + 1 && <span className="text-sm text-blue-400 font-medium">↓ Hier einfügen</span>}
                  </div>""",
    ""
)

# 6. Add visual insert indicator via border
content = content.replace(
    """onDrop={dropAtInsert}
                    className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'}`}>""",
    """onDrop={dropAtInsert}
                    className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'} ${insertAt?.sid === sec.id && insertAt?.idx === i ? 'border-t-2 border-t-blue-400' : ''} ${insertAt?.sid === sec.id && insertAt?.idx === i + 1 ? 'border-b-2 border-b-blue-400' : ''}`}>"""
)

# 7. Fix empty section drop
content = content.replace(
    """onDragOver={e => overSlot(e, sec.id, 0)} onDrop={e => dropSlot(e, sec.id, 0)}""",
    """onDragOver={e => overEmpty(e, sec.id)} onDrop={dropAtInsert}"""
)

# 8. Also make the section header a drop target
content = content.replace(
    """<div className="border-b bg-gray-50/50 px-4 py-3">
                <h2 className="text-base font-semibold">""",
    """<div className="border-b bg-gray-50/50 px-4 py-3" onDragOver={e => overEmpty(e, sec.id)} onDrop={dropAtInsert}>
                <h2 className="text-base font-semibold">"""
)

open('src/components/admin/menu-editor.tsx', 'w').write(content)
print('Done!')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Done ==="
