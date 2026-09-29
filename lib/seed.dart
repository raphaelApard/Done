import 'models.dart';

/// Sample projects shown on the very first launch.
List<Project> seedProjects() => [
      Project(name: 'Refonte du portfolio', tasks: [
        Task(title: 'Rédiger la page à propos'),
        Task(title: 'Exporter les maquettes en PNG'),
        Task(title: 'Mettre en ligne la v1'),
        Task(title: 'Choisir la typographie', done: true),
        Task(title: 'Acheter le nom de domaine', done: true),
      ]),
      Project(name: 'Appartement', tasks: [
        Task(title: 'Appeler le plombier'),
        Task(title: 'Repeindre la chambre'),
        Task(title: 'Rendre les clés de la cave', done: true),
      ]),
      Project(name: 'Lectures', tasks: [
        Task(title: 'Finir « Le Comte de Monte-Cristo »'),
        Task(title: 'Commander le prochain Tokarczuk'),
      ]),
      Project(name: 'Voyage à Lisbonne', tasks: [
        Task(title: 'Réserver les billets', done: true),
        Task(title: 'Trouver un logement', done: true),
        Task(title: 'Lister les restaurants', done: true),
      ]),
    ];
