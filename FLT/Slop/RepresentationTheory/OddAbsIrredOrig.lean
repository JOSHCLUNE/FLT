/-
Copyright (c) 2026 Zachary Feng, Y. Samanda Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zachary Feng, Y. Samanda Zhang
-/
module

public import FLT.Slop.RepresentationTheory.OddAbsIrredSlop
import Hammer

/-!
# Compatibility aliases for the original odd-representation namespace

The maintained proof of the odd-representation irreducibility criterion now lives in
`FLT.Slop.RepresentationTheory.OddAbsIrredSlop`, under `Slop.OddRep`.  This file keeps the old
`Slop.OddRepOrig` names available without recompiling a duplicate copy of the same proofs.
-/

@[expose] public section

open scoped TensorProduct

open Module

namespace Slop
namespace OddRepOrig

variable {k : Type*} [Field k]
variable {G : Type*} [Monoid G]
variable {V : Type*} [AddCommGroup V] [Module k V]

/-- Compatibility alias for `Slop.OddRep.baseChange`. -/
noncomputable abbrev baseChange (l : Type*) [Field l] [Algebra k l]
    (ρ : Representation k G V) : Representation l G (l ⊗[k] V) :=
  _root_.Slop.OddRep.baseChange l ρ

/-- Compatibility alias for `Slop.OddRep.adjoinRange`. -/
abbrev adjoinRange (ρ : Representation k G V) : Subalgebra k (Module.End k V) :=
  _root_.Slop.OddRep.adjoinRange ρ

/-- Compatibility alias for `Slop.OddRep.IsAbsolutelyIrreducible`. -/
abbrev IsAbsolutelyIrreducible (ρ : Representation k G V) : Prop :=
  _root_.Slop.OddRep.IsAbsolutelyIrreducible ρ

lemma isIrreducible_iff_forall (ρ : Representation k G V) :
    ρ.IsIrreducible ↔
      Nontrivial V ∧
        ∀ W : Submodule k V, (∀ g : G, ∀ v ∈ W, ρ g v ∈ W) → W = ⊥ ∨ W = ⊤ :=
  _root_.Slop.OddRep.isIrreducible_iff_forall ρ

lemma smul_tmul_mem_range_iff (l : Type*) [Field l] [Algebra k l]
    {e : V} (he : e ≠ 0) (c : l) :
    c ⊗ₜ[k] e ∈ LinearMap.range (TensorProduct.mk k l V 1) ↔
      ∃ a : k, algebraMap k l a = c :=
  _root_.Slop.OddRep.smul_tmul_mem_range_iff l he c

lemma exists_smul_eq_of_commute
    (ρ : Representation k G V)
    (hirr : ρ.IsIrreducible)
    {g : G} (hg : finrank k (Module.End.eigenspace (ρ g) 1) = 1)
    (T : Module.End k V) (hT : ∀ h : G, Commute (ρ h) T) :
    ∃ μ : k, T = μ • (1 : Module.End k V) :=
  _root_.Slop.OddRep.exists_smul_eq_of_commute ρ hirr hg T hT

lemma adjoinRange_eq_top (ρ : Representation k G V) [FiniteDimensional k V]
    (hirr : ρ.IsIrreducible)
    (hEnd : ∀ T : Module.End k V, (∀ h : G, Commute (ρ h) T) →
      ∃ μ : k, T = μ • (1 : Module.End k V)) :
    adjoinRange ρ = ⊤ :=
  _root_.Slop.OddRep.adjoinRange_eq_top ρ hirr hEnd

lemma adjoinRange_baseChange_eq_top (ρ : Representation k G V) [FiniteDimensional k V]
    (l : Type*) [Field l] [Algebra k l]
    (h : adjoinRange ρ = ⊤) :
    adjoinRange (baseChange l ρ) = ⊤ :=
  _root_.Slop.OddRep.adjoinRange_baseChange_eq_top ρ l h

lemma isIrreducible_of_adjoinRange_eq_top (ρ : Representation k G V) [Nontrivial V]
    (h : adjoinRange ρ = ⊤) :
    ρ.IsIrreducible :=
  _root_.Slop.OddRep.isIrreducible_of_adjoinRange_eq_top ρ h

lemma isIrreducible_of_baseChange (ρ : Representation k G V)
    (l : Type*) [Field l] [Algebra k l]
    (h : (baseChange l ρ).IsIrreducible) :
    ρ.IsIrreducible :=
  _root_.Slop.OddRep.isIrreducible_of_baseChange ρ l h

theorem isIrreducible_baseChange_of_finrank_eigenspace_eq_one
    (ρ : Representation k G V) [FiniteDimensional k V]
    (l : Type*) [Field l] [Algebra k l]
    (hirr : ρ.IsIrreducible)
    {g : G} (hg : finrank k (Module.End.eigenspace (ρ g) 1) = 1) :
    (baseChange l ρ).IsIrreducible :=
  _root_.Slop.OddRep.isIrreducible_baseChange_of_finrank_eigenspace_eq_one ρ l hirr hg

theorem isIrreducible_iff_isAbsolutelyIrreducible
    (ρ : Representation k G V) [FiniteDimensional k V]
    {g : G} (hg : finrank k (Module.End.eigenspace (ρ g) 1) = 1) :
    ρ.IsIrreducible ↔ IsAbsolutelyIrreducible ρ :=
  _root_.Slop.OddRep.isIrreducible_iff_isAbsolutelyIrreducible_slop ρ hg

end OddRepOrig
end Slop
