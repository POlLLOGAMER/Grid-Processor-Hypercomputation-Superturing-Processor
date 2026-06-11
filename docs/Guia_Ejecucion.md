# Grid Processor — Guía de Ejecución y Validación

Esta guía cubre paso a paso la validación completa del diseño, desde la simulación RTL hasta la presentación del chip para tapeout en TinyTapeout 7.

---

## 1. Prerrequisitos de Entorno

### 1.1. Herramientas de EDA

| Herramienta | Versión mín. | Función |
|------------|-------------|---------|
| OpenLane 2 | v2.2.0+ | Place & Route, CTS, GDS |
| Yosys | v0.30+ | Síntesis RTL |
| Magic VLSI | v1.6+ | DRC verification |
| Netgen | v1.5+ | LVS verification |
| KLayout | v0.28+ | GDS merge, seal ring, fillers |
| Verilator | v5.0+ | Simulación y lint |
| GNU Make | v4.3+ | Build automation |

```bash
# OpenLane 2 (instalación recomendada via Docker)
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane
git checkout openlane2
./env.sh

# Pico SDK (firmware RP2040)
git clone https://github.com/raspberrypi/pico-sdk.git --recurse-submodules
export PICO_SDK_PATH=$(pwd)/pico-sdk
```

### 1.2. Variables de Entorno Requeridas

```bash
export PDK_ROOT=/opt/pdks/sky130A
export OPENLANE_ROOT=$(pwd)/OpenLane
export PICO_SDK_PATH=$(pwd)/pico-sdk
```

---

## 2. Paso 1: Verificación RTL (Lint y Simulación)

### 2.1. Lint Estático

```bash
cd grid_processor

# Verificar que todos los módulos compilan y las conexiones son consistentes
verilator --lint-only \
    -Wall \
    --top-module tt_um_grid_oracle \
    src/tt_um_grid_oracle.sv \
    src/grid_cell.sv \
    src/grid_processor_core.sv \
    src/bridge_quantizer.sv \
    src/adc_interface.sv \
    src/clock_divider.sv \
    src/reset_synchronizer.sv \
    src/output_mux.sv \
    src/sfr_interface.sv
```

**Criterio de éxito:** Cero warnings de tipo `WIDTH` y `PINMISSING`.

### 2.2. Simulación Funcional

```bash
# Compilar el testbench
verilator --cc \
    src/tt_um_grid_oracle.sv \
    src/grid_cell.sv \
    src/grid_processor_core.sv \
    src/bridge_quantizer.sv \
    src/adc_interface.sv \
    src/clock_divider.sv \
    src/reset_synchronizer.sv \
    src/output_mux.sv \
    src/sfr_interface.sv \
    --top-module tt_um_grid_oracle \
    --exe src/tb_grid_oracle.sv \
    --trace

# Construir y ejecutar
make -j$(nproc) -C obj_dir
./obj_dir/Vtb_grid_oracle
```

### 2.3. Verificar las Señales Clave en la Simulación

| Señal | Comportamiento esperado |
|-------|------------------------|
| `ui_in[7:0]` | Carga patrón seed `8'b10110010` |
| `uio_in` (TRIGGER) | Pulso alto de 1 ciclo → inicia grid |
| `grid_stable` | Alto tras ~100 ciclos de evolución |
| `convergence` | Incrementa a `4'd3` antes de READY |
| `ready_out` | Alto tras convergencia |
| `irq_out` | Alto simultáneo con READY |
| `projection_out[63:0]` | Registro 64-bit estable |
| `sf_wdata` | Bytes de resultado disponibles via SPI |

### 2.4. Visualizar Formas de Onda

```bash
gtkwave tb_grid_oracle.vcd
```

Añadir al visor: `ui_in`, `uio_in`, `uo_out`, `uio_out`, `grid_stable`, `ready`, `irq`.

---

## 3. Paso 2: Síntesis y Place & Route (OpenLane 2)

### 3.1. Preparar Netlist para OpenLane

```bash
# Asegurar que config.json apunta a los archivos correctos
cat openlane/config.json | python3 -m json.tool
```

