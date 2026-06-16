export type ScreenId =
  | 'splash'
  | 'onboarding'
  | 'login'
  | 'home'
  | 'chat'
  | 'itinerary_gen'
  | 'discover'
  | 'flights'
  | 'hotels'
  | 'daily_view'
  | 'navigation'
  | 'alerts'
  | 'budget'
  | 'memories'
  | 'profile'
  | 'travel_history'
  | 'create_itinerary_input'
  | 'upcoming_trips'
  | 'translator'
  | 'bookings_hub'
  | 'audio_guide'
  | 'travel_utilities';

export interface ScreenSpec {
  id: ScreenId;
  name: string;
  purpose: string;
  layout: string;
  buttons: { action: string; effect: string }[];
  content: string[];
  next: string;
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'assistant';
  text: string;
  timestamp: string;
}

export interface TravelExpense {
  id: string;
  category: string;
  amount: number;
  label: string;
  date: string;
}

export interface Memory {
  id: string;
  title: string;
  date: string;
  location: string;
  image: string;
  notes: string;
  audioDuration?: string;
}

export interface ItineraryDay {
  day: number;
  theme: string;
  activities: {
    time: string;
    activity: string;
    description: string;
    cost: string;
    checked?: boolean;
    locationName?: string;
    suggestedAttire?: string;
    transport?: string;
    ticketInfo?: string;
    placeDetails?: string;
  }[];
}
