import { Icon } from '@iconify/react';

export default function App() {
  const menuItems = [
    {
      id: 1,
      name: 'Rinder-Carpaccio',
      price: '16,50 €',
      description: 'Hauchdünne Scheiben vom Weiderind, Trüffel-Vinaigrette, gehobelter Parmesan und Wildkräutersalat.',
      tag: 'Klassiker',
      image: './assets/IMG_7.webp',
    },
    {
      id: 2,
      name: 'Burrata di Puglia',
      price: '14,00 €',
      description: 'Cremiger Burrata auf marinierten Kirschtomaten, Basilikumpesto und geröstetes Ciabatta.',
      tag: 'Vegetarisch',
      image: './assets/IMG_8.webp',
    },
    {
      id: 3,
      name: 'Vitello Tonnato',
      price: '15,50 €',
      description: 'Zartes Kalbfleisch mit einer feinen Thunfischsauce, Kapernäpfeln und Zitrone.',
      tag: null,
      image: './assets/IMG_9.webp',
    },
    {
      id: 4,
      name: 'Gegrillte Jakobsmuscheln',
      price: '18,00 €',
      description: 'Drei Jakobsmuscheln auf Erbsenpüree mit knusprigem Pancetta.',
      tag: 'Empfehlung',
      image: './assets/IMG_10.webp',
    },
    {
      id: 5,
      name: 'Gebackener Ziegenkäse',
      price: '13,50 €',
      description: 'In Honig gebackener Ziegenkäse mit Thymian, Feigensenf und Walnüssen.',
      tag: 'Vegetarisch',
      image: './assets/IMG_11.webp',
    },
  ];

  return (
    <div className="min-h-screen bg-[#FDFBF7] flex flex-col lg:flex-row">
      {/* Desktop Sidebar Navigation */}
      <aside className="hidden lg:flex flex-col w-64 bg-white border-r border-[#dee1e6] h-screen sticky top-0 p-6">
        <div className="mb-10">
          <h1 className="text-2xl font-bold text-[#171a1f]">Ristorante</h1>
        </div>
        <nav className="flex flex-col gap-4">
          <SidebarLink icon="lucide:house" label="Home" />
          <SidebarLink icon="lucide:menu" label="Menü" active />
          <SidebarLink icon="lucide:shopping-bag" label="Warenkorb" badge="9" />
          <SidebarLink icon="lucide:info" label="Informationen" />
          <SidebarLink icon="lucide:heart" label="Favoriten" />
        </nav>
        <div className="mt-auto pt-6 border-t border-[#dee1e6]">
          <div className="flex items-center gap-3 p-2">
            <div className="w-10 h-10 rounded-full bg-[#DD3C71]/10 flex items-center justify-center">
              <Icon icon="lucide:user" className="text-[#DD3C71]" />
            </div>
            <div>
              <p className="text-sm font-semibold">Gast</p>
              <p className="text-xs text-[#565d6d]">Tisch 12</p>
            </div>
          </div>
        </div>
      </aside>

      <main className="flex-1 flex flex-col max-w-5xl mx-auto w-full">
        {/* Header */}
        <header className="sticky top-0 z-50 bg-[#FDFBF7]/80 backdrop-blur-md border-b border-[#dee1e6]">
          {/* Mobile Status Bar Placeholder */}
          <div className="h-10 flex justify-between items-center px-4 lg:hidden">
            <img src="./assets/IMG_1.svg" alt="status" className="h-10" />
            <img src="./assets/IMG_2.svg" alt="status-icons" className="h-10" />
          </div>

          <div className="h-16 flex items-center justify-between px-4 lg:px-8">
            <div className="flex items-center gap-4">
              <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
                <img src="./assets/IMG_3.svg" alt="back" className="w-5 h-5" />
              </button>
              <h2 className="text-lg font-semibold text-[#171a1f]">Vorspeisen</h2>
            </div>
            <div className="flex items-center gap-2">
              <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
                <img src="./assets/IMG_4.svg" alt="search" className="w-5 h-5" />
              </button>
              <div className="relative">
                <button className="p-2 hover:bg-black/5 rounded-full transition-colors">
                  <img src="./assets/IMG_5.svg" alt="cart" className="w-5 h-5" />
                </button>
                <span className="absolute -top-1 -right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">
                  2
                </span>
              </div>
            </div>
          </div>
        </header>

        {/* Hero Section */}
        <section className="py-12 px-6 text-center bg-white/40 border-b border-[#dee1e6]/30">
          <p className="text-[12px] tracking-[0.2em] uppercase text-[#565d6d] mb-4">Antipasti</p>
          <h1 className="text-3xl md:text-4xl lg:text-5xl font-bold text-[#171a1f] mb-6">
            Kulinarische Eröffnung
          </h1>
          <div className="w-12 h-[1px] bg-[#DD3C71] mx-auto mb-6" />
          <p className="max-w-md mx-auto text-[#565d6d] italic text-sm md:text-base leading-relaxed">
            Entdecken Sie unsere handverlesenen Vorspeisen, zubereitet mit den frischesten Zutaten der Saison.
          </p>
        </section>

        {/* Filter Bar */}
        <div className="sticky top-16 lg:top-0 z-40 bg-[#f3f4f6]/20 backdrop-blur-sm border-b border-[#dee1e6]/40 px-4 py-3 flex items-center justify-between">
          <span className="text-[11px] font-medium uppercase tracking-wider text-[#565d6d]">
            5 Gerichte verfügbar
          </span>
          <button className="flex items-center gap-2 px-3 py-1 border border-[#dee1e6] rounded-full bg-white hover:bg-gray-50 transition-colors">
            <img src="./assets/IMG_6.svg" alt="heart" className="w-3 h-3" />
            <span className="text-[11px] font-semibold text-[#DD3C71]">Favoriten</span>
          </button>
        </div>

        {/* Menu List */}
        <section className="flex-1 bg-white/60">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-1 gap-0">
            {menuItems.map((item) => (
              <div 
                key={item.id} 
                className="flex p-4 md:p-6 border-b border-[#dee1e6]/50 hover:bg-white/80 transition-colors group cursor-pointer"
              >
                <div className="relative w-16 h-16 md:w-20 md:h-20 flex-shrink-0 rounded-md overflow-hidden shadow-sm border border-[#dee1e6]/20">
                  <img 
                    src={item.image} 
                    alt={item.name} 
                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" 
                  />
                </div>
                <div className="ml-4 flex-1">
                  <div className="flex justify-between items-start mb-1">
                    <h3 className="text-[17px] font-bold text-[#171a1f] leading-tight group-hover:text-[#DD3C71] transition-colors">
                      {item.name}
                    </h3>
                    <span className="text-base font-semibold text-[#DD3C71] whitespace-nowrap ml-2">
                      {item.price}
                    </span>
                  </div>
                  <p className="text-[13px] text-[#565d6d] italic leading-snug mb-3 max-w-xl">
                    {item.description}
                  </p>
                  {item.tag && (
                    <span className="inline-block px-2 py-0.5 border border-[#DD3C71]/30 rounded-full text-[10px] font-semibold text-[#DD3C71]/80">
                      {item.tag}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Special Requests Card */}
          <div className="p-6 md:p-10">
            <div className="bg-[#EDFDF4]/50 border border-[#DD3C71]/20 rounded-xl p-6 text-center max-w-2xl mx-auto">
              <div className="w-10 h-10 bg-[#DD3C71]/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <img src="./assets/IMG_12.svg" alt="info" className="w-6 h-6" />
              </div>
              <h4 className="text-sm font-bold text-[#171a1f] mb-2">Besondere Wünsche?</h4>
              <p className="text-xs text-[#565d6d] leading-relaxed">
                Sollten Sie Allergien oder Unverträglichkeiten haben, sprechen Sie bitte unser Servicepersonal an.
              </p>
            </div>
          </div>
        </section>

        {/* Spacer for bottom nav */}
        <div className="h-20 lg:hidden" />
      </main>

      {/* Mobile Bottom Navigation */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-[#FDFBF7] border-t border-[#dee1e6]/50 shadow-nav flex justify-around items-center h-16 z-50">
        <MobileNavLink icon="./assets/IMG_13.svg" label="Home" />
        <MobileNavLink icon="./assets/IMG_14.svg" label="Menü" active />
        <MobileNavLink icon="./assets/IMG_15.svg" label="Korb" badge="9" />
        <MobileNavLink icon="./assets/IMG_12.svg" label="Info" />
      </nav>
    </div>
  );
}

function SidebarLink({ icon, label, active = false, badge }: { icon: string, label: string, active?: boolean, badge?: string }) {
  return (
    <a 
      href="#" 
      className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all ${
        active ? 'bg-[#DD3C71] text-white shadow-md' : 'text-[#565d6d] hover:bg-gray-100'
      }`}
    >
      <div className="relative">
        <Icon icon={icon} className="w-5 h-5" />
        {badge && !active && (
          <span className="absolute -top-2 -right-2 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            {badge}
          </span>
        )}
      </div>
      <span className="text-sm font-medium">{label}</span>
    </a>
  );
}

function MobileNavLink({ icon, label, active = false, badge }: { icon: string, label: string, active?: boolean, badge?: string }) {
  return (
    <a href="#" className="flex flex-col items-center justify-center flex-1 h-full relative">
      <div className="relative">
        <img 
          src={icon} 
          alt={label} 
          className={`w-6 h-6 ${active ? 'text-[#DD3C71]' : 'text-[#565d6d]'}`} 
          style={{ filter: active ? 'invert(34%) sepia(68%) saturate(2341%) hue-rotate(315deg) brightness(91%) contrast(92%)' : 'none' }}
        />
        {badge && (
          <span className="absolute -top-1 -right-1 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            {badge}
          </span>
        )}
      </div>
      <span className={`text-[10px] mt-1 ${active ? 'text-[#DD3C71] font-bold' : 'text-[#565d6d] font-normal'}`}>
        {label}
      </span>
    </a>
  );
}