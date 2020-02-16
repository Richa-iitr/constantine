# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# ############################################################
#
#                Common configuration
#
# ############################################################

import ../primitives/constant_time

type Word* = Ct[uint32]
  ## Logical BigInt word
  ## A logical BigInt word is of size physical MachineWord-1
type DoubleWord* = Ct[uint64]

type BaseType* = uint32
  ## Physical BigInt for conversion in "normal integers"

const
  WordPhysBitSize* = sizeof(Word) * 8
  WordBitSize* = WordPhysBitSize - 1

  CtTrue* = ctrue(Word)
  CtFalse* = cfalse(Word)

  Zero* = Word(0)
  One* = Word(1)
  MaxWord* = (not Zero) shr 1
    ## This represents 0x7F_FF_FF_FF__FF_FF_FF_FF
    ## also 0b0111...1111
    ## This biggest representable number in our limbs.
    ## i.e. The most significant bit is never set at the end of each function

# ############################################################
#
#                  Instrumentation
#
# ############################################################

template debug*(body: untyped): untyped =
  when defined(debugConstantine):
    body