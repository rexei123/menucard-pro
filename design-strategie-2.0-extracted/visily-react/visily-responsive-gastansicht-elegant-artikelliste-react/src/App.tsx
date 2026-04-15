import { Icon } from '@iconify/react';

export default function App() {
  const menuItems = [
    {
      id: "01",
      title: "Gegrillter Oktopus",
      price: "24.50 €",
      description: "Zart gegrillter Atlantik-Oktopus auf einem Bett von Safran-Fenchel-Püree, veredelt mit Chorizo-Öl und Kapern-Äpfeln.",
      tag: "Signature"
    },
    {
      id: "02",
      title: "Rindertatar „Royal“",
      price: "21.00 €",
      description: "Handgeschnittenes Weiderind, Bio-Eigelb, Trüffel-Mayonnaise und knuspriges Sauerteigbrot aus eigener Herstellung.",
      tag: null
    },
    {
      id: "03",
      title: "Jakobsmuscheln & Kaviar",
      price: "28.50 €",
      description: "Kurz angebratene Jakobsmuscheln mit Blumenkohl-Variationen und einer Nocke Ossetra-Kaviar.",
      tag: "Neu"
    },
    {
      id: "04",
      title: "Wildkräutersalat",
      price: "16.50 €",
      description: "Saisonale Wildkräuter mit kandierten Walnüssen, Ziegenkäse-Mousse und einem Dressing aus altem Balsamico.",
      tag: null
    },
    {
      id: "05",
      title: "Hummer-Bisque",
      price: "19.50 €",
      description: "Cremige Suppe vom bretonischen Hummer mit Cognac-Sahne und feinen Estragon-Noten.",
      tag: null
    }
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col font-playfair">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-gray-100">
        {/* Status Bar Placeholder (Mobile Only) */}
        <div className="h-10 flex justify-between items-center px-4 lg:hidden">
          <img src="./assets/IMG_1.svg" alt="status" className="h-10" />
          <img src="./assets/IMG_2.svg" alt="status-icons" className="h-10" />
        </div>

        {/* Navigation Bar */}
        <div className="h-16 flex items-center justify-between px-4 max-w-7xl mx-auto w-full">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
              <img src="./assets/IMG_3.svg" alt="back" className="w-5 h-5" />
            </button>
            <h1 className="text-lg font-semibold tracking-[0.1em] uppercase">Vorspeisen</h1>
          </div>
          
          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
              <img src="./assets/IMG_4.svg" alt="search" className="w-5 h-5" />
            </button>
            <div className="relative">
              <button className="p-2 hover:bg-gray-50 rounded-full transition-colors">
                <img src="./assets/IMG_5.svg" alt="cart" className="w-5 h-5" />
              </button>
              <span className="absolute top-1 right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">
                2
              </span>
            </div>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full lg:flex lg:gap-8 lg:px-8">
        {/* Desktop Sidebar Navigation */}
        <aside className="hidden lg:block w-64 py-12 border-r border-gray-100">
          <nav className="space-y-6 sticky top-28">
            <div className="space-y-2">
              <p className="eyebrow-text px-4">Kategorien</p>
              <a href="#" className="block px-4 py-2 text-black font-semibold border-l-2 border-black">Vorspeisen</a>
              <a href="#" className="block px-4 py-2 text-gray-400 hover:text-black transition-colors">Hauptspeisen</a>
              <a href="#" className="block px-4 py-2 text-gray-400 hover:text-black transition-colors">Desserts</a>
              <a href="#" className="block px-4 py-2 text-gray-400 hover:text-black transition-colors">Getränke</a>
            </div>
          </nav>
        </aside>

        <div className="flex-1">
          {/* Hero Section */}
          <section className="py-12 px-6 text-center bg-[#fafafb]/30 border-b border-gray-100">
            <p className="eyebrow-text mb-4 tracking-[0.3em]">Kulinarische Eleganz</p>
            <h2 className="text-2xl md:text-3xl font-light tracking-[0.1em] mb-6">L'ENTRÉE FINE</h2>
            <p className="max-w-md mx-auto text-sm text-[#565d6d] leading-relaxed font-light">
              Entdecken Sie unsere handverlesene Auswahl an Vorspeisen, die mit höchster Präzision und den feinsten Zutaten der Saison kreiert wurden.
            </p>
          </section>

          {/* Menu Grid */}
          <section className="divide-y divide-gray-100 lg:grid lg:grid-cols-2 lg:divide-y-0 lg:gap-x-8 lg:gap-y-12 lg:py-12">
            {menuItems.map((item) => (
              <div key={item.id} className="p-6 md:p-8 flex gap-4 group hover:bg-gray-50 transition-colors duration-300">
                <span className="item-number mt-1 shrink-0">{item.id}</span>
                <div className="flex-1">
                  <div className="flex justify-between items-start mb-3">
                    <h3 className="text-base font-medium tracking-wider uppercase pr-4">{item.title}</h3>
                    <span className="price-tag shrink-0 text-sm font-light">{item.price}</span>
                  </div>
                  <p className="menu-item-description text-sm mb-4">
                    {item.description}
                  </p>
                  {item.tag && (
                    <span className="inline-block px-3 py-0.5 border border-gray-100 rounded-full text-[9px] text-[#565d6d] font-light uppercase tracking-wider">
                      {item.tag}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </section>

          {/* Footer Info */}
          <footer className="py-12 px-6 text-center border-t border-gray-100">
            <p className="text-[10px] font-sans text-[#565d6d] tracking-[0.1em] leading-loose uppercase">
              Alle Preise in Euro inkl. Mehrwertsteuer.<br />
              Bei Allergien wenden Sie sich bitte an unser Personal.
            </p>
          </footer>
        </div>
      </main>

      {/* Bottom Navigation (Mobile/Tablet Only) */}
      <nav className="lg:hidden sticky bottom-0 bg-white border-t border-gray-100 shadow-[0px_-2px_10px_0px_rgba(0,0,0,0.05)] flex justify-around items-center h-16 px-2">
        <a href="#" className="flex flex-col items-center gap-1 flex-1">
          <img src="./assets/IMG_6.svg" alt="menu" className="w-6 h-6" />
          <span className="text-[10px] font-bold">Menü</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 flex-1 text-[#565d6d]">
          <img src="./assets/IMG_4.svg" alt="search" className="w-6 h-6 opacity-60" />
          <span className="text-[10px]">Suche</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 flex-1 text-[#565d6d] relative">
          <img src="./assets/IMG_5.svg" alt="cart" className="w-6 h-6 opacity-60" />
          <span className="text-[10px]">Warenkorb</span>
          <span className="absolute top-0 right-1/4 bg-[#E05252] text-white text-[8px] w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            9
          </span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 flex-1 text-[#565d6d]">
          <img src="./assets/IMG_7.svg" alt="info" className="w-6 h-6 opacity-60" />
          <span className="text-[10px]">Info</span>
        </a>
      </nav>

      {/* Desktop Footer (Additional context) */}
      <footer className="hidden lg:block bg-gray-50 border-t border-gray-100 py-12">
        <div className="max-w-7xl mx-auto px-8 grid grid-cols-4 gap-8">
          <div>
            <h4 className="text-xs font-bold mb-4">RESTAURANT</h4>
            <p className="text-sm text-gray-500 font-sans leading-relaxed">
              Feine Kulinarik in exklusivem Ambiente. Wir freuen uns auf Ihren Besuch.
            </p>
          </div>
          <div>
            <h4 className="text-xs font-bold mb-4">ÖFFNUNGSZEITEN</h4>
            <p className="text-sm text-gray-500 font-sans">Mo - Sa: 18:00 - 23:00<br />So: Ruhetag</p>
          </div>
          <div>
            <h4 className="text-xs font-bold mb-4">KONTAKT</h4>
            <p className="text-sm text-gray-500 font-sans">info@l-entree-fine.de<br />+49 (0) 123 456 789</p>
          </div>
          <div className="flex flex-col items-end">
            <div className="flex gap-4 mb-4">
              <Icon icon="ri:instagram-line" className="w-5 h-5 text-gray-400" />
              <Icon icon="ri:facebook-fill" className="w-5 h-5 text-gray-400" />
            </div>
            <p className="text-[10px] text-gray-400 font-sans uppercase tracking-widest">© 2024 L'Entrée Fine</p>
          </div>
        </div>
      </footer>
    </div>
  );
}