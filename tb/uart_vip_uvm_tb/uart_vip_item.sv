class uart_vip_item extends uvm_sequence_item;

  rand bit uart_rx_i;
  bit uart_tx_o;
  bit read_interrupt_o;
  rand bit fixed_clk_i;
  rand bit axi_aclk_i;
  rand bit axi_aresetn_i;
  rand bit [3:0] axi_arid_i;
  rand bit [7:0] axi_araddr_i;
  rand bit axi_arvalid_i;
  bit axi_arready_o;
  bit [3:0] axi_rid_o;
  bit [31:0] axi_rdata_o;
  bit [1:0] axi_rresp_o;
  bit axi_rvalid_o;
  rand bit axi_rready_i;
  rand bit [3:0] axi_awid_i;
  rand bit [7:0] axi_awaddr_i;
  rand bit axi_awvalid_i;
  bit axi_awready_o;
  rand bit [31:0] axi_wdata_i;
  rand bit [3:0] axi_wstrb_i;
  rand bit axi_wvalid_i;
  bit axi_wready_o;
  bit [3:0] axi_bid_o;
  bit [1:0] axi_bresp_o;
  bit axi_bvalid_o;
  rand bit axi_bready_i;

  `uvm_object_utils(uart_vip_item)

  function new(string name="uart_vip_item"); super.new(name); endfunction
endclass
