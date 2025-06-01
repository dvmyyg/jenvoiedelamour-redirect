//  lib/services/i18n_service.dart

String getUILabel(String key, String langCode) {
  const labels = {
    'send': {
      'fr': 'Envoyer', 'de': 'Schicken', 'es': 'Enviar', 'en': 'Send',
    },
    'message_received_title': {
      'fr': '💌 Message reçu', 'de': '💌 Nachricht empfangen', 'es': '💌 Mensaje recibido', 'en': '💌 Message received',
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
    'profile_title': {
      'fr': 'Mon profil', 'de': 'Mein Profil', 'es': 'Mi perfil', 'en': 'My Profile',
    },
    'profile_firstname_label': {
      'fr': 'Prénom', 'de': 'Vorname', 'es': 'Nombre', 'en': 'First name',
    },
    'profile_firstname_hint': {
      'fr': 'Entrez votre prénom', 'de': 'Geben Sie Ihren Vornamen ein', 'es': 'Escriba su nombre', 'en': 'Enter your first name',
    },
    'profile_email_label': {
      'fr': 'Mon email (identifiant)', 'de': 'Meine E-Mail (Benutzername)', 'es': 'Mi correo (identificador)', 'en': 'My email (identifier)',
    },
    'profile_save_button': {
      'fr': 'Sauvegarder', 'de': 'Speichern', 'es': 'Guardar', 'en': 'Save',
    },
    'profile_saved': {
      'fr': 'Profil mis à jour ✅', 'de': 'Profil aktualisiert ✅', 'es': 'Perfil actualizado ✅', 'en': 'Profile updated ✅',
    },
    'profile_save_error': {
      'fr': 'Erreur de sauvegarde', 'de': 'Fehler beim Speichern', 'es': 'Error al guardar', 'en': 'Error saving',
    },
    'profile_load_error': {
      'fr': 'Erreur de chargement', 'de': 'Fehler beim Laden', 'es': 'Error al cargar', 'en': 'Loading error',
    },
    'logout_button': {
      'fr': 'Déconnexion', 'de': 'Abmelden', 'es': 'Cerrar sesión', 'en': 'Logout',
    },
    'email_verification_title': {
      'fr': 'Vérification de l’email', 'de': 'E-Mail-Bestätigung', 'es': 'Verificación de correo', 'en': 'Email verification'
    },
    'email_verification_message': {
      'fr': 'Avant d’utiliser l’application, veuillez confirmer votre adresse email.', 'de': 'Bitte bestätigen Sie Ihre E-Mail-Adresse, bevor Sie die App verwenden.', 'es': 'Confirma tu dirección de correo antes de usar la app.', 'en': 'Before using the app, please confirm your email address.'
    },
    'email_verification_check_button': {
      'fr': 'Vérifier maintenant', 'de': 'Jetzt überprüfen', 'es': 'Verificar ahora', 'en': 'Verify now'
    },
    'email_verification_resend_button': {
      'fr': 'Renvoyer l’email', 'de': 'E-Mail erneut senden', 'es': 'Reenviar correo', 'en': 'Resend email'
    },
    'email_not_verified': {
      'fr': 'Votre email n’est pas encore vérifié.', 'de': 'Ihre E-Mail ist noch nicht bestätigt.', 'es': 'Tu correo aún no está verificado.', 'en': 'Your email is not yet verified.'
    },
    'email_resent_success': {
      'fr': 'Email de vérification renvoyé ✅', 'de': 'Bestätigungs-E-Mail erneut gesendet ✅', 'es': 'Correo de verificación reenviado ✅', 'en': 'Verification email resent ✅'
    },
    'email_resent_error': {
      'fr': 'Erreur lors de l’envoi de l’email', 'de': 'Fehler beim Senden der E-Mail', 'es': 'Error al enviar el correo', 'en': 'Error sending email'
    },
    'love_screen_title': {
      'fr': "J'envoie de l'amour", 'de': "Ich sende Liebe", 'es': "Envío amor", 'en': "Sending love",
    },
    'manage_recipients_tooltip': {
      'fr': "Gérer les destinataires", 'de': "Empfänger verwalten", 'es': "Gestionar destinatarios", 'en': "Manage recipients",
    },
    'message_sent': {
      'fr': "Message envoyé ✅", 'de': "Nachricht gesendet ✅", 'es': "Mensaje enviado ✅", 'en': "Message sent ✅",
    },
    'message_send_error': {
      'fr': "Échec de l'envoi", 'de': "Senden fehlgeschlagen", 'es': "Error al enviar", 'en': "Send failed",
    },
    'pairing_link_subject': {
      'fr': 'Lien d\'appairage', 'de': 'Kopplungslink', 'es': 'Enlace de emparejamiento', 'en': 'Pairing link',
    },
    'pairing_link_message': {
      'fr': "💌 Clique ici pour t'appairer avec moi dans l'app J'envoie de l'amour :", 'de': "💌 Klicke hier, um dich mit mir zu koppeln in der App \"Ich sende Liebe\":", 'es': "💌 Haz clic aquí para emparejarte conmigo en la app \"Envío amor\":", 'en': "💌 Click here to pair with me in the app \"Sending love\":",
    },
    'required_field': {
      'fr': 'Champ requis', 'de': 'Pflichtfeld', 'es': 'Campo requerido', 'en': 'Required field',
    },
    'display_name_label': {
      'fr': 'Nom affiché', 'de': 'Anzeigename', 'es': 'Nombre mostrado', 'en': 'Display name',
    },
    'icon_hint': {
      'fr': 'Icône (ex: 💖)', 'de': 'Symbol (z. B.: 💖)', 'es': 'Icono (ej: 💖)', 'en': 'Icon (e.g.: 💖)',
    },
    'share_pairing_link': {
      'fr': 'Partager le lien d’appairage', 'de': 'Kopplungslink teilen', 'es': 'Compartir el enlace de emparejamiento', 'en': 'Share pairing link',
    },
    'relation_label': {
      'fr': 'Relation', 'de': 'Beziehung', 'es': 'Relación', 'en': 'Relation',
    },
    'add_recipient_title': {
      'fr': '➕ Nouveau destinataire', 'de': '➕ Neuer Empfänger', 'es': '➕ Nuevo destinatario', 'en': '➕ New recipient',
    },
    'delete_contact_title': {
      'fr': 'Supprimer ce contact', 'de': 'Diesen Kontakt löschen', 'es': 'Eliminar este contacto', 'en': 'Delete this contact',
    },
    'delete_contact_warning': {
      'fr': 'Cette action est irréversible. Supprimer ce contact ?', 'de': 'Diese Aktion ist unwiderruflich. Kontakt löschen?', 'es': 'Esta acción no se puede deshacer. ¿Eliminar este contacto?', 'en': 'This action is irreversible. Delete this contact?',
    },
    'cancel_button': {
      'fr': 'Annuler', 'de': 'Abbrechen', 'es': 'Cancelar', 'en': 'Cancel',
    },
    'delete_button': {
      'fr': 'Supprimer', 'de': 'Löschen', 'es': 'Eliminar', 'en': 'Delete',
    },
    'access_messages_button': {
      'fr': 'Accéder aux messages', 'de': 'Nachrichten öffnen', 'es': 'Acceder a los mensajes', 'en': 'Access messages',
    },
    'recipients_title': {
      'fr': 'Destinataires', 'de': 'Empfänger', 'es': 'Destinatarios', 'en': 'Recipients',
    },
    'invite_someone_button': {
      'fr': 'Inviter quelqu’un', 'de': 'Jemanden einladen', 'es': 'Invitar a alguien', 'en': 'Invite someone',
    },
    'back_home_button': {
      'fr': 'Accueil', 'de': 'Startseite', 'es': 'Inicio', 'en': 'Home',
    },
    'register_title': {
      'fr': 'Inscription',
      'de': 'Registrierung',
      'es': 'Registro',
      'en': 'Register',
    },
    'register_button': {
      'fr': 'Créer mon compte',
      'de': 'Konto erstellen',
      'es': 'Crear cuenta',
      'en': 'Register',
    },
    'invalid_email': {
      'fr': 'Email invalide',
      'de': 'Ungültige E-Mail',
      'es': 'Correo inválido',
      'en': 'Invalid email',
    },
    'password_min_length': {
      'fr': 'Minimum 6 caractères',
      'de': 'Mindestens 6 Zeichen',
      'es': 'Mínimo 6 caracteres',
      'en': 'Minimum 6 characters',
    },
    'login_error': {
      'fr': 'Email ou mot de passe incorrect',
      'de': 'E-Mail oder Passwort falsch',
      'es': 'Correo o contraseña incorrectos',
      'en': 'Wrong email or password',
    },
    'validate_invite_button': {
      'fr': "Valider une invitation",
      'en': "Validate an invitation",
      'de': "Einladung bestätigen",
      'es': "Validar una invitación",
    },

    'paste_invite_hint': {
      'fr': "Collez ici le lien reçu",
      'en': "Paste the link here",
      'de': "Füge den Link hier ein",
      'es': "Pega el enlace aquí",
    },

    'validate_button': {
      'fr': "Valider",
      'en': "Validate",
      'de': "Bestätigen",
      'es': "Validar",
    },

    'pairing_success': {
      'fr': "Appairage réussi 🎉",
      'en': "Pairing successful 🎉",
      'de': "Erfolgreich gekoppelt 🎉",
      'es': "¡Emparejamiento exitoso 🎉!",
    },
    'already_paired': {
      'fr': "Cet utilisateur est déjà appairé.",
      'en': "This user is already paired.",
      'de': "Dieser Kontakt ist bereits gekoppelt.",
      'es': "Este contacto ya está emparejado.",
    },
    'invalid_invite_link': {
      'fr': "Lien invalide",
      'en': "Invalid link",
      'de': "Ungültiger Link",
      'es': "Enlace no válido",
    },
    'default_pairing_name': {
      'fr': '❤️ Appairé',
      'en': '❤️ Paired',
      'de': '❤️ Verbunden',
      'es': '❤️ Emparejado',
    },
    'relation_partner': {
      'fr': 'Partenaire',
      'en': 'Partner',
      'de': 'Partner',
      'es': 'Pareja',
    },
    'relation_friend': {
      'fr': 'Ami',
      'en': 'Friend',
      'de': 'Freund',
      'es': 'Amigo',
    },
    'relation_family': {
      'fr': 'Famille',
      'en': 'Family',
      'de': 'Familie',
      'es': 'Familia',
    },
    'relation_sibling': {
      'fr': 'Frère / Sœur',
      'en': 'Sibling',
      'de': 'Geschwister',
      'es': 'Hermano/a',
    },
    'relation_child': {
      'fr': 'Enfant',
      'en': 'Child',
      'de': 'Kind',
      'es': 'Niño/a',
    },
    'relation_parent': {
      'fr': 'Parent',
      'en': 'Parent',
      'de': 'Elternteil',
      'es': 'Padre/Madre',
    },
    'edit_contact_category': {
      'fr': 'Modifier la catégorie du contact',
      'en': 'Edit contact category',
      'de': 'Kontaktkategorie bearbeiten',
      'es': 'Editar la categoría del contacto',
    },
    'save_button': {
      'fr': 'Enregistrer',
      'en': 'Save',
      'de': 'Speichern',
      'es': 'Guardar',
    },
    'pairing_invitation_message': {
      'fr': 'Salut !\n\nPour te connecter à moi dans l\'app J\'envoie de l\'amour, copie ce code d\'appairage unique :\n\n{uid}\n\nEnsuite, ouvre l\'app, va dans la section Destinataires (l\'icône groupe/contacts) et utilise l\'option "Valider une invitation" pour coller ce code.\n\nSi tu n\'as pas encore installé l\'application, clique sur ce lien pour la télécharger :\n\n{appLink}',
      'en': 'Hi!\n\nTo connect with me in the Send Love app, copy this unique pairing code:\n\n{uid}\n\nThen, open the app, go to the Recipients section (the group/contacts icon) and use the "Validate Invitation" option to paste this code.\n\nIf you haven\'t installed the app yet, click this link to download it:\n\n{appLink}',
      'de': 'Hallo!\n\nUm dich mit mir in der Sende Liebe App zu verbinden, kopiere diesen einzigartigen Pairing-Code:\n\n{uid}\n\nÖffne dann die App, gehe zum Bereich Empfänger (das Gruppen-/Kontakte-Symbol) und verwende die Option "Einladung bestätigen", um diesen Code einzufügen.\n\nFalls du die App noch nicht installiert hast, klicke auf diesen Link, um sie herunterzuladen:\n\n{appLink}',
      'es': '¡Hola!\n\nPara conectarte conmigo en la aplicación Enviar Amor, copia este código de emparejamiento único:\n\n{uid}\n\nAbre la aplicación, ve a la sección Destinatarios (el icono de grupo/contactos) y usa la opción "Validar invitación" para pegar este código.\n\nSi aún no has instalado la aplicación, haz clic en este enlace para descargarla:\n\n{appLink}',
    },
    'edit_recipient_title': {
      'fr': '✏️ Modifier le destinataire',
      'de': '✏️ Empfänger bearbeiten',
      'es': '✏️ Editar destinatario',
      'en': '✏️ Edit recipient',
    },
    'save_changes_button': {
      'fr': 'Enregistrer les modifications',
      'de': 'Änderungen speichern',
      'es': 'Guardar cambios',
      'en': 'Save changes',
    },
    'login_title': {
      'fr': 'Connexion',
      'de': 'Anmeldung',
      'es': 'Iniciar sesión',
      'en': 'Login',
    },
    'email_label': {
      'fr': 'Email',
      'de': 'E-Mail',
      'es': 'Correo electrónico',
      'en': 'Email',
    },
    'password_label': {
      'fr': 'Mot de passe',
      'de': 'Passwort',
      'es': 'Contraseña',
      'en': 'Password',
    },
    'login_button': {
      'fr': 'Se connecter',
      'de': 'Einloggen',
      'es': 'Entrar',
      'en': 'Login',
    },
    'create_account_button': {
      'fr': 'Créer un compte',
      'de': 'Konto erstellen',
      'es': 'Crear una cuenta',
      'en': 'Create account',
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
        'fr': 'Je pense à toi 🪰', 'de': 'Ich denke an dich 🪰', 'es': 'Estoy pensando en ti 🪰', 'en': 'Thinking of you 🪰',
      }[langCode] ?? 'Thinking of you 🪰';
    case 'heart':
    default:
      return {
        'fr': 'Mon cœur 💖', 'de': 'Mein Herz 💖', 'es': 'Mi corazón 💖', 'en': 'My heart 💖',
      }[langCode] ?? 'My heart 💖';
  }
}
