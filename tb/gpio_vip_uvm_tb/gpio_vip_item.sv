class gpio_vip_item extends uvm_sequence_item;

  rand bit [63:0] gpio_i;
  bit [63:0] gpio_o;
  bit [63:0] gpio_dir_o;
  bit [1:0] gpio_intr_o;
  rand bit aclk;
  rand bit aresetn;
  rand bit [11:0] s_axi_awaddr;
  rand bit [2:0] s_axi_awprot;
  rand bit s_axi_awvalid;
  bit s_axi_awready;
  rand bit [31:0] s_axi_wdata;
  rand bit [3:0] s_axi_wstrb;
  rand bit s_axi_wvalid;
  bit s_axi_wready;
  bit [1:0] s_axi_bresp;
  bit s_axi_bvalid;
  rand bit s_axi_bready;
  rand bit [11:0] s_axi_araddr;
  rand bit [2:0] s_axi_arprot;
  rand bit s_axi_arvalid;
  bit s_axi_arready;
  bit [31:0] s_axi_rdata;
  bit [1:0] s_axi_rresp;
  bit s_axi_rvalid;
  rand bit s_axi_rready;

  `uvm_object_utils(gpio_vip_item)

  function new(string name="gpio_vip_item"); super.new(name); endfunction
endclass
