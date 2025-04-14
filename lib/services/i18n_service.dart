// 📄 lib/services/i18n_service.dart

String getUILabel(String key, String langCode) {
  const labels = {
    'send': {
      'fr': 'Envoyer',
      'de': 'Schicken',
      'es': 'Enviar',
      'en': 'Send',
    },
    'message_received_title': {
      'fr': '💌 Message reçu',
      'de': '💌 Nachricht empfangen',
      'es': '💌 Mensaje recibido',
      'en': '💌 Message received',
    },
    'compagne': {
      'fr': 'Compagne', 'de': 'Partnerin', 'es': 'Compañera', 'en': 'Girlfriend'
    },
    'compagnon': {
      'fr': 'Compagnon', 'de': 'Partner', 'es': 'Compañero', 'en': 'Boyfriend'
    },
    'enfant': {
      'fr': 'Enfant', 'de': 'Kind', 'es': 'Niño', 'en': 'Child'
    },
    'maman': {
      'fr': 'Maman', 'de': 'Mama', 'es': 'Mamá', 'en': 'Mom'
    },
    'papa': {
      'fr': 'Papa', 'de': 'Papa', 'es': 'Papá', 'en': 'Dad'
    },
    'ami': {
      'fr': 'Ami', 'de': 'Freund', 'es': 'Amigo', 'en': 'Friend'
    },
    'autre': {
      'fr': 'Autre', 'de': 'Andere', 'es': 'Otro', 'en': 'Other'
    },
    'pair_button': {
      'fr': 'Appairer ce destinataire', 'de': 'Empfänger koppeln', 'es': 'Emparejar destinatario', 'en': 'Pair this recipient'
    },
    'pairing_code_hint': {
      'fr': 'Code à 4 chiffres', 'de': '4-stelliger Code', 'es': 'Código de 4 cifras', 'en': '4-digit code'
    },
    'pairing_status_waiting': {
      'fr': '🕐 En attente d’un autre appareil...', 'de': '🕐 Warten auf ein anderes Gerät...', 'es': '🕐 Esperando otro dispositivo...', 'en': '🕐 Waiting for the other device...'
    },
    'pairing_status_success': {
      'fr': '✅ Appairage terminé !', 'de': '✅ Kopplung abgeschlossen!', 'es': '✅ Emparejamiento completo!', 'en': '✅ Pairing complete!'
    },
    'pairing_status_already': {
      'fr': '🔁 Déjà appairé.', 'de': '🔁 Bereits gekoppelt.', 'es': '🔁 Ya emparejado.', 'en': '🔁 Already paired.'
    },
    'pairing_status_invalid': {
      'fr': '❌ Code déjà utilisé.', 'de': '❌ Code bereits verwendet.', 'es': '❌ Código ya usado.', 'en': '❌ Code already used.'
    },
    'invalid_code': {
      'fr': '⚠️ Code invalide (4 chiffres)', 'de': '⚠️ Ungültiger Code (4 Ziffern)', 'es': '⚠️ Código inválido (4 cifras)', 'en': '⚠️ Invalid code (4 digits)'
    },
  };

  return labels[key]?[langCode] ?? labels[key]?['en'] ?? key;
}

List<String> getAllMessageTypes() {
  return [
    'heart', 'love_you', 'miss_you', 'good_night', 'thinking_of_you', 'hug', 'smile', 'look_up',
  ];
}

String getMessageBody(String type, String langCode) {
  const messages = {
    'heart': {
      'fr': "Tu es mon cœur ❤️", 'de': "Du bist mein Herz ❤️", 'es': "Eres mi corazón ❤️", 'en': "You are my heart ❤️",
    },
    'love_you': {
      'fr': "Je t’aime 💖", 'de': "Ich liebe dich 💖", 'es': "Te quiero 💖", 'en': "I love you 💖",
    },
    'miss_you': {
      'fr': "Tu me manques 💫", 'de': "Ich vermisse dich 💫", 'es': "Te extraño 💫", 'en': "I miss you 💫",
    },
    'good_night': {
      'fr': "Bonne nuit 🌙", 'de': "Gute Nacht 🌙", 'es': "Buenas noches 🌙", 'en': "Good night 🌙",
    },
    'thinking_of_you': {
      'fr': "Quelqu’un pense à toi 💖", 'de': "Jemand denkt an dich 💖", 'es': "Alguien piensa en ti 💖", 'en': "Someone’s thinking of you 💖",
    },
    'hug': {
      'fr': "Un câlin pour toi 🤗", 'de': "Eine Umarmung für dich 🤗", 'es': "Un abrazo para ti 🤗", 'en': "A hug for you 🤗",
    },
    'smile': {
      'fr': "Juste un sourire 😊", 'de': "Einfach ein Lächeln 😊", 'es': "Solo una sonrisa 😊", 'en': "Just a smile 😊",
    },
    'look_up': {
      'fr': "Regarde le ciel ce soir 🌌", 'de': "Schau heute Abend zum Himmel 🌌", 'es': "Mira el cielo esta noche 🌌", 'en': "Look up at the sky tonight 🌌",
    },
  };

  return messages[type]?[langCode] ?? messages[type]?['en'] ?? "💌 Nouveau message reçu";
}

String getPreviewText(String type, String langCode) {
  switch (type) {
    case 'love_you':
      return {
        'fr': 'Je t’aime ❤️', 'de': 'Ich liebe dich ❤️', 'es': 'Te quiero ❤️', 'en': 'I love you ❤️',
      }[langCode] ?? 'I love you ❤️';
    case 'miss_you':
      return {
        'fr': 'Tu me manques 💫', 'de': 'Ich vermisse dich 💫', 'es': 'Te extraño 💫', 'en': 'I miss you 💫',
      }[langCode] ?? 'I miss you 💫';
    case 'good_night':
      return {
        'fr': 'Bonne nuit 🌙', 'de': 'Gute Nacht 🌙', 'es': 'Buenas noches 🌙', 'en': 'Good night 🌙',
      }[langCode] ?? 'Good night 🌙';
    case 'hug':
      return {
        'fr': 'Un câlin 🤗', 'de': 'Eine Umarmung 🤗', 'es': 'Un abrazo 🤗', 'en': 'A hug 🤗',
      }[langCode] ?? 'A hug 🤗';
    case 'smile':
      return {
        'fr': 'Un sourire 😊', 'de': 'Ein Lächeln 😊', 'es': 'Una sonrisa 😊', 'en': 'A smile 😊',
      }[langCode] ?? 'A smile 😊';
    case 'look_up':
      return {
        'fr': 'Regarde le ciel 🌌', 'de': 'Schau zum Himmel 🌌', 'es': 'Mira el cielo 🌌', 'en': 'Look at the sky 🌌',
      }[langCode] ?? 'Look at the sky 🌌';
    case 'thinking_of_you':
      return {
        'fr': 'Je pense à toi 🤍', 'de': 'Ich denke an dich 🤍', 'es': 'Estoy pensando en ti 🤍', 'en': 'Thinking of you 🤍',
      }[langCode] ?? 'Thinking of you 🤍';
    case 'heart':
    default:
      return {
        'fr': 'Mon cœur 💖', 'de': 'Mein Herz 💖', 'es': 'Mi corazón 💖', 'en': 'My heart 💖',
      }[langCode] ?? 'My heart 💖';
  }
}
