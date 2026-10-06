# htn-planning-jshop2

Hierarchical Task Network (HTN) planning with JSHOP2 for an emergency logistics domain: drones pick up crates with supplies (food, medicine...) at a depot and deliver them to the people who need them. The domain is the same one modelled in PDDL in [pddl-drone-logistics](https://github.com/crest4s/pddl-drone-logistics), rewritten as HTN methods and operators.

Lab project (lab 2) for the *Planificación Automática* (Automated Planning) course at the University of Alcalá (UAH), 2025–26 academic year.

## Contents

| Folder | Description |
|--------|-------------|
| `parte1-1/` | Basic SHOP2 domain (`emergency.lisp`) with an `(enviar-todo)` task that sends every needed crate. People's needs are part of the initial state. Includes a problem generator (`generate-problem.py`), generated problems from 2 to 375 locations (`problems/`), their plans (`soluciones/`) and `benchmark.sh` to time JSHOP2 on all of them. |
| `parte1-2/` | Extended domain (`emergency2.lisp`) with carriers, fluents and advanced SHOP2 features: axioms to serve the location with the greatest need first, choose the smallest suitable carrier, load to capacity and make multi-stop trips. Seven hand-written problems (`problems/problemN`) covering the different situations, each with its plan (`problemN.sln`). |

Main operators: `!vuelo`, `!cargar`, `!cargar-suelta`, `!entregar`, `!entregar-suelta`, `!coger-transportador`, `!dejar-transportador`. Main methods: `enviar-todo`, `atender-localizacion`, `atender-multiparada`, `carga-maxima`, `carga-si-necesario`, `entrega-si-necesario`, `descarga-todo`, `ir-a`.

## Requirements

- Java (JDK 17 was used)
- Python 3 for the problem generators
- **JSHOP2**, which is not included in this repository. Download it from SourceForge: <https://sourceforge.net/projects/shop/files/JSHOP2/>. The course used a packaged version with `jshop2-console.sh` / `jshop2-gui.sh` launchers and a `domains/` folder.

## Usage

Generate a problem (basic domain):

```bash
cd parte1-1
python3 generate-problem.py -d 1 -r 0 -l 10 -p 10 -c 10 -g 10 -o problems
```

Run JSHOP2 with the course launchers: copy the domain file into `JSHOP2/domains/<name>/<name>` (no extension) and the problem into `JSHOP2/domains/<name>/problem`, then from the `JSHOP2/` folder:

```bash
./jshop2-console.sh <name>   # prints the plan
./jshop2-gui.sh <name>       # shows the plan in the GUI
```

Under the hood the launcher compiles the domain and the problem to Java and runs them:

```bash
java JSHOP2.InternalDomain <name>
java JSHOP2.InternalDomain -r1 ./problem
javac <name>.java problem.java
java problem
```

(with `JSHOP2.jar` and `antlr.jar` on the `CLASSPATH`).

## Authors

- Adrián Morales Rodríguez ([@crest4s](https://github.com/crest4s))
- [@aliciasiguenza](https://github.com/aliciasiguenza)
- [@avuren13](https://github.com/avuren13)
