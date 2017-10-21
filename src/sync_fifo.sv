//#################################################################################
// Project       :  Hamming weight counter and index indentifier
// Editor        :  Notepad++ on Windows 8
// File          :  sync_fifo.sv
// Description   :  Parameterized FIFO
// Created by    :  Sukrut Kelkar
// Date          :  09/21/2017                 
//#################################################################################

module sync_fifo #(parameter DEPTH=32, WIDTH=32)(
		input 											clk,
		input 											rst,
		input 											wr,
		input 											rd,
		input				[WIDTH-1 : 0] 	data_in,
		output reg	[WIDTH-1 : 0] 	data_out,
		output 											emp,
		output 											full
  );
	
	localparam PTR_WIDTH = $clog2(DEPTH);
	
	logic [WIDTH-1:0] fifo_memory [0:DEPTH-1] = '{default:'0};

	// Internal wires
	
	logic	[PTR_WIDTH-1:0]	rd_ptr;
	logic	[PTR_WIDTH-1:0]	wr_ptr;
	
	logic	[PTR_WIDTH:0]	rd_ptr_tmp;
	logic	[PTR_WIDTH:0]	wr_ptr_tmp;
	
	logic				wr_en;
	logic				rd_en;

	logic				emp_tmp;
	logic				full_tmp;

	logic 			ptr_equal;
	logic 			rd_ptr_msb;
	logic 			wr_ptr_msb;

	assign	rd_ptr = rd_ptr_tmp[PTR_WIDTH-1:0];
	assign	wr_ptr = wr_ptr_tmp[PTR_WIDTH-1:0];

	assign rd_ptr_msb = rd_ptr_tmp[PTR_WIDTH];
	assign wr_ptr_msb = wr_ptr_tmp[PTR_WIDTH];

	assign	wr_en = !full_tmp & wr;
	assign	rd_en = !emp_tmp & rd;

	assign	emp		= emp_tmp;
	assign	full	= full_tmp;

	assign ptr_equal = (rd_ptr_tmp[PTR_WIDTH-1:0] == wr_ptr_tmp[PTR_WIDTH-1:0]);

	assign	emp_tmp	= ((rd_ptr_msb & wr_ptr_msb) | (~rd_ptr_msb & ~wr_ptr_msb)) & ptr_equal;

	assign	full_tmp=	((~rd_ptr_msb & wr_ptr_msb) | (rd_ptr_msb & ~wr_ptr_msb)) & ptr_equal;

	always_ff @(posedge clk or posedge rst) begin : pointer_increment_logic
			if (rst) begin
				rd_ptr_tmp <= 'd0;
				wr_ptr_tmp <= 'd0;
			end
			else begin
				if (rd_en) begin
					rd_ptr_tmp	<=	rd_ptr_tmp + 'd1;
				end
				else begin
					rd_ptr_tmp	<=	rd_ptr_tmp;
				end

				if (wr_en) begin
					wr_ptr_tmp	<=	wr_ptr_tmp + 'd1;
				end
				else begin
					wr_ptr_tmp	<=	wr_ptr_tmp;
				end
			end
	end : pointer_increment_logic

	always_ff @(posedge clk) begin : fifo_mem_rd_wr
		if(wr_en)
      fifo_memory[wr_ptr] <= data_in;

    if(rd_en)
      data_out <= fifo_memory[rd_ptr];
    else
      data_out <= 'd0;
	end : fifo_mem_rd_wr

endmodule // sync_fifo
