#!/usr/bin/env python3

########################################################################################
# Problem generator for emergency logistics domain v2 (SHOP2 / JSHOP2) with fluents.
# Replaces person/crate objects with numeric fluents for stock and needs per location.
# Adds transporters with capacity fluents.
########################################################################################

from optparse import OptionParser
import random
import sys
import os

content_types = ["food", "medicine"]


def main():
    parser = OptionParser(usage='python generate-problem.py [-help] options...')
    parser.add_option('-d', '--drones', metavar='NUM', dest='drones', action='store', type=int,
                      help='number of drones')
    parser.add_option('-r', '--carriers', metavar='NUM', type=int, dest='carriers',
                      help='number of transporters (0 for none)')
    parser.add_option('-l', '--locations', metavar='NUM', type=int, dest='locations',
                      help='number of locations apart from the depot')
    parser.add_option('-c', '--crates', metavar='NUM', type=int, dest='crates',
                      help='total crates of each type available at depot')
    parser.add_option('-g', '--goals', metavar='NUM', type=int, dest='goals',
                      help='total crates needed across all locations')
    parser.add_option('-o', '--output-dir', metavar='DIR', dest='output_dir', default='.',
                      help='directory to write problem file (default: current directory)')
    parser.add_option('-s', '--seed', metavar='SEED', type=int, dest='seed', default=None,
                      help='random seed for reproducibility')
    parser.add_option('--cap-min', metavar='NUM', type=int, dest='cap_min', default=5,
                      help='minimum transporter capacity (default: 5)')
    parser.add_option('--cap-max', metavar='NUM', type=int, dest='cap_max', default=30,
                      help='maximum transporter capacity (default: 30)')

    (options, args) = parser.parse_args()

    required = [('drones', options.drones), ('carriers', options.carriers),
                ('locations', options.locations), ('crates', options.crates),
                ('goals', options.goals)]
    for name, val in required:
        if val is None:
            print(f"You must specify --{name} (use --help for help)")
            sys.exit(1)

    if options.seed is not None:
        random.seed(options.seed)

    # --- Names ---
    drones    = [f"drone{i+1}" for i in range(options.drones)]
    carriers  = [f"carrier{i+1}" for i in range(options.carriers)]
    locations = ["depot"] + [f"loc{i+1}" for i in range(options.locations)]
    non_depot = locations[1:]

    # --- Stock at depot: random split of total crates across content types ---
    stock = {}
    remaining = options.crates * len(content_types)
    for i, ct in enumerate(content_types[:-1]):
        n = random.randint(1, remaining - (len(content_types) - i - 1))
        stock[ct] = n
        remaining -= n
    stock[content_types[-1]] = remaining

    # --- Needs per location: distribute goals randomly across locations & types ---
    # goals = total units needed (sum across all locations and types)
    needs = {loc: {ct: 0 for ct in content_types} for loc in non_depot}
    goals_left = options.goals
    # ensure every location gets at least 0 (some may get 0)
    # distribute randomly
    slots = [(loc, ct) for loc in non_depot for ct in content_types]
    random.shuffle(slots)
    for loc, ct in slots:
        if goals_left <= 0:
            break
        give = random.randint(0, min(goals_left, max(1, options.goals // len(slots) + 1)))
        needs[loc][ct] += give
        goals_left -= give
    # distribute the remainder if any
    while goals_left > 0:
        loc = random.choice(non_depot)
        ct  = random.choice(content_types)
        needs[loc][ct] += 1
        goals_left -= 1

    # Ensure stock covers needs
    for ct in content_types:
        total_need = sum(needs[loc][ct] for loc in non_depot)
        if stock[ct] < total_need:
            stock[ct] = total_need

    # --- Transporter capacities ---
    capacities = {}
    for c in carriers:
        capacities[c] = random.randint(options.cap_min, options.cap_max)

    # --- Print summary ---
    print(f"Drones\t\t{options.drones}")
    print(f"Carriers\t{options.carriers}")
    print(f"Locations\t{options.locations}")
    print(f"Goals\t\t{options.goals}")
    print(f"Stock depot:\t{stock}")
    for loc in non_depot:
        print(f"  {loc} needs: {needs[loc]}")
    if carriers:
        for c in carriers:
            print(f"  {c} capacity: {capacities[c]}")

    # --- Write problem file ---
    problem_name = (f"problem_d{options.drones}_r{options.carriers}"
                    f"_l{options.locations}_c{options.crates}_g{options.goals}")
    os.makedirs(options.output_dir, exist_ok=True)
    output_path = os.path.join(options.output_dir, problem_name)

    with open(output_path, 'w') as f:
        f.write(f"(defproblem {problem_name} emergency\n(\n")

        # Drones: position and transporter status
        for dr in drones:
            f.write(f"  (at {dr} depot)\n")
            f.write(f"  (libre-trans {dr})\n")

        # Transporters: position and fluents
        for c in carriers:
            f.write(f"  (at {c} depot)\n")
            f.write(f"  (= (capacidad {c}) {capacities[c]})\n")
            f.write(f"  (= (carga {c}) 0)\n")
            for ct in content_types:
                f.write(f"  (= (en-trans {c} {ct}) 0)\n")

        # Stock at depot as fluents
        for ct in content_types:
            f.write(f"  (= (stock depot {ct}) {stock[ct]})\n")

        # Needs per location as fluents
        for loc in non_depot:
            for ct in content_types:
                f.write(f"  (= (necesita {loc} {ct}) {needs[loc][ct]})\n")

        f.write(")\n(\n  (enviar-todo)\n)\n)\n")

    print(f"\nProblem written to: {output_path}")
    return output_path


if __name__ == '__main__':
    main()
