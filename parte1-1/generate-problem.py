#!/usr/bin/env python3

########################################################################################
# Problem instance generator for the emergency logistics domain (SHOP2 / JSHOP2).
# Based on the Linköping University TDDD48 2021 course.
# https://www.ida.liu.se/~TDDD48/labs/2021/lab1/index.en.shtml
########################################################################################

from optparse import OptionParser
import random
import math
import sys
import os

content_types = ["food", "medicine"]


def distance(location_coords, location_num1, location_num2):
    x1 = location_coords[location_num1][0]
    y1 = location_coords[location_num1][1]
    x2 = location_coords[location_num2][0]
    y2 = location_coords[location_num2][1]
    return math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)


def flight_cost(location_coords, location_num1, location_num2):
    return int(distance(location_coords, location_num1, location_num2)) + 1


def setup_content_types(options):
    while True:
        num_crates_with_contents = []
        crates_left = options.crates
        for x in range(len(content_types) - 1):
            types_after_this = len(content_types) - x - 1
            max_now = crates_left - types_after_this
            num = random.randint(1, max_now)
            num_crates_with_contents.append(num)
            crates_left -= num
        num_crates_with_contents.append(crates_left)

        maxgoals = sum(min(num_crates, options.persons) for num_crates in num_crates_with_contents)
        if options.goals <= maxgoals:
            break

    print("Types\tQuantities")
    for x in range(len(num_crates_with_contents)):
        if num_crates_with_contents[x] > 0:
            print(content_types[x] + "\t " + str(num_crates_with_contents[x]))

    crates_with_contents = []
    counter = 1
    for x in range(len(content_types)):
        crates = []
        for y in range(num_crates_with_contents[x]):
            crates.append("crate" + str(counter))
            counter += 1
        crates_with_contents.append(crates)

    return crates_with_contents


def setup_location_coords(options):
    location_coords = [(0, 0)]  # depot
    for x in range(1, options.locations + 1):
        location_coords.append((random.randint(1, 200), random.randint(1, 200)))
    return location_coords


def setup_person_needs(options, crates_with_contents):
    need = [[False for i in range(len(content_types))] for j in range(options.persons)]
    goals_per_contents = [0 for i in range(len(content_types))]

    for goalnum in range(options.goals):
        generated = False
        while not generated:
            rand_person = random.randint(0, options.persons - 1)
            rand_content = random.randint(0, len(content_types) - 1)
            if (goals_per_contents[rand_content] < len(crates_with_contents[rand_content])
                    and not need[rand_person][rand_content]):
                need[rand_person][rand_content] = True
                goals_per_contents[rand_content] += 1
                generated = True
    return need


def main():
    parser = OptionParser(usage='python generate-problem.py [-help] options...')
    parser.add_option('-d', '--drones', metavar='NUM', dest='drones', action='store', type=int,
                      help='number of drones')
    parser.add_option('-r', '--carriers', metavar='NUM', type=int, dest='carriers',
                      help='number of carriers (use 0 for none)')
    parser.add_option('-l', '--locations', metavar='NUM', type=int, dest='locations',
                      help='number of locations apart from the depot')
    parser.add_option('-p', '--persons', metavar='NUM', type=int, dest='persons',
                      help='number of persons')
    parser.add_option('-c', '--crates', metavar='NUM', type=int, dest='crates',
                      help='number of crates available')
    parser.add_option('-g', '--goals', metavar='NUM', type=int, dest='goals',
                      help='number of delivery goals')
    parser.add_option('-o', '--output-dir', metavar='DIR', dest='output_dir', default='.',
                      help='directory to write problem file (default: current directory)')
    parser.add_option('-s', '--seed', metavar='SEED', type=int, dest='seed', default=None,
                      help='random seed for reproducibility')

    (options, args) = parser.parse_args()

    required = [('drones', options.drones), ('carriers', options.carriers),
                ('locations', options.locations), ('persons', options.persons),
                ('crates', options.crates), ('goals', options.goals)]
    for name, val in required:
        if val is None:
            print(f"You must specify --{name} (use --help for help)")
            sys.exit(1)

    if options.goals > options.crates:
        print("Cannot have more goals than crates")
        sys.exit(1)
    if len(content_types) > options.crates:
        print("Cannot have more content types than crates:", content_types)
        sys.exit(1)
    if options.goals > len(content_types) * options.persons:
        print(f"For {options.persons} persons, you can have at most "
              f"{len(content_types) * options.persons} goals")
        sys.exit(1)

    if options.seed is not None:
        random.seed(options.seed)

    print(f"Drones\t\t{options.drones}")
    print(f"Carriers\t{options.carriers}")
    print(f"Locations\t{options.locations}")
    print(f"Persons\t\t{options.persons}")
    print(f"Crates\t\t{options.crates}")
    print(f"Goals\t\t{options.goals}")

    drone = [f"drone{x+1}" for x in range(options.drones)]
    person = [f"person{x+1}" for x in range(options.persons)]
    crate = [f"crate{x+1}" for x in range(options.crates)]
    carrier = [f"carrier{x+1}" for x in range(options.carriers)]
    location = ["depot"] + [f"loc{x+1}" for x in range(options.locations)]

    crates_with_contents = setup_content_types(options)
    location_coords = setup_location_coords(options)
    need = setup_person_needs(options, crates_with_contents)

    problem_name = (f"problem_d{options.drones}_r{options.carriers}"
                    f"_l{options.locations}_p{options.persons}"
                    f"_c{options.crates}_g{options.goals}")
    output_path = os.path.join(options.output_dir, problem_name + ".lisp")

    with open(output_path, 'w') as f:
        f.write(f"(defproblem problem emergency\n(\n")

        for x in drone:
            f.write(f"  (at {x} depot)\n")
            f.write(f"  (libre {x} brazo1)\n")
            f.write(f"  (libre {x} brazo2)\n")

        for x in range(options.crates):
            crate_name = crate[x]
            content_name = content_types[0]
            for y in range(len(content_types)):
                if crate_name in crates_with_contents[y]:
                    content_name = content_types[y]
                    break
            f.write(f"  (at {crate_name} depot)\n")
            f.write(f"  (tipo {crate_name} {content_name})\n")

        for x in range(options.persons):
            person_name = person[x]
            # Persons are placed at non-depot locations so there's always something to do
            person_location = location[random.randint(1, len(location) - 1)]
            f.write(f"  (at {person_name} {person_location})\n")
            for y in range(len(content_types)):
                if need[x][y]:
                    f.write(f"  (necesita {person_name} {content_types[y]})\n")

        f.write(")\n(\n  (enviar-todo)\n)\n)\n")

    print(f"\nProblem written to: {output_path}")
    return output_path


if __name__ == '__main__':
    main()
