export default function ItemsIndexPage() {
  return (
    <div className="flex h-full items-center justify-center">
      <div className="text-center">
        <p className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>inventory_2</span></p>
        <h2 className="text-xl font-semibold text-gray-400">Produkt auswählen</h2>
        <p className="text-base text-gray-300 mt-1">Wähle ein Produkt aus der Liste links</p>
      </div>
    </div>
  );
}
