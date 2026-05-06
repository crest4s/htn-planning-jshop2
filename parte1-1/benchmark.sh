#!/usr/bin/env bash
# Run JSHOP2 on benchmark problems and record elapsed time.
# Usage: ./benchmark.sh [path/to/JSHOP2.jar]
#
# JSHOP2 jar can be downloaded from: https://sourceforge.net/projects/shop/files/JSHOP2/
# Typical invocation: java -jar JSHOP2.jar -r emergency problem_name

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

# Write TSV header
echo -e "problem\tlocations\tpersons\tcrates\tgoals\ttime_ms" > "$RESULTS_FILE"

for problem_file in "$PROBLEMS_DIR"/problem_d1_r0_l*.lisp; do
    problem_name=$(basename "$problem_file" .lisp)
    echo "Running: $problem_name"

    # Parse size info from filename: problem_d1_r0_l<L>_p<P>_c<C>_g<G>
    IFS='_' read -ra parts <<< "$problem_name"
    L="${parts[3]#l}"
    P="${parts[4]#p}"
    C="${parts[5]#c}"
    G="${parts[6]#g}"

    start_ms=$(date +%s%3N)

    java -jar "$JSHOP2_JAR" -r "$DOMAIN" \
        "$PROBLEMS_DIR/$problem_name" \
        > "${problem_name}.plan" 2>&1

    end_ms=$(date +%s%3N)
    elapsed=$((end_ms - start_ms))

    echo -e "${problem_name}\t${L}\t${P}\t${C}\t${G}\t${elapsed}" >> "$RESULTS_FILE"
    echo "  -> ${elapsed} ms"
done

echo ""
echo "Results saved to $RESULTS_FILE"
