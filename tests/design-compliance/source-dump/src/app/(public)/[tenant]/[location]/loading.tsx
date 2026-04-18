export default function LocationLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-6 py-6 text-center">
        <div className="skeleton mx-auto h-3 w-24 mb-3" />
        <div className="skeleton mx-auto h-7 w-36" />
      </header>
      <main className="mx-auto max-w-lg px-4 py-6 space-y-3">
        {[1,2,3,4].map(i => (
          <div key={i} className="flex items-center gap-4 rounded-2xl border bg-white p-5">
            <div className="skeleton h-10 w-10 rounded-full" />
            <div className="flex-1">
              <div className="skeleton h-5 w-32 mb-2" />
              <div className="skeleton h-3 w-48" />
            </div>
          </div>
        ))}
      </main>
    </div>
  );
}
