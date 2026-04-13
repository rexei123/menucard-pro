'use client';

import { useState, useEffect } from 'react';

/* ──────────────────────────────────────────
   Types
   ────────────────────────────────────────── */
type SubNavItem = {
  key: string;
  label: string;
  icon: string;
};

const subNavItems: SubNavItem[] = [
  { key: 'general', label: 'Allgemein', icon: 'tune' },
  { key: 'language', label: 'Sprache & Region', icon: 'translate' },
  { key: 'account', label: 'Konto', icon: 'person' },
  { key: 'about', label: 'Über MenuCard Pro', icon: 'info' },
];

/* ──────────────────────────────────────────
   Hilfsfunktionen
   ────────────────────────────────────────── */
function SectionCard({ title, description, children }: { title: string; description?: string; children: React.ReactNode }) {
  return (
    <div
      className="rounded-xl p-6 mb-5"
      style={{ backgroundColor: '#FFFFFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
    >
      <h3 className="text-base font-bold mb-1" style={{ fontFamily: "'Inter', sans-serif", color: '#171A1F' }}>
        {title}
      </h3>
      {description && (
        <p className="text-sm mb-4" style={{ color: '#999' }}>{description}</p>
      )}
      {children}
    </div>
  );
}

function SettingRow({ label, description, children }: { label: string; description?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-6 py-3" style={{ borderBottom: '1px solid #F3F3F6' }}>
      <div className="flex-1">
        <div className="text-sm font-medium" style={{ color: '#171A1F' }}>{label}</div>
        {description && <div className="text-xs mt-0.5" style={{ color: '#999' }}>{description}</div>}
      </div>
      <div className="flex-shrink-0">{children}</div>
    </div>
  );
}

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!checked)}
      className="relative w-10 h-5 rounded-full transition-colors duration-200"
      style={{ backgroundColor: checked ? '#DD3C71' : '#DEE1E6' }}
    >
      <div
        className="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform duration-200"
        style={{ transform: checked ? 'translateX(22px)' : 'translateX(2px)' }}
      />
    </button>
  );
}

/* ──────────────────────────────────────────
   Tab-Inhalte
   ────────────────────────────────────────── */
function GeneralSettings() {
  const [hotelName, setHotelName] = useState('Hotel Sonnblick');
  const [location, setLocation] = useState('Saalbach, Österreich');
  const [showSoldOut, setShowSoldOut] = useState(true);
  const [showAllergens, setShowAllergens] = useState(true);
  const [showDescriptions, setShowDescriptions] = useState(true);
  const [saved, setSaved] = useState(false);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <>
      <SectionCard title="Hotel-Informationen" description="Grundlegende Angaben zu Ihrem Betrieb">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Hotelname</label>
            <input
              type="text"
              value={hotelName}
              onChange={e => setHotelName(e.target.value)}
              className="w-full px-3 py-2 rounded-lg text-sm outline-none transition-colors"
              style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif" }}
              onFocus={e => (e.currentTarget.style.borderColor = '#DD3C71')}
              onBlur={e => (e.currentTarget.style.borderColor = '#DEE1E6')}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Standort</label>
            <input
              type="text"
              value={location}
              onChange={e => setLocation(e.target.value)}
              className="w-full px-3 py-2 rounded-lg text-sm outline-none transition-colors"
              style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif" }}
              onFocus={e => (e.currentTarget.style.borderColor = '#DD3C71')}
              onBlur={e => (e.currentTarget.style.borderColor = '#DEE1E6')}
            />
          </div>
        </div>
      </SectionCard>

      <SectionCard title="Anzeige-Optionen" description="Steuern Sie, was Ihren Gästen angezeigt wird">
        <SettingRow label="Ausverkaufte Produkte anzeigen" description="Zeigt ausverkaufte Artikel ausgegraut in der Karte">
          <Toggle checked={showSoldOut} onChange={setShowSoldOut} />
        </SettingRow>
        <SettingRow label="Allergene anzeigen" description="Allergen-Codes werden bei jedem Produkt eingeblendet">
          <Toggle checked={showAllergens} onChange={setShowAllergens} />
        </SettingRow>
        <SettingRow label="Kurzbeschreibungen anzeigen" description="Produktbeschreibungen in der Listenansicht">
          <Toggle checked={showDescriptions} onChange={setShowDescriptions} />
        </SettingRow>
      </SectionCard>

      <div className="flex justify-end">
        <button
          onClick={handleSave}
          className="flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors"
          style={{ backgroundColor: saved ? '#22C55E' : '#DD3C71', color: '#FFF' }}
          onMouseEnter={e => { if (!saved) e.currentTarget.style.backgroundColor = '#C42D60'; }}
          onMouseLeave={e => { if (!saved) e.currentTarget.style.backgroundColor = '#DD3C71'; }}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 16 }}>
            {saved ? 'check_circle' : 'save'}
          </span>
          {saved ? 'Gespeichert!' : 'Speichern'}
        </button>
      </div>
    </>
  );
}

