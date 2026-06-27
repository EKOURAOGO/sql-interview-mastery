# SQL Interview Mastery - MySQL

Base de données de test et 64 requêtes SQL avancées couvrant les questions les plus posées en entretien technique Data Analyst / Data Engineer (PwC, Deloitte, EY, KPMG, Accenture). Schéma, données et requêtes sont **exécutables tels quels** sur MySQL 8.0+ ou MariaDB 10.5+, et validés par une suite de tests automatisés.

---

## Pourquoi ce projet

La plupart des recueils de questions SQL en ligne donnent des requêtes isolées, sans schéma ni données pour les exécuter. Ici, tout est fourni : un schéma relationnel complet, un jeu de données avec des cas particuliers volontaires (départements vides, clients sans achat, salariés sans historique...), et chaque requête est vérifiée par un test qui contrôle le résultat, pas seulement l'absence d'erreur SQL.

---

## Structure du projet

```
sql-interview-mastery/
├── 01_schema.sql                          # 15 tables, contraintes FK, hiérarchie auto-référencée
├── 02_seed_data.sql                       # Données de test avec cas limites volontaires
├── queries_01_fundamentals.sql            # 21 requêtes — filtrage, agrégation, jointures
├── queries_02_window_functions_ctes.sql   # 26 requêtes — fenêtrage, CTE récursives, gaps & islands
├── queries_03_business_reporting.sql      # 17 requêtes — séries temporelles, KPIs métier
├── run_tests.sh                           # Suite de 19 tests automatisés avec assertions
└── README.md
```

---

## Schéma de données

15 tables couvrant trois domaines métier classiques en entretien :

| Domaine | Tables |
|---------|--------|
| RH | `employees` (hiérarchie auto-référencée), `departments`, `salary_history`, `promotions`, `attendance`, `projects`, `project_assignments`, `shifts` |
| Ventes | `customers`, `products`, `orders`, `order_items`, `sales`, `product_reviews` |
| Activité | `user_logins`, `bookings` |

**Cas limites intégrés au jeu de données** (pour tester les `LEFT JOIN`, `NOT EXISTS`, et la gestion des `NULL`) :

- Un département sans aucun employé
- Un employé sans département ni manager
- Un client n'ayant jamais acheté
- Un produit jamais vendu et jamais commandé
- Des employés sans historique de salaire ni promotion
- Des séries de connexions et de présences consécutives, pour tester les motifs *gaps & islands*
- Des créneaux horaires et réservations qui se chevauchent volontairement

---

## Catégories de requêtes couvertes

**Fondamentaux** - second salaire le plus élevé, doublons, jointures manager/employé, agrégations avec `HAVING`, `LEFT JOIN ... WHERE NULL` pour les anti-jointures, Nième salaire le plus élevé.

**Fenêtrage et CTE** - `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `PERCENT_RANK`, `NTILE`, `CUME_DIST`, totaux courants, moyennes mobiles, requêtes récursives (chaîne hiérarchique complète, ascendants, descendants), détection de plages qui se chevauchent, *gaps & islands* sur les séquences de dates.

**Reporting métier** - évolution mensuelle des ventes en pourcentage, ancienneté moyenne par département, valeur moyenne de commande, comptage cumulé de commandes par client, notation moyenne des produits.

---

## Installation

```bash
# Créer la base et charger le schéma
mysql -u root < 01_schema.sql

# Charger les données de test
mysql -u root < 02_seed_data.sql

# Exécuter un fichier de requêtes
mysql -u root sql_interview_db < queries_01_fundamentals.sql
```

---

## Lancer les tests

La suite de tests vérifie le **résultat** de chaque requête contre une valeur attendue, calculée manuellement à partir du jeu de données.

```bash
chmod +x run_tests.sh
./run_tests.sh
```

Sortie attendue :

```
RESULTS: 19 passed, 0 failed
```

Exemples d'assertions vérifiées :

| Test | Valeur attendue |
|------|-----------------|
| Second salaire le plus élevé | 15000.00 |
| Département sans employé détecté | Empty Department |
| Plus longue série de connexions (user 1) | 5 jours |
| Nombre de subordonnés directs du manager 101 | 4 |
| Paire de réservations qui se chevauchent | 1 (Room A) |
| Créneaux horaires en conflit (employé 103) | 2 lignes |

---

## Notes techniques

- Toutes les requêtes utilisent la syntaxe **MySQL 8.0+** (`DATE_SUB`, `DATE_FORMAT`, `GROUP_CONCAT`, `WITH RECURSIVE`) — pas de syntaxe PostgreSQL (`DATE_TRUNC`, `STRING_AGG`, `INTERVAL 'n months'`).
- `MEDIAN` n'existant pas nativement en MySQL, il est émulé par fenêtrage (`ROW_NUMBER` + `COUNT(*) OVER()`).
- Les dates de référence (`CURRENT_DATE`) sont fixées à `'2024-12-01'` pour garantir des résultats reproductibles, le jeu de données étant historique.

---

## Stack technique

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Window%20Functions%20·%20CTE%20·%20Recursive-blue?style=flat-square)
![Bash](https://img.shields.io/badge/Bash-Tests%20automatisés-4EAA25?style=flat-square&logo=gnubash&logoColor=white)

---

## Auteur

**Emmanuel KOURAOGO**

[GitHub](https://github.com/EKOURAOGO) · [Email](mailto:ekouraogo73@gmail.com)
