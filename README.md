# RC Servo Receiver

## Description
PWM receiver to receive and decode PWM pulses from flight controllers / remote controllers

# Theory of Operation
- This IP Core operates in terms of Unit Interval or abbreviated as UI. This is what allows this core to be firmware friendly. The *UI Clock Ticks Register* programs the terminal count used to accumulate one UI. In the current RTL implementation, firmware should load the desired AXI clock ticks per UI minus one. For example, at a 50 MHz AXI clock, a 1 uS UI is programmed as `49`, and a 1 mS pulse is reported as 1000 UI.
- Capture is disabled until the *UI Clock Ticks Register* is programmed to a non-zero value.
- As currently implemented, this IP core is Frame Length agnostic. Although this may change after additional real world testing.
- The `pwm_in` signal is synchronized into the AXI clock domain and majority-deglitched before edge detection and pulse measurement.
- Reported received pulse width is automatically rounded to the nearest UI.
- A completed pulse measurement asserts the interrupt status, and reading the Rx Pulse UI Count Register acknowledges and clears that interrupt.

# Register Interface
## List of registers

Note: All registers are 32-bits wide.

| Offset  | Name | Access | Description |
| ------------- | ------------- | - | - |
| 0x00 | Control Register | RW | Main control and status register for Servo PWM Rx controller |
| 0x04 | UI Clock Ticks Register | RW | Defines number of clock ticks per Unit Interval (UI) |
| 0x08 | Rx Pulse UI Count Register | RO | Width of last received pulse in units of UI |

Offset `0x0C` is reserved and unimplemented in the current RTL. Reads return `0`.

### Control Register
| 31 | 30:2 | 1 | 0 |
| - | - | - | - |
| IRQ_pin | Reserved | IRQ Mask | Reset |

- IRQ_pin - Read Only status of Interrupt pin
- IRQ Mask - IRQ_pin mask
- Reset - Set to one to reset this IP Core

### UI Clock Ticks Register
| 31:12 | 11:0 |
| - | - |
| Reserved | UI Clock Ticks Count |

- UI Clock Ticks Count - Defines the number of clock ticks per Unit Interval (UI)
- A value of `0` disables capture until firmware programs a non-zero UI tick count

### Rx Pulse UI Count Register
| 31:12 | 11:0 |
| - | - |
| Reserved | Rx Pulse UI Ticks Count |

- Rx Pulse UI Ticks Count - Length in UI of the last received PWM pulse
- Reading this register automatically acknowledges and clears the pending capture interrupt

