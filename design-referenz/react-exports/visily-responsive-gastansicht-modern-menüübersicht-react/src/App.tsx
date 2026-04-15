import { Icon } from '@iconify/react';

export default function App() {
  return (
    <div className="min-h-screen bg-white flex flex-col lg:flex-row">
      {/* Desktop Sidebar Navigation */}
      <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-gray-200 h-screen sticky top-0 p-6">
        <div className="flex items-center gap-3 mb-10">
          <div className="w-10 h-10 bg-[#171a1f] rounded-lg flex items-center justify-center">
            <img src="./assets/IMG_5.svg" alt="Logo" className="w-6 h-6" />
          </div>
          <h1 className="text-2xl font-semibold text-[#171a1f] font-['Playfair_Display']">GastroMenu</h1>
        </div>

        <nav className="flex-1 space-y-2">
          <SidebarLink icon="lucide:layout-grid" label="Start" />
          <SidebarLink icon="lucide:list" label="Menü" active />
          <SidebarLink icon="lucide:shopping-cart" label="Warenkorb" badge={9} />
          <SidebarLink icon="lucide:settings" label="Profil" />
        </nav>

        <div className="mt-auto p-4 bg-[#DD3C71]/5 rounded-2xl">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-8 h-8 bg-[#DD3C71]/10 rounded-lg flex items-center justify-center">
              <Icon icon="lucide:star" className="text-[#DD3C71] w-5 h-5" />
            </div>
            <span className="text-sm font-bold font-['Playfair_Display']">GastroClub</span>
          </div>
          <p className="text-xs text-[#565d6d] font-['Playfair_Display']">Sammle Punkte bei jeder Bestellung!</p>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col pb-20 lg:pb-0">
        {/* Mobile Header */}
        <header className="lg:hidden sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100 px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-[#171a1f] rounded-md flex items-center justify-center">
                <img src="./assets/IMG_5.svg" alt="Logo" className="w-5 h-5" />
              </div>
              <h1 className="text-lg font-semibold text-[#171a1f] font-['Playfair_Display']">GastroMenu</h1>
            </div>
            <div className="flex items-center gap-2">
              <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                <Icon icon="lucide:search" className="w-5 h-5 text-[#171a1f]" />
              </button>
              <div className="relative">
                <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                  <Icon icon="lucide:shopping-cart" className="w-5 h-5 text-[#171a1f]" />
                </button>
                <span className="absolute top-1 right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">2</span>
              </div>
            </div>
          </div>
        </header>

        {/* Search Bar (Desktop/Tablet) */}
        <div className="px-4 lg:px-10 pt-6 lg:pt-10">
          <div className="relative max-w-2xl">
            <Icon icon="lucide:search" className="absolute left-4 top-1/2 -translate-y-1/2 text-[#565d6d] w-5 h-5" />
            <input 
              type="text" 
              placeholder="Finde dein Lieblingsgericht..." 
              className="w-full bg-[#fafafb] border-none rounded-2xl py-3.5 pl-12 pr-4 text-[#565d6d] font-['Playfair_Display'] shadow-sm focus:ring-2 focus:ring-[#DD3C71]/20 outline-none"
            />
          </div>
        </div>

        {/* Highlights Section */}
        <section className="mt-8">
          <div className="px-4 lg:px-10 flex items-center justify-between mb-4">
            <h2 className="text-xl lg:text-2xl font-extrabold text-[#171a1f] font-['Playfair_Display'] tracking-tight">Highlights</h2>
            <button className="flex items-center gap-1 text-[#DD3C71] font-semibold text-sm font-['Playfair_Display']">
              Alle zeigen
              <Icon icon="lucide:chevron-right" className="w-4 h-4" />
            </button>
          </div>
          
          <div className="flex overflow-x-auto hide-scrollbar gap-4 px-4 lg:px-10 pb-4">
            <HighlightCard 
              image="./assets/IMG_7.jpeg"
              title="Trüffel Burger"
              description="Angus Beef & Schwarzer Trüffel"
              tag="Empfehlung"
            />
            <HighlightCard 
              image="./assets/IMG_9.jpeg"
              title="Lachs Poke Bowl"
              description="Frischer Lachs, Avocado & Mango"
              tag="Empfehlung"
            />
            <HighlightCard 
              image="./assets/IMG_10.jpeg"
              title="Veggie Pizza"
              description="Gartenfrisches Gemüse & Pesto"
              tag="Empfehlung"
            />
          </div>
        </section>

        {/* Categories Section */}
        <section className="mt-8 px-4 lg:px-10">
          <div className="mb-6">
            <h2 className="text-xl lg:text-2xl font-extrabold text-[#171a1f] font-['Playfair_Display'] tracking-tight">Menü Kategorien</h2>
            <p className="text-[#565d6d] text-sm font-['Playfair_Display']">Entdecke unsere kulinarische Vielfalt</p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-4 gap-4 mb-8">
            <CategoryCard image="./assets/IMG_11.jpeg" title="Burger" count="12 Gerichte" />
            <CategoryCard image="./assets/IMG_12.jpeg" title="Pizza" count="18 Gerichte" />
            <CategoryCard image="./assets/IMG_13.jpeg" title="Pasta" count="14 Gerichte" isNew />
            <CategoryCard image="./assets/IMG_14.jpeg" title="Salate" count="9 Gerichte" />
            <CategoryCard image="./assets/IMG_15.jpg" title="Steaks" count="8 Gerichte" isNew />
            <CategoryCard image="./assets/IMG_16.jpeg" title="Desserts" count="10 Gerichte" />
          </div>
        </section>

        {/* Membership Banner */}
        <section className="px-4 lg:px-10 mb-10">
          <div className="bg-[#DD3C71]/5 rounded-2xl p-5 flex items-center gap-4 cursor-pointer hover:bg-[#DD3C71]/10 transition-colors group">
            <div className="w-12 h-12 bg-[#DD3C71]/10 rounded-2xl flex items-center justify-center flex-shrink-0">
              <img src="./assets/IMG_17.svg" alt="Star" className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-bold text-[#171a1f] font-['Playfair_Display']">GastroClub Mitgliedschaft</h3>
              <p className="text-xs text-[#565d6d] font-['Playfair_Display']">Sammle Punkte bei jeder Bestellung und spare!</p>
            </div>
            <Icon icon="lucide:chevron-right" className="w-5 h-5 text-[#565d6d] group-hover:translate-x-1 transition-transform" />
          </div>
        </section>
      </main>

      {/* Mobile Bottom Navigation */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 flex justify-around items-center h-16 px-2 z-50">
        <MobileNavLink icon="./assets/IMG_18.svg" label="Start" />
        <MobileNavLink icon="./assets/IMG_19.svg" label="Menü" active />
        <MobileNavLink icon="./assets/IMG_4.svg" label="Warenkorb" badge={9} />
        <MobileNavLink icon="./assets/IMG_20.svg" label="Profil" />
      </nav>
    </div>
  );
}

// --- Sub-components ---

function HighlightCard({ image, title, description, tag }: { image: string, title: string, description: string, tag: string }) {
  return (
    <div className="relative min-w-[280px] h-[160px] rounded-2xl overflow-hidden shadow-md flex-shrink-0 group cursor-pointer">
      <img src={image} alt={title} className="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
      <div className="absolute inset-0 bg-gradient-to-r from-black/80 via-black/40 to-transparent flex flex-col justify-center px-5">
        <div className="flex items-center gap-1.5 mb-1">
          <img src="./assets/IMG_8.svg" alt="Flame" className="w-4 h-4" />
          <span className="text-[#F97316] text-[10px] font-bold uppercase tracking-tighter font-['Playfair_Display']">{tag}</span>
        </div>
        <h3 className="text-white text-xl font-extrabold font-['Playfair_Display'] leading-tight">{title}</h3>
        <p className="text-white/90 text-sm font-medium font-['Playfair_Display'] mt-1">{description}</p>
      </div>
    </div>
  );
}

function CategoryCard({ image, title, count, isNew }: { image: string, title: string, count: string, isNew?: boolean }) {
  return (
    <div className="relative aspect-[3/4] rounded-2xl overflow-hidden shadow-sm group cursor-pointer">
      <img src={image} alt={title} className="absolute inset-0 w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
      
      {isNew && (
        <div className="absolute top-3 left-3 bg-[#DD3C71] text-black text-[10px] font-bold px-2 py-0.5 rounded-full font-['Playfair_Display']">
          NEU
        </div>
      )}
      
      <div className="absolute bottom-4 left-4">
        <h3 className="text-white text-lg font-bold uppercase tracking-wider font-['Playfair_Display']">{title}</h3>
        <p className="text-white/80 text-xs font-medium font-['Playfair_Display']">{count}</p>
      </div>
    </div>
  );
}

function SidebarLink({ icon, label, active, badge }: { icon: string, label: string, active?: boolean, badge?: number }) {
  return (
    <a 
      href="#" 
      className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-colors ${active ? 'bg-[#DD3C71]/10 text-[#DD3C71]' : 'text-[#565d6d] hover:bg-gray-50'}`}
    >
      <Icon icon={icon} className="w-6 h-6" />
      <span className={`font-['Playfair_Display'] font-semibold ${active ? 'text-[#DD3C71]' : ''}`}>{label}</span>
      {badge && (
        <span className="ml-auto bg-[#E05252] text-white text-[10px] font-bold w-5 h-5 flex items-center justify-center rounded-full">
          {badge}
        </span>
      )}
    </a>
  );
}

function MobileNavLink({ icon, label, active, badge }: { icon: string, label: string, active?: boolean, badge?: number }) {
  return (
    <a href="#" className="flex flex-col items-center justify-center gap-1 relative flex-1">
      <img 
        src={icon} 
        alt={label} 
        className={`w-6 h-6 ${active ? 'brightness-0 saturate-100 invert-[34%] sepia-[61%] saturate-[1834%] hue-rotate-[313deg] brightness-[91%] contrast-[92%]' : 'opacity-70'}`} 
      />
      <span className={`text-[10px] font-['Playfair_Display'] ${active ? 'text-[#DD3C71] font-bold' : 'text-[#565d6d]'}`}>
        {label}
      </span>
      {badge && (
        <span className="absolute top-0 right-1/4 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
          {badge}
        </span>
      )}
    </a>
  );
}