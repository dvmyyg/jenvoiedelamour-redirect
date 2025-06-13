// -------------------------------------------------------------
// 📄 FICHIER : functions/index.js
// -------------------------------------------------------------
// 🧹 FONCTIONNALITÉS PRINCIPALES
// -------------------------------------------------------------
// ✅ Cloud Function (2nd Gen) déclenchée par l'ajout d'un nouveau message dans Firestore.
// ✅ Récupère les données du message et l'UID du destinataire.
// ✅ Récupère le token FCM du destinataire depuis son document utilisateur.
// ✅ Envoie une notification FCM au destinataire via Firebase Admin SDK.
// ✅ **Implémente la logique de nettoyage des tokens FCM invalides après l'envoi.**
// -------------------------------------------------------------
// 🕓 HISTORIQUE DES MODIFICATIONS
// -------------------------------------------------------------
// V001 - Création de la fonction sendNotificationOnMessage (syntaxe v1). - 2025/06/02
// V002 - Migration vers la syntaxe des Cloud Functions de Seconde Génération (v2). - 2025/06/02
// V003 - Ajout de la logique de nettoyage des tokens FCM invalides après l'envoi. - 2025/06/04 // Mise à jour le 04/06
// -------------------------------------------------------------

// GEM - Code vérifié et historique mis à jour par Gémini le 2025/06/04 // Mise à jour le 04/06


// Importe la syntaxe de seconde génération pour les triggers Firestore et le logger
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions/v2"); // Utilise le logger de v2
const admin = require('firebase-admin');

// Initialise l'Admin SDK pour pouvoir interagir avec les services Firebase (Firestore, FCM)
// Cette initialisation reste la même quelle que soit la génération de fonction.
admin.initializeApp();

// --- Cloud Function (2nd Gen) déclenchée par un nouveau message ---

