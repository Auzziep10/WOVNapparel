'use client';

import { useActionState } from 'react';
import { createTechPack } from '@/actions/techPackActions';

const initialState = {
  success: false,
  message: '',
};

export default function NewTechPackPage() {
  const [state, formAction, isPending] = useActionState(createTechPack, initialState);

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 p-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold tracking-tight mb-2">Ingest Tech Pack</h1>
        <p className="text-neutral-400 mb-8">
          Upload precise garment measurements to populate the 3D matching engine.
        </p>

        {state?.message && (
          <div className={`p-4 mb-6 rounded-lg ${state.success ? 'bg-emerald-900/50 text-emerald-200 border border-emerald-800' : 'bg-red-900/50 text-red-200 border border-red-800'}`}>
            {state.message}
          </div>
        )}

        <form action={formAction} className="space-y-6 bg-neutral-900 p-8 rounded-2xl border border-neutral-800 shadow-2xl">
          
          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-2">
              <label className="text-sm font-medium text-neutral-300">Garment Name</label>
              <input required name="name" type="text" placeholder="Heavyweight Box Tee" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium text-neutral-300">Base Size</label>
              <select required name="baseSize" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all">
                <option value="XS">XS</option>
                <option value="S">S</option>
                <option value="M" defaultValue="M">M</option>
                <option value="L">L</option>
                <option value="XL">XL</option>
              </select>
            </div>
          </div>

          <div className="pt-4 border-t border-neutral-800">
            <h3 className="text-lg font-semibold mb-4 text-neutral-200">Measurements (cm)</h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Bust/Chest</label>
                <input required name="bustCm" type="number" step="0.1" placeholder="110.0" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Waist</label>
                <input required name="waistCm" type="number" step="0.1" placeholder="108.0" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Hem</label>
                <input required name="hemCm" type="number" step="0.1" placeholder="108.0" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Sleeve Length</label>
                <input required name="sleeveLengthCm" type="number" step="0.1" placeholder="24.0" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-neutral-800">
            <h3 className="text-lg font-semibold mb-4 text-neutral-200">Material & Color</h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Stretch Coefficient</label>
                <input required name="stretchCoefficient" type="number" step="0.01" placeholder="1.15" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
                <p className="text-xs text-neutral-500">Multiplier representing fabric elasticity.</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-6 mt-4">
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">Colorway Name</label>
                <input required name="colorName" type="text" placeholder="Midnight Charcoal" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium text-neutral-300">CIELAB Values</label>
                <input required name="dominantLab" type="text" placeholder="25.0, 0.0, -2.0" className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-4 py-3 text-neutral-100 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all" />
                <p className="text-xs text-neutral-500">Comma separated L, a, b format.</p>
              </div>
            </div>
          </div>

          <button 
            type="submit" 
            disabled={isPending}
            className="w-full bg-blue-600 hover:bg-blue-500 text-white font-semibold py-4 px-6 rounded-xl transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-blue-900/20"
          >
            {isPending ? 'Syncing to Firebase...' : 'Ingest to Database'}
          </button>
        </form>
      </div>
    </div>
  );
}
