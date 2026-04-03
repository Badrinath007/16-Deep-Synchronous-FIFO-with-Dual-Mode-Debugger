module fifo_top (
  input  wire       CLOCK_50,
  input  wire       rst_n_btn,  // PIN_88
  input  wire       KEY0,       // PIN_114 write
  input  wire       KEY1,       // PIN_89  read
  input  wire       KEY2,       // PIN_80  spare
  input  wire       KEY3,       // PIN_73  spare
  output wire [4:0] LED         // active-low
);

  // ── Synchronous reset (sync to clock, active-low) ────────
  reg rst_n_sync;
  always @(posedge CLOCK_50)
    rst_n_sync <= rst_n_btn;   // sync reset to clock domain

  // ── Button debounce — 20ms counter @ 50MHz ───────────────
  // 50MHz × 20ms = 1_000_000 cycles
  localparam DEBOUNCE_MAX = 20'd1_000_000;

  reg [19:0] db0_cnt, db1_cnt;
  reg        key0_stable, key1_stable;
  reg        key0_prev,   key1_prev;
  reg        wr_pulse,    rd_pulse;

  always @(posedge CLOCK_50) begin
    wr_pulse <= 1'b0;
    rd_pulse <= 1'b0;

    if (!rst_n_sync) begin
      db0_cnt     <= 20'd0; key0_stable <= 1'b1; key0_prev <= 1'b1;
      db1_cnt     <= 20'd0; key1_stable <= 1'b1; key1_prev <= 1'b1;
    end else begin

      // KEY0 debounce
      if (KEY0 != key0_stable) begin
        db0_cnt <= db0_cnt + 1'b1;
        if (db0_cnt >= DEBOUNCE_MAX - 1) begin
          db0_cnt    <= 20'd0;
          key0_stable <= KEY0;
        end
      end else begin
        db0_cnt <= 20'd0;
      end
      // rising edge of stable = button released, falling = pressed
      key0_prev <= key0_stable;
      if (key0_prev == 1'b1 && key0_stable == 1'b0)
        wr_pulse <= 1'b1;  // falling edge = button pressed

      // KEY1 debounce
      if (KEY1 != key1_stable) begin
        db1_cnt <= db1_cnt + 1'b1;
        if (db1_cnt >= DEBOUNCE_MAX - 1) begin
          db1_cnt    <= 20'd0;
          key1_stable <= KEY1;
        end
      end else begin
        db1_cnt <= 20'd0;
      end
      key1_prev <= key1_stable;
      if (key1_prev == 1'b1 && key1_stable == 1'b0)
        rd_pulse <= 1'b1;

    end
  end

  // ── Auto-incrementing write data ──────────────────────────
  reg [7:0] din_reg;
  always @(posedge CLOCK_50)
    if (!rst_n_sync) din_reg <= 8'h00;
    else if (wr_pulse) din_reg <= din_reg + 1'b1;

  // ── FIFO instantiation ────────────────────────────────────
  wire [7:0] dout;
  wire       full, empty, almost_full, almost_empty;

  sync_fifo #(
    .DATA_WIDTH (8),
    .FIFO_DEPTH (16)
  ) u_fifo (
    .clk          (CLOCK_50),
    .rst_n        (rst_n_sync),
    .wr_en        (wr_pulse),
    .rd_en        (rd_pulse),
    .din          (din_reg),
    .dout         (dout),
    .full         (full),
    .empty        (empty),
    .almost_full  (almost_full),
    .almost_empty (almost_empty),
    .count        ()
  );

  // ── Activity toggle on every successful write ─────────────
  reg activity;
  always @(posedge CLOCK_50)
    if (!rst_n_sync) activity <= 1'b0;
    else if (wr_pulse && !full) activity <= ~activity;

  // ── Count — how many items in FIFO ───────────────────────
  wire [4:0] count;
  // reconnect count from FIFO
  sync_fifo #(
    .DATA_WIDTH (8),
    .FIFO_DEPTH (16)
  ) u_fifo_count (  // dummy — remove this, use count below
    .clk(CLOCK_50), .rst_n(rst_n_sync),
    .wr_en(1'b0), .rd_en(1'b0), .din(8'b0),
    .dout(), .full(), .empty(), .almost_full(),
    .almost_empty(), .count()
  );

  // ── LED drive — show FIFO state clearly ──────────────────
  // LED[0] = empty flag       (PIN_1  — ON when empty)
  // LED[1] = almost_empty     (PIN_2  — ON when 1 item)
  // LED[2] = almost_full      (PIN_3  — ON when 15 items)
  // LED[3] = full flag        (PIN_7  — ON when full/16)
  // LED[4] = activity toggle  (PIN_11 — toggles each write)
  assign LED[0] = ~empty;
  assign LED[1] = ~almost_empty;
  assign LED[2] = ~almost_full;
  assign LED[3] = ~full;
  assign LED[4] = ~activity;

endmodule