function LanguageSettings() {
  const [defaultLang, setDefaultLang] = useState('de');
  const [autoTranslate, setAutoTranslate] = useState(true);
  const [currency, setCurrency] = useState('EUR');

  return (
    <>
      <SectionCard title="Sprache" description="Standard-Sprache und Übersetzungseinstellungen">
        <div className="space-y-4 mb-2">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Standard-Sprache</label>
            <select
              value={defaultLang}
              onChange={e => setDefaultLang(e.target.value)}
              className="w-full px-3 py-2 rounded-lg text-sm outline-none"
              style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif", backgroundColor: '#FFF' }}
            >
              <option value="de">Deutsch</option>
              <option value="en">English</option>
            </select>
          </div>
        </div>
        <SettingRow label="Auto-Übersetzung" description="Neue Produkte automatisch in alle Sprachen übersetzen">
          <Toggle checked={autoTranslate} onChange={setAutoTranslate} />
        </SettingRow>
      </SectionCard>

      <SectionCard title="Region" description="Währung und Formatierung">
        <div>
          <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Währung</label>
          <select
            value={currency}
            onChange={e => setCurrency(e.target.value)}
            className="w-full px-3 py-2 rounded-lg text-sm outline-none"
            style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif", backgroundColor: '#FFF' }}
          >
            <option value="EUR">Euro (€)</option>
            <option value="CHF">Schweizer Franken (CHF)</option>
          </select>
        </div>
      </SectionCard>
    </>
  );
}

function AccountSettings() {
  return (
    <>
      <SectionCard title="Konto" description="Ihr Admin-Konto verwalten">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>E-Mail</label>
            <input
              type="email"
              value="admin@hotel-sonnblick.at"
              readOnly
              className="w-full px-3 py-2 rounded-lg text-sm"
              style={{ border: '1px solid #DEE1E6', color: '#999', backgroundColor: '#F9FAFB', fontFamily: "'Inter', sans-serif" }}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Rolle</label>
            <div className="flex items-center gap-2">
              <span
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold"
                style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 14 }}>shield</span>
                Administrator
              </span>
            </div>
          </div>
        </div>
      </SectionCard>

      <SectionCard title="Passwort ändern">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Aktuelles Passwort</label>
            <input
              type="password"
              placeholder="••••••••"
              className="w-full px-3 py-2 rounded-lg text-sm outline-none transition-colors"
              style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif" }}
              onFocus={e => (e.currentTarget.style.borderColor = '#DD3C71')}
              onBlur={e => (e.currentTarget.style.borderColor = '#DEE1E6')}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#565D6D' }}>Neues Passwort</label>
            <input
              type="password"
              placeholder="••••••••"
              className="w-full px-3 py-2 rounded-lg text-sm outline-none transition-colors"
              style={{ border: '1px solid #DEE1E6', color: '#171A1F', fontFamily: "'Inter', sans-serif" }}
              onFocus={e => (e.currentTarget.style.borderColor = '#DD3C71')}
              onBlur={e => (e.currentTarget.style.borderColor = '#DEE1E6')}
            />
          </div>
        </div>
        <div className="flex justify-end mt-4">
          <button
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
            style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#C42D60')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#DD3C71')}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>lock</span>
            Passwort ändern
          </button>
        </div>
      </SectionCard>
    </>
  );
}

