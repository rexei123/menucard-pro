export default function ItemLoading() {
  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-4 py-4">
        <div className="skeleton h-4 w-32 mb-1" />
        <div className="skeleton h-3 w-20" />
      </header>
      <main className="mx-auto max-w-2xl px-4 py-6">
        <div className="skeleton h-8 w-3/4 mb-2" />
        <div className="skeleton h-4 w-1/2 mb-6" />
        <div className="rounded-xl border bg-white p-5 mb-6">
          <div className="skeleton h-4 w-full mb-2" />
          <div className="skeleton h-4 w-5/6 mb-2" />
          <div className="skeleton h-4 w-2/3" />
        </div>
        <div className="rounded-xl border bg-white p-5 mb-6">
          <div className="skeleton h-4 w-16 mb-4" />
          <div className="flex justify-between">
            <div className="skeleton h-4 w-20" />
            <div className="skeleton h-5 w-16" />
          </div>
        </div>
        <div className="rounded-xl border bg-white p-5">
          <div className="skeleton h-4 w-24 mb-4" />
          <div className="grid grid-cols-2 gap-3">
            {[1,2,3,4,5,6].map(i => (
              <div key={i}>
                <div className="skeleton h-2 w-16 mb-1" />
                <div className="skeleton h-4 w-24" />
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}