### 3.2. Ejecutar OpenLane 2

```bash
openlane --config openlane/config.json
```

Esto ejecuta secuencialmente:
1. **Yosys** — Síntesis RTL → netlist
2. **Floorplanning** — Colocación de macros y pad ring
3. **Placement** — Ubicacióń de celdas estándar
4. **CTS** — Síntesis de árbol de reloj
5. **Routing** — Enrutamiento met1–met5
6. **Antenna fixing** — Inserción de diodos
7. **Fill insertion** — Celdas de relleno para densidad

### 3.3. Verificar Reportes

```bash
# Revisar utilización del core
cat openlane/runs/tt_um_grid_oracle/reports/placement/placement.rpt

# Verificar violaciones de timing
cat openlane/runs/tt_um_grid_oracle/reports/signoff/timing.rpt

# Verificar congestión de ruteo
cat openlane/runs/tt_um_grid_oracle/reports/routing/antenna.rpt
```

**Criterios de éxito:**
- Utilización del core: 25–45% (para 160×200 µm)
- Timing: slack ≥ 0 ns a 20 MHz
- Antenna violations: 0
- DRC errors pre-fix: < 100

---

## 4. Paso 3: Generación GDSII DRC-Clean

### 4.1. Merge con Seal Ring

```bash
bash scripts/generate_gds.sh
```

Este script ejecuta:
1. Añade **seal ring** SkyWater 130nm al perímetro del die
2. Inserta **fill cells** (metálicos y de difusión) para cumplir reglas de densidad (20–45%)
3. Corre verificación **DRC** con KLayout
4. Genera `gds/tt_um_grid_oracle_filled.gds`

### 4.2. Verificación DRC Independiente

```bash
# Magic DRC
magic -dnull -noconsole \
    -rcfile $PDK_ROOT/libs.tech/magic/sky130A.magicrc \
    <<'EOF'
gds read gds/tt_um_grid_oracle_filled.gds
drc check
drc catchup
drc report gds/drc_magic.rpt
EOF

# Contar errores
wc -l gds/drc_magic.rpt
```

**Criterio de éxito:** 0 violaciones DRC.

### 4.3. Verificación LVS

```bash
# Extraer netlist del GDS
magic -dnull -noconsole \
    -rcfile $PDK_ROOT/libs.tech/magic/sky130A.magicrc \
    <<'EOF'
gds read gds/tt_um_grid_oracle_filled.gds
extract all
ext2spice lvs
ext2spice gds/tt_um_grid_oracle.spice
EOF

# Comparar con netlist RTL
netgen -batch lvs \
    "gds/tt_um_grid_oracle.spice tt_um_grid_oracle" \
    "openlane/runs/tt_um_grid_oracle/results/synthesis/tt_um_grid_oracle.v tt_um_grid_oracle" \
    $PDK_ROOT/libs.tech/netgen/sky130A_setup.tcl \
    gds/lvs_report.txt
```

**Criterio de éxito:** "Circuits match correctly".

---

## 5. Paso 4: Firmware RP2040

### 5.1. Compilar

```bash
cd firmware
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

Output esperado: `grid_oracle_firmware.uf2`

### 5.2. Flashear al RP2040

1. Conectar el RP2040 al PC manteniendo presionado **BOOTSEL**
2. Aparecerá un drive `RPI-RP2`
3. Copiar `grid_oracle_firmware.uf2` al drive
4. El RP2040 se reinicia y ejecuta el firmware

### 5.3. Validación del Firmware

Conectar por USB serial (`/dev/ttyACM0`):

```bash
minicom -D /dev/ttyACM0 -b 115200
```

Secuencia de prueba esperada:
1. OLED muestra `GRID ORACLE v1.0` → `Init...` → `System Ready`
2. Presionar **BTN_TRIGGER** → LED azul (COMPUTE) enciende
3. Tras convergencia → LED verde (READY) enciende
4. IRQ se dispara → LED amarillo parpadea
5. OLED muestra resultado en hex + entropía de Shannon
6. Presionar **BTN_RESET** → todo vuelve a estado inicial

---

## 6. Paso 5: Submission a TinyTapeout

### 6.1. Preparar Paquete

```bash
# Verificar que todo está en orden
python3 scripts/verify_grid_design.py --verbose

