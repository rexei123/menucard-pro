import { Icon } from '@iconify/react';

export default function App() {
  return (
    <div className="min-h-screen bg-white text-[#171a1f] font-['Playfair_Display'] selection:bg-[#DD3C71]/20">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/95 backdrop-blur-sm border-b border-[#f3f4f6]">
        {/* Status Bar (Mobile Only) */}
        <div className="flex justify-between items-center px-4 h-10 lg:hidden">
          <img src="./assets/IMG_1.svg" alt="time" className="h-10 w-auto" />
          <img src="./assets/IMG_2.svg" alt="status" className="h-10 w-auto" />
        </div>

        {/* Navigation Bar */}
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
              <img src="./assets/IMG_3.svg" alt="back" className="w-5 h-5" />
            </button>
            <h1 className="text-lg font-semibold tracking-[1.8px] truncate max-w-[200px] md:max-w-md">
              Jakobsmuscheln 'L'Océan'
            </h1>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
              <img src="./assets/IMG_4.svg" alt="search" className="w-5 h-5" />
            </button>
            <div className="relative">
              <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
                <img src="./assets/IMG_5.svg" alt="cart" className="w-5 h-5" />
              </button>
              <span className="absolute top-1 right-1 w-4 h-4 bg-[#DD3C71] text-white text-[10px] font-bold flex items-center justify-center rounded-full">
                1
              </span>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8 lg:py-16">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:items-start">
          
          {/* Left Column: Image Section */}
          <div className="flex flex-col items-center">
            <div className="relative w-full max-w-[320px] aspect-square flex items-center justify-center">
              {/* Decorative Rings */}
              <div className="absolute inset-0 border border-[#f3f4f6] rounded-full scale-110 opacity-90" />
              <div className="absolute inset-0 border border-[#dee1e6] rounded-full" />
              
              {/* Main Image Container */}
              <div className="w-[90%] h-[90%] rounded-full overflow-hidden bg-[#dcffe7]">
                <img 
                  src="./assets/IMG_6.jpg" 
                  alt="Jakobsmuscheln" 
                  className="w-full h-full object-cover"
                />
              </div>
            </div>
          </div>

          {/* Right Column: Content Section */}
          <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
            {/* Title & Subtitle */}
            <div className="space-y-4 mb-8">
              <h2 className="text-2xl md:text-3xl lg:text-4xl font-light tracking-[3.6px] uppercase leading-tight">
                Jakobsmuscheln 'L'Océan'
              </h2>
              <p className="text-[#565d6d] text-sm md:text-base italic-serif tracking-[0.35px]">
                Handgetauchte Jakobsmuscheln aus der Bretagne
              </p>
            </div>

            {/* Tags */}
            <div className="flex flex-wrap justify-center lg:justify-start gap-3 mb-10">
              <span className="px-4 py-1 border border-[#f3f4f6] rounded-full text-[10px] font-light tracking-wider uppercase">
                Signature Dish
              </span>
              <span className="px-4 py-1 border border-[#f3f4f6] rounded-full text-[10px] font-light tracking-wider uppercase">
                Laktosefrei möglich
              </span>
            </div>

            {/* Story Section */}
            <div className="w-full max-w-xl mx-auto lg:mx-0">
              <div className="hr-with-star mb-8">
                <img src="./assets/IMG_7.svg" alt="sparkle" className="w-4 h-4 opacity-50" />
              </div>
              
              <h3 className="text-[10px] tracking-[3px] uppercase text-[#565d6d] mb-4">
                Die Geschichte des Gerichts
              </h3>
              <p className="text-[#171a1f]/80 text-sm md:text-base leading-relaxed mb-10">
                Dieses Gericht ist eine Hommage an die raue Schönheit der bretonischen Küste. 
                Jede Muschel wird einzeln von Hand getaucht und in einer Emulsion aus gesalzener Butter, 
                Zitronenthymian und einem Hauch von Meeresspargel sanft pochiert. 
                Wir servieren dazu ein feines Püree aus Topinambur, das die nussige Süße der Meeresfrucht unterstreicht.
              </p>
            </div>

            {/* Ingredients Card */}
            <div className="w-full max-w-xl bg-[#fafafb]/30 border border-[#f3f4f6] rounded-lg p-6 mb-8 text-left">
              <div className="flex items-center gap-3 mb-3">
                <img src="./assets/IMG_8.svg" alt="leaf" className="w-3 h-3 text-[#565d6d]" />
                <h4 className="text-[10px] tracking-[2px] uppercase text-[#565d6d]">Zutaten</h4>
              </div>
              <p className="text-[#171a1f]/70 text-xs md:text-sm italic-serif leading-relaxed">
                Atlantik-Jakobsmuscheln, Topinambur, Salzbutter, Zitronenthymian, Meeresspargel, Fleur de Sel.
              </p>
            </div>

            {/* Allergens Section */}
            <div className="w-full max-w-xl border-t border-[#dee1e6]/50 pt-6 mb-12">
              <button className="w-full flex items-center justify-between group">
                <div className="flex items-center gap-4">
                  <div className="w-8 h-8 bg-[#f3f4f6]/30 rounded-full flex items-center justify-center">
                    <img src="./assets/IMG_9.svg" alt="info" className="w-4 h-4" />
                  </div>
                  <span className="text-xs tracking-[1.2px] uppercase font-light">Allergene & Hinweise</span>
                </div>
                <img src="./assets/IMG_10.svg" alt="arrow" className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </button>
              
              <div className="flex flex-wrap gap-2 mt-4">
                <span className="px-3 py-1 bg-[#f3f4f6]/20 rounded-full text-[10px] text-[#565d6d]">Weichtiere</span>
                <span className="px-3 py-1 bg-[#f3f4f6]/20 rounded-full text-[10px] text-[#565d6d]">Milchprodukte</span>
              </div>
            </div>

            {/* Pricing & CTA */}
            <div className="w-full max-w-xl flex flex-col items-center lg:items-start gap-6">
              <div className="text-center lg:text-left">
                <div className="text-3xl font-light tracking-[-1.5px]">34.00 €</div>
                <div className="text-[9px] tracking-[1.8px] uppercase text-[#565d6d] mt-1">
                  Inklusive gesetzlicher MwSt.
                </div>
              </div>

              <button className="w-full md:w-auto min-w-[240px] h-14 bg-[#171a1f] text-white flex items-center justify-center gap-4 shadow-lg hover:bg-black transition-all btn-dark-active">
                <img src="./assets/IMG_11.svg" alt="plus" className="w-4 h-4 invert" />
                <span className="text-xs font-medium uppercase tracking-wider">Zum Warenkorb</span>
              </button>

              <button className="text-[10px] text-[#565d6d] hover:text-black transition-colors uppercase tracking-widest">
                Zurück zur Übersicht
              </button>
            </div>
          </div>
        </div>
      </main>

      {/* Bottom Navigation (Mobile Only) */}
      <div className="lg:hidden h-20" /> {/* Spacer for fixed nav */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-[#f3f4f6] shadow-[0_-2px_10px_rgba(0,0,0,0.05)] lg:hidden">
        <div className="flex justify-around items-center h-16">
          <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
            <img src="./assets/IMG_12.svg" alt="home" className="w-6 h-6" />
            <span className="text-[10px]">Home</span>
          </a>
          <a href="#" className="flex flex-col items-center gap-1 text-[#171a1f] font-bold">
            <img src="./assets/IMG_4.svg" alt="categories" className="w-6 h-6" />
            <span className="text-[10px]">Kategorien</span>
          </a>
          <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d] relative">
            <img src="./assets/IMG_5.svg" alt="cart" className="w-6 h-6" />
            <span className="text-[10px]">Warenkorb</span>
            <span className="absolute -top-1 right-2 w-4 h-4 bg-[#E05252] text-white text-[8px] flex items-center justify-center rounded-full ring-2 ring-white">
              9
            </span>
          </a>
          <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
            <img src="./assets/IMG_13.svg" alt="profile" className="w-6 h-6" />
            <span className="text-[10px]">Profil</span>
          </a>
        </div>
      </nav>

      {/* Desktop Sidebar (Hidden on Mobile) */}
      <aside className="hidden lg:flex fixed left-0 top-0 bottom-0 w-20 flex-col items-center py-8 bg-white border-r border-[#f3f4f6] z-50">
        <div className="flex flex-col gap-10">
          <Icon icon="ph:house-light" className="w-6 h-6 text-[#565d6d] cursor-pointer hover:text-black" />
          <Icon icon="ph:magnifying-glass-bold" className="w-6 h-6 text-[#171a1f] cursor-pointer" />
          <div className="relative">
            <Icon icon="ph:shopping-cart-light" className="w-6 h-6 text-[#565d6d] cursor-pointer hover:text-black" />
            <span className="absolute -top-2 -right-2 w-4 h-4 bg-[#E05252] text-white text-[8px] flex items-center justify-center rounded-full">9</span>
          </div>
          <Icon icon="ph:user-light" className="w-6 h-6 text-[#565d6d] cursor-pointer hover:text-black" />
        </div>
      </aside>
    </div>
  );
}