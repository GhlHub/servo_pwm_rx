`timescale 1ns / 1ps

module servo_pwm_rx_tb;

    localparam int CLK_PERIOD_NS = 20;
    localparam int CLK_HALF_PERIOD_NS = CLK_PERIOD_NS / 2;
    localparam int CYCLES_PER_US = 50;

    localparam logic [3:0] REG_CONTROL = 4'h0;
    localparam logic [3:0] REG_UI      = 4'h4;
    localparam logic [3:0] REG_CAPTURE = 4'h8;

    localparam logic [31:0] CTRL_IRQ_ENABLE = 32'h0000_0002;

    // The capture RTL counts from 0 to ui_clk_ticks inclusive, so 49 yields a 50-cycle UI at 50 MHz.
    localparam logic [31:0] UI_TICKS_1US = 32'd49;

    reg         s00_axi_aclk = 1'b0;
    reg         s00_axi_aresetn = 1'b0;
    reg  [3:0]  s00_axi_awaddr = 4'd0;
    reg  [2:0]  s00_axi_awprot = 3'd0;
    reg         s00_axi_awvalid = 1'b0;
    wire        s00_axi_awready;
    reg  [31:0] s00_axi_wdata = 32'd0;
    reg  [3:0]  s00_axi_wstrb = 4'h0;
    reg         s00_axi_wvalid = 1'b0;
    wire        s00_axi_wready;
    wire [1:0]  s00_axi_bresp;
    wire        s00_axi_bvalid;
    reg         s00_axi_bready = 1'b0;
    reg  [3:0]  s00_axi_araddr = 4'd0;
    reg  [2:0]  s00_axi_arprot = 3'd0;
    reg         s00_axi_arvalid = 1'b0;
    wire        s00_axi_arready;
    wire [31:0] s00_axi_rdata;
    wire [1:0]  s00_axi_rresp;
    wire        s00_axi_rvalid;
    reg         s00_axi_rready = 1'b0;
    reg         pwm_in = 1'b0;
    wire        irq_pin;

    function automatic longint timestamp_ns();
    begin
        timestamp_ns = $rtoi($realtime + 0.5);
    end
    endfunction

    servo_pwm_rx dut (
        .pwm_in         (pwm_in),
        .irq_pin        (irq_pin),
        .s00_axi_aclk   (s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready)
    );

    always #(CLK_HALF_PERIOD_NS) s00_axi_aclk = ~s00_axi_aclk;

    task automatic axi_write(input logic [3:0] addr, input logic [31:0] data);
        int cycle_count;
    begin
        @(negedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_awvalid <= 1'b1;
        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= 4'hF;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_bready  <= 1'b1;

        for (cycle_count = 0; cycle_count < 32; cycle_count = cycle_count + 1) begin
            @(posedge s00_axi_aclk);
            if ((s00_axi_awready === 1'b1) && (s00_axi_wready === 1'b1)) begin
                break;
            end
        end

        if ((s00_axi_awready !== 1'b1) || (s00_axi_wready !== 1'b1)) begin
            $fatal(1, "AXI write handshake timed out at address 0x%0h", addr);
        end

        @(negedge s00_axi_aclk);
        s00_axi_awaddr  <= 4'd0;
        s00_axi_awvalid <= 1'b0;
        s00_axi_wdata   <= 32'd0;
        s00_axi_wstrb   <= 4'h0;
        s00_axi_wvalid  <= 1'b0;

        for (cycle_count = 0; cycle_count < 32; cycle_count = cycle_count + 1) begin
            @(posedge s00_axi_aclk);
            if (s00_axi_bvalid === 1'b1) begin
                break;
            end
        end

        if (s00_axi_bvalid !== 1'b1) begin
            $fatal(1, "AXI write response timed out at address 0x%0h", addr);
        end

        @(negedge s00_axi_aclk);
        s00_axi_bready  <= 1'b0;
    end
    endtask

    task automatic axi_read(input logic [3:0] addr, output logic [31:0] data);
        int cycle_count;
    begin
        @(negedge s00_axi_aclk);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1'b1;
        s00_axi_rready  <= 1'b1;

        for (cycle_count = 0; cycle_count < 32; cycle_count = cycle_count + 1) begin
            @(posedge s00_axi_aclk);
            if (s00_axi_rvalid === 1'b1) begin
                break;
            end
        end

        if (s00_axi_rvalid !== 1'b1) begin
            $fatal(1, "AXI read timed out at address 0x%0h", addr);
        end

        data = s00_axi_rdata;

        @(negedge s00_axi_aclk);
        s00_axi_araddr  <= 4'd0;
        s00_axi_arvalid <= 1'b0;
        s00_axi_rready  <= 1'b0;
    end
    endtask

    task automatic drive_pulse_us(input int pulse_width_us);
    begin
        pwm_in <= 1'b1;
        repeat (pulse_width_us * CYCLES_PER_US) @(posedge s00_axi_aclk);
        pwm_in <= 1'b0;
    end
    endtask

    task automatic wait_for_irq(input int max_cycles);
        int cycle_count;
    begin
        for (cycle_count = 0; cycle_count < max_cycles; cycle_count = cycle_count + 1) begin
            if (irq_pin === 1'b1) begin
                return;
            end
            @(posedge s00_axi_aclk);
        end

        $fatal(1, "Timed out waiting for irq_pin to assert");
    end
    endtask

    task automatic run_capture_test(input string test_name, input int pulse_width_us, input int expected_ui_ticks);
        logic [31:0] capture_reg;
    begin
        $display("[%0d ns] Starting %s", timestamp_ns(), test_name);

        if (irq_pin !== 1'b0) begin
            $fatal(1, "%s: irq_pin should be low before the pulse", test_name);
        end

        drive_pulse_us(pulse_width_us);
        wait_for_irq((pulse_width_us * CYCLES_PER_US) + 200);

        axi_read(REG_CAPTURE, capture_reg);
        if (capture_reg[11:0] !== expected_ui_ticks[11:0]) begin
            $fatal(1, "%s: expected capture %0d UI, got %0d", test_name, expected_ui_ticks, capture_reg[11:0]);
        end

        @(posedge s00_axi_aclk);
        if (irq_pin !== 1'b0) begin
            $fatal(1, "%s: irq_pin did not clear after reading REG_CAPTURE", test_name);
        end

        axi_read(REG_CAPTURE, capture_reg);
        if (capture_reg[11:0] !== expected_ui_ticks[11:0]) begin
            $fatal(1, "%s: capture register changed unexpectedly after IRQ clear", test_name);
        end

        if (irq_pin !== 1'b0) begin
            $fatal(1, "%s: repeated capture register read reasserted irq_pin", test_name);
        end

        repeat (20) @(posedge s00_axi_aclk);
        $display("[%0d ns] PASS %s", timestamp_ns(), test_name);
    end
    endtask

    initial begin
        logic [31:0] control_reg;
        logic [31:0] ui_reg;

        repeat (5) @(posedge s00_axi_aclk);
        s00_axi_aresetn <= 1'b1;
        repeat (5) @(posedge s00_axi_aclk);

        axi_write(REG_UI, UI_TICKS_1US);
        axi_write(REG_CONTROL, CTRL_IRQ_ENABLE);

        axi_read(REG_UI, ui_reg);
        if (ui_reg[11:0] !== UI_TICKS_1US[11:0]) begin
            $fatal(1, "UI register readback mismatch: expected %0d got %0d", UI_TICKS_1US[11:0], ui_reg[11:0]);
        end

        axi_read(REG_CONTROL, control_reg);
        if (control_reg[1:0] !== CTRL_IRQ_ENABLE[1:0]) begin
            $fatal(1, "Control register readback mismatch: expected 0x%0h got 0x%0h", CTRL_IRQ_ENABLE[1:0], control_reg[1:0]);
        end

        run_capture_test("TC1_1ms_pulse_capture_irq_clear", 1000, 1000);
        run_capture_test("TC2_1p5ms_pulse_capture_irq_clear", 1500, 1500);

        $display("[%0d ns] All testcases passed", timestamp_ns());
        $finish;
    end

endmodule
