**Français** · [English](pwa.md)

# Done en application web (PWA)

`pwa/` est une version web autonome et installable de Done. Elle reproduit le design « Todo App v2 » fait avec Claude Design : jetons Broadsheet, Instrument Sans, cartes carrées avec anneau de progression, composeur carré dont le bouton s'élargit en « Ajouter », thème clair et thème sombre.

Elle ne partage rien avec le code Flutter, à part les icônes de l'app. Les données ne sont pas synchronisées entre les deux versions.

## Fonctionnalités

- **Projets** en grille de deux colonnes, chacun avec un anneau de progression, un compteur terminées/total et une ligne d'état (« 3 restantes »). Le total des tâches à faire est affiché à côté du titre.
- **Tâches** : en ajouter plusieurs à la suite, les cocher, les modifier en touchant le texte (Entrée enregistre, Échap annule, un titre vide supprime la tâche), les supprimer.
- **Réorganisation** : glisser une ligne à la souris, ou glisser la poignée au doigt.
- **Section « Terminées »** repliable, avec « Effacer » pour la vider.
- **Confirmation de suppression** dans une feuille en bas de l'écran, pour les projets et les tâches.
- **Thèmes** : suit le système. Sur grand écran, la barre du design (« Clair » / « Sombre ») apparaît au-dessus de l'app et le choix est mémorisé.
- **Hors ligne et installable** : un service worker met en cache l'app et sa police, et le manifeste permet de l'installer sur l'écran d'accueil.
- **Persistance locale** dans `localStorage`. Les projets d'exemple du design s'affichent à la première visite.

L'interface est en français.

## Mise en page

Sur téléphone, l'app occupe tout l'écran. Les marges que le design réserve à la barre d'état et à l'indicateur d'accueil deviennent les zones de sécurité de l'appareil. À partir de 600 px de large, la page reproduit le canevas du design : la barre du haut, puis l'app dans un cadre arrondi de 402 px de large.

## Structure

```
pwa/
├── index.html            balisage des deux écrans et de la feuille de confirmation
├── styles.css            jetons Broadsheet, variante sombre et styles du design
├── app.js                rendu et interactions (mise à jour du DOM par clé, sans framework)
├── store.js              transitions d'état, libellés et persistance, sans DOM
├── sw.js                 service worker (cache hors ligne)
├── manifest.webmanifest
├── icons/                générées par tool/generate_icons.py
└── tests/store.test.js   tests unitaires de store.js
```

Les lignes sont conservées d'un rendu à l'autre et indexées par identifiant : les animations d'entrée du design ne se jouent que pour les nouvelles lignes.

## Lancer et tester

Prérequis : Python 3 pour servir les fichiers et Node.js 20 ou plus pour les tests.

```bash
cd pwa
npm start   # python3 -m http.server 8080
npm test    # node --test
```

Ouvrir http://localhost:8080. Un service worker ne tourne que sur `localhost` ou en HTTPS. La CI lance les tests dans le job `pwa`.

## Déployer

N'importe quel hébergement statique convient : publier le contenu de `pwa/` tel quel, en HTTPS. Tous les chemins sont relatifs, l'app peut donc vivre dans un sous-dossier (GitHub Pages, par exemple).

Quand la liste des fichiers de `sw.js` change, incrémenter `VERSION` pour que les copies installées abandonnent l'ancien cache. Les modifications des fichiers existants arrivent chez les utilisateurs au lancement qui suit le téléchargement de la mise à jour.
