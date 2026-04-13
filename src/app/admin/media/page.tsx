import MediaArchive from '@/components/admin/media-archive';

export const metadata = { title: 'Bildarchiv – MenuCard Pro' };

export default function MediaPage() {
  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1
            className="text-2xl font-bold mb-1"
            style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
          >
            Bildarchiv
          </h1>
          <p className="text-sm" style={{ color: '#565D6D' }}>
            Verwalten Sie Bilder, Logos und Medien für Ihre Speisekarten
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span
            className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
            style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>photo_library</span>
            Medien
          </span>
        </div>
      </div>
      <MediaArchive />
    </div>
  );
}
