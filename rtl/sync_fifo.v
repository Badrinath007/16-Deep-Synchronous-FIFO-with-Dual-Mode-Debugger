module sync_fifo #(
  parameter DATA_WIDTH = 8,            // Data bus width
  parameter FIFO_DEPTH = 16,           // Must be power of 2
  parameter ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
  input  wire                  clk,    // System clock
  input  wire                  rst_n,  // Active-low sync reset
  input  wire                  wr_en,  // Write enable
  input  wire                  rd_en,  // Read enable
  input  wire [DATA_WIDTH-1:0] din,    // Write data input
  output reg  [DATA_WIDTH-1:0] dout,   // Read data output
  output wire                  full,   // FIFO full flag
  output wire                  empty,  // FIFO empty flag
  output wire                  almost_full,  // One slot left
  output wire                  almost_empty, // One item left
  output reg  [ADDR_WIDTH:0]   count   // Number of items
);

  // ── Memory array ─────────────────────────────────────────
  reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

  // ── Pointers ─────────────────────────────────────────────
  reg [ADDR_WIDTH-1:0] wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr;

  // ── Status flags ─────────────────────────────────────────
  assign full         = (count == FIFO_DEPTH);
  assign empty        = (count == 0);
  assign almost_full  = (count == FIFO_DEPTH - 1);
  assign almost_empty = (count == 1);

  // ── Write logic ──────────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr <= {ADDR_WIDTH{1'b0}};
    end else if (wr_en && !full) begin
      mem[wr_ptr] <= din;
      wr_ptr      <= wr_ptr + 1'b1;
    end
  end

  // ── Read logic ───────────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      rd_ptr <= {ADDR_WIDTH{1'b0}};
      dout   <= {DATA_WIDTH{1'b0}};
    end else if (rd_en && !empty) begin
      dout   <= mem[rd_ptr];
      rd_ptr <= rd_ptr + 1'b1;
    end
  end

  // ── Count logic ──────────────────────────────────────────
  always @(posedge clk) begin
    if (!rst_n) begin
      count <= {(ADDR_WIDTH+1){1'b0}};
    end else begin
      case ({wr_en && !full, rd_en && !empty})
        2'b10   : count <= count + 1'b1; // Write only
        2'b01   : count <= count - 1'b1; // Read only
        default : count <= count;        // Both or neither
      endcase
    end
  end

endmodule