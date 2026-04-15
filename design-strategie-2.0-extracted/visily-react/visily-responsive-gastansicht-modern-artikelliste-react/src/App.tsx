import { Icon } from '@iconify/react';

export default function App() {
  const categories = ['Alle', 'Burger', 'Pizza', 'Salate', 'Bowls', 'Pasta'];

  const dishes = [
    {
      id: 1,
      name: 'Trüffel-Burger Deluxe',
      price: '18,50 €',
      description: 'Saftiges Angus-Rind mit schwarzem Trüffel, karamellisierten Zwiebeln und Rucola.',
      calories: '850 kcal',
      time: '15-20 Min',
      image: './assets/IMG_7.jpeg',
      tag: 'Beliebt',
      tagIcon: 'lucide:star',
    },
    {
      id: 2,
      name: "Gegrillter Lachs 'Teriyaki'",
      price: '22,90 €',
      description: 'Frisches Lachsfilet in hausgemachter Teriyaki-Glasur auf wildem Reis.',
      calories: '620 kcal',
      time: '25 Min',
      image: './assets/IMG_11.jpeg',
      tag: 'Neu',
      tagColor: 'bg-[#DD3C71]',
    },
    {
      id: 3,
      name: "Quinoa-Bowl 'Avocado'",
      price: '14,00 €',
      description: 'Bunte Bowl mit Quinoa, reifer Avocado, Kichererbsen und Zitronen-Dressing.',
      calories: '450 kcal',
      time: '10 Min',
      image: './assets/IMG_12.jpeg',
    },
    {
      id: 4,
      name: 'Pizza Diavola',
      price: '13,50 €',
      description: 'Scharfe Salami, Peperoni und Mozzarella auf Steinofen-Teig.',
      calories: '920 kcal',
      time: '12 Min',
      image: './assets/IMG_13.jpeg',
      tag: 'Scharf',
      tagIcon: 'lucide:flame',
      tagColor: 'bg-[#E05252]',
    },
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col font-sans text-[#171a1f]">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-white border-b border-[#dee1e6]">
        {/* Status Bar Placeholder (Mobile Only) */}
        <div className="h-10 flex justify-between items-center px-4 lg:hidden">
          <img src="./assets/IMG_1.svg" alt="time" className="h-10 w-auto" />
          <img src="./assets/IMG_2.svg" alt="status" className="h-10 w-auto" />
        </div>

        <div className="max-w-7xl mx-auto w-full px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <Icon icon="lucide:chevron-left" className="w-6 h-6" />
            </button>
            <h1 className="text-xl font-semibold font-serif">Hauptspeisen</h1>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <Icon icon="lucide:search" className="w-6 h-6" />
            </button>
            <button className="p-2 hover:bg-gray-100 rounded-full transition-colors relative">
              <Icon icon="lucide:shopping-cart" className="w-6 h-6" />
              <span className="absolute top-1 right-1 bg-[#DD3C71] text-white text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full">
                2
              </span>
            </button>
            {/* Desktop Navigation */}
            <nav className="hidden lg:flex items-center gap-6 ml-8">
              <a href="#" className="font-medium text-[#DD3C71]">Speisekarte</a>
              <a href="#" className="font-medium hover:text-[#DD3C71] transition-colors">Bestellungen</a>
              <a href="#" className="font-medium hover:text-[#DD3C71] transition-colors">Profil</a>
            </nav>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-6 pb-24 lg:pb-12">
        {/* Section Title */}
        <div className="flex items-center gap-4 mb-6">
          <h2 className="text-xl lg:text-2xl font-black font-serif uppercase tracking-tight whitespace-nowrap">
            Unsere Favoriten
          </h2>
          <div className="h-1 flex-1 bg-[#f3f4f6] rounded-full" />
        </div>

        {/* Categories Scrollable */}
        <div className="flex gap-3 overflow-x-auto hide-scrollbar pb-4 mb-6 -mx-4 px-4 lg:mx-0 lg:px-0">
          {categories.map((cat, idx) => (
            <button
              key={cat}
              className={`px-6 py-2 rounded-full whitespace-nowrap font-serif font-medium text-sm transition-all shadow-sm
                ${idx === 0 
                  ? 'bg-[#DD3C71] text-white border border-[#DD3C71]' 
                  : 'bg-[#fafafb] text-[#565d6d] hover:bg-gray-100'}`}
            >
              {cat}
            </button>
          ))}
          <button className="p-2 bg-[#fafafb] rounded-full min-w-[40px] flex items-center justify-center">
            <img src="./assets/IMG_6.svg" alt="filter" className="w-4 h-4" />
          </button>
        </div>

        {/* Dish Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {dishes.map((dish) => (
            <div key={dish.id} className="bg-white rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-shadow border border-gray-100 flex flex-col">
              {/* Image Container */}
              <div className="relative h-56 w-full overflow-hidden">
                <img 
                  src={dish.image} 
                  alt={dish.name} 
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-0 left-0 w-full h-12 bg-gradient-to-b from-black/40 to-transparent" />
                
                {/* Top Left Tag */}
                {dish.tag && (
                  <div className={`absolute top-3 left-3 px-3 py-1 rounded-full flex items-center gap-1 shadow-sm ${dish.tagColor || 'bg-white/90'}`}>
                    {dish.tagIcon && <Icon icon={dish.tagIcon} className={`w-3 h-3 ${dish.tagColor ? 'text-white' : 'text-[#171a1f]'}`} />}
                    <span className={`text-[10px] font-bold uppercase tracking-wider font-serif ${dish.tagColor ? 'text-white' : 'text-[#171a1f]'}`}>
                      {dish.tag}
                    </span>
                  </div>
                )}

                {/* Time Badge */}
                <div className="absolute bottom-3 right-3 bg-white/90 backdrop-blur-sm px-3 py-1 rounded-full flex items-center gap-1.5 shadow-sm">
                  <Icon icon="lucide:clock" className="w-3 h-3 text-[#DD3C71]" />
                  <span className="text-[10px] font-bold font-serif">{dish.time}</span>
                </div>
              </div>

              {/* Content */}
              <div className="p-4 flex-1 flex flex-col">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="text-lg font-bold font-serif leading-tight">{dish.name}</h3>
                  <span className="text-lg font-black font-serif text-[#DD3C71] whitespace-nowrap ml-2">
                    {dish.price}
                  </span>
                </div>
                <p className="text-sm text-[#565d6d] font-serif leading-relaxed mb-4 flex-1">
                  {dish.description}
                </p>
                
                <div className="pt-3 border-t border-[#dee1e6]/50 flex justify-between items-center">
                  <span className="text-[11px] font-medium text-[#565d6d] font-serif">{dish.calories}</span>
                  <button className="flex items-center gap-1 text-[#DD3C71] font-bold text-sm font-serif hover:underline">
                    Details ansehen
                    <Icon icon="lucide:chevron-right" className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Special Offer Card */}
        <div className="mt-8 relative bg-[#EDFDF4] rounded-2xl p-4 border border-[#DD3C71]/20 shadow-sm overflow-hidden flex items-center gap-4">
          <div className="absolute top-0 right-10 bg-[#DD3C71] px-3 py-1 rounded-b-lg">
            <span className="text-[8px] font-black text-white uppercase font-serif">Angebot</span>
          </div>
          
          <div className="w-16 h-16 rounded-xl overflow-hidden shadow-sm flex-shrink-0">
            <img src="./assets/IMG_15.jpeg" alt="Special" className="w-full h-full object-cover" />
          </div>

          <div className="flex-1">
            <h4 className="text-sm font-bold font-serif">Heutiges Special</h4>
            <p className="text-xs text-[#565d6d] font-serif">BBQ Ribs mit Coleslaw</p>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-sm font-bold text-[#DD3C71] font-serif">Nur 12,90 €</span>
              <span className="text-[10px] text-[#565d6d] line-through font-serif">16,50 €</span>
            </div>
          </div>

          <button className="w-10 h-10 bg-[#DD3C71] rounded-full flex items-center justify-center text-white shadow-md hover:scale-105 transition-transform">
            <Icon icon="lucide:shopping-cart" className="w-5 h-5" />
          </button>
        </div>
      </main>

      {/* Bottom Navigation (Mobile Only) */}
      <nav className="lg:hidden fixed bottom-0 left-0 w-full bg-white border-t border-[#dee1e6] h-16 flex items-center justify-around px-4 z-50 shadow-[0_-4px_12px_rgba(0,0,0,0.05)]">
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <Icon icon="lucide:book-open" className="w-6 h-6" />
          <span className="text-[10px] font-serif">Home</span>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d] relative">
          <Icon icon="lucide:shopping-cart" className="w-6 h-6" />
          <span className="text-[10px] font-serif">Warenkorb</span>
          <div className="absolute -top-1 right-2 bg-[#E05252] text-white text-[8px] font-bold w-4 h-4 flex items-center justify-center rounded-full border-2 border-white">
            9
          </div>
        </a>
        <a href="#" className="flex flex-col items-center gap-1 text-[#565d6d]">
          <Icon icon="lucide:user" className="w-6 h-6" />
          <span className="text-[10px] font-serif">Profil</span>
        </a>
      </nav>
    </div>
  );
}