export default function MenuLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      {/* Header skeleton */}
      <header className="border-b px-6 py-6 text-center">
        <div className="skeleton mx-auto h-3 w-24 mb-3" />
        <div className="skeleton mx-auto h-8 w-48" />
      </header>

      {/* Search bar skeleton */}
      <div className="border-b bg-white/95 px-4 py-3">
        <div className="mx-auto max-w-2xl">
          <div className="skeleton h-10 w-full rounded-full" />
        </div>
      </div>

      {/* Section nav skeleton */}
      <div className="border-b px-4 py-2">
        <div className="flex gap-2 overflow-hidden">
          {[1,2,3,4,5].map(i => (
            <div key={i} className="skeleton h-8 w-24 flex-shrink-0 rounded-full" />
          ))}
        </div>
      </div>

      {/* Content skeleton */}
      <main className="mx-auto max-w-2xl px-4 py-8">
        <div className="mb-6 text-center">
          <div className="skeleton mx-auto h-6 w-40 mb-3" />
          <div className="skeleton mx-auto h-px w-16" />
        </div>
        <div className="space-y-3">
          {[1,2,3,4,5,6].map(i => (
            <div key={i} className="rounded-xl border bg-white p-4 shadow-sm">
              <div className="skeleton h-5 w-3/4 mb-2" />
              <div className="skeleton h-3 w-1/2 mb-3" />
              <div className="skeleton h-4 w-16" />
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
