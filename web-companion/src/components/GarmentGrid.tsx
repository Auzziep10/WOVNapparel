'use client';

import React, { useState } from 'react';
import DeleteButton from './DeleteButton';

export default function GarmentGrid({ techPacks }: { techPacks: any[] }) {
  const [selectedPack, setSelectedPack] = useState<any | null>(null);

  const formatMeasurement = (cm: any, originalUnit: string = 'cm') => {
    if (cm === undefined || cm === null || cm === '') return '--';
    const num = typeof cm === 'string' ? parseFloat(cm) : cm;
    if (isNaN(num)) return cm;
    if (originalUnit === 'in') {
      const inches = num / 2.54;
      return `${parseFloat(inches.toFixed(2))}"`;
    }
    return `${parseFloat(num.toFixed(2))} cm`;
  };

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {techPacks.map((pack) => (
          <div 
            key={pack.id} 
            onClick={() => setSelectedPack(pack)}
            className="group relative flex flex-col bg-zinc-900/50 rounded-3xl border border-white/10 overflow-hidden hover:bg-zinc-800/50 transition-all duration-300 hover:shadow-[0_0_40px_rgba(0,0,0,0.5)] hover:-translate-y-1 cursor-pointer"
          >
            {/* Image Container */}
            <div className="aspect-[4/5] w-full relative bg-zinc-950 overflow-hidden">
              <div onClick={(e) => e.stopPropagation()}>
                <DeleteButton id={pack.id} />
              </div>

              {pack.renderUrl ? (
                <img 
                  src={pack.renderUrl} 
                  alt={pack.name} 
                  className="w-full h-full object-cover opacity-80 group-hover:opacity-100 transition-opacity duration-500 group-hover:scale-105"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-zinc-800">
                  <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>
                </div>
              )}
              
              {/* Size Badges */}
              <div className="absolute top-4 right-4 flex flex-col gap-1.5 items-end">
                <div className="bg-black/60 backdrop-blur-md px-3 py-1 rounded-full border border-white/10 text-[10px] font-bold tracking-wider text-white">
                  BASE: {pack.baseSize}
                </div>
                {pack.matrices?.chest?.grades && Object.keys(pack.matrices.chest.grades).length > 0 && (
                  <div className="bg-blue-600/80 backdrop-blur-md px-3 py-1 rounded-full border border-white/10 text-[10px] font-bold tracking-wider text-white shadow-[0_0_10px_rgba(37,99,235,0.4)]">
                    {Object.keys(pack.matrices.chest.grades).length} SIZES MATRIX
                  </div>
                )}
              </div>
              
              {/* Subtle Gradient Overlay */}
              <div className="absolute inset-0 bg-gradient-to-t from-zinc-950 via-transparent to-transparent opacity-90 pointer-events-none" />
            </div>

            {/* Content */}
            <div className="absolute bottom-0 left-0 w-full p-6 flex flex-col justify-end pointer-events-none">
              <h3 className="text-xl font-bold text-white mb-1 drop-shadow-md line-clamp-1">{pack.name}</h3>
              <div className="flex items-center gap-2 text-xs text-zinc-400 mb-4 font-medium uppercase tracking-wider">
                <span className="flex items-center gap-1.5">
                  <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.8)]" />
                  Database Synced
                </span>
              </div>

              {/* Measurement Data Grid */}
              <div className="grid grid-cols-2 gap-2 mt-auto">
                <div className="bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl p-3 flex flex-col justify-center">
                  <span className="text-[10px] text-zinc-500 uppercase tracking-widest font-bold mb-1 flex items-center gap-1">
                    Chest
                    {pack.matrices?.chest?.grades && (
                       <span className="text-[8px] bg-white/10 px-1 rounded text-zinc-400">GRADED</span>
                    )}
                  </span>
                  <span className="text-zinc-100 font-mono text-sm">{formatMeasurement(pack.measurements?.bustCm, pack.globalUnit)}</span>
                </div>
                <div className="bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl p-3 flex flex-col justify-center">
                  <span className="text-[10px] text-zinc-500 uppercase tracking-widest font-bold mb-1 flex items-center gap-1">
                    Length
                    {pack.matrices?.hem?.grades && (
                       <span className="text-[8px] bg-white/10 px-1 rounded text-zinc-400">GRADED</span>
                    )}
                  </span>
                  <span className="text-zinc-100 font-mono text-sm">{formatMeasurement(pack.measurements?.hemCm, pack.globalUnit)}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Raw Data Overlay Modal */}
      {selectedPack && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/80 backdrop-blur-sm" onClick={() => setSelectedPack(null)}>
          <div className="bg-zinc-950 border border-white/10 rounded-3xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <div className="px-6 py-4 border-b border-white/10 flex justify-between items-center bg-zinc-900/50">
              <h2 className="text-xl font-bold text-white flex items-center gap-3">
                <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span>
                {selectedPack.name} - Sync Payload
              </h2>
              <button onClick={() => setSelectedPack(null)} className="text-zinc-500 hover:text-white p-2">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-6 bg-zinc-950">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    {/* Key Attributes Visualizer */}
                    <div className="bg-zinc-900/30 border border-white/5 rounded-2xl p-5">
                        <h3 className="text-sm uppercase tracking-wider text-zinc-500 font-bold mb-4">Core Properties</h3>
                        <div className="space-y-3">
                            <div className="flex justify-between border-b border-white/5 pb-2">
                                <span className="text-zinc-400">Garment Type</span>
                                <span className="text-white font-medium">{selectedPack.garmentType || 'N/A'}</span>
                            </div>
                            <div className="flex justify-between border-b border-white/5 pb-2">
                                <span className="text-zinc-400">Occasion</span>
                                <span className="text-blue-400 font-medium">{selectedPack.occasion || 'N/A'}</span>
                            </div>
                            <div className="flex justify-between border-b border-white/5 pb-2">
                                <span className="text-zinc-400">Audience</span>
                                <span className="text-white font-medium">{selectedPack.audience || 'N/A'}</span>
                            </div>
                        </div>
                    </div>

                    {/* Colorways Visualizer */}
                    <div className="bg-zinc-900/30 border border-white/5 rounded-2xl p-5">
                        <h3 className="text-sm uppercase tracking-wider text-zinc-500 font-bold mb-4">Dominant Colorways</h3>
                        {selectedPack.dominantColorways && selectedPack.dominantColorways.length > 0 ? (
                            <div className="flex flex-col gap-3 max-h-40 overflow-y-auto pr-2">
                                {selectedPack.dominantColorways.map((cw: any, idx: number) => (
                                    <div key={idx} className="flex items-center gap-3 bg-white/5 p-2 rounded-xl">
                                        {cw.image && (
                                            <div className="w-10 h-10 rounded-lg bg-zinc-900 overflow-hidden shrink-0 border border-white/10">
                                                <img src={cw.image} alt={cw.name} className="w-full h-full object-cover" />
                                            </div>
                                        )}
                                        <div className="flex-1 min-w-0">
                                            <div className="text-white font-bold text-sm truncate">{cw.name}</div>
                                            <div className="text-[10px] text-zinc-500 font-mono">LAB: {cw.lab?.map((v: any) => v?.toFixed(1)).join(', ')}</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-zinc-500 text-sm italic">No colorways extracted.</div>
                        )}
                    </div>

                    {/* Graded Matrices Visualizer */}
                    <div className="bg-zinc-900/30 border border-white/5 rounded-2xl p-5">
                        <h3 className="text-sm uppercase tracking-wider text-zinc-500 font-bold mb-4">Graded Matrices</h3>
                        {selectedPack.matrices && Object.keys(selectedPack.matrices).length > 0 ? (
                            <div className="flex flex-col gap-4 max-h-40 overflow-y-auto pr-2">
                                {Object.entries(selectedPack.matrices).map(([key, data]: [string, any]) => (
                                    <div key={key} className="flex flex-col gap-2">
                                        <div className="text-xs text-white uppercase tracking-wider font-bold border-b border-white/10 pb-1">{key}</div>
                                        {data.grades && Object.keys(data.grades).length > 0 ? (
                                            <div className="flex flex-wrap gap-2">
                                                {Object.entries(data.grades).map(([size, val]: [string, any]) => (
                                                    <div key={size} className="flex items-center bg-black/40 rounded-lg overflow-hidden border border-white/5 text-[10px] font-mono">
                                                        <span className="bg-white/10 px-2 py-1 text-zinc-300 font-bold border-r border-white/5">{size}</span>
                                                        <span className="px-2 py-1 text-white">{formatMeasurement(val, selectedPack.globalUnit)}</span>
                                                    </div>
                                                ))}
                                            </div>
                                        ) : (
                                            <div className="text-[10px] text-zinc-500 italic">No grades defined</div>
                                        )}
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-zinc-500 text-sm italic">No matrices defined.</div>
                        )}
                    </div>
                </div>

                <div className="bg-zinc-900/80 border border-white/10 rounded-2xl p-4 overflow-hidden">
                    <h3 className="text-xs uppercase tracking-widest text-zinc-500 font-bold mb-3 pl-2">Raw JSON Payload</h3>
                    <pre className="text-xs text-green-400 font-mono overflow-x-auto bg-black p-4 rounded-xl leading-relaxed">
                        {JSON.stringify(selectedPack, null, 2)}
                    </pre>
                </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
