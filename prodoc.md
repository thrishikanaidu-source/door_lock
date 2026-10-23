
# Door Lock System using Verilog HDL

A parameterized password-based door lock controller designed in Verilog HDL using a Finite State Machine (FSM). This project covers RTL design, simulation-based verification, synthesis, and RTL-to-GDSII physical design using OpenLane and the SkyWater SKY130 standard-cell library.

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Default Configuration](#default-configuration)
- [How It Works](#how-it-works)
- [Tools and Technologies](#tools-and-technologies)
- [Project Structure](#project-structure)
- [Verification and Simulation](#verification-and-simulation)
- [Synthesis and Physical Design](#synthesis-and-physical-design)
- [Limitations](#limitations)
- [What I Learned](#what-i-learned)
- [Project Presentation](#project-presentation)

## Project Overview

The controller checks a four-digit code entered through keypad inputs. If the correct code is entered, it unlocks for a configured period and then relocks automatically. Repeated incorrect codes trigger an alarm and a temporary lockout.

The password, unlock duration, lockout duration, and maximum number of incorrect attempts can be changed through module parameters.

> **Note:** This is a digital controller design and RTL-to-GDSII implementation. It does not by itself demonstrate a physical door, keypad, motor, or alarm connected to real hardware.

## Features

- Four-digit password verification
- FSM-based control logic
- Automatic relocking after the unlock timer expires
- Incorrect-attempt counter
- Alarm and temporary lockout after repeated incorrect entries
- Key inputs ignored during lockout
- Reset support, including reset during password entry
- Parameterized password, timers, and attempt limit
- Self-checking RTL and gate-level simulation tests
- Synthesis and physical-design flow using OpenLane and SKY130

## Default Configuration

| Parameter | Default |
|---|---|
| Password | `1234` |
| Password length | 4 digits |
| Unlock duration | 5,000 clock cycles |
| Lockout duration | 30,000 clock cycles |
| Maximum incorrect attempts | 3 |
| Final physical-design clock period | 12 ns |
| Final synthesis strategy | `DELAY 0` |

The unlock and lockout durations are expressed in clock cycles. Their real-time duration depends on the clock frequency.

## How It Works

1. **Reset / Initial State:** The controller starts locked and prepares to receive keypad input.
2. **Password Entry:** The controller reads the entered digits and checks the completed code.
3. **Correct Password:** The unlock output is activated and the unlock timer starts.
4. **Automatic Relock:** When the timer expires, the controller returns to the locked state.
5. **Incorrect Password:** The door remains locked and the incorrect-attempt count is updated.
6. **Maximum Attempts Reached:** After three incorrect codes, the alarm/lockout behavior is activated and keypad input is ignored for the configured lockout period.
7. **Lockout Completion:** Normal password entry becomes available again after the lockout timer expires.

## Tools and Technologies

- **Verilog HDL** — RTL design
- **Icarus Verilog** — RTL simulation
- **Gate-Level Simulation** — Verification of the synthesized netlist
- **Yosys** — Logic synthesis
- **OpenLane** — RTL-to-GDSII physical-design flow
- **SkyWater SKY130 (`sky130_fd_sc_hd`)** — Standard-cell library
- **Static Timing Analysis (STA)** — Timing checks across available library corners

## Project Structure

```text
door_lock/
├── src/                  # RTL source and testbench files
├── deliverables/         # Simulation results and waveforms
├── images/               # Screenshots and design snapshots
├── comparison/           # Comparison of earlier implementation runs
├── openlane_run3/        # Final physical-design run and reports
├── door_lock_synth.v     # Synthesized Verilog netlist
└── README.md             # Project documentation
```

Generated reports and files may be located inside subfolders of `openlane_run3/`.

## Verification and Simulation

The testbench includes **18 self-checking tests** covering important controller behavior:

- Correct password unlocks the door without activating the alarm
- Automatic relocking after the unlock timer expires
- Incorrect digits/passwords are rejected
- A correct password works after earlier incorrect attempts
- The attempt counter resets after a correct code
- Alarm and lockout activate after three incorrect codes
- Key inputs are ignored during lockout
- Normal entry resumes after the lockout timer expires
- A held key is not counted repeatedly
- Reset works during password entry

According to the recorded results, all 18 tests pass in RTL simulation using Icarus Verilog and in gate-level simulation using the final synthesized netlist. The RTL and gate-level outputs matched for the tested cases.

### Running the Tests

The RTL and gate-level testbenches are in `src/`. Check the filenames in that folder and use the appropriate source files.

A typical Icarus Verilog flow is:

```bash
iverilog -o simulation.out <source_files.v> <testbench_file.v>
vvp simulation.out
```

Replace the placeholders with the actual filenames. Gate-level simulation may also require the synthesized netlist and standard-cell simulation models.

## Synthesis and Physical Design

The design was taken through an OpenLane RTL-to-GDSII flow using the `sky130_fd_sc_hd` library. The final recorded run used the `DELAY 0` synthesis strategy with a 12 ns clock period.

The flow includes implementation stages such as:

1. RTL synthesis
2. Floorplanning
3. Placement
4. Clock-tree synthesis
5. Routing
6. Design-rule checks (DRC)
7. Layout verification
8. Static timing analysis (STA)

## Results

| Metric | Recorded Result |
|---|---:|
| Clock period | 12 ns |
| Synthesis strategy | `DELAY 0` |
| Synthesized standard cells | 285 |
| Die area | 0.012852 mm² |
| Worst setup slack | +0.76 ns |
| Worst hold slack | +0.17 ns |
| Reported DRC violations | 0 |
| Reported LVS violations | 0 |
| Reported antenna violations | 0 |
| Reported Magic violations | 0 |
| STA library corners checked | 18; all reported passing |

The reported worst setup slack was +0.76 ns at `ss_n40C_1v28`. The reported worst hold slack was +0.17 ns at `ff_n40C_1v95`.

An earlier area-focused `AREA 0` run at a 10 ns clock period failed setup timing at low-voltage corners. The final recorded run used `DELAY 0` and a 12 ns clock period to meet the reported timing checks.

These results describe the recorded run and may change if the RTL, constraints, tool versions, or library setup change.

## Limitations

- Only one SPEF parasitic file was used because per-corner RC extraction rules were not available in the installed setup.
- SDF-annotated simulation and a wire-delay sensitivity check were not performed.
- This is a digital design and implementation flow; physical hardware operation is outside the scope of the results described here.

## What I Learned

- Designing a parameterized digital controller in Verilog HDL
- Modeling control behavior with an FSM
- Writing self-checking testbenches and verifying corner cases
- Running RTL and gate-level simulations
- Understanding logic synthesis and standard-cell area
- Following an RTL-to-GDSII flow with OpenLane
- Reading timing, design-rule, and layout-verification reports
- Comparing area-focused and timing-focused implementation settings

