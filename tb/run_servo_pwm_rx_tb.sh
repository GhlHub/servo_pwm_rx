#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/.." && pwd)

SNAPSHOT_NAME="servo_pwm_rx_tb_sim_dbg"
TB_TCL="${ROOT_DIR}/tb/servo_pwm_rx_tb.tcl"
TB_WDB="${ROOT_DIR}/tb/servo_pwm_rx_tb.wdb"
TB_LOG="${ROOT_DIR}/tb/servo_pwm_rx_tb.log"

cd "${ROOT_DIR}"

xvlog -sv \
    hdl/servo_pwm_rx.v \
    hdl/servo_pwm_rx_slave_lite_v1_0_S00_AXI.v \
    src/servo_pwm_rx_capture.v \
    tb/servo_pwm_rx_tb.sv

xelab -debug all servo_pwm_rx_tb -s "${SNAPSHOT_NAME}"

xsim "${SNAPSHOT_NAME}" \
    -tclbatch "${TB_TCL}" \
    -wdb "${TB_WDB}" \
    -log "${TB_LOG}"
