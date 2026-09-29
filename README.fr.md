**Français** · [English](README.md)

# Done

[![CI](https://github.com/raphaelApard/Done/actions/workflows/ci.yml/badge.svg)](https://github.com/raphaelApard/Done/actions/workflows/ci.yml)

Une app de tâches calme et pastel, organisée par projets. Écrite en Flutter, elle fonctionne hors ligne et suit le thème clair ou sombre du système.

<p>
  <img src="docs/screenshots/light-home.png" width="200" alt="Accueil, thème clair">
  <img src="docs/screenshots/light-project.png" width="200" alt="Projet, thème clair">
  <img src="docs/screenshots/dark-home.png" width="200" alt="Accueil, thème sombre">
  <img src="docs/screenshots/dark-project.png" width="200" alt="Projet, thème sombre">
</p>

## Fonctionnalités

- **Projets** avec une carte teintée, un anneau de progression et une ligne de statut (« 3 restantes »).
- **Tâches** : ajout à la chaîne, édition en place (toucher le texte), réordonnancement par glisser sur la poignée, cocher, supprimer.
- **Section « Terminées »** repliable, avec « Tout effacer » en un geste.
- **Suppression sécurisée** : projets et tâches sont supprimés après confirmation, et les projets peuvent aussi être balayés.
- **Thèmes clair et sombre** : suit le système par défaut, avec un bouton de bascule sur l'accueil.
- **Persistance locale** : tout est enregistré sur l'appareil, sans compte ni réseau.

L'interface est en français.

## Démarrage

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) 3.47 ou plus (Dart 3.13).

```bash
git clone git@github.com:raphaelApard/Done.git
cd Done
flutter pub get
flutter run
```

Choisir un appareil avec `flutter run -d <appareil>` (`flutter devices` les liste). Plus Jakarta Sans est téléchargée par `google_fonts` au premier lancement, qui demande donc une connexion réseau.

Le projet cible iOS, Android, macOS et le web. Il a été lancé et vérifié sur le simulateur iOS ; les autres cibles sont générées par `flutter create` et n'ont pas été testées à la main.

## Tests

```bash
flutter analyze
flutter test
```

La suite couvre les modèles, le store (persistance et données corrompues comprises), les thèmes, les widgets et les parcours principaux à travers les écrans. La CI lance ces deux commandes à chaque push et chaque pull request.

## Structure du projet

```
lib/
├── main.dart               point d'entrée et DoneApp (thème, langue, largeur max)
├── models.dart             Project et Task, sérialisation JSON
├── store.dart              TodoStore : état et persistance (shared_preferences)
├── seed.dart               projets d'exemple au premier lancement
├── todo_scope.dart         donne accès au store aux widgets
├── theme.dart              thèmes clair et sombre, teintes des projets
├── screens/
│   ├── home_screen.dart    liste des projets
│   └── project_screen.dart liste des tâches
└── widgets/
    ├── check_circle.dart
    ├── composer.dart       pilule flottante d'ajout
    ├── confirm_dialog.dart
    └── progress_ring.dart
```

L'état tient dans un seul `ChangeNotifier`, exposé par un `InheritedNotifier` : aucune dépendance de gestion d'état.

## Design

L'interface est un portage de la proposition « Pastel » faite avec Claude Design : Plus Jakarta Sans, cartes pastel par projet, composeur en pilule et variante sombre.

## Contribuer

Le travail se fait sur des branches courtes issues de `develop` (`feat/…`, `fix/…`, `docs/…`) et fusionnées par pull request. `main` ne reçoit que des merges taggés depuis `develop`. Les commits suivent [Conventional Commits](https://www.conventionalcommits.org/).
