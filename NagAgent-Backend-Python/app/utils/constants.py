"""Constants used throughout the NagAgent application"""

PERSONALITIES = {
    'sergeant': {
        'name': 'Sergeant Slacker',
        'emoji': '🔥',
        'description': 'Military drill instructor who\'s disappointed in you'
    },
    'sassy': {
        'name': 'Sassy Susan',
        'emoji': '😈',
        'description': 'Your toxic bestie who secretly wants you to succeed'
    },
    'passive': {
        'name': 'Passive-Aggressive Pat',
        'emoji': '🤖',
        'description': 'Corporate middle manager energy'
    },
    'brutal': {
        'name': 'Brutal Brandon',
        'emoji': '👹',
        'description': 'Zero filter, just truth bombs'
    }
}

EXCUSE_CATEGORIES = [
    'tired',
    'busy',
    'forgot',
    'tomorrow',
    'sick',
    'unmotivated',
    'external',
    'other'
]

SUBSCRIPTION_TIERS = {
    'free': {
        'name': 'Taste of Pain',
        'price': 0,
        'personalities': ['sassy'],
        'daily_nags': 3,
        'features': ['basic_roasts', 'daily_report']
    },
    'pro': {
        'name': 'Full Roast',
        'price': 6.99,
        'personalities': ['sergeant', 'sassy', 'passive', 'brutal'],
        'daily_nags': -1,  # unlimited
        'features': ['all_personalities', 'unlimited_nags', 'voice_messages', 'excuse_bingo']
    },
    'elite': {
        'name': 'Scorched Earth',
        'price': 12.99,
        'personalities': ['sergeant', 'sassy', 'passive', 'brutal'],
        'daily_nags': -1,  # unlimited
        'features': ['everything_pro', 'custom_personalities', 'public_shame', 'money_stakes']
    }
}

DEFAULT_NOTIFICATION_TIMES = ["09:00", "14:00", "19:00"]

ROAST_CONTEXTS = [
    'morning_nag',
    'excuse_response',
    'completion_response',
    'daily_report',
    'afternoon_checkup',
    'evening_report'
]