// Exporte une fonction nommée 'sendNotificationOnMessage'.
// Elle est déclenchée par l'événement 'onCreate' (création de document) dans Firestore.
// Utilise le trigger de seconde génération 'onDocumentCreated' importé ci-dessus.
exports.sendNotificationOnMessage = onDocumentCreated(
  // Spécifie le chemin du document à écouter comme une chaîne.
  // Les jokers ({...}) capturent les parties dynamiques.
  'users/{senderId}/recipients/{recipientId}/messages/{messageId}',
  async (event) => { // Dans les fonctions v2, le trigger passe un seul objet 'event'

    // Vérifie que l'événement contient bien des données de document (ce qui est le cas pour onCreate)
    const snapshot = event.data; // event.data contient les données du document créé (l'équivalent de l'ancien 'snapshot')

    if (!snapshot) {
      // Cette condition est principalement pour d'autres types de triggers (onUpdate, onDelete)
      // mais la laisser pour onCreate est une bonne pratique pour la robustesse.
      logger.warn('⚠️ L\'événement onCreate ne contient pas de données de snapshot.');
      return null; // Arrête si les données du document ne sont pas présentes
    }

    // Récupère les données du nouveau message à partir du snapshot
    const newMessageData = snapshot.data();

    // Accède aux paramètres capturés par les jokers via event.params
    const senderId = event.params.senderId;
    const recipientId = event.params.recipientId;
    const messageId = event.params.messageId;

    // Utilise le logger de v2 pour un meilleur logging dans Cloud Logs
    logger.info(`📥 [sendNotificationOnMessage] Triggered for message | Sender UID: ${senderId} | Recipient UID: ${recipientId} | Message ID: ${messageId}`, { structuredData: true });
    logger.debug('Message data:', newMessageData);


    // --- 1. Récupérer le token FCM du destinataire ---
    let recipientToken = null;
    try {
      // Accède à Firestore via l'Admin SDK
      const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();

      if (!recipientDoc.exists) {
        // Si le document utilisateur du destinataire n'existe pas, on ne peut pas lui envoyer de notification.
        logger.warn(`⚠️ [sendNotificationOnMessage] Document destinataire (UID: ${recipientId}) non trouvé. Impossible d'envoyer la notification.`, { structuredData: true });
        return null; // Arrête l'exécution
      }

      const recipientData = recipientDoc.data();
      // Récupère le champ 'fcmToken' stocké par l'application Flutter
      recipientToken = recipientData.fcmToken;

      if (!recipientToken) {
        // Si le destinataire existe mais n'a pas de token FCM enregistré sur cet appareil.
        logger.info(`🪪 [sendNotificationOnMessage] Destinataire (UID: ${recipientId}) n'a pas de token FCM enregistré. Notification non envoyée.`, { structuredData: true });
        return null; // Arrête l'exécution
      }

      logger.debug(`[sendNotificationOnMessage] Token FCM du destinataire (${recipientId}): ${recipientToken}`);

    } catch (error) {
      // Enregistre l'erreur si la lecture Firestore ou l'accès aux données échoue
      logger.error(`❌ [sendNotificationOnMessage] Erreur lors de la récupération du token FCM pour UID ${recipientId}:`, error);
      return null; // Arrête l'exécution en cas d'erreur
    }


    // --- 2. Construire le payload de la notification ---

    // Extrait les informations nécessaires du message pour la notification.
    const senderName = newMessageData.name || 'Quelqu\'un'; // Utilise le nom de l'expéditeur s'il est dans le message, sinon un défaut
    const messageText = newMessageData.text; // Le contenu texte du message

    // Définir le contenu de la notification.
    // 'notification' est utilisé par le système d'exploitation pour afficher la notif.
    // 'data' est passé directement à l'application pour un traitement personnalisé.
    const payload = {
      notification: {
        title: `Nouveau message de ${senderName}`, // Titre de la notification visible par l'utilisateur
        body: messageText ? (messageText.length > 150 ? messageText.substring(0, 147) + '...' : messageText) : 'Vous avez reçu un nouveau contenu.', // Corps de la notification, tronqué si trop long
        // Tu peux ajouter d'autres champs 'notification' ici (ex: 'sound', 'badge', 'icon').
        // icon: ... // Chemin vers une petite icône (drawable Android)
        // color: ... // Couleur d'accentuation pour l'icône/notif Android
      },
      // Le champ 'data' est crucial pour passer des infos à ton application Flutter.
      // L'application utilisera ces données pour, par exemple, naviguer vers la bonne conversation.
      data: {
        // IMPORTANT: Les valeurs dans le champ 'data' DOIVENT être des chaînes de caractères.
        senderId: senderId,
        recipientId: recipientId, // C'est l'UID de l'utilisateur qui reçoit la notif (l'utilisateur actuel)
        messageId: messageId, // L'ID du message qui a déclenché la notif
        messageType: (newMessageData.type || 'text').toString(), // Assure-toi que c'est une string
        // Tu peux ajouter d'autres données du message si nécessaire, en t'assurant qu'elles sont des strings.
      },
    };


    // --- 3. Envoyer la notification via FCM ---
    try {
            // Utilise l'Admin SDK Messaging pour envoyer la notification.
            // sendToDevice est la méthode pour envoyer à un ou plusieurs tokens spécifiques.
            // Puisque tu n'envoies qu'à UN SEUL token ici (recipientToken),
            // la méthode send() ou sendEachForDevice() avec une liste d'un seul token
            // pourrait être légèrement plus idiomatique pour un envoi unique, mais sendToDevice fonctionne aussi.
            // La réponse de sendToDevice pour un seul token est un objet avec un tableau 'results'.
            const response = await admin.messaging().sendToDevice(recipientToken, payload);

            // Enregistre la réponse de l'envoi FCM (utile pour le debug et la gestion des erreurs de token)
            logger.info('✅ [sendNotificationOnMessage] Réponse de l\'envoi FCM:', response);

            // --- Logique de nettoyage des tokens invalides ---
            // Pour sendToDevice avec un seul token, la réponse.results est un tableau d'un élément.
            if (response.results && response.results.length > 0) {
                const result = response.results[0]; // Accède au résultat pour le token unique
                const error = result.error;

                if (error) {
                    logger.error('❌ [sendNotificationOnMessage] Échec de l\'envoi au token:', recipientToken, error);

                    // Vérifie si l'erreur indique un token invalide ou non enregistré.
                    // Ces codes d'erreur proviennent de la documentation FCM.
                    if (error.code === 'messaging/invalid-registration-token' ||
                        error.code === 'messaging/registration-token-not-registered') {
                        // Le token est invalide, supprime-le de Firestore.
                        logger.warn(`🗑️ [sendNotificationOnMessage] Token invalide détecté (${error.code}). Suppression du token de Firestore pour UID: ${recipientId}`, { structuredData: true });

                        try {
                            // Supprime le champ 'fcmToken' du document utilisateur.
                            await admin.firestore().collection('users').doc(recipientId).update({
                                fcmToken: admin.firestore.FieldValue.delete()
                            });
                            logger.info(`✅ [sendNotificationOnMessage] Token invalide supprimé de Firestore pour UID: ${recipientId}`, { structuredData: true });
                        } catch (deleteError) {
                            logger.error(`❌ [sendNotificationOnMessage] Erreur lors de la suppression du token invalide pour UID ${recipientId}:`, deleteError);
                        }
                    }
                    // Tu pourrais gérer d'autres codes d'erreur ici si nécessaire
                } else {
                    logger.info('✅ [sendNotificationOnMessage] Notification envoyée avec succès au token.', { structuredData: true });
                }
            } else {
                 // Ce cas ne devrait pas arriver avec sendToDevice pour un seul token, mais ajoutons un log pour la robustesse.
                 logger.warn('⚠️ [sendNotificationOnMessage] Réponse FCM inattendue (pas de résultats).', response);
            }

          } catch (error) {
            // Enregistre l'erreur si l'appel à admin.messaging().sendToDevice() échoue avant de recevoir une réponse structurée.
            // Cela peut arriver pour des problèmes de configuration FCM ou des erreurs au niveau de l'API.
            logger.error('❌ [sendNotificationOnMessage] Erreur générale lors de l\'envoi de la notification FCM:', error);
            // TODO: Gérer cette erreur d'envoi (ex: notifier l'expéditeur ? logging plus détaillé ?)
          }

          // Les Cloud Functions déclenchées par des événements (comme Firestore)
          // doivent retourner un Promise, null, ou une valeur pour signaler leur fin.
          // Ici, on retourne null après avoir attendu toutes les opérations asynchrones.
          return null;
        });

// TODO: Ajouter d'autres Cloud Functions ici si nécessaire (ex: pour la suppression de messages/destinataires, etc.)

// 📄 FIN de functions/index.js
