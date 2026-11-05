# 4431 IPTV · iPhone

Application native SwiftUI, conçue pour l’iPhone 15 et les modèles suivants, sous iOS 17 ou ultérieur. Thème bleu nuit et accent violet. Le projet utilise les capacités iOS plutôt qu’un blocage artificiel des modèles plus anciens.

## Télécharger et installer

Le fichier local est `dist/4431-IPTV-Iphone-0.0.1-unsigned.ipa`.

Le projet fournit les sources et une IPA **non signée à signer avant installation**. Ouvrir ce lien dans Safari ne suffit pas à installer l’application sur un iPhone. Une signature et un profil de provisioning couvrant l’app et son extension Dynamic Island sont nécessaires. Aucun lien TestFlight n’est publié à ce stade.

### Installation personnelle avec Xcode

1. Télécharger les sources sur le Mac ou cloner ce dépôt.
2. Exécuter `./Scripts/fetch-vlc.sh`, puis ouvrir `4431-IPTV-Iphone.xcodeproj`.
3. Dans Xcode → Settings → Apple Accounts, connecter son compte Apple.
4. Pour les targets **IPTVPhone** et **IPTVIsland**, activer Automatically manage signing et sélectionner la même Team. Adapter les deux Bundle Identifiers si Xcode le demande, avec l’extension sous l’identifiant principal.
5. Connecter l’iPhone au Mac, accepter « Faire confiance », puis sélectionner cet appareil dans Xcode.
6. Activer Réglages → Confidentialité et sécurité → Mode développeur sur l’iPhone si demandé, redémarrer et confirmer.
7. Lancer avec le bouton Run de Xcode. Si iOS demande d’autoriser le développeur, suivre l’indication dans Réglages → Général → VPN et gestion de l’appareil.

C’est la procédure Apple de développement sur appareil. iOS exige la signature du code. Le mode développeur permet l’exécution des apps de développement signées. Il ne rend pas installable une IPA non signée. Les signatures personnelles peuvent expirer et nécessiter de relancer depuis Xcode.

[Procédure Apple pour lancer sur un appareil](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices) · [Mode développeur](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

### Distribuer à d’autres utilisateurs

Pour un téléchargement simple sur iPhone, archiver depuis Xcode avec un compte Apple Developer Program puis distribuer sur TestFlight via App Store Connect. Ajouter le lien d’invitation TestFlight à ce README lorsque la version est disponible. Une IPA de développement ou Ad Hoc fonctionne seulement sur les appareils autorisés par son profil. Les mises à jour iOS passent par la méthode de distribution choisie.

## Fonctions

- Connexion Xtream par serveur, utilisateur et mot de passe, ou URL M3U get.php.
- Identifiants dans le Trousseau avec protection liée à l’appareil. Déconnexion et effacement.
- TV, films, séries, catégories chargées à la demande et recherche globale déclenchée explicitement.
- Saisons et épisodes avec illustrations du fournisseur et images de remplacement.
- Moteur MobileVLCKit intégré, choix des pistes audio et des sous-titres disponibles, recherche dans la vidéo.
- Commandes tactiles de 44 points minimum, masquage après deux secondes, lecture réduite pendant la navigation et plein écran avec rotation.
- Live Activity sur écran verrouillé et Dynamic Island, titre et état lecture/pause, lien pour revenir au lecteur.
- Pause lors du passage en arrière-plan. La Live Activity n’est pas un lecteur vidéo dans la Dynamic Island.
- URL et identifiants absents des sources. Utiliser HTTPS quand le fournisseur le propose.

Le catalogue M3U est chargé ligne par ligne en mémoire. La recherche globale Xtream demande successivement les trois catalogues. La mémoire dépend de la taille d’une catégorie et de la réponse fournisseur. Le décodage dépend du média reçu et de ses éventuelles protections.

## Compilation et tests

```sh
./Scripts/fetch-vlc.sh
xcodebuild -project 4431-IPTV-Iphone.xcodeproj -scheme IPTVPhone -sdk iphonesimulator -configuration Debug -derivedDataPath .build build CODE_SIGN_IDENTITY=-
```

Pour un iPhone réel, configurer la signature dans Xcode. Le script `Scripts/build-unsigned.sh` produit une IPA non signée destinée à une signature ultérieure, pas à une installation directe.

Les tests de catalogue utilisent des données fictives. Le dossier Tests vérifie l’encodage des identifiants, les catégories, les épisodes et les images. Aucun compte IPTV de test n’est fourni.

## Dépendances

MobileVLCKit 3.7.5, téléchargé depuis VideoLAN et vérifié par SHA-256. Le framework est embarqué dans le bundle. La licence distribuée avec le moteur est conservée dans Vendor. Conserver et respecter ses obligations lors d’une redistribution. Le projet Xcode est livré prêt à ouvrir. Sa génération facultative nécessite Ruby et la gem xcodeproj.

Version initiale **0.0.1**.
