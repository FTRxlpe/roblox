# Mars Escape

Jeu Roblox multijoueur : survivre sur Mars, combattre des vagues d'aliens,
collecter des ressources et des matériaux, acheter du matériel à la
boutique, puis construire collectivement un vaisseau pour s'échapper vers
la Terre.

## Stack

- Luau (Lua typé Roblox)
- [Rojo](https://rojo.space/) pour synchroniser ce dépôt avec Roblox Studio
- `src/server` → `ServerScriptService`
- `src/client` → `StarterPlayer.StarterPlayerScripts`
- `src/shared` → `ReplicatedStorage`

## Lancer le projet

1. Installer [Rojo](https://rojo.space/docs/installation/) (CLI) et le
   plugin Rojo dans Roblox Studio.
2. Cloner ce dépôt en local.
3. Depuis la racine du dépôt, lancer le serveur Rojo :

   ```bash
   rojo serve
   ```

4. Dans Roblox Studio, ouvrir le plugin Rojo, se connecter à
   `localhost:34872` (port par défaut), puis cliquer sur **Connect**.
5. Le contenu de `src/` apparaît dans l'explorateur Studio. Toute
   modification de fichier en local est synchronisée automatiquement.

## Assets à créer dans Roblox Studio (non versionnés en code)

Ces éléments doivent être créés manuellement dans Studio car ce sont des
modèles 3D / parts, pas du code :

| Emplacement | Nom | Description |
|---|---|---|
| `ServerStorage` | `AlienNPC` | Modèle avec `Humanoid` + `HumanoidRootPart`, cloné par `WaveService` |
| `ServerStorage` | `AlienEgg` | Modèle avec au moins une `BasePart` (idéalement avec `PrimaryPart` défini), cloné par `EggService` |
| `ServerStorage.Weapons` | Un `Tool` par arme définie dans `Config.Shop.Items` (ex. `BasicBlaster`, `PlasmaRifle`) | Cloné et donné au joueur par `ShopService` lors d'un achat |
| `Workspace` | `AlienSpawn1`, `AlienSpawn2`, ... | Parts nommées où les aliens apparaissent |
| `Workspace` | `EggSpawn1`, `EggSpawn2`, ... | Parts nommées où les œufs apparaissent |
| `Workspace` | `ShipBuildZone` | Part sur laquelle marcher pour déposer ses matériaux |
| `Workspace` | `EarthTeleport` | Part vers laquelle les joueurs sont téléportés à la victoire |

Sans ces parts/modèles, les services correspondants affichent un
avertissement dans la sortie serveur (`warn`) plutôt que d'échouer
silencieusement.

## Configuration

Toutes les valeurs d'équilibrage (intervalle des vagues, vie des aliens,
récompenses, prix de la boutique, objectif du vaisseau, etc.) sont
centralisées dans [`src/shared/Config.lua`](src/shared/Config.lua).

Note de conception : la taille des vagues et la vie des aliens sont
tirées aléatoirement à chaque vague, indépendamment des vagues
précédentes — la difficulté ne progresse donc pas de façon strictement
croissante, pour rester accessible aux joueurs qui rejoignent en cours de
partie.

## Systèmes implémentés

- **Vagues d'aliens** (`WaveService`, `AlienAI`) : apparition périodique de
  vagues à des points nommés, taille/vie aléatoires, IA simple (poursuite
  + dégâts au contact), attribution du kill via un tag `creator` standard
  sur le `Humanoid`.
- **Ressources & matériaux** (`ResourceService`) : deux monnaies séparées
  exposées via `leaderstats`.
- **Œufs explosifs** (`EggService`) : apparition périodique, délai
  d'explosion aléatoire, distribution de matériaux aux joueurs proches.
- **PvP & loot** (`PvPService`) : perte d'un pourcentage de ressources au
  sol uniquement en cas de mort causée par un autre joueur (détecté via le
  tag `creator`), loot ramassable qui disparaît après un délai.
- **Boutique** (`ShopService` + `ShopUI`) : achat via `RemoteEvent` avec
  vérification serveur du solde, armes (`Tool`) ou packs de matériaux.
- **Construction du vaisseau** (`ShipService` + `ShipProgressUI`) :
  objectif de matériaux partagé par tout le serveur, barre de progression
  en temps réel, séquence de victoire puis téléportation vers
  `EarthTeleport`.

## Étapes suivantes

1. Créer les assets listés ci-dessus dans Roblox Studio.
2. Tester en solo, puis en partie privée avec des amis.
3. Ajuster les valeurs dans `Config.lua` selon l'équilibrage souhaité.
4. Publier via le Roblox Creator Hub.
