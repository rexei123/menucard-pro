import { Icon } from '@iconify/react';

export default function App() {
  const extras = [
    { name: 'Extra Cheddar Käse', price: '+ €1.50' },
    { name: 'Knuspriger Bacon', price: '+ €2.00' },
    { name: 'Frische Avocado', price: '+ €2.50' },
    { name: 'Scharfe Jalapeños', price: '+ €1.00' },
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col lg:flex-row">
      {/* Desktop Sidebar Navigation */}
      <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-gray-200 h-screen sticky top-0 p-6">
        <div className="flex items-center gap-2 mb-10">
          <div className="w-10 h-10 bg-[#DD3C71] rounded-xl flex items-center justify-center">
            <Icon icon="lucide:leaf" className="text-white w-6 h-6" />
          </div>
          <span className="text-xl font-bold text-[#181821]">Modern Burger</span>
        </div>
        
        <nav className="space-y-2 flex-1">
          <SidebarItem icon="lucide:leaf" label="Menü" active />
          <SidebarItem icon="lucide:search" label="Suche" />
          <SidebarItem icon="lucide:shopping-cart" label="Warenkorb" badge="9" />
          <SidebarItem icon="lucide:user" label="Profil" />
        </nav>

        <div className="mt-auto pt-6 border-t border-gray-100">
          <div className="flex items-center gap-3 p-3 rounded-xl bg-gray-50">
            <img src="./assets/IMG_13.webp" className="w-10 h-10 rounded-full object-cover" alt="User" />
            <div>
              <p className="text-sm font-bold text-[#181821]">Alex Schmidt</p>
              <p className="text-xs text-gray-500">Premium Member</p>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col relative">
        {/* Mobile Header */}
        <header className="lg:hidden sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100 px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
              <img src="./assets/IMG_3.svg" className="w-5 h-5" alt="Back" />
            </button>
            <h1 className="text-lg font-semibold text-[#181821]">Modern Burger</h1>
          </div>
          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
              <img src="./assets/IMG_4.svg" className="w-5 h-5" alt="Search" />
            </button>
            <div className="relative">
              <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                <img src="./assets/IMG_5.svg" className="w-5 h-5" alt="Cart" />
              </button>
              <span className="absolute top-1 right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">2</span>
            </div>
          </div>
        </header>

        {/* Hero Section */}
        <section className="relative w-full h-[220px] md:h-[350px] lg:h-[400px] overflow-hidden">
          <img 
            src="./assets/IMG_6.jpeg" 
            className="w-full h-full object-cover" 
            alt="The Ultimate BBQ Bacon Burger" 
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent" />
          
          <div className="absolute top-4 left-4 flex gap-2">
            <span className="bg-[#DD3C71] text-white text-xs font-bold px-3 py-1 rounded-full">Bestseller</span>
            <div className="glass-badge flex items-center gap-1 px-3 py-1 rounded-full">
              <img src="./assets/IMG_7.svg" className="w-3 h-3" alt="Hot" />
              <span className="text-white text-xs font-semibold">Hot</span>
            </div>
          </div>

          <div className="absolute bottom-6 left-4 right-4 md:left-8 md:right-8 flex flex-col md:flex-row md:items-end md:justify-between gap-4">
            <div className="max-w-md">
              <h2 className="hero-title text-white text-2xl md:text-4xl lg:text-5xl mb-2 drop-shadow-md">
                The Ultimate BBQ Bacon Burger
              </h2>
              <div className="flex items-center gap-1">
                <div className="flex gap-0.5">
                  {[1, 2, 3, 4].map((i) => (
                    <img key={i} src="./assets/IMG_8.svg" className="w-3 h-3 text-[#FACC15]" alt="Star" />
                  ))}
                  <Icon icon="lucide:star" className="w-3 h-3 text-gray-400" />
                </div>
                <span className="text-white/80 text-[10px] md:text-xs font-medium ml-2">(120+ Bewertungen)</span>
              </div>
            </div>
            <div className="hidden md:block bg-[#DD3C71] text-white px-6 py-3 rounded-xl shadow-lg shadow-[#DD3C71]/30">
              <span className="text-xl font-black">€14.90</span>
            </div>
            {/* Mobile Price Tag */}
            <div className="md:hidden absolute bottom-0 right-0 bg-[#DD3C71] text-white px-4 py-2 rounded-xl shadow-lg shadow-[#DD3C71]/30">
              <span className="text-base font-black">€14.90</span>
            </div>
          </div>
        </section>

        {/* Content Container */}
        <div className="max-w-5xl mx-auto w-full px-4 md:px-8 py-8 space-y-8">
          
          {/* Stats Grid */}
          <div className="grid grid-cols-4 gap-2 md:gap-4 bg-[#F9F9FB] border border-[#DFDFE7]/50 p-4 rounded-xl soft-shadow">
            <StatItem icon="./assets/IMG_9.svg" label="15 Min" />
            <StatItem icon="./assets/IMG_7.svg" label="850 kcal" />
            <StatItem icon="./assets/IMG_10.svg" label="Frisch" />
            <StatItem icon="./assets/IMG_11.svg" label="Bio" />
          </div>

          {/* Description & Info */}
          <div className="grid lg:grid-cols-2 gap-8">
            <div className="space-y-4">
              <h3 className="section-label">Beschreibung</h3>
              <p className="text-[#353546] text-sm md:text-base leading-relaxed">
                Ein Meisterwerk der Grillkunst. Saftiges 100% Weiderind-Patty trifft auf hausgemachte rauchige BBQ-Sauce, karamellisierte Zwiebeln und knusprigen Applewood-Bacon. Serviert in einem buttrigen, goldgelben Brioche-Bun.
              </p>
              <button className="flex items-center gap-1 text-[#DD3C71] font-bold text-sm hover:underline">
                Mehr lesen <img src="./assets/IMG_12.svg" className="w-4 h-4" alt="Arrow" />
              </button>
              
              <div className="flex items-center gap-3 pt-2">
                <div className="flex -space-x-2">
                  <img src="./assets/IMG_13.webp" className="w-8 h-8 rounded-full border-2 border-white object-cover" alt="Avatar" />
                  <img src="./assets/IMG_14.webp" className="w-8 h-8 rounded-full border-2 border-white object-cover" alt="Avatar" />
                </div>
                <span className="text-[#353546] text-[11px] font-medium italic">Enthält Gluten, Milchprodukte & Senf</span>
              </div>
            </div>

            {/* Extras Section */}
            <div className="space-y-4">
              <h3 className="section-label">Extras anpassen</h3>
              <div className="grid gap-3">
                {extras.map((extra, idx) => (
                  <div key={idx} className="flex items-center justify-between p-4 bg-[#F3F3F6]/30 rounded-xl border border-transparent hover:border-[#DD3C71]/20 transition-all soft-shadow group cursor-pointer">
                    <div className="flex items-center gap-3">
                      <div className="w-6 h-6 bg-[#F3F3F6] rounded-md flex items-center justify-center group-hover:bg-[#DD3C71]/10 transition-colors">
                        <img src="./assets/IMG_15.svg" className="w-4 h-4" alt="Check" />
                      </div>
                      <span className="text-[#181821] text-sm font-semibold">{extra.name}</span>
                    </div>
                    <span className="text-[#DD3C71] text-sm font-bold">{extra.price}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Action Bar */}
        <div className="sticky bottom-0 lg:bottom-4 lg:mx-auto lg:max-w-2xl w-full z-40">
          <div className="bg-white/90 backdrop-blur-xl border-t lg:border border-gray-100 lg:rounded-2xl p-4 flex items-center gap-4 shadow-2xl lg:mb-4">
            <div className="flex items-center bg-[#F3F3F6]/50 border border-[#DFDFE7] rounded-xl h-12 px-2">
              <button className="w-10 h-10 flex items-center justify-center hover:bg-gray-200 rounded-lg transition-colors">
                <img src="./assets/IMG_16.svg" className="w-4 h-4" alt="Minus" />
              </button>
              <span className="w-8 text-center text-lg font-bold text-[#181821]">1</span>
              <button className="w-10 h-10 flex items-center justify-center hover:bg-gray-200 rounded-lg transition-colors">
                <img src="./assets/IMG_17.svg" className="w-4 h-4" alt="Plus" />
              </button>
            </div>
            
            <button className="flex-1 btn-gradient h-14 rounded-xl flex items-center justify-between px-6 text-white shadow-lg shadow-[#DD3C71]/40 hover:scale-[1.02] active:scale-[0.98] transition-all">
              <div className="text-left">
                <p className="text-[10px] font-black uppercase opacity-80 leading-none mb-1">Hinzufügen</p>
                <p className="text-xs font-medium">In den Warenkorb</p>
              </div>
              <span className="text-xl font-black">€14.90</span>
            </button>
          </div>
        </div>

        {/* Mobile Tab Bar */}
        <nav className="lg:hidden sticky bottom-0 w-full h-16 bg-white border-t border-gray-100 flex items-center justify-around px-2 z-50">
          <TabItem icon="./assets/IMG_10.svg" label="Menü" active />
          <TabItem icon="./assets/IMG_9.svg" label="Suche" />
          <div className="relative">
            <TabItem icon="./assets/IMG_17.svg" label="Warenkorb" />
            <span className="absolute top-2 right-4 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full ring-2 ring-white">9</span>
          </div>
          <TabItem icon="./assets/IMG_11.svg" label="Profil" />
        </nav>
      </main>
    </div>
  );
}

function SidebarItem({ icon, label, active = false, badge }: { icon: string, label: string, active?: boolean, badge?: string }) {
  return (
    <a href="#" className={`flex items-center justify-between p-3 rounded-xl transition-all ${active ? 'bg-[#DD3C71]/10 text-[#DD3C71]' : 'text-gray-500 hover:bg-gray-50 hover:text-[#181821]'}`}>
      <div className="flex items-center gap-3">
        <Icon icon={icon} className="w-5 h-5" />
        <span className="text-sm font-bold">{label}</span>
      </div>
      {badge && (
        <span className="bg-[#DD3C71] text-white text-[10px] font-bold px-2 py-0.5 rounded-full">{badge}</span>
      )}
    </a>
  );
}

function StatItem({ icon, label }: { icon: string, label: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 p-2 bg-[#F3F3F6]/50 rounded-xl">
      <img src={icon} className="w-5 h-5 text-[#DD3C71]" alt={label} />
      <span className="text-[10px] font-bold text-[#353546] uppercase tracking-wider">{label}</span>
    </div>
  );
}

function TabItem({ icon, label, active = false }: { icon: string, label: string, active?: boolean }) {
  return (
    <a href="#" className="flex flex-col items-center justify-center gap-1 flex-1">
      <img src={icon} className={`w-6 h-6 ${active ? 'text-[#DD3C71]' : 'opacity-40'}`} alt={label} />
      <span className={`text-[10px] font-bold ${active ? 'text-[#DD3C71]' : 'text-gray-400'}`}>{label}</span>
    </a>
  );
}