# Empaquetar
tar czf grid_oracle_tapeout.tar.gz \
    src/ openlane/ constraints/ firmware/ pcb/ \
    gds/tt_um_grid_oracle_filled.gds \
    config.yaml README.md build_manifest.json
```

### 6.2. Submit via GitHub

1. Fork del repo de TinyTapeout correspondiente al shuttle activo
2. Copiar `gds/tt_um_grid_oracle_filled.gds` a `gds/user_0x00000001.gds`
3. Copiar `config.yaml` a `projects/grid_oracle/config.yaml`
4. Crear Pull Request

### 6.3. Checklist Pre-Submission

- [ ] Lint Verilator sin errores
- [ ] Simulación testbench pasa (READY + IRQ se assertan)
- [ ] OpenLane 2 completa sin DRC errors
- [ ] GDS merge con seal ring y fillers exitoso
- [ ] LVS: netlist extraída coincide con RTL
- [ ] Firmware compila sin warnings críticos
- [ ] `config.yaml` sigue esquema TT7
- [ ] `pin_order.cfg` completo y consistente
- [ ] Área del die ≤ 160×200 µm
- [ ] User ID único asignado

---

## 7. Diagnóstico de Problemas Comunes

### El grid no converge
- Verificar que `trigger` se mantiene alto exactamente 1 ciclo
- Aumentar `max_iterations` en `config.yaml` (de 256 a 512)
- Comprobar que `rst_n` está en alto durante la computación

### READY nunca se asserta
- Verificar la señal `grid_stable` en simulación
- Confirmar que `convergence_threshold = 3` se alcanza
- Revisar que las celdas del grid tienen seed input conectado

### DRC violations en GDS
- Ejecutar `generate_gds.sh` con `set -x` para ver paso exacto
- Revisar `drc_report.xml` en KLayout para ubicación
- Ajustar `fill_density` en `config.yaml` si es problema de densidad

### Firmware no lee datos del chip
- Verificar level shifter TXB0108 (OE debe estar en 3.3V)
- Confirmar SPI clock ≤ 1 MHz (limitación de 130nm)
- Probar con `sf_rd_en` manual via GPIO

### Entropía de Shannon < 2.0 bits
- El resultado puede ser todo ceros o patrón repetitivo
- Verificar que el seed de entrada tiene bits variados
- Comprobar que el ADC filter no está sobre-suavizando (ajustar `alpha`)

---

## 8. Parámetros Ajustables

| Parámetro | Default | Rango válido | Efecto |
|-----------|---------|-------------|--------|
| `grid.rows/cols` | 8 | 4–16 | Tamaño del grid (área) |
| `grid.cell_state_bits` | 4 | 2–8 | Resolución del estado continuo |
| `bridge.projection_buffer.depth` | 64 | 16–256 | Tamaño del registro de colapso |
| `bridge.adc.filter_alpha` | 0.125 | 0.01–0.5 | Suavizado de ruido térmico |
| `bridge.adc.averaging_window` | 16 | 4–64 | Muestras por filtro EMA |
| `bridge.handshake.timeout_cycles` | 4096 | 256–16384 | Límite de espera |
| `timing.grid_clock_divider` | 4 | 2–16 | Velocidad de evolución |
| `build.clock_period_ns` | 50 | 25–100 | Frecuencia del sistema |

---

## 9. Extensión Futura

Para escalar el diseño más allá de las restricciones de TinyTapeout 7:

1. **Grid más grande (16×16 o 32×32):** Usar macro personalizado fuera de TT con PDK completo.
2. **Analog-to-digital real:** Integrar ADC de pipeline en lugar del filtro EMA digital.
3. **Múltiples oráculos:** Instanciar varios grid cores con diferentes rule tables.
4. **Memoria externa:** Añadir interfaz QSPI a flash para almacenar estados de grid.
5. **Interfaz Ethernet:** RP2040 con W5500 para oráculo remoto accesible por red.
