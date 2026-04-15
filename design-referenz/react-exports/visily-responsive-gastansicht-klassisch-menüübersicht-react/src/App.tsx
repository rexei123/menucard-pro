import { Icon } from '@iconify/react';

export default function App() {
  const categories = [
    {
      id: 1,
      title: 'Vorspeisen',
      count: 12,
      description: 'Feine Köstlichkeiten zum Auftakt Ihres Menüs.',
      icon: './assets/IMG_6.svg',
      iconColor: 'text-[#DD3C71]',
    },
    {
      id: 2,
      title: 'Hauptgerichte',
      count: 18,
      description: 'Traditionelle Spezialitäten und moderne Kreationen.',
      icon: './assets/IMG_5.svg',
      iconColor: 'text-[#E05252]',
    },
    {
      id: 3,
      title: 'Hausgemachte Pasta',
      count: 8,
      description: 'Täglich frisch zubereitet in unserer Manufaktur.',
      icon: './assets/IMG_8.svg',
      iconColor: 'text-[#171a1f]',
    },
    {
      id: 4,
      title: 'Weinkarte',
      count: 24,
      description: 'Erlesene Tropfen aus den besten Anbauregionen.',
      icon: './assets/IMG_9.svg',
      iconColor: 'text-[#9167E4]',
    },
    {
      id: 5,
      title: 'Desserts',
      count: 6,
      description: 'Süße Versuchungen für den perfekten Abschluss.',
      icon: './assets/IMG_10.svg',
      iconColor: 'text-[#171a1f]',
    },
    {
      id: 6,
      title: 'Kaffee & Digestif',
      count: 10,
      description: 'Röstfrische Kaffeespezialitäten und edle Brände.',
      icon: './assets/IMG_11.svg',
      iconColor: 'text-[#171a1f]',
    },
  ];

  return (
    <div className="min-h-screen bg-[#FDFBF7] flex flex-col font-['Playfair_Display']">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-[#FDFBF7] border-b border-[#dee1e6]/50">
        {/* Status Bar (Mobile Only) */}
        <div className="flex justify-between items-center px-4 h-10 md:hidden">
          <img src="./assets/IMG_1.svg" alt="time" className="h-10 w-[70px]" />
          <img src="./assets/IMG_2.svg" alt="status" className="h-10 w-[96px]" />
        </div>

        {/* Navigation Bar */}
        <div className="flex items-center justify-between px-4 py-4 max-w-7xl mx-auto w-full">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-[#171a1f] rounded-md flex items-center justify-center">
              <img src="./assets/IMG_5.svg" alt="logo" className="w-5.5 h-5.5 invert" />
            </div>
            <h1 className="text-lg font-semibold text-[#171a1f]">GastroMenu</h1>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-black/5 rounded-md transition-colors">
              <Icon icon="lucide:search" className="w-5 h-5 text-[#171a1f]" />
            </button>
            <div className="relative">
              <button className="p-2 hover:bg-black/5 rounded-md transition-colors">
                <Icon icon="lucide:shopping-cart" className="w-5 h-5 text-[#171a1f]" />
              </button>
              <span className="absolute top-1 right-1 w-4 h-4 bg-[#DD3C71] text-white text-[10px] font-bold flex items-center justify-center rounded-full">
                2
              </span>
            </div>
            {/* Desktop Nav */}
            <nav className="hidden md:flex items-center gap-6 ml-8">
              <a href="#" className="text-sm font-medium text-[#565d6d] hover:text-[#E05252]">Start</a>
              <a href="#" className="text-sm font-bold text-[#E05252]">Menü</a>
              <a href="#" className="text-sm font-medium text-[#565d6d] hover:text-[#E05252]">Warenkorb</a>
              <a href="#" className="text-sm font-medium text-[#565d6d] hover:text-[#E05252]">Info</a>
            </nav>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8 md:py-16">
        {/* Hero Section */}
        <div className="flex flex-col items-center text-center mb-12">
          <div className="w-12 h-12 rounded-full border border-[#E05252]/30 flex items-center justify-center mb-6">
            <img src="./assets/IMG_5.svg" alt="utensils" className="w-6 h-6 text-[#E05252]" />
          </div>
          <h2 className="text-2xl md:text-4xl font-bold text-[#171a1f] mb-4">Unsere Speisekarte</h2>
          
          <div className="flex items-center gap-4 mb-6">
            <div className="w-8 h-[1px] bg-[#E05252]/30"></div>
            <span className="text-[10px] tracking-[2px] uppercase font-medium text-[#565d6d]">Seit 1924</span>
            <div className="w-8 h-[1px] bg-[#E05252]/30"></div>
          </div>
          
          <p className="max-w-[280px] md:max-w-md text-sm md:text-base italic text-[#565d6d] leading-relaxed">
            Genießen Sie erlesene Zutaten und meisterhafte Zubereitung in einem Ambiente voller Tradition.
          </p>
        </div>

        {/* Categories Section */}
        <div className="mb-8">
          <h3 className="text-[12px] font-semibold tracking-[1.2px] uppercase text-[#565d6d] mb-6">
            Kategorien
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {categories.map((cat) => (
              <div 
                key={cat.id}
                className="group relative bg-white rounded-[10px] overflow-hidden shadow-[0px_0px_1px_0px_#171a1f0d,0px_0px_2px_0px_#171a1f14] hover:shadow-lg transition-all cursor-pointer flex h-[102px] md:h-[120px]"
              >
                {/* Icon Sidebar */}
                <div className="w-16 md:w-20 bg-[#f3f4f6]/30 flex items-center justify-center relative border-r border-[#dee1e6]/20">
                  <img 
                    src={cat.icon} 
                    alt={cat.title} 
                    className={`w-7 h-7 opacity-80 ${cat.iconColor}`} 
                  />
                </div>

                {/* Content Area */}
                <div className="flex-1 p-4 flex flex-col justify-center relative">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="text-lg font-bold text-[#171a1f] group-hover:text-[#E05252] transition-colors">
                      {cat.title}
                    </h4>
                    <div className="px-3 py-0.5 border border-[#dee1e6]/60 rounded-full">
                      <span className="text-[10px] font-medium text-[#565d6d]">
                        {cat.count} Artikel
                      </span>
                    </div>
                  </div>
                  <p className="text-sm text-[#565d6d] line-clamp-2 pr-8">
                    {cat.description}
                  </p>
                  
                  {/* Chevron */}
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 opacity-40 group-hover:opacity-100 group-hover:translate-x-1 transition-all">
                    <Icon icon="lucide:chevron-right" className="w-5 h-5 text-[#565d6d]" />
                  </div>
                </div>

                {/* Bottom Gradient Border */}
                <div className="absolute bottom-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-[#dee1e6]/40 to-transparent"></div>
              </div>
            ))}
          </div>
        </div>

        {/* Footer Info */}
        <div className="mt-16 mb-24 flex flex-col items-center opacity-40">
          <div className="flex items-center gap-4 w-full max-w-xs mb-4">
            <div className="flex-1 h-[1px] bg-[#171a1f]"></div>
            <div className="w-2 h-2 bg-[#171a1f] rotate-45"></div>
            <div className="flex-1 h-[1px] bg-[#171a1f]"></div>
          </div>
          <span className="text-[10px] uppercase tracking-tight text-[#171a1f]">
            Alle Preise inkl. MwSt. und Bedienung
          </span>
        </div>
      </main>

      {/* Bottom Navigation (Mobile Only) */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-[#FDFBF7] border-t border-[#dee1e6]/40 shadow-[0px_-2px_10px_0px_#00000005] z-50">
        <div className="flex justify-around items-center h-16">
          <a href="#" className="flex flex-col items-center justify-center gap-1 px-4">
            <Icon icon="lucide:house" className="w-6 h-6 text-[#565d6d]" />
            <span className="text-[10px] text-[#565d6d]">Start</span>
          </a>
          <a href="#" className="flex flex-col items-center justify-center gap-1 px-4">
            <Icon icon="lucide:menu" className="w-6 h-6 text-[#E05252]" />
            <span className="text-[10px] font-bold text-[#E05252]">Menü</span>
          </a>
          <a href="#" className="flex flex-col items-center justify-center gap-1 px-4 relative">
            <Icon icon="lucide:shopping-bag" className="w-6 h-6 text-[#565d6d]" />
            <span className="text-[10px] text-[#565d6d]">Warenkorb</span>
            <span className="absolute top-2 right-3 w-4 h-4 bg-[#E05252] text-white text-[8px] font-bold flex items-center justify-center rounded-full ring-2 ring-white">
              9
            </span>
          </a>
          <a href="#" className="flex flex-col items-center justify-center gap-1 px-4">
            <Icon icon="lucide:info" className="w-6 h-6 text-[#565d6d]" />
            <span className="text-[10px] text-[#565d6d]">Info</span>
          </a>
        </div>
      </nav>

      {/* Desktop Footer */}
      <footer className="hidden md:block bg-white border-t border-[#dee1e6]/50 py-12 mt-auto">
        <div className="max-w-7xl mx-auto px-4 grid grid-cols-4 gap-8">
          <div className="col-span-1">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-8 h-8 bg-[#171a1f] rounded-md flex items-center justify-center">
                <img src="./assets/IMG_5.svg" alt="logo" className="w-5.5 h-5.5 invert" />
              </div>
              <h1 className="text-lg font-semibold text-[#171a1f]">GastroMenu</h1>
            </div>
            <p className="text-sm text-[#565d6d] leading-relaxed">
              Traditionelle Gastronomie seit 1924. Qualität und Leidenschaft auf jedem Teller.
            </p>
          </div>
          <div>
            <h5 className="font-bold mb-4">Navigation</h5>
            <ul className="space-y-2 text-sm text-[#565d6d]">
              <li><a href="#" className="hover:text-[#E05252]">Startseite</a></li>
              <li><a href="#" className="hover:text-[#E05252]">Speisekarte</a></li>
              <li><a href="#" className="hover:text-[#E05252]">Reservierung</a></li>
              <li><a href="#" className="hover:text-[#E05252]">Kontakt</a></li>
            </ul>
          </div>
          <div>
            <h5 className="font-bold mb-4">Rechtliches</h5>
            <ul className="space-y-2 text-sm text-[#565d6d]">
              <li><a href="#" className="hover:text-[#E05252]">Impressum</a></li>
              <li><a href="#" className="hover:text-[#E05252]">Datenschutz</a></li>
              <li><a href="#" className="hover:text-[#E05252]">AGB</a></li>
            </ul>
          </div>
          <div>
            <h5 className="font-bold mb-4">Kontakt</h5>
            <p className="text-sm text-[#565d6d]">
              Musterstraße 123<br />
              12345 Musterstadt<br />
              Tel: +49 123 456789
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}