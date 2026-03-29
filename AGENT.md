# AGENT.md

This repository contains a packaged Vivado AXI4-Lite IP core for RC servo PWM pulse-width capture.

## Key Files

- `hdl/servo_pwm_rx.v`: top-level AXI-wrapped IP module
- `hdl/servo_pwm_rx_slave_lite_v1_0_S00_AXI.v`: AXI4-Lite slave, register map, IRQ behavior
- `src/servo_pwm_rx_capture.v`: pulse capture, synchronization, deglitch, UI counting, rounding
- `component.xml`: legacy root-level packaged IP metadata
- `package_ip_core.tcl`: rebuilds `ip_repo/servo_pwm_rx/`
- `ip_repo/servo_pwm_rx/component.xml`: generated packaged IP metadata for Vivado repository discovery
- `drivers/servo_pwm_rx_v1_0/`: packaged software driver metadata and sources
- `tb/servo_pwm_rx_tb.sv`: self-checking top-level testbench
- `tb/run_servo_pwm_rx_tb.sh`: one-command Xilinx simulation runner

## Register Map

Implemented registers:

- `0x00`: control/status
- `0x04`: UI clock ticks
- `0x08`: captured pulse width

Reserved/unimplemented:

- `0x0C`: reads return `0`

Do not assume old generated `slv_reg3` behavior still exists. The current RTL implements only the three registers above.

## UI Programming Convention

The capture RTL currently uses an inclusive terminal-count scheme for UI accumulation.

- Program `ui_clk_ticks` as `desired_clock_ticks_per_ui - 1`
- At 50 MHz, a 1 us UI is programmed as `49`

This is a behavior detail of the current RTL and is important for firmware and testbench work.

## Capture Behavior

- `pwm_in` is synchronized into the AXI clock domain before deglitch and edge detection
- capture is disabled until the UI register is programmed to a non-zero value
- measured pulse width is rounded to the nearest UI
- a completed measurement asserts interrupt status
- reading register `0x08` acknowledges and clears the pending interrupt

## Simulation

Preferred simulation entry point:

```bash
./tb/run_servo_pwm_rx_tb.sh
```

This runs:

- `xvlog`
- `xelab -debug all`
- `xsim` with waveform logging

Generated outputs:

- `tb/servo_pwm_rx_tb.log`
- `tb/servo_pwm_rx_tb.wdb`

The `.gitignore` is set up to ignore generated simulator artifacts while keeping the testbench sources trackable.

## Packaging Notes

- Keep `component.xml` and `drivers/servo_pwm_rx_v1_0/data/servo_pwm_rx.mdd` version numbers aligned when bumping the packaged IP version
- The current packaged software driver is legacy-style (`.mdd` + `.tcl`)
- Prefer editing source collateral under `hdl/`, `src/`, `xgui/`, `bd/`, and `drivers/`, then rerun `package_ip_core.tcl` instead of editing `ip_repo/servo_pwm_rx/` by hand
- Modern Vitis Unified support still needs YAML + CMake packaging; see `TODO.md`

## Documentation Rule

If RTL behavior changes, update `README.md` so the Theory of Operation and register map stay aligned with the implementation.
