// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package lc_ctrl_env_pkg;
  // dep packages
  import uvm_pkg::*;
  import top_pkg::*;
  import dv_utils_pkg::*;
  import dv_lib_pkg::*;
  import tl_agent_pkg::*;
  import cip_base_pkg::*;
  import csr_utils_pkg::*;
  import lc_ctrl_ral_pkg::*;
  import lc_ctrl_pkg::*;
  import otp_ctrl_pkg::*;

  // macro includes
  `include "uvm_macros.svh"
  `include "dv_macros.svh"

  // parameters
  parameter string LIST_OF_ALERTS[] = {"lc_programming_failure", "lc_state_failure"};
  parameter uint   NUM_ALERTS = 2;
  parameter uint   CLAIM_TRANS_VAL = 'ha5;

  // associative array cannot declare parameter here, so we used const instead
  const dec_lc_state_e VALID_NEXT_STATES [dec_lc_state_e][$] = '{
    DecLcStRma:     {DecLcStScrap},
    DecLcStProdEnd: {DecLcStScrap},
    DecLcStProd:    {DecLcStScrap, DecLcStRma},
    DecLcStDev:     {DecLcStScrap, DecLcStRma},
    DecLcStTestUnlocked3: {DecLcStScrap, DecLcStRma, DecLcStProdEnd, DecLcStProd, DecLcStDev},
    DecLcStTestUnlocked2: {DecLcStScrap, DecLcStProdEnd, DecLcStProd, DecLcStDev,
                           DecLcStTestLocked2},
    DecLcStTestUnlocked1: {DecLcStScrap, DecLcStRma, DecLcStProdEnd, DecLcStProd, DecLcStDev,
                           DecLcStTestLocked2, DecLcStTestLocked1},
    DecLcStTestUnlocked0: {DecLcStScrap, DecLcStRma, DecLcStProdEnd, DecLcStProd, DecLcStDev,
                           DecLcStTestLocked2, DecLcStTestLocked1, DecLcStTestLocked0},
    DecLcStTestLocked2: {DecLcStScrap, DecLcStProdEnd, DecLcStProd,
                         DecLcStDev, DecLcStTestUnlocked3},
    DecLcStTestLocked1: {DecLcStScrap, DecLcStProdEnd, DecLcStProd, DecLcStDev,
                         DecLcStTestUnlocked3, DecLcStTestUnlocked2},
    DecLcStTestLocked0: {DecLcStScrap, DecLcStProdEnd, DecLcStProd, DecLcStDev,
                         DecLcStTestUnlocked3, DecLcStTestUnlocked2, DecLcStTestUnlocked1},
    DecLcStRaw: {DecLcStScrap, DecLcStTestUnlocked2, DecLcStTestUnlocked1, DecLcStTestUnlocked0}
  };

  // types
  typedef enum bit [1:0] {
    LcPwrInitReq,
    LcPwrIdleRsp,
    LcPwrDoneRsp,
    LcPwrIfWidth
  } lc_pwr_if_e;

  typedef virtual pins_if #(LcPwrIfWidth) pwr_lc_vif;
  typedef virtual lc_ctrl_if              lc_ctrl_vif;

  // functions
  function automatic bit valid_state_for_trans(lc_state_e curr_state);
    valid_state_for_trans = 0;
    if (curr_state inside {LcStRma, LcStProdEnd, LcStProd, LcStDev, LcStTestUnlocked3,
                          LcStTestUnlocked2, LcStTestUnlocked1, LcStTestUnlocked0,
                          LcStTestLocked2, LcStTestLocked1, LcStTestLocked0, LcStRaw}) begin
      valid_state_for_trans = 1;
    end
  endfunction

  function automatic dec_lc_state_e dec_lc_state(lc_state_e curr_state);
    case (curr_state)
      LcStRaw:           return DecLcStRaw;
      LcStTestUnlocked0: return DecLcStTestUnlocked0;
      LcStTestLocked0:   return DecLcStTestLocked0;
      LcStTestUnlocked1: return DecLcStTestUnlocked1;
      LcStTestLocked1:   return DecLcStTestLocked1;
      LcStTestUnlocked2: return DecLcStTestUnlocked2;
      LcStTestLocked2:   return DecLcStTestLocked2;
      LcStTestUnlocked3: return DecLcStTestUnlocked3;
      LcStDev:           return DecLcStDev;
      LcStProd:          return DecLcStProd;
      LcStProdEnd:       return DecLcStProdEnd;
      LcStRma:           return DecLcStRma;
      LcStScrap:         return DecLcStScrap;
      default: `uvm_fatal("lc_env_pkg", $sformatf("unknown lc_state 0x%0h", curr_state))
    endcase
  endfunction

  // package sources
  `include "lc_ctrl_env_cfg.sv"
  `include "lc_ctrl_env_cov.sv"
  `include "lc_ctrl_virtual_sequencer.sv"
  `include "lc_ctrl_scoreboard.sv"
  `include "lc_ctrl_env.sv"
  `include "lc_ctrl_vseq_list.sv"

endpackage
