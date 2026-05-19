import { db } from '@/lib/firebase';
import Image from 'next/image';
import DeleteButton from '@/components/DeleteButton';
import GarmentGrid from '@/components/GarmentGrid';

export const revalidate = 0; // Force dynamic to always show the latest syncs

export default async function Dashboard() {
  let techPacks: any[] = [];
  try {
    // Fetch all synced tech packs from Firestore, newest first
    const snapshot = await db.collection('tech_packs').orderBy('importedAt', 'desc').get();
    techPacks = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error("Failed to fetch tech packs", e);
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-white font-sans selection:bg-blue-500/30">
      {/* Dynamic Glassmorphism Header */}
      <header className="sticky top-0 z-50 bg-zinc-950/60 backdrop-blur-xl border-b border-white/10 px-8 py-5 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-400 flex items-center justify-center shadow-[0_0_20px_rgba(37,99,235,0.4)]">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" className="text-white"><path d="M4 22h14a2 2 0 0 0 2-2V7l-5-5H6a2 2 0 0 0-2 2v4"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M3 15h6"/><path d="M3 18h6"/></svg>
          </div>
          <h1 className="text-xl font-bold tracking-tight text-zinc-100">WOVN <span className="text-zinc-500 font-medium">Companion</span></h1>
        </div>
        <div className="flex items-center gap-4">
          <div className="text-sm text-zinc-400">
            {techPacks.length} Garments Synced
          </div>
          <div className="h-8 w-8 rounded-full bg-zinc-800 border border-white/10 overflow-hidden relative">
            {/* Avatar placeholder */}
            <div className="absolute inset-0 bg-gradient-to-br from-zinc-700 to-zinc-900" />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-8 py-12">
        <div className="mb-12">
          <h2 className="text-4xl font-extrabold tracking-tight mb-3 bg-clip-text text-transparent bg-gradient-to-r from-white to-zinc-500">
            Synced Inventory
          </h2>
          <p className="text-zinc-400 text-lg">
            Garments synced directly from the Tech Pack OS for immediate iOS matching.
          </p>
        </div>

        {techPacks.length === 0 ? (
          <div className="w-full rounded-3xl border border-dashed border-white/10 bg-white/[0.02] p-20 flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-6">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-zinc-500"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" x2="12" y1="3" y2="15"/></svg>
            </div>
            <h3 className="text-xl font-semibold text-zinc-200 mb-2">No Garments Found</h3>
            <p className="text-zinc-500 max-w-sm">
              Head over to your Tech Pack Creator website and hit "Sync to WOVN" to populate this dashboard.
            </p>
          </div>
        ) : (
          <GarmentGrid techPacks={techPacks} />
        )}
      </main>
    </div>
  );
}
