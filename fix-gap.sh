#!/bin/bash
set -e
cd /var/www/menucard-pro

python3 << 'PYEOF'
c = open('src/components/admin/menu-editor.tsx').read()

old_render = """              {sec.placements.map((pl, i) => (
                <div key={pl.id}>
                  <div draggable
                    onDragStart={e => startDrag(e, pl.productId, sec.id)}
                    onDragEnd={endDrag}
                    onDragOver={e => overItem(e, sec.id, i)}
                    onDrop={dropAtInsert}
                    className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'} ${insertAt?.sid === sec.id && insertAt?.idx === i ? 'border-t-2 border-t-blue-400' : ''} ${insertAt?.sid === sec.id && insertAt?.idx === i + 1 ? 'border-b-2 border-b-blue-400' : ''}`}>"""

new_render = """              {sec.placements.map((pl, i) => (
                <div key={pl.id}>
                  <div
                    onDragOver={e => { e.preventDefault(); e.dataTransfer.dropEffect = 'move'; setInsertAt({ sid: sec.id, idx: i }); }}
                    onDrop={dropAtInsert}
                    className={`transition-all duration-300 ease-in-out overflow-hidden ${insertAt?.sid === sec.id && insertAt?.idx === i ? 'h-12 bg-gradient-to-r from-blue-50 to-blue-100 border-2 border-dashed border-blue-300 rounded-lg mx-3 my-1' : 'h-0'}`}
                  />
                  <div draggable
                    onDragStart={e => startDrag(e, pl.productId, sec.id)}
                    onDragEnd={endDrag}
                    onDragOver={e => overItem(e, sec.id, i)}
                    onDrop={dropAtInsert}
                    className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-200 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'}`}>"""

c = c.replace(old_render, new_render)

old_after = """                </div>
              ))}
              {insertAt?.sid === sec.id && insertAt?.idx === sec.placements.length && (
                <div className="h-8 bg-blue-50 border-2 border-dashed border-blue-300 flex items-center justify-center transition-all">
                  <span className="text-sm text-blue-400 font-medium">\u2193 Hier einf\u00fcgen</span>
                </div>
              )}"""

new_after = """                </div>
              ))}
              <div
                onDragOver={e => { e.preventDefault(); e.dataTransfer.dropEffect = 'move'; setInsertAt({ sid: sec.id, idx: sec.placements.length }); }}
                onDrop={dropAtInsert}
                className={`transition-all duration-300 ease-in-out overflow-hidden ${insertAt?.sid === sec.id && insertAt?.idx === sec.placements.length ? 'h-12 bg-gradient-to-r from-blue-50 to-blue-100 border-2 border-dashed border-blue-300 rounded-lg mx-3 my-1' : 'h-1'}`}
              />"""

c = c.replace(old_after, new_after)

open('src/components/admin/menu-editor.tsx', 'w').write(c)
print('Done!')
PYEOF

npm run build; pm2 restart menucard-pro
echo "=== Done ==="