function AboutSection() {
  const stats = [
    { label: 'Version', value: '1.0.0', icon: 'tag' },
    { label: 'Framework', value: 'Next.js 14', icon: 'code' },
    { label: 'Datenbank', value: 'PostgreSQL', icon: 'database' },
    { label: 'Templates', value: '4 verfügbar', icon: 'palette' },
  ];

  return (
    <>
      <SectionCard title="MenuCard Pro" description="Digitale Speise- und Getränkekarten">
        <div className="grid grid-cols-2 gap-4 mb-4">
          {stats.map((s, i) => (
            <div
              key={i}
              className="flex items-center gap-3 p-3 rounded-lg"
              style={{ backgroundColor: '#F9FAFB' }}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#DD3C71' }}>{s.icon}</span>
              <div>
                <div className="text-[11px] uppercase tracking-wider font-medium" style={{ color: '#999' }}>{s.label}</div>
                <div className="text-sm font-semibold" style={{ color: '#171A1F' }}>{s.value}</div>
              </div>
            </div>
          ))}
        </div>

        <div
          className="flex items-center gap-3 p-4 rounded-lg"
          style={{ backgroundColor: '#FDF2F5', border: '1px solid rgba(221,60,113,0.12)' }}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 24, color: '#DD3C71' }}>hotel</span>
          <div>
            <div className="text-sm font-bold" style={{ color: '#171A1F' }}>Hotel Sonnblick</div>
            <div className="text-xs" style={{ color: '#565D6D' }}>Saalbach, Österreich</div>
          </div>
        </div>
      </SectionCard>

      <SectionCard title="System-Status">
        <div className="space-y-2">
          {[
            { label: 'Server', status: 'Online', ok: true },
            { label: 'Datenbank', status: 'Verbunden', ok: true },
            { label: 'Bildverarbeitung', status: 'Aktiv (Sharp)', ok: true },
            { label: 'Auto-Übersetzung', status: 'Bereit', ok: true },
          ].map((item, i) => (
            <div key={i} className="flex items-center justify-between py-2" style={{ borderBottom: '1px solid #F3F3F6' }}>
              <span className="text-sm" style={{ color: '#565D6D' }}>{item.label}</span>
              <span className="flex items-center gap-1.5 text-xs font-medium" style={{ color: item.ok ? '#22C55E' : '#EF4444' }}>
                <span
                  className="w-2 h-2 rounded-full"
                  style={{ backgroundColor: item.ok ? '#22C55E' : '#EF4444' }}
                />
                {item.status}
              </span>
            </div>
          ))}
        </div>
      </SectionCard>
    </>
  );
}

/* ──────────────────────────────────────────
   HAUPTSEITE
   ────────────────────────────────────────── */
export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState('general');

  const renderContent = () => {
    switch (activeTab) {
      case 'general': return <GeneralSettings />;
      case 'language': return <LanguageSettings />;
      case 'account': return <AccountSettings />;
      case 'about': return <AboutSection />;
      default: return <GeneralSettings />;
    }
  };

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1
          className="text-2xl font-bold mb-1"
          style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
        >
          Einstellungen
        </h1>
        <p className="text-sm" style={{ color: '#565D6D' }}>
          Verwalten Sie Ihre Hotel- und System-Einstellungen
        </p>
      </div>

      <div className="flex gap-8">
        {/* Sub-Navigation */}
        <nav className="flex-shrink-0 w-48">
          <div className="space-y-0.5">
            {subNavItems.map(item => (
              <button
                key={item.key}
                onClick={() => setActiveTab(item.key)}
                className="w-full flex items-center gap-2.5 px-3 py-2.5 rounded-lg text-sm text-left transition-colors"
                style={{
                  backgroundColor: activeTab === item.key ? '#FDF2F5' : 'transparent',
                  color: activeTab === item.key ? '#DD3C71' : '#565D6D',
                  fontWeight: activeTab === item.key ? 600 : 400,
                }}
                onMouseEnter={e => {
                  if (activeTab !== item.key) e.currentTarget.style.backgroundColor = '#F9FAFB';
                }}
                onMouseLeave={e => {
                  if (activeTab !== item.key) e.currentTarget.style.backgroundColor = 'transparent';
                }}
              >
                <span
                  className="material-symbols-outlined"
                  style={{
                    fontSize: 18,
                    color: activeTab === item.key ? '#DD3C71' : '#999',
                  }}
                >
                  {item.icon}
                </span>
                {item.label}
              </button>
            ))}
          </div>
        </nav>

        {/* Content Area */}
        <div className="flex-1 min-w-0">
          {renderContent()}
        </div>
      </div>
    </div>
  );
}
