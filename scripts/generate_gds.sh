#!/bin/bash
set -e
GDS_DIR="$(dirname "$0")/../gds"
PDK_ROOT="${PDK_ROOT:-/opt/pdks/sky130A}"
echo "[1/3] Adding seal ring..."
klayout -z -rd in_gds="$GDS_DIR/../openlane/runs/final/gds/*.gds" \
        -rd out_gds="$GDS_DIR/tt_um_grid_oracle_sealed.gds" \
        -r "$GDS_DIR/../openlane/scripts/add_seal_ring.lym"
echo "[2/3] Adding fill cells..."
klayout -z -rd in_gds="$GDS_DIR/tt_um_grid_oracle_sealed.gds" \
        -rd out_gds="$GDS_DIR/tt_um_grid_oracle_filled.gds" \
        -r "$GDS_DIR/../openlane/scripts/add_fillers.lym"
echo "[3/3] DRC check..."
klayout -z -rd in_gds="$GDS_DIR/tt_um_grid_oracle_filled.gds" \
        -rd report="$GDS_DIR/drc_report.xml" \
        -r "$GDS_DIR/../openlane/scripts/drc_check.lym"
echo "Final GDS: $GDS_DIR/tt_um_grid_oracle_filled.gds"
