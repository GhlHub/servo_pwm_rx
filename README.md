# RC Servo Receiver

## Description
PWM receiver to receive and decode PWM pulses from flight controllers / remote controllers

# Theory of Operation
- This IP Core operates in terms of Unit Interval or abbreviated as UI. This is what allows this core to be firmware friendly. The *UI Clock Ticks Register* defines the number of AXI clock ticks for a UI. In the case for RC Servo Motor Control, a convienant UI is the number of clock ticks for 1uS. In this way when a 1 mS pulse is received, the IP core will report 1000 UI.
- As currently implemented, this IP core is Frame Length agnostic. Although this may change after additional real world testing.
- Reported received pulse width is automatically rounded to the nearest UI.

# Register Interface
## List of registers

Note: All registers are 32-bits wide.

| Offset  | Name | Description |
| ------------- | ------------- | - |
| 0x00 | Control Register | Main control register for Servo PWM Rx controller  |
| 0x04 | UI Clock Ticks Register | Defines number of clock ticks per Unit Interval (UI) |
| 0x08 | Rx Pulse UI Count Register | Width of last received pulse in units of UI |

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

### Rx Pulse UI Count Register
| 31:12 | 11:0 |
| - | - |
| Reserved | Rx Pulse UI Ticks Count |

- Rx Pulse UI Ticks Count - Length in UI of the last received PWM pulse. Note reading this register will automatically acknowlege and clear this interrupt.



