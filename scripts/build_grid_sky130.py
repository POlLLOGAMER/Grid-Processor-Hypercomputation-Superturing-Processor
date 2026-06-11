#!/usr/bin/env python3
"""
build_grid_sky130.py
====================
SkyWater 130nm Grid Processor Layout Generator.
Compatible with TinyTapeout 7 standards and OpenLane 2 flow.

Usage:  python3 build_grid_sky130.py [--output-dir DIR] [--run]
"""
import argparse
import json
import os
import sys
from pathlib import Path

# ------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------
GRID_ROWS, GRID_COLS = 8, 8
PDK_ROOT = os.environ.get("PDK_ROOT", "/opt/pdks/sky130A")

# ------------------------------------------------------------------
# Directory setup
# ------------------------------------------------------------------
def setup(root: Path) -> dict:
    dirs = {}
    for d in ("src","openlane","constraints","scripts","docs","gds","firmware"):
        p = root / d;  p.mkdir(parents=True, exist_ok=True)
        dirs[d] = p
    return dirs

# ------------------------------------------------------------------
# Flattened grid cell array (for OpenLane synthesis)
# ------------------------------------------------------------------
def gen_cell_array(dst: Path) -> Path:
    p = dst / "grid_cell_array.v"
    lines = [
        "`default_nettype none",
        "`timescale 1ns / 1ps",
        "",
        "module grid_cell_array (",
        "    input  wire        clk,",
        "    input  wire        rst_n,",
        "    input  wire        enable,",
        "    input  wire [7:0]  seed_data,",
        "    output wire [63:0] cell_outputs,",
        "    output wire [63:0] cell_stable_flags,",
        "    output wire        global_stable",
        ");",
        "",
        "    wire [3:0] cell_state [0:63];",
        "",
    ]
    for i in range(GRID_ROWS):
        for j in range(GRID_COLS):
            idx = i * GRID_COLS + j
            ni = (i-1+GRID_ROWS) % GRID_ROWS
            si = (i+1) % GRID_ROWS
            ej = (j+1) % GRID_COLS
            wj = (j-1+GRID_COLS) % GRID_COLS
            seed = f"{{4'b0000, seed_data[{j}]}}" if i == 0 else "4'b0000"
            lines += [
                f"    grid_cell u_cell_{idx} (",
                f"        .clk(clk), .rst_n(rst_n & enable), .enable(1'b1),",
                f"        .nw(cell_state[{ni*8+wj}]), .n(cell_state[{ni*8+j}]),",
                f"        .ne(cell_state[{ni*8+ej}]), .w(cell_state[{i*8+wj}]),",
                f"        .e(cell_state[{i*8+ej}]),",
                f"        .sw(cell_state[{si*8+wj}]), .s(cell_state[{si*8+j}]),",
                f"        .se(cell_state[{si*8+ej}]),",
                f"        .seed_in({seed}),",
                f"        .state_out(cell_state[{idx}]),",
                f"        .is_stable(cell_stable_flags[{idx}])",
                f"    );",
                f"    assign cell_outputs[{idx*4+3}:{idx*4}] = cell_state[{idx}];",
                "",
            ]
    lines += [
        "    assign global_stable = &cell_stable_flags[63:0];",
        "endmodule",
        "",
    ]
    p.write_text("\n".join(lines))
    return p

# ------------------------------------------------------------------
# OpenLane 2 config
# ------------------------------------------------------------------
def gen_openlane_cfg(dst: Path) -> Path:
    p = dst / "config.json"
    cfg = {
        "meta": {"version": 2, "flow": "OpenLane 2"},
        "design_name": "tt_um_grid_oracle",
        "top_module":  "tt_um_grid_oracle",
        "pdk": "sky130A", "scl": "sky130_fd_sc_hd",
        "clock_nets": ["ui_clk"], "clock_period": 50, "clock_uncertainty": 2,
        "max_fanout_const": 16, "max_capacitance_const": 0.05, "max_transition_const": 1.5,
        "yosys_synth_options": "-flatten",
        "die_area": "0 0 160 200", "core_area": "5 5 155 195",
        "fp_core_utilization": 40, "fp_core_aspect_ratio": 0.8,
        "route_max_layer": "met5", "route_min_layer": "met1",
        "diode_insertion": True,
        "vdd_pins": ["vccd1","vccd2"], "gnd_pins": ["vssd1","vssd2"],
        "pwr_net": "vccd1", "gnd_net": "vssd1",
        "max_drc_iterations": 10, "drc_exhaustive": True,
        "gds_allow_empty": True,
        "tt_include_wrapper": True, "tt_user_id": "0x00000001",
        "tt_project_name": "grid_oracle", "tt_clock_period": 50,
    }
    p.write_text(json.dumps(cfg, indent=2))
    return p

