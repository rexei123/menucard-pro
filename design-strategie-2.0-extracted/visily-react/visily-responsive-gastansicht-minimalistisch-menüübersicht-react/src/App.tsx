import { Icon } from '@iconify/react';

export default function App() {
  const categories = [
    {
      title: 'VORSPEISEN',
      count: 12,
      description: 'Leichte Kreationen für den perfekten Start.',
    },
    {
      title: 'HAUPTSPEISEN',
      count: 24,
      description: 'Herzhafte Klassiker und moderne Kompositionen.',
    },
    {
      title: 'DESSERTS',
      count: 8,
      description: 'Süße Vollendung aus unserer Patisserie.',
    },
    {
      title: 'ALKOHOLFREI',
      count: 15,
      description: 'Erfrischende hausgemachte Limonaden und Säfte.',
    },
    {
      title: 'WEIN & BIER',
      count: 30,
      description: 'Handverlesene Tropfen und lokale Braukunst.',
    },
  ];

  const tags = ['Vegan', 'Bio', 'Saisonal', 'Regional', 'Alkoholfrei'];

  return (
    <div className="min-h-screen bg-white flex flex-col font-sans text-[#171a1f]">
      {/* Status Bar (Mobile Only) */}
      <div className="flex justify-between items-center px-6 py-2 md:hidden">
        <img src="./assets/IMG_1.svg" alt="time" className="h-10 w-[70px]" />
        <img src="./assets/IMG_2.svg" alt="status" className="h-10 w-[96px]" />
      </div>

      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-[#dee1e6] px-4 py-4 md:px-8 lg:px-12">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-[#171a1f] p-1.5 rounded-md">
              <img src="./assets/IMG_5.svg" alt="logo" className="w-5 h-5 invert" />
            </div>
            <h1 className="text-lg font-bold tracking-tight font-serif-display">MENÜ</h1>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-100 rounded-md transition-colors">
              <Icon icon="lucide:search" className="w-5 h-5" />
            </button>
            <div className="relative">
              <button className="p-2 hover:bg-gray-100 rounded-md transition-colors">
                <Icon icon="lucide:shopping-cart" className="w-5 h-5" />
              </button>
              <span className="absolute -top-1 -right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">
                2
              </span>
            </div>
            {/* Desktop Navigation */}
            <nav className="hidden md:flex items-center gap-6 ml-8">
              <a href="#" className="text-sm font-semibold text-[#565d6d] hover:text-[#171a1f]">Home</a>
              <a href="#" className="text-sm font-bold border-b-2 border-[#171a1f]">Menü</a>
              <a href="#" className="text-sm font-semibold text-[#565d6d] hover:text-[#171a1f]">Info</a>
            </nav>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full pb-24 md:pb-12">
        {/* Horizontal Tags */}
        <div className="border-b border-[#dee1e6]/20 overflow-x-auto no-scrollbar py-4 px-4 md:px-8">
          <div className="flex gap-3 min-w-max">
            {tags.map((tag) => (
              <button
                key={tag}
                className="px-5 py-1.5 border border-[#171a1f]/10 text-[11px] font-bold font-serif-display hover:bg-gray-50 transition-colors"
              >
                {tag}
              </button>
            ))}
          </div>
        </div>

        <div className="px-6 py-10 md:px-12 lg:px-20">
          {/* Hero Section */}
          <div className="mb-12">
            <span className="text-[10px] font-bold tracking-[3px] text-[#565d6d] uppercase block mb-4">
              Unsere Auswahl
            </span>
            <h2 className="text-[36px] leading-[0.9] font-black mb-6 tracking-[-1.8px]">
              DIGITALES<br />SPEISEN
            </h2>
            <p className="text-[#565d6d] text-sm max-w-xs leading-relaxed">
              Wählen Sie eine Kategorie aus, um unsere minimalistisch kuratierten Gerichte zu entdecken.
            </p>
          </div>

          {/* Categories Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-x-12">
            {categories.map((cat, idx) => (
              <div
                key={idx}
                className="group relative py-10 border-b border-[#dee1e6]/40 flex justify-between items-center cursor-pointer hover:bg-gray-50/50 transition-colors px-2"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-2xl font-bold tracking-tighter font-serif-display">
                      {cat.title}
                    </h3>
                    <span className="bg-[#f3f4f6] text-[#565d6d] text-[10px] font-medium px-1.5 py-0.5 rounded tracking-widest">
                      {cat.count}
                    </span>
                  </div>
                  <p className="text-[#565d6d] text-sm leading-snug max-w-[260px]">
                    {cat.description}
                  </p>
                </div>
                <div className="w-10 h-10 rounded-full border border-[#dee1e6] flex items-center justify-center group-hover:bg-[#171a1f] group-hover:text-white transition-all">
                  <Icon icon="lucide:arrow-right" className="w-5 h-5" />
                </div>
              </div>
            ))}
          </div>

          {/* Weekly Special Card */}
          <div className="mt-12 bg-[#171a1f] p-8 md:p-12 relative overflow-hidden group cursor-pointer">
            <div className="relative z-10 flex flex-col h-full justify-between">
              <div className="flex justify-between items-start mb-12">
                <h3 className="text-white text-3xl font-black italic leading-none tracking-tighter">
                  WOCHEN<br />KARTE
                </h3>
                <span className="bg-white text-[#171a1f] text-[9px] font-bold px-2 py-0.5">
                  HOT
                </span>
              </div>
              
              <div className="flex items-center gap-2 text-white/80 group-hover:text-white transition-colors">
                <span className="text-xs font-bold tracking-[1.2px] uppercase">Jetzt entdecken</span>
                <Icon icon="lucide:chevron-right" className="w-4 h-4" />
              </div>
            </div>
            {/* Decorative background element */}
            <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 -mr-16 -mt-16 rounded-full blur-3xl group-hover:bg-white/10 transition-all"></div>
          </div>

          {/* Footer Info */}
          <div className="mt-20 flex flex-col items-center">
            <div className="w-12 h-[1px] bg-[#dee1e6] mb-4"></div>
            <span className="text-version text-center">GastroMenu Minimal v1.0</span>
          </div>
        </div>
      </main>

      {/* Bottom Navigation (Mobile Only) */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-[#dee1e6] shadow-[0px_-2px_10px_0px_rgba(0,0,0,0.05)] flex justify-around items-center h-16 px-2">
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <Icon icon="lucide:list" className="w-6 h-6" />
          <span className="text-[10px]">Home</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#171a1f] font-bold">
          <Icon icon="lucide:utensils-crossed" className="w-6 h-6" />
          <span className="text-[10px]">Menü</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d] relative">
          <Icon icon="lucide:shopping-cart" className="w-6 h-6" />
          <span className="text-[10px]">Korb</span>
          <span className="absolute top-0 right-0 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            9
          </span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <Icon icon="lucide:info" className="w-6 h-6" />
          <span className="text-[10px]">Info</span>
        </a>
      </nav>
    </div>
  );
}