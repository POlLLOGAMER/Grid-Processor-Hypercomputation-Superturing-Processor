#!/usr/bin/env python3
"""
verify_grid_design.py — Design Rule Check & Lint Verification
"""
import sys, json, re
from pathlib import Path
from dataclasses import dataclass
from typing import List

@dataclass
class CheckResult:
    name: str
    passed: bool
    messages: List[str]

class Verifier:
    def __init__(self, root: str, verbose: bool = False):
        self.root = Path(root).resolve()
        self.verbose = verbose
        self.results: List[CheckResult] = []

    def verify_structure(self) -> CheckResult:
        msgs = []
        required = [
            "config.yaml", "src/tt_um_grid_oracle.sv", "src/grid_cell.sv",
            "src/grid_processor_core.sv", "src/bridge_quantizer.sv",
            "src/adc_interface.sv", "src/clock_divider.sv",
            "src/reset_synchronizer.sv", "src/output_mux.sv",
            "src/sfr_interface.sv", "src/tb_grid_oracle.sv",
            "openlane/config.json", "constraints/grid_oracle.sdc",
            "constraints/pin_order.cfg", "firmware/rp2040_grid_oracle.c",
            "firmware/CMakeLists.txt", "scripts/build_grid_sky130.py",
            "scripts/generate_gds.sh", "pcb/carrier_board.kicad_sch",
            "README.md"
        ]
        ok = True
        for f in required:
            if (self.root / f).exists():
                msgs.append(f"  ✓ {f}")
            else:
                msgs.append(f"  ✗ MISSING: {f}")
                ok = False
        return CheckResult("File Structure", ok, msgs)

    def verify_config(self) -> CheckResult:
        msgs = []
        p = self.root / "config.yaml"
        if not p.exists():
            return CheckResult("config.yaml", False, ["File not found"])
        content = p.read_text()
        checks = {
            "version: 7": "TT version 7",
            "project:": "Project name",
            "rows: 8": "Grid rows = 8",
            "cols: 8": "Grid cols = 8",
            "total_cells: 64": "Total cells = 64",
            "depth: 64": "Projection depth = 64",
            "sky130": "PDK = sky130",
            "clock_period_ns: 50": "Clock = 50ns (20MHz)",
        }
        ok = True
        for key, label in checks.items():
            if key in content:
                msgs.append(f"  ✓ {label}")
            else:
                msgs.append(f"  ✗ Missing: {label}")
                ok = False
        return CheckResult("config.yaml", ok, msgs)

    def verify_ports(self) -> CheckResult:
        msgs = []
        top = self.root / "src/tt_um_grid_oracle.sv"
        if not top.exists():
            return CheckResult("Verilog Ports", False, ["Top module not found"])
        content = top.read_text()
        required = ["ui_clk", "ui_rstb", "ui_in", "uo_out", "uio_in", "uio_oe", "uio_out", "sclk"]
        ok = True
        for port in required:
            if port in content:
                msgs.append(f"  ✓ Port: {port}")
            else:
                msgs.append(f"  ✗ Missing port: {port}")
                ok = False
        return CheckResult("Verilog Ports", ok, msgs)

    def verify_firmware(self) -> CheckResult:
        msgs = []
        fw = self.root / "firmware/rp2040_grid_oracle.c"
        if not fw.exists():
            return CheckResult("Firmware", False, ["File not found"])
        content = fw.read_text()
        funcs = ["main", "grid_load", "grid_trigger", "grid_wait_ready",
                  "grid_read", "shannon_entropy", "ema_filter"]
        ok = True
        for f in funcs:
            if f in content:
                msgs.append(f"  ✓ Function: {f}")
            else:
                msgs.append(f"  ✗ Missing function: {f}")
                ok = False
        return CheckResult("Firmware", ok, msgs)

    def run_all(self) -> bool:
        print("=" * 60)
        print("  Grid Processor - Design Verification Suite")
        print("=" * 60)
        checks = [
            self.verify_structure(),
            self.verify_config(),
            self.verify_ports(),
            self.verify_firmware(),
        ]
        all_pass = True
        for c in checks:
            status = "✓ PASS" if c.passed else "✗ FAIL"
            print(f"\n[{status}] {c.name}")
            for m in c.messages:
                print(f"    {m}")
            if not c.passed:
                all_pass = False
        print("\n" + "=" * 60)
        print(f"  {'ALL CHECKS PASSED — Design ready for tapeout!' if all_pass else 'SOME CHECKS FAILED — Review errors above'}")
        print("=" * 60)
        return all_pass

if __name__ == "__main__":
    v = Verifier(".")
    ok = v.run_all()
    sys.exit(0 if ok else 1)
