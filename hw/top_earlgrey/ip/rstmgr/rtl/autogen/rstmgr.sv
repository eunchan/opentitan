// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// ------------------- W A R N I N G: A U T O - G E N E R A T E D   C O D E !! -------------------//
// PLEASE DO NOT HAND-EDIT THIS FILE. IT HAS BEEN AUTO-GENERATED WITH THE FOLLOWING COMMAND:
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// This module is the overall reset manager wrapper
// TODO: This module is only a draft implementation that covers most of the rstmgr
// functoinality but is incomplete

`include "prim_assert.sv"

// This top level controller is fairly hardcoded right now, but will be switched to a template
module rstmgr import rstmgr_pkg::*; (
  // Primary module clocks
  input clk_i,
  input rst_ni, // this is currently connected to top level reset, but will change once ast is in
  input clk_aon_i,
  input clk_io_div2_i,
  input clk_main_i,
  input clk_io_i,
  input clk_io_div4_i,
  input clk_usb_i,

  // Bus Interface
  input tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  // pwrmgr interface
  input pwrmgr_pkg::pwr_rst_req_t pwr_i,
  output pwrmgr_pkg::pwr_rst_rsp_t pwr_o,

  // ast interface
  input rstmgr_ast_t ast_i,

  // cpu related inputs
  input rstmgr_cpu_t cpu_i,

  // peripheral reset requests
  input rstmgr_peri_t peri_i,

  // Interface to alert handler

  // reset outputs
  output rstmgr_ast_out_t resets_ast_o,
  output rstmgr_out_t resets_o

);

  // receive POR and stretch
  // The por is at first stretched and synced on clk_aon
  // The rst_ni and pok_i input will be changed once AST is integrated
  logic rst_por_aon_n;
  rstmgr_por u_rst_por_aon (
    .clk_i(clk_aon_i),
    .rst_ni(ast_i.aon_pok),
    .rst_no(rst_por_aon_n)
  );

  assign resets_o.rst_por_aon_n = rst_por_aon_n;

  ////////////////////////////////////////////////////
  // Register Interface                             //
  ////////////////////////////////////////////////////

  rstmgr_reg_pkg::rstmgr_reg2hw_t reg2hw;
  rstmgr_reg_pkg::rstmgr_hw2reg_t hw2reg;

  rstmgr_reg_top u_reg (
    .clk_i,
    .rst_ni(resets_o.rst_por_io_div2_n),
    .tl_i,
    .tl_o,
    .reg2hw,
    .hw2reg,
    .devmode_i(1'b1)
  );

  ////////////////////////////////////////////////////
  // Input handling                                 //
  ////////////////////////////////////////////////////

  logic ndmreset_req_q;
  logic ndm_req_valid;

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_sync (
    .clk_i,
    .rst_ni(resets_o.rst_por_io_div2_n),
    .d_i(cpu_i.ndmreset_req),
    .q_o(ndmreset_req_q)
  );

  assign ndm_req_valid = ndmreset_req_q & (pwr_i.reset_cause == pwrmgr_pkg::ResetNone);

  ////////////////////////////////////////////////////
  // Source resets in the system                    //
  // These are hardcoded and not directly used.     //
  // Instead they act as async reset roots.         //
  ////////////////////////////////////////////////////

  // The two source reset modules are chained together.  The output of one is fed into the
  // the second.  This ensures that if upstream resets for any reason, the associated downstream
  // reset will also reset.

  logic [PowerDomains-1:0] rst_lc_src_n;
  logic [PowerDomains-1:0] rst_sys_src_n;

  // lc reset sources
  rstmgr_ctrl #(
    .PowerDomains(PowerDomains)
  ) u_lc_src (
    .clk_i,
    .rst_ni(resets_o.rst_por_io_div2_n),
    .rst_req_i(pwr_i.rst_lc_req),
    .rst_parent_ni({PowerDomains{1'b1}}),
    .rst_no(rst_lc_src_n)
  );

  // sys reset sources
  rstmgr_ctrl #(
    .PowerDomains(PowerDomains)
  ) u_sys_src (
    .clk_i,
    .rst_ni(resets_o.rst_por_io_div2_n),
    .rst_req_i(pwr_i.rst_sys_req | {PowerDomains{ndm_req_valid}}),
    .rst_parent_ni(rst_lc_src_n),
    .rst_no(rst_sys_src_n)
  );

  assign pwr_o.rst_lc_src_n = rst_lc_src_n;
  assign pwr_o.rst_sys_src_n = rst_sys_src_n;

  ////////////////////////////////////////////////////
  // leaf reset in the system                       //
  // These should all be generated                  //
  ////////////////////////////////////////////////////

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_por (
    .clk_i(clk_main_i),
    .rst_ni(rst_por_aon_n),
    .d_i(1'b1),
    .q_o(resets_o.rst_por_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_por_io (
    .clk_i(clk_io_i),
    .rst_ni(rst_por_aon_n),
    .d_i(1'b1),
    .q_o(resets_o.rst_por_io_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_por_io_div2 (
    .clk_i(clk_io_div2_i),
    .rst_ni(rst_por_aon_n),
    .d_i(1'b1),
    .q_o(resets_o.rst_por_io_div2_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_por_io_div4 (
    .clk_i(clk_io_div4_i),
    .rst_ni(rst_por_aon_n),
    .d_i(1'b1),
    .q_o(resets_o.rst_por_io_div4_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_por_usb (
    .clk_i(clk_usb_i),
    .rst_ni(rst_por_aon_n),
    .d_i(1'b1),
    .q_o(resets_o.rst_por_usb_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_lc (
    .clk_i(clk_main_i),
    .rst_ni(rst_lc_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_lc_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_lc_io (
    .clk_i(clk_io_div4_i),
    .rst_ni(rst_lc_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_lc_io_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_sys (
    .clk_i(clk_main_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_sys_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_sys_io (
    .clk_i(clk_io_div2_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_sys_io_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_sys_io_div4 (
    .clk_i(clk_io_div4_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_sys_io_div4_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_sys_aon (
    .clk_i(clk_aon_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(1'b1),
    .q_o(resets_o.rst_sys_aon_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_spi_device (
    .clk_i(clk_io_div2_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(reg2hw.rst_spi_device_n.q),
    .q_o(resets_o.rst_spi_device_n)
  );

  prim_flop_2sync #(
    .Width(1),
    .ResetValue('0)
  ) u_usb (
    .clk_i(clk_usb_i),
    .rst_ni(rst_sys_src_n[0]),
    .d_i(reg2hw.rst_usb_n.q),
    .q_o(resets_o.rst_usb_n)
  );


  ////////////////////////////////////////////////////
  // Reset info construction                        //
  ////////////////////////////////////////////////////

  logic [ResetReasons-1:0] rst_reqs;
  logic rst_hw_req;
  logic rst_low_power;

  assign rst_hw_req = pwr_i.reset_cause == pwrmgr_pkg::HwReq;
  assign rst_low_power = pwr_i.reset_cause == pwrmgr_pkg::LowPwrEntry;

  assign rst_reqs = {
                    ndm_req_valid,
                    rst_hw_req ? peri_i.rst_reqs : ExtResetReasons'(0),
                    rst_low_power
                    };

  rstmgr_info #(
    .Reasons(ResetReasons)
  ) i_info (
    .clk_i,
    .rst_ni(rst_por_aon_n),
    .rst_cpu_ni(cpu_i.rst_cpu_n),
    .rst_req_i(rst_reqs),
    .wr_i(reg2hw.reset_info.qe),
    .data_i(reg2hw.reset_info.q),
    .rst_reasons_o(hw2reg.reset_info)
  );

  ////////////////////////////////////////////////////
  // Exported resets                                //
  ////////////////////////////////////////////////////
  assign resets_ast_o.rst_ast_usbdev_sys_io_div4_n = resets_o.rst_sys_io_div4_n;
  assign resets_ast_o.rst_ast_usbdev_usb_n = resets_o.rst_usb_n;
  assign resets_ast_o.rst_ast_sensor_ctrl_sys_io_div4_n = resets_o.rst_sys_io_div4_n;

  ////////////////////////////////////////////////////
  // Assertions                                     //
  ////////////////////////////////////////////////////

  // when upstream resets, downstream must also reset

endmodule // rstmgr
