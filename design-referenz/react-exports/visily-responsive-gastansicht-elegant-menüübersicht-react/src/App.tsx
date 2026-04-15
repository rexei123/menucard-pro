import { Icon } from '@iconify/react';

export default function App() {
  const menuCategories = [
    {
      id: '01',
      title: 'LES ENTRÉES',
      count: '8 AUSWAHLEN',
      description: 'Feine Vorspeisen, die den Gaumen auf eine Reise vorbereiten.',
      image: './assets/IMG_6.jpeg',
    },
    {
      id: '02',
      title: 'PLATS PRINCIPAUX',
      count: '12 AUSWAHLEN',
      description: 'Meisterhafte Hauptgänge aus regionalen Zutaten höchster Güte.',
      image: './assets/IMG_8.jpeg',
    },
    {
      id: '03',
      title: 'DESSERTS D\'ART',
      count: '6 AUSWAHLEN',
      description: 'Süße Vollendung, inspiriert von klassischer Patisserie.',
      image: './assets/IMG_9.jpeg',
    },
    {
      id: '04',
      title: 'LA CAVE',
      count: '24 AUSWAHLEN',
      description: 'Eine kuratierte Auswahl edler Tropfen aus den besten Lagen.',
      image: './assets/IMG_10.jpeg',
    },
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col font-serif">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-sm border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-[#171a1f] rounded flex items-center justify-center">
              <img src="./assets/IMG_5.svg" alt="Logo" className="w-5 h-5 invert" />
            </div>
            <h1 className="text-lg font-semibold tracking-[0.15em] text-[#171a1f]">LA CARTE</h1>
          </div>
          
          <div className="flex items-center gap-1">
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <Icon icon="lucide:search" className="w-5 h-5 text-[#171a1f]" />
            </button>
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors relative">
              <Icon icon="lucide:shopping-cart" className="w-5 h-5 text-[#171a1f]" />
              <span className="absolute top-1 right-1 w-4 h-4 bg-[#DD3C71] text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                2
              </span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-7xl mx-auto w-full px-6 py-10 md:py-16">
        {/* Hero Section */}
        <section className="text-center mb-16 md:mb-24">
          <div className="inline-block px-6 py-1 border border-[#171a1f] rounded-full mb-8">
            <span className="text-[10px] uppercase tracking-widest text-[#171a1f]">Gourmet Erlebnis</span>
          </div>
          <h2 className="text-3xl md:text-5xl font-light tracking-[0.2em] text-[#171a1f] mb-6">
            UNSERE WELT
          </h2>
          <p className="max-w-md mx-auto text-[#565d6d] font-serif-italic text-sm md:text-base leading-relaxed">
            "Qualität ist kein Zufall, sie ist immer das Ergebnis angestrengten Denkens."
          </p>
        </section>

        {/* Menu Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-16">
          {menuCategories.map((category) => (
            <article key={category.id} className="group cursor-pointer">
              <div className="flex justify-between items-end mb-4">
                <span className="category-number text-[#171a1f]">{category.id}</span>
                <span className="selection-count">{category.count}</span>
              </div>
              
              <div className="relative aspect-[21/9] overflow-hidden rounded-sm mb-6">
                <img 
                  src={category.image} 
                  alt={category.title}
                  className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-black/5 group-hover:bg-transparent transition-colors" />
              </div>

              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <h3 className="text-xl font-light tracking-[0.2em] text-[#171a1f] mb-2 group-hover:text-gold transition-colors">
                    {category.title}
                  </h3>
                  <p className="text-sm text-[#565d6d] leading-relaxed max-w-xs">
                    {category.description}
                  </p>
                </div>
                <Icon 
                  icon="lucide:chevron-right" 
                  className="w-5 h-5 text-[#171a1f] mt-1 group-hover:translate-x-1 transition-transform" 
                />
              </div>
              
              <div className="mt-8 border-b border-gray-100 md:hidden" />
            </article>
          ))}
        </div>

        {/* Footer Signature */}
        <section className="mt-24 mb-12 text-center">
          <div className="flex items-center justify-center gap-4 mb-6 opacity-30">
            <div className="h-[1px] w-12 bg-[#171a1f]" />
            <img src="./assets/IMG_5.svg" alt="Utensils" className="w-4 h-4" />
            <div className="h-[1px] w-12 bg-[#171a1f]" />
          </div>
          
          <span className="block text-[10px] tracking-[0.4em] uppercase text-[#565d6d] mb-8">
            Bon Appétit
          </span>

          <div className="flex items-center justify-center gap-4">
            <div className="w-10 h-10 rounded-full overflow-hidden border border-gray-100">
              <img src="./assets/IMG_11.jpeg" alt="Chef Marc-Antoine" className="w-full h-full object-cover" />
            </div>
            <div className="text-left">
              <p className="text-xs font-medium tracking-wider text-[#171a1f]">Marc-Antoine</p>
              <p className="text-[10px] text-[#565d6d]">Chef de Cuisine</p>
            </div>
          </div>
        </section>
      </main>

      {/* Bottom Navigation (Mobile Only) */}
      <nav className="md:hidden sticky bottom-0 bg-white border-t border-gray-100 nav-shadow px-2 py-1 flex justify-around items-center z-50">
        <a href="#" className="flex flex-col items-center p-2 gap-1">
          <img src="./assets/IMG_12.svg" alt="Home" className="w-6 h-6 opacity-60" />
          <span className="text-[10px] text-[#565d6d]">Willkommen</span>
        </a>
        <a href="#" className="flex flex-col items-center p-2 gap-1">
          <img src="./assets/IMG_5.svg" alt="Menu" className="w-6 h-6" />
          <span className="text-[10px] font-bold text-[#171a1f]">Menü</span>
        </a>
        <a href="#" className="flex flex-col items-center p-2 gap-1 relative">
          <img src="./assets/IMG_13.svg" alt="Cart" className="w-6 h-6 opacity-60" />
          <span className="text-[10px] text-[#565d6d]">Warenkorb</span>
          <span className="absolute top-1 right-3 w-4 h-4 bg-[#E05252] text-white text-[8px] font-bold rounded-full flex items-center justify-center ring-2 ring-white">
            9
          </span>
        </a>
        <a href="#" className="flex flex-col items-center p-2 gap-1">
          <img src="./assets/IMG_14.svg" alt="Info" className="w-6 h-6 opacity-60" />
          <span className="text-[10px] text-[#565d6d]">Info</span>
        </a>
      </nav>

      {/* Desktop Sidebar / Navigation Enhancement (Hidden on Mobile) */}
      <div className="hidden md:block fixed left-0 top-0 h-full w-20 bg-white border-r border-gray-100 z-40">
        <div className="flex flex-col items-center py-24 gap-12">
          <div className="rotate-90 whitespace-nowrap text-[10px] tracking-[0.5em] uppercase text-gray-400 origin-center">
            Established 1984
          </div>
          <div className="flex flex-col gap-8 mt-auto mb-12">
            <Icon icon="ri:instagram-line" className="w-5 h-5 text-gray-400 hover:text-gold cursor-pointer" />
            <Icon icon="ri:facebook-fill" className="w-5 h-5 text-gray-400 hover:text-gold cursor-pointer" />
          </div>
        </div>
      </div>

      <style>{`
        .font-serif-italic {
          font-family: "Playfair Display", serif;
          font-style: italic;
        }
        .category-number {
          font-family: "Playfair Display", serif;
          font-size: 0.75rem;
          letter-spacing: 0.3em;
        }
        .selection-count {
          font-family: "Playfair Display", serif;
          font-style: italic;
          font-size: 0.7rem;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: #999999;
        }
        .text-gold {
          color: #c5a059;
        }
        .nav-shadow {
          box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.05);
        }
      `}</style>
    </div>
  );
}