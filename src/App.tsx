import React, { useState } from 'react';
import { ScreenId } from './types';
import SpecsViewer from './components/SpecsViewer';
import MobileSimulator from './components/MobileSimulator';
import { 
  Compass, 
  MapPin, 
  BookOpen, 
  Sparkles, 
  Layers, 
  GitFork, 
  ShieldAlert,
  Tv,
  Globe
} from 'lucide-react';

export default function App() {
  const [currentScreenId, setCurrentScreenId] = useState<ScreenId>('splash');

  // Handle bidirectional sync updates
  const handleSelectScreen = (id: ScreenId) => {
    setCurrentScreenId(id);
  };

  return (
    <div className="min-h-screen bg-[#070E1B] flex flex-col font-sans relative overflow-hidden">
      
      {/* Ambient aurora background glow */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute top-[-30%] left-[-10%] w-[500px] h-[500px] bg-[#FF6B35] rounded-full opacity-[0.04] blur-[120px] animate-aurora"></div>
        <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] bg-[#00B4D8] rounded-full opacity-[0.03] blur-[140px] animate-aurora" style={{ animationDelay: '3s' }}></div>
        <div className="absolute top-[40%] left-[50%] w-[400px] h-[400px] bg-[#7B2FF7] rounded-full opacity-[0.03] blur-[100px] animate-aurora" style={{ animationDelay: '6s' }}></div>
      </div>

      {/* Top Universal Navbar for Workspace */}
      <header className="bg-[#0A1628]/90 border-b border-white/[0.06] px-6 py-4 flex items-center justify-between z-10 sticky top-0 backdrop-blur-xl">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-gradient-to-br from-[#FF6B35] to-[#FF477E] rounded-xl flex items-center justify-center text-white shadow-lg shadow-[#FF6B35]/20">
            <Compass className="w-5 h-5 animate-spin-slow" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-black tracking-tight text-white font-mono">AIRA CONCEPT LAB</h2>
              <span className="text-[9px] bg-[#FF6B35]/10 border border-[#FF6B35]/30 text-[#FF8F66] font-bold px-1.5 py-0.5 rounded uppercase font-mono">Senior UI/UX Spec</span>
            </div>
            <p className="text-[11px] text-slate-400">Continuous Integration Live Simulator • Mobile Prototype Dashboard</p>
          </div>
        </div>
        
        {/* Dynamic header badge */}
        <div className="hidden md:flex items-center gap-4 text-xs font-mono text-slate-400">
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 bg-[#06D6A0] rounded-full animate-pulse"></span>
            <span>Gemini 3.5 Ready</span>
          </div>
          <div className="p-1 bg-[#1A2744] border border-white/[0.06] rounded text-[10px] text-slate-300">
            Scenario: Tokyo 5-Day ($1,500 budget)
          </div>
        </div>
      </header>

      {/* Split screen content area */}
      <main className="flex-1 grid grid-cols-1 lg:grid-cols-12 overflow-hidden relative z-[1]">
        
        {/* Left Side: Spec Explorer (7 columns) */}
        <section className="lg:col-span-7 flex flex-col border-b lg:border-b-0 border-white/[0.04]">
          <SpecsViewer 
            currentScreenId={currentScreenId} 
            onSelectScreen={handleSelectScreen} 
          />
        </section>

        {/* Right Side: Interactive Device Simulator (5 columns) */}
        <section className="lg:col-span-5 bg-gradient-to-br from-[#070E1B] via-[#0D1B2A] to-[#070E1B] flex flex-col justify-center min-h-[600px] lg:min-h-0 border-l border-white/[0.04] relative">
          {/* Ambient glow behind simulator */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[320px] h-[320px] bg-gradient-to-br from-[#FF6B35]/10 to-[#00B4D8]/10 rounded-full blur-[80px] pointer-events-none"></div>
          <MobileSimulator 
            currentScreenId={currentScreenId} 
            onScreenChange={handleSelectScreen} 
          />
        </section>

      </main>

      {/* Custom Global CSS styles injected for layout */}
      <style>{`
        /* Premium login screen styling */
        .login-screen input, 
        .login-screen select {
          background-color: rgba(255, 255, 255, 0.08) !important;
          border-color: rgba(255, 255, 255, 0.12) !important;
          backdrop-filter: blur(8px) !important;
          color: white !important;
          transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1) !important;
        }
        .login-screen input::placeholder {
          color: rgba(226, 232, 240, 0.5) !important;
        }
        .login-screen input:focus, 
        .login-screen select:focus {
          background-color: rgba(255, 255, 255, 0.14) !important;
          border-color: rgba(255, 107, 53, 0.6) !important;
          box-shadow: 0 0 0 2px rgba(255, 107, 53, 0.15) !important;
        }
        .login-screen .bg-slate-900 {
          background-color: rgba(255, 255, 255, 0.07) !important;
          border-color: rgba(255, 255, 255, 0.1) !important;
          backdrop-filter: blur(8px) !important;
        }
        .login-screen .border-slate-800 {
          border-color: rgba(255, 255, 255, 0.1) !important;
        }
        .login-screen .border-slate-900 {
          border-color: rgba(255, 255, 255, 0.1) !important;
        }
        .login-screen .bg-slate-950\\/80 {
          background-color: rgba(0, 0, 0, 0.4) !important;
          backdrop-filter: blur(8px) !important;
        }
        .login-screen .bg-slate-950 {
          background-color: transparent !important;
        }
        .login-screen .hover\\:bg-slate-800:hover {
          background-color: rgba(255, 255, 255, 0.15) !important;
        }
      `}
      </style>

    </div>
  );
}
