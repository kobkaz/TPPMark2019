Require Import Arith Lia.
Require Import List.
Require Import Recdef.
Import ListNotations.

Require Import TPPMark2019.Value.
Require Import TPPMark2019.Tape.
Require Import TPPMark2019.CTM.
Require Import TPPMark2019.Clearer.
Require Import TPPMark2019.Util.

Set Implicit Arguments.

Instance BoolFinite : Finite.class bool :=
  {|
    Finite.card := 2;
    Finite.surj n := n =? 1;
  |}.
Proof.
  destruct x; eauto.
Defined.

Instance BoolValue : @Value.class bool BoolFinite :=
  {|
    Value.zero := false;
    Value.one := true;
  |}.
Proof.
  - decide equality.
  - auto.
Defined.

Module ListTape.
  Record t (V : Type) : Type :=
    {
      left_part: list V;
      top : V;
      right_part :list V;
    }.
  Arguments Build_t {V}.
  Arguments left_part {V} t.
  Arguments top {V} t.
  Arguments right_part {V} t.

  Definition size {V} '(Build_t l v r : t V) : nat := S (length l + length r).
  
  Definition head {V} '(Build_t l _ _ : t V) : nat := length l.

  Definition read {V} '(Build_t _ v _ : t V) : V := v.
  
  Definition write {V} (v : V) '(Build_t l _ r : t V)  : t V :=
    Build_t l v r.

  Function move_right {V} (tape : t V) :=
    let '(Build_t l v r) := tape in
    match r with
    | [] =>
      match rev l with
      | nil => Build_t [] v []
      | v' :: r' => Build_t [] v' (r' ++ [v])
      end
    | v' :: r' => Build_t (v :: l) v' r'
    end.
  
  Function move_left {V} (tape : t V) : t V :=
    let '(Build_t l v r) := tape in
    match l with
    | [] =>
      match rev r with
      | nil => Build_t [] v []
      | v' :: l' => Build_t (l' ++ [v]) v' []
      end
    | v' :: l' => Build_t  l' v' (v :: r)
    end.

  Definition to_list {V} '(Build_t l v r : t V)  : list V :=
    rev l ++ v :: r.

  Definition from_list {V} `{Value.class V} (vs : list V) : t V :=
    match vs with
    | [] => Build_t [] Value.zero []
    | v :: vs'  => Build_t [] v vs'
    end.

End ListTape.

Instance ListTape_Tape V `{Value.class V} : Tape.ops (ListTape.t V) V :=
  {|
    Tape.read := ListTape.read;
    Tape.write := ListTape.write;
    Tape.move_right := ListTape.move_right;
    Tape.move_left := ListTape.move_left;

  |}.

Instance ListTape_TapeSpec V `{Value.class V} : Tape.spec :=
  {|
    Tape.to_list := ListTape.to_list;
    Tape.size := ListTape.size;
    Tape.head := ListTape.head;
  |}.
Proof.
  - destruct t. simpl. ssimpl_list. auto.
  - destruct t. simpl. auto with arith.
  - destruct t. simpl. rewrite nth_error_app2; ssimpl_list; auto.
    rewrite Nat.sub_diag. reflexivity.
  - destruct t. simpl. rewrite nth_error_app2; ssimpl_list; auto.
    rewrite Nat.sub_diag. reflexivity.
  - intros i v t. destruct t. simpl.
    destruct (Nat.lt_ge_cases i (length (rev left_part))).
    + rewrite !nth_error_app1; auto.
    + rewrite !nth_error_app2; auto.
      case_eq (i - length (rev left_part)); simpl; auto.
      rewrite rev_length in *. lia.
  - intros v t. destruct t. reflexivity.
  - destruct t as [l v r]. destruct r; simpl; [destruct l using rev_ind|]; ssimpl_list; auto.
    rewrite <- List.app_assoc. auto.
  - destruct t as [l v r]. simpl.
    destruct r; [destruct l using rev_ind|]; rewrite ?rev_unit; simpl; auto; destruct_cmpbs.
  - destruct t as [l v r]; simpl; destruct l; simpl; [destruct r using rev_ind|]; ssimpl_list; auto.
    rewrite <- List.app_assoc. auto.
  - destruct t as [l v r]. simpl.
    destruct l; [destruct r using rev_ind|]; rewrite ?rev_unit; simpl; auto; destruct_cmpbs.
    ssimpl_list. auto with arith.
Defined.

