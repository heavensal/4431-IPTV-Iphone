# Avancement — 4431 IPTV iPhone

Version prévue : 0.0.1.

## Réalisé

- [x] Créer le dépôt Git local sans écraser un projet existant.
- [x] Créer le projet Xcode iOS 17+, avec app iPhone et extension WidgetKit/ActivityKit.
- [x] Porter le client Xtream/M3U, les catégories et la recherche globale.
- [x] Porter les saisons, épisodes et illustrations du fournisseur.
- [x] Implémenter le stockage Keychain et la déconnexion.
- [x] Implémenter le lecteur MobileVLCKit, les commandes tactiles, les pistes audio et sous-titres.
- [x] Implémenter les modes plein écran et réduit ainsi que le masquage des commandes après deux secondes.
- [x] Implémenter la Live Activity et son lien de retour au lecteur.
- [x] Appliquer le thème bleu nuit/violet et créer l’icône.
- [x] Compiler l’extension Dynamic Island pour simulateur.
- [x] Compiler l’app pour simulateur iPhone 17 Pro.
- [x] Exécuter les quatre tests de catalogue sur simulateur, avec zéro échec.
- [x] Ajouter et exécuter un test de décodage vidéo local, avec arrêt du lecteur vérifié.
- [x] Installer et lancer l’app sur simulateur.
- [x] Recompiler avec signature locale pour vérifier le Trousseau dans des conditions adaptées.

## Itération en cours

- [x] Vérifier visuellement l’écran de connexion après signature.
- [x] Terminer le téléchargement de MobileVLCKit 3.7.5 depuis VideoLAN.
- [x] Finaliser le script de téléchargement avec empreinte SHA-256.
- [x] Synchroniser les dernières sources et ressources dans ce dépôt local.
- [x] Compiler la version iPhone physique arm64.
- [x] Produire une IPA non signée et clairement identifiée comme à signer avant installation.
- [x] Vérifier le contenu et les dépendances de l’IPA.
- [x] Finaliser le README avec téléchargement et installation Xcode/mode développeur.
- [x] Vérifier l’absence de secrets dans les fichiers suivis par Git.
- [x] Créer le dépôt GitHub public 4431-IPTV-Iphone et pousser les sources.
- [x] Publier la release 0.0.1 avec l’IPA non signée et les sources.
- [x] Vérifier les liens de la release et remettre le récapitulatif.

## Validation sur appareil réel

- [ ] Configurer une Team et un profil couvrant l’app et son extension.
- [ ] Installer sur un iPhone physique (aucun appareil connecté détecté).
- [ ] Vérifier la lecture réelle TV/film/épisode avec le fournisseur de l’utilisateur.
- [ ] Vérifier le changement de langue et de sous-titres sur un média multipiste.
- [ ] Vérifier la Dynamic Island sur appareil, les interruptions et le retour depuis l’arrière-plan.
- [ ] Publier un lien TestFlight après configuration Apple Developer et distribution.

## Journal

- Le simulateur est disponible et les quatre tests passent.
- La première capture provenait d’un build non signé et affichait une erreur du Trousseau. Le build a été recompilé avec signature locale pour vérifier ce point.
- La partie simulateur de MobileVLCKit a été extraite et sa signature vérifiée. Le téléchargement complet du paquet officiel est très lent et retarde la compilation physique.
- Un certificat Apple Development est présent sur le Mac, mais aucun iPhone physique ni profil de provisioning adapté n’a été détecté.
- Une IPA non signée ne s’installe pas directement depuis Safari. Le README décrit l’installation personnelle signée par Xcode et les conditions de distribution TestFlight.

- Le contrôle visuel du build signé confirme le thème et l’absence d’erreur Keychain au lancement. Un test supplémentaire de décodage vidéo local est en cours.

- Cinq tests passent sur simulateur, dont le décodage effectif de la vidéo fictive. Les sélecteurs audio et sous-titres utilisent désormais des dialogues tactiles qui suspendent le masquage des commandes.

- 5 novembre : archive VideoLAN reçue, empreinte enregistrée. Build Release arm64 réussi et archive IPA vérifiée (app, widget et framework présents). Dépôt et release publics, téléchargements vérifiés.
