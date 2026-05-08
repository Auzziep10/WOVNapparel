import { db } from '@/lib/firebase';
import Link from 'next/link';

export const revalidate = 0; // Force dynamic rendering so it always pulls live data

async function getTechPacks() {
  const snapshot = await db.collection('tech_packs').orderBy('importedAt', 'desc').get();
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}

export default async function TechPacksLibrary() {
  const techPacks = await getTechPacks();

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold tracking-tight mb-2">Tech Pack Library</h1>
            <p className="text-neutral-400">
              Garments synced from the Tech Pack Creator ecosystem.
            </p>
          </div>
          <Link 
            href="/dashboard/tech-packs/new" 
            className="bg-blue-600 hover:bg-blue-500 text-white px-4 py-2 rounded-lg font-medium transition-colors"
          >
            + Manual Ingest
          </Link>
        </div>

        {techPacks.length === 0 ? (
          <div className="text-center py-20 border border-neutral-800 rounded-2xl bg-neutral-900/50">
            <h3 className="text-xl font-semibold text-neutral-300 mb-2">No Tech Packs Found</h3>
            <p className="text-neutral-500">Sync a garment from the Tech Pack Creator or ingest one manually.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {techPacks.map((pack: any) => (
              <div key={pack.id} className="bg-neutral-900 border border-neutral-800 rounded-2xl overflow-hidden hover:border-neutral-700 transition-all shadow-xl">
                <div className="h-48 bg-neutral-800 flex items-center justify-center relative">
                  {pack.renderUrl ? (
                    <img src={pack.renderUrl} alt={pack.name} className="w-full h-full object-cover opacity-80" />
                  ) : (
                    <div className="text-neutral-600 text-5xl">👕</div>
                  )}
                  {pack.source === 'tech_pack_creator_legacy' && (
                    <div className="absolute top-3 right-3 bg-blue-900/80 text-blue-200 text-xs px-2 py-1 rounded border border-blue-700/50 backdrop-blur-sm">
                      Synced
                    </div>
                  )}
                </div>
                <div className="p-5">
                  <h3 className="text-lg font-bold mb-1 truncate">{pack.name}</h3>
                  <div className="flex gap-2 mb-4">
                    <span className="text-xs bg-neutral-800 text-neutral-300 px-2 py-1 rounded">Base Size: {pack.baseSize}</span>
                    <span className="text-xs bg-neutral-800 text-neutral-300 px-2 py-1 rounded">Stretch: {pack.fabricProperties?.stretchCoefficient}</span>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-2 text-sm text-neutral-400 mb-4 bg-neutral-950 p-3 rounded-lg border border-neutral-800/50">
                    <div className="text-center">
                      <div className="text-xs text-neutral-500 mb-1">Bust</div>
                      <div className="font-mono text-neutral-200">{pack.measurements?.bustCm}</div>
                    </div>
                    <div className="text-center border-l border-r border-neutral-800">
                      <div className="text-xs text-neutral-500 mb-1">Waist</div>
                      <div className="font-mono text-neutral-200">{pack.measurements?.waistCm}</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xs text-neutral-500 mb-1">Hem</div>
                      <div className="font-mono text-neutral-200">{pack.measurements?.hemCm}</div>
                    </div>
                  </div>
                  
                  <div className="text-xs text-neutral-600 font-mono truncate">
                    ID: {pack.id}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
