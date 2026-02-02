README — Mini SQL Interpreter (Flex & Bison)

1. Introduction:
    GLSimpleSQL est un mini-interpréteur SQL développé dans le cadre du module théorie des langages et compilation
    capable d’analyser, vérifier et afficher des statistiques sur un sous-ensemble de requêtes SQL simples.

2. Exigences:
    .FLEX version 2.6.4 ou supérieure : pour la partie lexicale
    .BISON: pour 3.8.2 ou supérieure : pour la partie syntaxique
    .Compilateur GCC version 15.1.0 ou supérieure : pour compiler le projet
    .makefile : recommander pour simplifier la compilation

3. Structure du projet:

    GLSimpleSQL/
    │
    ├── src/                  # Ce dossier contient le code source du projet.
    |   |                  
    │   ├── sql.l             → Code source Analyseur lexical (Flex)
    │   ├── sql.y             → Code source Analyseur syntaxique (Bison)
    │   └── ast.h/.c          → Structures d’arbres syntaxiques, les fonctions d'analyse symentique et les fonctions auxiliaire
    │
    ├── tests/                # Ce dossier contient les fichiers de test de vérification.
    |   |
    │   ├── baseTests.txt     → Requêtes simples, correctes, permettant de valider les bases du parser.
    │   ├── errorTests.txt    → Cas de figure déclenchant des erreurs lexicales ou syntaxiques.
    │   └── generalTests.txt  → Scénarios divers combinant plusieurs commandes.
    │
    ├── docs/                           # Ce dossier contient les documentations du projet.          
    │   ├── MiniProjetLSTGL2526.pdf     → énoncé du projet.
    |   ├── Grammaire.pdf               → La grammaire formelle complète du langage GLSimpleSQL.
    |   └── Rapport.pdf                 → description détaillée du projet.
    |
    ├── main.c                → Contient la fonction principale main(), le Point d’entrée du programme.
    ├── Makefile              → Script pour compiler le projet.
    ├── Video                 → Une Vidéo montrant l’exécution et le test.
    └── README.txt

4. Compilation et exécution :
    Assurez-vous que Flex, Bison et GCC sont installés.

    Dans votre terminal ( cmd \ powerShell \ ... ), changez de répertoire pour accéder au dossier du projet GLSimpleSQL.
        > cd ...\GLSimpleSQL
    
    Exécuter la commande make
        > make
    Pour nettoyer :
        > make clean

    Si vous n’avez pas le makefile, exécuter ces commande l'une après l'autre
        > bison -d -o src/sql.tab.c src/sql.y
        > flex -o src/lex.yy.c src/sql.l
        > gcc -o sql main.c src/lex.yy.c src/sql.tab.c src/ast.c

    Cela génère l’exécutable: sql.exe

    pour exécuter taper l'une des ces commandes:
        > .\sql input_file  # exécuter un fichier contenant des commandes exemple se trouve dans tests\baseTests.txt
                            # > .\sql tests\baseTests.txt

        > .\sql             # saisir les requête directement.

5. Auteur:
    ELYOUSFI FAYSAL
    si vous trouvez un problème, veuillez me contacter sur email: fay.elyousfi1@gmail.com