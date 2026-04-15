import { Icon } from '@iconify/react';

export default function App() {
  return (
    <div className="min-h-screen bg-[#FDFBF7] font-serif text-[#171a1f] flex flex-col">
      {/* Header - Fixed on Mobile, Sticky on Desktop */}
      <header className="sticky top-0 z-50 bg-[#FDFBF7] border-b border-[#dee1e6] px-4 h-16 flex items-center justify-between lg:px-8">
        <div className="flex items-center gap-4">
          <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
            <img src="./assets/IMG_3.svg" alt="Back" className="w-5 h-5" />
          </button>
          <h1 className="text-lg font-semibold lg:text-xl">Gericht-Details</h1>
        </div>
        <div className="flex items-center gap-2">
          <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
            <img src="./assets/IMG_4.svg" alt="Search" className="w-5 h-5" />
          </button>
          <div className="relative">
            <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
              <img src="./assets/IMG_5.svg" alt="Cart" className="w-5 h-5" />
            </button>
            <span className="absolute top-1 right-1 bg-[#DD3C71] text-[#19191F] text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">
              2
            </span>
          </div>
        </div>
      </header>

      <main className="flex-1 pb-32 lg:pb-16">
        <div className="max-w-6xl mx-auto lg:grid lg:grid-cols-2 lg:gap-12 lg:pt-8 lg:px-8">
          
          {/* Hero Image Section */}
          <section className="relative h-[256px] md:h-[400px] lg:h-[500px] lg:rounded-2xl overflow-hidden">
            <img 
              src="./assets/IMG_6.jpg" 
              alt="Rinderfilet Rossini" 
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent" />
            <div className="absolute bottom-6 left-6 right-6">
              <div className="inline-block bg-[#DD3C71] px-3 py-0.5 rounded-full mb-3">
                <span className="text-[12px] font-bold text-[#19191F]">Empfehlung des Hauses</span>
              </div>
              <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold text-white leading-tight">
                Rinderfilet 'Rossini'
              </h2>
            </div>
          </section>

          {/* Content Section */}
          <div className="px-6 py-8 lg:px-0 lg:py-0 space-y-8">
            {/* Price & Subtitle */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <p className="text-[#565d6d] text-sm tracking-[1.4px] uppercase max-w-[280px]">
                Ein Klassiker der französischen Haute Cuisine
              </p>
              <span className="text-[#DD3C71] text-2xl md:text-3xl font-bold">42,50 €</span>
            </div>

            <hr className="border-[#dee1e6]/50" />

            {/* Description */}
            <section>
              <div className="flex items-center gap-3 mb-4">
                <img src="./assets/IMG_7.svg" alt="Info" className="w-5 h-5 text-[#DD3C71]" />
                <h3 className="text-xl font-semibold">Beschreibung</h3>
              </div>
              <div className="text-[#565d6d] text-base leading-relaxed italic space-y-4">
                <p>
                  Zartes Filetsteak vom Weiderind, perfekt rosa gebraten, gekrönt mit einer feinen Scheibe Gänseleber und frischen Trüffelscheiben. Serviert auf einem knusprigen Crouton mit einer kräftigen Madeira-Sauce und glasierten Fingermöhren.
                </p>
                <p>
                  Dieses Gericht vereint luxuriöse Aromen und traditionelle Handwerkskunst in einer harmonischen Komposition.
                </p>
              </div>
            </section>

            {/* Allergens */}
            <section>
              <h3 className="text-xl font-semibold mb-4">Allergene & Hinweise</h3>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { name: 'Gluten', icon: './assets/IMG_8.svg' },
                  { name: 'Laktose', icon: './assets/IMG_9.svg' },
                  { name: 'Sulfite', icon: './assets/IMG_10.svg' },
                  { name: 'Fisch', icon: './assets/IMG_11.svg' },
                ].map((item) => (
                  <div key={item.name} className="flex items-center gap-3 p-3 bg-white/50 rounded-xl border border-[#dee1e6]/30">
                    <div className="w-8 h-8 rounded-full bg-[#DD3C71]/10 flex items-center justify-center">
                      <img src={item.icon} alt={item.name} className="w-4 h-4" />
                    </div>
                    <span className="text-sm font-medium">{item.name}</span>
                  </div>
                ))}
              </div>
            </section>

            {/* Ingredients Card */}
            <section className="bg-[#fafafb] rounded-xl border border-[#dee1e6] p-6">
              <div className="flex items-center gap-3 mb-6">
                <img src="./assets/IMG_12.svg" alt="Check" className="w-5 h-5" />
                <h3 className="text-lg font-semibold">Hauptzutaten</h3>
              </div>
              <ul className="space-y-3">
                {[
                  '200g Rinderfilet (Bio)',
                  'Frischer schwarzer Trüffel',
                  'Gänseleber-Mousse',
                  'Madeira-Reduktion',
                  'Bio-Fingermöhren',
                  'Hausgemachtes Brioche-Crouton'
                ].map((ingredient) => (
                  <li key={ingredient} className="flex items-center gap-3 text-[#565d6d] text-sm">
                    <div className="w-1.5 h-1.5 rounded-full bg-[#DD3C71]" />
                    {ingredient}
                  </li>
                ))}
              </ul>
            </section>

            <p className="text-[#565d6d]/70 text-[12px] leading-relaxed">
              * Alle Preise inkl. MwSt. und Bedienung. Wir verwenden ausschließlich regionale Zutaten von zertifizierten Partnern.
            </p>
          </div>
        </div>
      </main>

      {/* Floating Action Button - Mobile Only */}
      <div className="fixed bottom-20 left-0 right-0 px-4 lg:hidden">
        <button className="w-full h-14 bg-[#DD3C71] rounded-lg shadow-lg flex items-center justify-between px-4 text-[#19191F] active:scale-[0.98] transition-transform">
          <div className="flex items-center gap-3">
            <img src="./assets/IMG_13.svg" alt="Add" className="w-6 h-6" />
            <span className="text-lg font-bold">In den Warenkorb</span>
          </div>
          <div className="bg-white/20 px-3 py-1 rounded text-sm font-bold">
            42,50 €
          </div>
        </button>
      </div>

      {/* Desktop Add to Cart - Fixed Sidebar or Bottom Bar */}
      <div className="hidden lg:block fixed bottom-8 right-8">
        <button className="bg-[#DD3C71] hover:bg-[#c93465] text-[#19191F] px-8 py-4 rounded-full shadow-2xl flex items-center gap-4 transition-all hover:scale-105">
          <Icon icon="lucide:plus" className="w-6 h-6" />
          <span className="text-lg font-bold">In den Warenkorb • 42,50 €</span>
        </button>
      </div>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-[#FDFBF7] border-t border-[#dee1e6] h-16 flex items-center justify-around px-2 lg:hidden">
        <a href="#" className="flex flex-col items-center gap-1 text-[#DD3C71]">
          <img src="./assets/IMG_14.svg" alt="Menu" className="w-6 h-6" />
          <span className="text-[10px] font-bold">Menü</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <img src="./assets/IMG_4.svg" alt="Search" className="w-6 h-6" />
          <span className="text-[10px]">Suche</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d] relative">
          <img src="./assets/IMG_5.svg" alt="Cart" className="w-6 h-6" />
          <span className="text-[10px]">Warenkorb</span>
          <span className="absolute -top-1 right-2 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            9
          </span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <img src="./assets/IMG_15.svg" alt="Profile" className="w-6 h-6" />
          <span className="text-[10px]">Profil</span>
        </a>
      </nav>
    </div>
  );
}