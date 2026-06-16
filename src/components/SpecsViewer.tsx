import React, { useState } from 'react';
import { ScreenSpec, ScreenId } from '../types';
import { SCREEN_SPECS } from '../data';
import { FLUTTER_CODE_BY_SCREEN } from '../flutterCode';
import { 
  Compass, 
  MapPin, 
  Smartphone, 
  ArrowRight, 
  ListTodo, 
  Layers, 
  Cpu, 
  Sparkles, 
  Palette, 
  Tv, 
  ShieldAlert,
  GitFork,
  BookOpen,
  Code,
  Check,
  Copy
} from 'lucide-react';

interface SpecsViewerProps {
  currentScreenId: ScreenId;
  onSelectScreen: (id: ScreenId) => void;
}

export default function SpecsViewer({ currentScreenId, onSelectScreen }: SpecsViewerProps) {
  const [activeTab, setActiveTab] = useState<'blueprints' | 'flows' | 'nav' | 'design-spec' | 'flutter'>('blueprints');
  const [selectedFlutterKey, setSelectedFlutterKey] = useState<string>('app_setup');
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const handleCopyCode = (key: string, code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div className="flex flex-col h-full bg-[#0A1628] border-r border-white/[0.06] text-slate-100 overflow-hidden font-sans">
      {/* Header Banner */}
      <div className="p-6 bg-gradient-to-r from-[#0A1628] via-[#1A2744] to-[#0A1628] border-b border-white/[0.06]">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gradient-to-br from-[#FF6B35] to-[#FF477E] rounded-lg text-white shadow-lg shadow-[#FF6B35]/20">
            <Compass className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs uppercase font-mono tracking-widest text-[#FF8F66] font-bold px-2 py-0.5 bg-[#FF6B35]/10 rounded border border-[#FF6B35]/30">UX DESIGN BLUEPRINT</span>
              <span className="text-xs text-slate-400 font-mono">v1.4.0</span>
            </div>
            <h1 className="text-xl font-bold tracking-tight text-white mb-1">Aira: AI Travel Concierge</h1>
            <p className="text-xs text-slate-400">Interactive Senior Product Design Workspace & Screen Simulator</p>
          </div>
        </div>
      </div>

      {/* Workspace Tabs */}
      <div className="flex border-b border-white/[0.06] bg-[#070E1B] p-1 flex-wrap gap-1">
        <button
          onClick={() => setActiveTab('blueprints')}
          className={`flex-1 min-w-[120px] py-2 px-2 text-xs font-semibold rounded-md transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'blueprints' 
              ? 'bg-[#1A2744] text-white shadow-sm border-b-2 border-[#FF6B35]' 
              : 'text-slate-400 hover:text-white hover:bg-[#1A2744]/50'
          }`}
        >
          <Smartphone className="w-3.5 h-3.5" />
          Blueprints
        </button>
        <button
          onClick={() => setActiveTab('flows')}
          className={`flex-1 min-w-[120px] py-2 px-2 text-xs font-semibold rounded-md transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'flows' 
              ? 'bg-[#1A2744] text-white shadow-sm border-b-2 border-[#FF6B35]' 
              : 'text-slate-400 hover:text-white hover:bg-[#1A2744]/50'
          }`}
        >
          <GitFork className="w-3.5 h-3.5" />
          Flow Diagram
        </button>
        <button
          onClick={() => setActiveTab('nav')}
          className={`flex-1 min-w-[120px] py-2 px-2 text-xs font-semibold rounded-md transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'nav' 
              ? 'bg-[#1A2744] text-white shadow-sm border-b-2 border-[#FF6B35]' 
              : 'text-slate-400 hover:text-white hover:bg-[#1A2744]/50'
          }`}
        >
          <Layers className="w-3.5 h-3.5" />
          Navigation Hub
        </button>
        <button
          onClick={() => setActiveTab('design-spec')}
          className={`flex-1 min-w-[120px] py-2 px-2 text-xs font-semibold rounded-md transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'design-spec' 
              ? 'bg-[#1A2744] text-white shadow-sm border-b-2 border-[#FF6B35]' 
              : 'text-slate-400 hover:text-white hover:bg-[#1A2744]/50'
          }`}
        >
          <Palette className="w-3.5 h-3.5" />
          Design Tokens
        </button>
        <button
          onClick={() => setActiveTab('flutter')}
          className={`flex-1 min-w-[130px] py-2 px-2 text-xs font-semibold rounded-md transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'flutter' 
              ? 'bg-[#00B4D8]/10 text-[#48CAE4] shadow-sm border-b-2 border-[#00B4D8]' 
              : 'text-[#00B4D8]/70 hover:text-[#48CAE4] hover:bg-[#1A2744]/50'
          }`}
        >
          <Code className="w-3.5 h-3.5 text-[#48CAE4]" />
          Flutter / Dart Code
        </button>
      </div>

      {/* Workspace Active Area */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6 scrollbar-thin scrollbar-thumb-[#1A2744]">
        
        {/* TAB 1: 18 SCREEN BLUEPRINTS */}
        {activeTab === 'blueprints' && (
          <div className="space-y-4">
            <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06] flex items-start gap-3">
              <Sparkles className="w-5 h-5 text-[#FF8F66] mt-1 flex-shrink-0" />
              <div>
                <h3 className="text-xs font-semibold tracking-wider text-slate-300 uppercase">Interactive Design Alignment</h3>
                <p className="text-xs text-slate-400 mt-1 leading-relaxed">
                  Below is the technical index of all 18 screens required. Clicking any item instantly changes the mobile device simulator on the right, allowing you to walk through the journey side-by-side with real UX criteria.
                </p>
              </div>
            </div>

            <div className="divide-y divide-white/[0.04] bg-[#0A1628]/60 rounded-xl border border-white/[0.06] overflow-hidden">
              {SCREEN_SPECS.map((spec) => {
                const isActive = spec.id === currentScreenId;
                return (
                  <div 
                    key={spec.id} 
                    onClick={() => onSelectScreen(spec.id)}
                    className={`p-4 transition-all cursor-pointer ${
                      isActive 
                        ? 'bg-[#FF6B35]/10 border-l-4 border-[#FF6B35] shadow-inner' 
                        : 'hover:bg-[#1A2744]/30 border-l-4 border-transparent'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full font-mono ${
                          isActive 
                            ? 'bg-[#FF6B35] text-white' 
                            : 'bg-[#1A2744] text-slate-400'
                        }`}>
                          ID: {spec.id.toUpperCase()}
                        </span>
                        <h4 className={`text-sm font-bold tracking-tight ${isActive ? 'text-[#FF8F66]' : 'text-slate-200'}`}>
                          {spec.name}
                        </h4>
                      </div>
                      <ArrowRight className={`w-4 h-4 transition-transform ${isActive ? 'text-[#FF8F66] translate-x-1' : 'text-slate-600'}`} />
                    </div>

                    <div className="mt-2 text-xs text-slate-300 leading-relaxed font-sans">
                      <span className="font-semibold text-slate-400">Purpose: </span> 
                      {spec.purpose}
                    </div>

                    {/* Expand Detail Specs if Active */}
                    {isActive && (
                      <div className="mt-3 pt-3 border-t border-white/[0.06] grid grid-cols-1 md:grid-cols-2 gap-4 text-xs animate-fade-in animate-duration-300">
                        <div className="bg-[#0A1628] p-2.5 rounded border border-white/[0.06]">
                          <span className="font-mono text-[10px] text-[#FF8F66] uppercase font-bold tracking-wider block mb-1">Visual Layout Spec</span>
                          <p className="text-slate-300 leading-relaxed font-sans">{spec.layout}</p>
                        </div>
                        <div className="bg-[#0A1628] p-2.5 rounded border border-white/[0.06]">
                          <span className="font-mono text-[10px] text-[#FFD166] uppercase font-bold tracking-wider block mb-1">Sample Grounded Content</span>
                          <ul className="list-disc pl-4 space-y-1 text-slate-300">
                            {spec.content.map((c, idx) => (
                              <li key={idx}>{c}</li>
                            ))}
                          </ul>
                        </div>
                        <div className="bg-[#0A1628] p-2.5 rounded border border-white/[0.06] md:col-span-2">
                          <span className="font-mono text-[10px] text-[#06D6A0] uppercase font-bold tracking-wider block mb-1">Interactive Triggers & Target States</span>
                          <div className="space-y-1.5 mt-1.5">
                            {spec.buttons.map((btn, idx) => (
                              <div key={idx} className="flex items-start gap-1">
                                <span className="font-mono text-[10px] px-1 py-0.5 bg-[#1A2744] border border-white/[0.08] rounded text-slate-300 font-semibold">{btn.action}</span>
                                <span className="text-slate-400">→ {btn.effect}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 2: INTERACTIVE USER FLOW DIAGRAM */}
        {activeTab === 'flows' && (
          <div className="space-y-6">
            <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06]">
              <h3 className="text-xs font-semibold tracking-wider text-slate-300 uppercase flex items-center gap-2">
                <GitFork className="w-4 h-4 text-[#FF8F66]" />
                Scenario User Journey Flow: Tokyo Medium-Budget
              </h3>
              <p className="text-xs text-slate-400 mt-1">
                Visual transition map of how travelers progress. Green bubbles are booking thresholds, glowing borders depict where cognitive AI routing modifies traditional flows.
              </p>
            </div>

            {/* Simulated UI Flow Graph */}
            <div className="p-6 bg-[#0A1628] rounded-xl border border-white/[0.06] relative overflow-x-auto">
              <div className="min-w-[500px] flex flex-col gap-6">
                
                {/* Row 1: Entrance */}
                <div className="flex items-center justify-around">
                  <div 
                    onClick={() => onSelectScreen('splash')}
                    className="p-3 bg-gradient-to-br from-indigo-900 to-slate-900 rounded-lg border border-[#FF6B35]/700 hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow-lg transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-[#FF8F66] uppercase">Step 01</div>
                    <div className="text-xs font-semibold text-white mt-1">Splash Screen</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Brand entry</div>
                  </div>
                  
                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('onboarding')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 02</div>
                    <div className="text-xs font-semibold text-white mt-1">Onboarding</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">App benefits</div>
                  </div>

                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('login')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 03</div>
                    <div className="text-xs font-semibold text-white mt-1">Login</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Google / Magic</div>
                  </div>
                </div>

                {/* Vertical Connector */}
                <div className="flex justify-center h-4 text-slate-600 font-mono text-xs">↓</div>

                {/* Row 2: Intake & Decision Core */}
                <div className="flex items-center justify-around">
                  <div 
                    onClick={() => onSelectScreen('home')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 04</div>
                    <div className="text-xs font-semibold text-white mt-1">Home Hub</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Dashboard & Alerts</div>
                  </div>
                  
                  <div className="text-indigo-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('chat')}
                    className="p-3 bg-[#FF6B35]/10/80 rounded-lg border-2 border-[#FF6B35]/500 ring-2 ring-indigo-500/10 hover:border-[#FF6B35]/400 cursor-pointer text-center w-40 shadow-xl transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-[#FF8F66] uppercase">Step 05 [CORE INTAKE]</div>
                    <div className="text-xs font-semibold text-white mt-1">Conversational AI</div>
                    <div className="text-[9px] text-[#FF8F66] mt-0.5">Traveler requirements</div>
                  </div>

                  <div className="text-indigo-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('itinerary_gen')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 06</div>
                    <div className="text-xs font-semibold text-white mt-1">AI Gen Itinerary</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">5-Day Roadmap</div>
                  </div>
                </div>

                {/* Vertical Connector */}
                <div className="flex justify-center h-4 text-slate-600 font-mono text-xs">↓</div>

                {/* Row 3: Discover & Bookings */}
                <div className="flex items-center justify-around">
                  <div 
                    onClick={() => onSelectScreen('discover')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 07</div>
                    <div className="text-xs font-semibold text-white mt-1">Discover Places</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Bento card reviews</div>
                  </div>
                  
                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('flights')}
                    className="p-3 bg-[#00B4D8]/10/60 rounded-lg border border-emerald-600/80 hover:border-[#00B4D8] cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-[#48CAE4] uppercase">Step 08 [TRANSACT]</div>
                    <div className="text-xs font-semibold text-white mt-1">Book Flights</div>
                    <div className="text-[10px] text-[#48CAE4] mt-0.5">Budget checks</div>
                  </div>

                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('hotels')}
                    className="p-3 bg-[#00B4D8]/10/60 rounded-lg border border-emerald-600/80 hover:border-[#00B4D8] cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-[#48CAE4] uppercase">Step 09 [LODGING]</div>
                    <div className="text-xs font-semibold text-white mt-1">Book Hotels</div>
                    <div className="text-[10px] text-[#48CAE4] mt-0.5">Comfort selections</div>
                  </div>
                </div>

                {/* Vertical Connector */}
                <div className="flex justify-center h-4 text-slate-600 font-mono text-xs">↓</div>

                {/* Row 4: Travel Realization */}
                <div className="flex items-center justify-around">
                  <div 
                    onClick={() => onSelectScreen('daily_view')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 10</div>
                    <div className="text-xs font-semibold text-white mt-1">Daily Itinerary</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Hourly timeline</div>
                  </div>
                  
                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('navigation')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 11</div>
                    <div className="text-xs font-semibold text-white mt-1">Navigation Maps</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">GPS alignment</div>
                  </div>

                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('alerts')}
                    className="p-3 bg-[#FFD166]/10/60 rounded-lg border border-amber-600/80 hover:border-amber-500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-[#FFD166] uppercase">Step 12 [CRISIS]</div>
                    <div className="text-xs font-semibold text-white mt-1">Real-time Alerts</div>
                    <div className="text-[10px] text-amber-400 mt-0.5">Active AI rerouting</div>
                  </div>
                </div>

                {/* Vertical Connector */}
                <div className="flex justify-center h-4 text-slate-600 font-mono text-xs">↓</div>

                {/* Row 5: Finance, Scrapbook & Profile */}
                <div className="flex items-center justify-around">
                  <div 
                    onClick={() => onSelectScreen('budget')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 13</div>
                    <div className="text-xs font-semibold text-white mt-1">Budget Planner</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Categorized Ledger</div>
                  </div>
                  
                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('memories')}
                    className="p-3 bg-[#1A2744] rounded-lg border border-white/[0.08] hover:border-[#FF6B35]/500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-slate-400 uppercase">Step 14</div>
                    <div className="text-xs font-semibold text-white mt-1">Trip Scrapbook</div>
                    <div className="text-[10px] text-slate-400 mt-0.5">Journals & Audios</div>
                  </div>

                  <div className="text-slate-500 font-mono text-xs">→</div>

                  <div 
                    onClick={() => onSelectScreen('profile')}
                    className="p-3 bg-gradient-to-br from-indigo-950 to-slate-950 rounded-lg border border-yellow-600 hover:border-yellow-500 cursor-pointer text-center w-36 shadow transition-all"
                  >
                    <div className="text-[9px] font-mono font-bold text-yellow-400 uppercase">Step 15 [GOLD]</div>
                    <div className="text-xs font-semibold text-white mt-1">Profile & rewards</div>
                    <div className="text-[10px] text-yellow-400/80 mt-0.5">Shogun Club lounge</div>
                  </div>
                </div>

              </div>
            </div>
          </div>
        )}

        {/* TAB 3: APP NAVIGATION ARCHITECTURE */}
        {activeTab === 'nav' && (
          <div className="space-y-6">
            <div className="bg-[#0A1628] p-5 rounded-xl border border-white/[0.06] space-y-3">
              <h3 className="text-xs font-bold tracking-wider text-slate-300 uppercase flex items-center gap-2">
                <Layers className="w-4.5 h-4.5 text-[#FF8F66]" />
                Mobile Application Navigation Hierarchy
              </h3>
              <p className="text-xs text-slate-400 leading-relaxed font-sans">
                Aira integrates the dual-structural layout popularized by premium travel products like Airbnb and Booking.com: 
                a flat top-level **Hub Tab-Bar** backed by a **Context-Driven Multimodal AI core**.
              </p>
            </div>

            {/* Nav Architecture Tree */}
            <div className="space-y-4 font-mono text-xs text-slate-300 bg-[#0A1628] p-5 rounded-xl border border-white/[0.06]">
              <div className="p-3 bg-[#FF6B35]/10/40 rounded border border-[#FF6B35]/900/60 font-sans text-xs">
                <span className="font-bold text-[#FF8F66]">Core Principle: Contextual Sticky Navigation.</span> Navigation switches context based on what active part of the journey you occupy (e.g. Booking state vs. Transit state).
              </div>

              <div className="space-y-2.5">
                <div className="text-white font-bold text-sm">📍 PLATFORM ENTRY</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Splash Screen <span className="text-[10px] text-[#FF8F66] px-1 bg-[#FF6B35]/10/80 rounded border border-[#FF6B35]/900">[Brand Load]</span></div>
                  <div>├─ Onboarding Slide deck <span className="text-[10px] text-[#FF8F66] px-1 bg-[#FF6B35]/10/80 rounded border border-[#FF6B35]/900">[Carousel / Intro]</span></div>
                  <div>└─ Unified Auth Portal <span className="text-[10px] text-[#FF8F66] px-1 bg-[#FF6B35]/10/80 rounded border border-[#FF6B35]/900">[OAuth, SSO, Email]</span></div>
                </div>

                <div className="text-white font-bold text-sm pt-2">🏠 FIRST TAB: HOME ENGINE (THE DASHBOARD)</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Active Trip Summary widget</div>
                  <div>├─ Real-Time Local Weather & Delay Alert bars</div>
                  <div>├─ Micro-Trigger: Open Conversational Workspace</div>
                  <div>└─ Bento Modules (Local Map, Rewards stat, Quick Scrapbook)</div>
                </div>

                <div className="text-white font-bold text-sm pt-2">🤖 SECOND TAB: AI CONCIERGE (THROUGHPUT ENGINE)</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Chat stream Workspace <span className="text-[10px] text-[#FFD166] px-1 bg-[#FFD166]/10/60 rounded border border-[#FFD166]/30">Gemini Powered</span></div>
                  <div>├─ Dynamic Computation Screen (Itinerary compiler)</div>
                  <div>└─ Swipable Discover Spot deck (Food, Anime, Crafts reviews)</div>
                </div>

                <div className="text-white font-bold text-sm pt-2">💳 THIRD TAB: RESERVATION & SECURE PAY (CHECKOUTS)</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Flight Procurement comparisons (ANA/JAL)</div>
                  <div>├─ Design Hostel/Ryokan curation selectors</div>
                  <div>└─ Integrated Budget Ledger & Multi-Service transaction approval</div>
                </div>

                <div className="text-white font-bold text-sm pt-2">📅 FOURTH TAB: DAILY TRAVEL WALK (IN-METROPOLIS WORK)</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Chronological schedule timeline with checkpoints</div>
                  <div>├─ In-App minimal Route navigation maps</div>
                  <div>├─ Active Real-Time Local Commute delay monitors</div>
                  <div>└─ User Memories digital scrapbook & audio notes diaries</div>
                </div>

                <div className="text-white font-bold text-sm pt-2">🏆 FIFTH TAB: USER PROFILE STATUS CLUB</div>
                <div className="pl-4 border-l-2 border-white/[0.06] space-y-1.5 text-slate-400">
                  <div>├─ Gold Tier Status club card ("Shogun Explorer")</div>
                  <div>├─ XP Wallet & Airport lounge QR pass generator</div>
                  <div>└─ Master reset triggers & Developer specs</div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 4: HIGH-FIDELITY SPECS */}
        {activeTab === 'design-spec' && (
          <div className="space-y-6">
            <div className="bg-[#0A1628] p-5 rounded-xl border border-white/[0.06] space-y-2">
              <h3 className="text-xs font-bold tracking-wider text-slate-300 uppercase flex items-center gap-2">
                <Palette className="w-4.5 h-4.5 text-[#FF8F66]" />
                Modern UI Design System Token Guide
              </h3>
              <p className="text-xs text-slate-400 leading-relaxed font-sans">
                Aira defines a highly balanced, comfortable off-white visual landscape with strategic rich twilight-dark accent blocks to minimize eye strain during nocturnal flight boarding checks.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              
              {/* Token Card 1: Colors */}
              <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06] space-y-3">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#FF8F66] block uppercase">🎨 Color Palette Tokens</span>
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Deep Navy (Background)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#0A1628 / deep navy</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Sunset Orange (Primary CTA)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#FF6B35 / primary</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Ocean Teal (Secondary Accent)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#00B4D8 / secondary</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Tropical Green (Success)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#06D6A0 / tropical</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Warm Gold (Premium Rewards)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#FFD166 / gold</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Coral Pink (Hearts/Favorites)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#FF477E / coral</span>
                  </div>
                  <div className="flex items-center justify-between text-xs font-sans">
                    <span className="text-slate-400">Warm Cream (Light Background)</span>
                    <span className="font-mono text-[10px] p-1 bg-[#1A2744] border border-white/[0.06] rounded">#FFF8F0 / cream</span>
                  </div>
                </div>
              </div>

              {/* Token Card 2: Typography */}
              <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06] space-y-3">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#FF8F66] block uppercase">✍️ Typography Stack</span>
                <div className="space-y-2 text-xs">
                  <div>
                    <span className="font-sans font-semibold text-slate-200 block">Display (Headings & Large Quotes)</span>
                    <p className="text-slate-400 text-[10.5px]">Space Grotesk - bold, tight letter tracking (-0.02em).</p>
                  </div>
                  <div>
                    <span className="font-sans font-semibold text-slate-200 block">UI Interface Text</span>
                    <p className="text-slate-400 text-[10.5px]">Inter - clean, proportional aspect ratio, easily read at small scales.</p>
                  </div>
                  <div>
                    <span className="font-sans font-semibold text-slate-200 block">Price Details & Financials</span>
                    <p className="text-slate-400 text-[10.5px]">JetBrains Mono - monospace, ensures symmetrical spacing of numbers.</p>
                  </div>
                </div>
              </div>

              {/* Token Card 3: Microinteractions */}
              <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06] space-y-3">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#FF8F66] block uppercase">⚡ Micro-Interactions & Motion</span>
                <div className="space-y-2 text-xs leading-relaxed text-slate-400">
                  <p>• **Swipe Decorum:** Cards features elastic horizontal boundaries imitating physiological inertia.</p>
                  <p>• **Dynamic Stencils:** Itinerary compiling uses rotating stencils matching specific content keywords (e.g., sushi bowl rotating while thinking about food crawls).</p>
                  <p>• **Fade transitions:** Swapping state paths uses custom transitions inside the mobile iframe viewer.</p>
                </div>
              </div>

              {/* Token Card 4: Wireframe Rules */}
              <div className="bg-[#0A1628] p-4 rounded-xl border border-white/[0.06] space-y-3">
                <span className="text-[10px] font-mono font-bold tracking-wider text-[#FF8F66] block uppercase">📐 Wireframe & Structural Grid</span>
                <div className="space-y-2 text-xs leading-relaxed text-slate-400 font-sans">
                  <p>• **Layout Width:** Standardized 390px simulated portrait environment modeling modern high-end iOS bezels.</p>
                  <p>• **Safe Areas:** 44px top status bar with 34px bottom home gesture indicator integrated.</p>
                  <p>• **Grid Units:** 8dp structural system spacing. Margins strict at 16dp.</p>
                </div>
              </div>

            </div>
          </div>
        )}

        {/* TAB 5: FLUTTER / DART ENGINE */}
        {activeTab === 'flutter' && (
          <div className="space-y-6 animate-fade-in">
            <div className="bg-[#00B4D8]/10/20 p-5 rounded-xl border border-emerald-800/40 space-y-2">
              <h3 className="text-sm font-bold tracking-wider text-[#48CAE4] uppercase flex items-center gap-2 font-display">
                <Code className="w-4 h-4 text-[#48CAE4]" />
                Aira Flutter & Dart Production Codebase
              </h3>
              <p className="text-xs text-slate-300 leading-relaxed font-sans">
                You can easily implement this high-fidelity travel prototype in **Flutter/Dart**. We have crafted modern Flutter widgets utilizing Material 3, providers for state mechanics, and seamless HTTP controllers to route AI queries.
              </p>
            </div>

            {/* Selector Grid of files */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
              {Object.entries(FLUTTER_CODE_BY_SCREEN).map(([key, block]) => {
                const isActive = key === selectedFlutterKey;
                return (
                  <button
                    key={key}
                    onClick={() => setSelectedFlutterKey(key)}
                    className={`p-3 text-left rounded-lg border transition-all flex flex-col justify-between h-20 outline-none ${
                      isActive 
                        ? 'bg-[#00B4D8]/10/30 border-[#00B4D8] text-[#48CAE4] ring-1 ring-emerald-500/20 shadow-md' 
                        : 'bg-[#0A1628] border-white/[0.06] text-slate-400 hover:border-white/[0.08] hover:text-white'
                    }`}
                  >
                    <span className="font-mono text-[9px] font-bold text-[#00B4D8]">{block.filename}</span>
                    <span className="text-xs font-semibold line-clamp-1">{block.title}</span>
                  </button>
                );
              })}
            </div>

            {/* Dynamic Code Display Container */}
            {(() => {
              const activeBlock = FLUTTER_CODE_BY_SCREEN[selectedFlutterKey];
              if (!activeBlock) return null;
              const isCopied = copiedKey === selectedFlutterKey;

              return (
                <div className="space-y-4">
                  <div className="bg-[#0A1628] border border-white/[0.06] rounded-xl overflow-hidden shadow-inner">
                    
                    {/* Source Code Header / Controls */}
                    <div className="bg-[#1A2744] px-4 py-3 border-b border-white/[0.06]/80 flex items-center justify-between">
                      <div className="flex items-center gap-2 font-mono">
                        <span className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse animate-duration-1000"></span>
                        <span className="text-xs text-[#48CAE4] font-bold">{activeBlock.filename}</span>
                        <span className="text-[10px] text-slate-500">• Ready for device</span>
                      </div>

                      <button
                        onClick={() => handleCopyCode(selectedFlutterKey, activeBlock.code)}
                        className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-all flex items-center gap-1.5 outline-none ${
                          isCopied 
                            ? 'bg-[#00B4D8] text-white' 
                            : 'bg-slate-800 text-slate-300 hover:text-white hover:bg-slate-700'
                        }`}
                      >
                        {isCopied ? (
                          <>
                            <Check className="w-3.5 h-3.5" />
                            Copied!
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5" />
                            Copy Code
                          </>
                        )}
                      </button>
                    </div>

                    {/* Source Code File Description */}
                    <div className="p-4 bg-[#0A1628] border-b border-white/[0.06]/40 text-xs text-slate-300 font-sans">
                      <span className="font-semibold text-slate-400 block mb-1">Module Objective:</span>
                      {activeBlock.description}
                    </div>

                    {/* Syntax Styled Monospace Viewer */}
                    <div className="p-4 overflow-x-auto max-h-[450px] overflow-y-auto font-mono text-[11px] text-slate-300 bg-[#070b13] leading-relaxed scrollbar-thin">
                      <pre className="whitespace-pre">{activeBlock.code}</pre>
                    </div>

                  </div>

                  {/* Dev instructions / Quick guide */}
                  <div className="p-4 bg-[#0A1628] border border-white/[0.06] rounded-xl space-y-3 font-sans">
                    <span className="text-[10px] uppercase font-mono font-bold text-[#FFD166] tracking-wider flex items-center gap-1.5">
                      <BookOpen className="w-3.5 h-3.5" />
                      Flutter Implementation Guide
                    </span>

                    <div className="text-xs text-slate-400 space-y-2 leading-relaxed">
                      <p>
                        1. **Add State Capabilities**: Add the key state manager package to your <code className="text-amber-400 bg-[#1A2744] px-1 py-0.5 rounded font-mono text-xs">pubspec.yaml</code>:
                      </p>
                      <pre className="bg-[#1A2744] p-2.5 rounded text-[10px] font-mono text-slate-300 whitespace-pre scrollbar-none overflow-x-auto">
{`dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  http: ^1.2.0`}
                      </pre>
                      <p>
                        2. **Organize Folders**: Create screen files inside a <code className="text-[#FF8F66] bg-[#1A2744] px-1 py-0.5 rounded font-mono text-xs">lib/screens/</code> directory and reference them in your routing system.
                      </p>
                      <p>
                        3. **Theme customizers**: Use <code className="text-[#48CAE4] font-mono text-xs">ThemeData(useMaterial3: true)</code> inside your master theme generator to enforce high contrast of the Aira Spec.
                      </p>
                    </div>
                  </div>

                </div>
              );
            })()}

          </div>
        )}

      </div>
    </div>
  );
}