# ------------------------------------------------------------------
# GDS merge script
# ------------------------------------------------------------------
def gen_gds_script(dst: Path) -> Path:
    p = dst / "generate_gds.sh"
    p.write_text(f"""#!/bin/bash
set -e
GDS_DIR="$(dirname "$0")/../gds"
PDK_ROOT="${{PDK_ROOT:-{PDK_ROOT}}}"
echo "[1/3] Adding seal ring..."
klayout -z -rd in_gds="$GDS_DIR/../openlane/runs/final/gds/*.gds" \\
        -rd out_gds="$GDS_DIR/tt_um_grid_oracle_sealed.gds" \\
        -r "$GDS_DIR/../openlane/scripts/add_seal_ring.lym"
echo "[2/3] Adding fill cells..."
klayout -z -rd in_gds="$GDS_DIR/tt_um_grid_oracle_sealed.gds" \\
        -rd out_gds="$GDS_DIR/tt_um_grid_oracle_filled.gds" \\
        -r "$GDS_DIR/../openlane/scripts/add_fillers.lym"
echo "[3/3] DRC check..."
klayout -z -rd in_gds="$GDS_DIR/tt_um_grid_oracle_filled.gds" \\
        -rd report="$GDS_DIR/drc_report.xml" \\
        -r "$GDS_DIR/../openlane/scripts/drc_check.lym"
echo "Final GDS: $GDS_DIR/tt_um_grid_oracle_filled.gds"
""")
    p.chmod(0o755)
    return p

# ------------------------------------------------------------------
# Build manifest
# ------------------------------------------------------------------
def gen_manifest(root: Path) -> Path:
    m = root / "build_manifest.json"
    steps = [
        ("lint",      "verilator",  "verilator --lint-only -Wall src/*.sv --top-module tt_um_grid_oracle"),
        ("simulate",  "verilator",  "verilator --cc src/*.sv --exe src/tb_grid_oracle.sv && make -j$(nproc)"),
        ("synthesis", "yosys",      "yosys -c openlane/synth.tcl"),
        ("place_route","openlane2", "openlane --config openlane/config.json"),
        ("gds",       "klayout",    "bash scripts/generate_gds.sh"),
        ("drc",       "magic",      "magic -dnull -noconsole -rcfile sky130A/libs.tech/magic/sky130A.magicrc gds/drc.tcl"),
        ("lvs",       "netgen",     "netgen -batch lvs gds/final.gds gds/netlist.spice"),
        ("firmware",  "pico-sdk",   "cd firmware && mkdir -p build && cd build && cmake .. && make"),
        ("submit",    "tt-tool",    "tt submit --project grid_oracle --gds gds/tt_um_grid_oracle_filled.gds"),
    ]
    manifest = {
        "project": "grid_oracle", "version": "1.0.0",
        "technology": "sky130", "tt_version": 7,
        "build_steps": [{"step": i+1, "name": n, "tool": t, "command": c, "description": f"Step {i+1}"}
                        for i,(n,t,c) in enumerate(steps)]
    }
    m.write_text(json.dumps(manifest, indent=2))
    return m

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def main():
    pa = argparse.ArgumentParser()
    pa.add_argument("--output-dir", default=".")
    pa.add_argument("--run", action="store_true")
    args = pa.parse_args()
    root = Path(args.output_dir).resolve()
    print("=" * 60)
    print("  Grid Processor Layout Generator")
    print("  SkyWater 130nm / TinyTapeout 7")
    print("=" * 60)

    dirs = setup(root)
    print(f"[1/5] Directories under {root}")

    p = gen_cell_array(dirs["src"])
    print(f"[2/5] Generated {p}")

    p = gen_openlane_cfg(dirs["openlane"])
    print(f"[3/5] Generated {p}")

    p = gen_gds_script(dirs["scripts"])
    print(f"[4/5] Generated {p}")

    p = gen_manifest(root)
    print(f"[5/5] Generated {p}")

    print("\nAll files generated successfully.")

if __name__ == "__main__":
    main()
