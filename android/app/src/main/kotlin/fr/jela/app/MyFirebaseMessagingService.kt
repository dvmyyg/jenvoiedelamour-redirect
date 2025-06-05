package fr.jela.app // <-- Assure-toi que ceci correspond à ton package

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.util.Log // Pour les logs si tu en ajoutes

class MyFirebaseMessagingService : FirebaseMessagingService() {

    // Ce handler est appelé quand un nouveau token FCM est généré (ex: première exécution, désinstallation/réinstallation, etc.)
    // Tu as déjà géré la mise à jour du token en Flutter dans FcmService,
    // donc tu peux laisser cette méthode vide ou ajouter un simple log.
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FCM Token", "Refreshed token: $token")
        // Si tu gérais le token *nativement*, c'est ici que tu l'enverrais à ton backend.
        // Pour l'instant, ton FcmService Flutter s'en charge.
    }

    // Ce handler est appelé quand un message FCM est reçu alors que l'application est AU PREMIER PLAN.
    // La logique de gestion des messages au premier plan est déjà dans ton FcmService Flutter (onMessage listener).
    // Tu peux laisser cette méthode vide si tu gères tout en Flutter.
    // Note: Les messages avec "notification" payload ne déclenchent onMessageReceived *nativement*
    // si l'app est en arrière-plan/terminée; ils sont affichés directement par l'OS.
    // Seuls les messages "data" payload déclenchent onMessageReceived en arrière-plan.
    // Le plugin Flutter gère cela pour toi.
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d("FCM Message", "From: ${remoteMessage.from}")
        // Logique Flutter gérée par FirebaseMessaging.onMessage
    }

    // Tu peux ajouter d'autres overrides de FirebaseMessagingService ici si nécessaire,
    // mais pour une app Flutter gérant les handlers, ce minimum suffit souvent.
}
