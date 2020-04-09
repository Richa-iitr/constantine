# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# ############################################################
#
#      Quadratic Extension field over extension field 𝔽p6
#                      𝔽p12 = 𝔽p6[√γ]
#       with γ the cubic root of the non-residue of 𝔽p6
#
# ############################################################

# This implements a quadratic extension field over
#   𝔽p12 = 𝔽p6[γ]
# with γ the cubic root of the non-residue of 𝔽p6
# with element A of coordinates (a0, a1) represented
# by a0 + a1 γ
#
# The irreducible polynomial chosen is
#   w² - γ
# with γ the cubic root of the non-residue of 𝔽p6
# I.e. if 𝔽p6 irreducible polynomial is
#   v³ - ξ with ξ = 1+𝑖
# γ = v = ∛(1 + 𝑖)
#
# Consequently, for this file 𝔽p12 to be valid
# ∛(1 + 𝑖) MUST not be a square in 𝔽p6

import
  ../arithmetic,
  ../config/curves,
  ./abelian_groups,
  ./fp6_1_plus_i

type
  Fp12*[C: static Curve] = object
    ## Element of the extension field
    ## 𝔽p12 = 𝔽p6[γ]
    ##
    ## I.e. if 𝔽p6 irreducible polynomial is
    ##   v³ - ξ with ξ = 1+𝑖
    ## γ = v = ∛(1 + 𝑖)
    ##
    ## with coordinates (c0, c1) such as
    ## c0 + c1 w
    c0*, c1*: Fp6[C]

  Gamma = object
    ## γ (Gamma) the quadratic non-residue of 𝔽p6
    ## γ = v with v the factor in for 𝔽p6 coordinate
    ## i.e. a point in 𝔽p6 as coordinates a0 + a1 v + a2 v²

func `*`(_: typedesc[Gamma], a: Fp6): Fp6 {.noInit, inline.} =
  ## Multiply an element of 𝔽p6 by 𝔽p12 quadratic non-residue
  ## Conveniently γ = v with v the factor in for 𝔽p6 coordinate
  ## and v³ = ξ
  ## (c0 + c1 v + c2 v²) v => ξ c2 + c0 v + c1 v²
  discard

  result.c0 = a.c2 * Xi
  result.c1 = a.c0
  result.c2 = a.c1

template `*`(a: Fp6, _: typedesc[Gamma]): Fp6 =
  Gamma * a

func `*=`(a: var Fp6, _: typedesc[Gamma]) {.inline.} =
  a = Gamma * a

func square*[C](r: var Fp12[C], a: Fp12[C]) =
  ## Return a² in ``r``
  ## ``r`` is initialized/overwritten
  # (c0, c1)² => (c0 + c1 w)²
  #           => c0² + 2 c0 c1 w + c1²w²
  #           => c0² + γ c1² + 2 c0 c1 w
  #           => (c0² + γ c1², 2 c0 c1)
  # We have 2 squarings and 1 multiplication in 𝔽p6
  # which are significantly more costly:
  # - 4 limbs like BN254:     multiplication is 20x slower than addition/substraction
  # - 6 limbs like BLS12-381: multiplication is 28x slower than addition/substraction
  #
  # We can save operations with one of the following expressions
  # of c0² + γ c1² and noticing that c0c1 is already computed for the "y" coordinate
  #
  # Alternative 1:
  #   c0² + γ c1² <=> (c0 - c1)(c0 - γ c1) + γ c0c1 + c0c1
  #
  # Alternative 2:
  #   c0² + γ c1² <=> (c0 + c1)(c0 + γ c1) - γ c0c1 - c0c1

  # r0 <- (c0 + c1)(c0 + γ c1)
  r.c0.sum(a.c0, a.c1)
  r.c1.sum(a.c0, Gamma * a.c1)
  r.c0 *= r.c1

  # r1 <- c0 c1
  r.c1.prod(a.c0, a.c1)

  # r0 = (c0 + c1)(c0 + γ c1) - γ c0c1 - c0c1
  r.c0 -= Gamma * r.c1
  r.c0 -= r.c1

  # r1 = 2 c0c1
  r.c1.double()