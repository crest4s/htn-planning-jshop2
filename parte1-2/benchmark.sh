#!/usr/bin/env bash
# Run JSHOP2 on benchmark problems for parte1-2 and record elapsed time.
# Usage: ./benchmark.sh [path/to/JSHOP2.jar]

set -euo pipefail

JSHOP2_JAR="${1:-JSHOP2.jar}"
DOMAIN="emergency"
PROBLEMS_DIR="problems"
RESULTS_FILE="benchmark_results.tsv"

if [[ ! -f "$JSHOP2_JAR" ]]; then
    echo "ERROR: JSHOP2 jar not found at '$JSHOP2_JAR'"
    echo "Usage: $0 [path/to/JSHOP2.jar]"
    exit 1
fi

echo -e "problem\tlocations\tcrates\tgoals\tcarriers\ttime_ms" > "$RESULTS_FILE"

for problem_file in "$PROBLEMS_DIR"/problem_d*; do
    problem_name=$(basename "$problem_file")
    echo "Running: $problem_name"

    # Parse: problem_d<D>_r<R>_l<L>_c<C>_g<G>
    IFS='_' read -ra parts <<< "$problem_name"
    R="${parts[2]#r}"
    L="${parts[3]#l}"
    C="${parts[4]#c}"
    G="${parts[5]#g}"

    start_ms=$(date +%s%3N)

    java -jar "$JSHOP2_JAR" -r "$DOMAIN" \
        "$PROBLEMS_DIR/$problem_name" \
        > "${problem_name}.plan" 2>&1

    end_ms=$(date +%s%3N)
    elapsed=$((end_ms - start_ms))

    echo -e "${problem_name}\t${L}\t${C}\t${G}\t${R}\t${elapsed}" >> "$RESULTS_FILE"
    echo "  -> ${elapsed} ms"
done

echo ""
echo "Results saved to $RESULTS_FILE"
