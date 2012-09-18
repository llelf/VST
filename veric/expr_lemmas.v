Require Import msl.msl_standard.
Require Import veric.base.
Require Import veric.Address.
Require Import msl.rmaps.
Require Import msl.rmaps_lemmas.
Require Import veric.compcert_rmaps.
Require Import veric.Clight_lemmas.
Require Import veric.expr.

Definition mkEnviron' (ge: Clight.genv) (ve: Clight.env) (te: Clight.temp_env) :=
  mkEnviron (filter_genv ge) ve te.

Definition Delta1 : tycontext := (PTree.set 1%positive (type_int32s, false) (PTree.empty (type * bool)),
                                 PTree.empty type, Tvoid,nil).


Lemma tc_assert_simpl_sound : forall asn rho, 
denote_tc_assert asn rho -> denote_tc_assert (tc_assert_simpl asn) rho.
Proof.
intros. induction asn; simpl; auto.

simpl in *. intuition. remember (tc_assert_simpl asn1).
remember (tc_assert_simpl asn2). destruct t; destruct t0; simpl in *; auto.

destruct e; auto. simpl in *. unfold denote_tc_nonzero in *. simpl in *.
destruct (Int.eq i Int.zero); intuition.

destruct e; auto. simpl in *. unfold denote_tc_ilt in *.
simpl in *. destruct (Int.ltu i0 i); simpl; intuition.

destruct e; auto. simpl in *. unfold denote_tc_Zle in *.
simpl in *. destruct (Float.Zoffloat f); intuition. rewrite H. simpl. auto.

destruct e; auto. simpl in *. unfold denote_tc_Zge in *.
simpl in *. destruct (Float.Zoffloat f); intuition. rewrite H. simpl. auto.
Qed.
Definition tc_te_denote (te: temp_env) (tc: PTree.t (type * bool)) :=
forall id ty b, tc ! id = Some (ty,b) -> exists v, (te ! id = Some v /\ typecheck_val v ty = true). 

Definition tc_vl_denote (ve:env) le := forall id,
(In id le -> ve! id = None).

Definition tc_ve_denote (ve: env) (ge:genviron) (tc: PTree.t type) :=
forall id ty, tc ! id = Some (ty) -> 
((exists v, (ve ! id = Some(v, ty))) \/
((exists b, exists i, 
(ge id = Some (Vptr b i, ty) /\ typecheck_val (Vptr b i) ty = true)
 /\ (exists v, (ve ! id = Some(v, ty)))) \/
((exists b, exists i, 
(ge id = Some (Vptr b i, ty) /\ typecheck_val (Vptr b i) ty = true)
 /\ (ve ! id = None)))))
.

Lemma eqb_type_eq: forall t1 t2, eqb_type t1 t2 = proj_sumbool (type_eq t1 t2).
Proof.
intros.
case_eq (eqb_type t1 t2); intros.
apply eqb_type_true in H; subst; simpl; auto.
rewrite proj_sumbool_is_true; auto.
destruct (type_eq t1 t2); simpl; subst.
rewrite eqb_type_refl in H; auto.
auto.
Qed.

Lemma join_ve_denote2 : forall ve1 ve2 id v1,
(join_ve ve1 ve2) ! id = Some (v1) ->
ve1 ! id = Some (v1) /\ ve2 ! id = Some (v1).
Proof.
intros. unfold join_ve in *.

rewrite PTree.fold_spec in *.
rewrite  <- fold_left_rev_right in *.

assert (forall t : type, In (id, t) (rev (PTree.elements ve1)) -> ve1 ! id = Some t).
intros. apply PTree.elements_complete. apply in_rev. auto.

assert (NOREP := PTree.elements_keys_norepet (ve1)).

induction (rev (PTree.elements ve1)). simpl in H. rewrite PTree.gempty in *.
congruence.

destruct a. simpl in H. remember (ve2 ! p). destruct o. simpl in *.
if_tac in H. subst. rewrite PTree.gsspec in H. if_tac in H. subst.
specialize (H0 t0). inv H. intuition.

apply IHl; eauto.
apply IHl; eauto.
apply IHl; eauto. intros. apply H0. simpl. eauto.
Qed.

Lemma fold_left_false : forall T l f, 
fold_left (fun (a:bool) (p: T) => f p && a) l false = false.
Proof.
intros.
induction l. auto. simpl in *. rewrite andb_false_r. auto.
Qed.

Lemma fold_left_forallb : forall T l f, 
fold_left (fun (a:bool) (p:T) => f p && a) l true = forallb f l.
Proof.
intros.
induction l; auto. simpl. destruct (f a). simpl. auto. simpl. apply fold_left_false.
Qed.


Lemma typecheck_vl_eqv : forall vl ve, 
typecheck_var_list vl ve = true <->
tc_vl_denote ve vl.
Proof.
intros. split; intros; unfold tc_vl_denote. intros.

unfold typecheck_var_list in *. 
rewrite forallb_forall in H.
induction vl.

inv H0.

simpl in H0. destruct H0. subst. simpl in *. specialize (H id).
intuition. destruct (ve ! id); try congruence; auto.
apply IHvl; auto. intros. simpl in H. specialize (H x). intuition.

unfold tc_vl_denote in *. unfold typecheck_var_list. rewrite forallb_forall.
intros. specialize (H x). intuition. rewrite H1. auto.
Qed.


Lemma typecheck_ve_eqv : forall dv ve ge,
typecheck_var_environ (PTree.elements dv) ve ge = true <->
tc_ve_denote ve ge dv.
Proof.
intros; split; intros.
unfold tc_ve_denote. intros. 
assert (In (id, ty) (PTree.elements dv)). apply PTree.elements_correct.
auto.
assert (forall t: type, In (id,t) (PTree.elements dv) -> dv ! id = Some t).
intros. apply PTree.elements_complete. auto. 



assert (In (id, ty) (PTree.elements dv)). apply PTree.elements_correct.
auto.
assert (forall t: type, In (id,t) (PTree.elements dv) -> dv ! id = Some t).
intros. apply PTree.elements_complete. auto.
induction (PTree.elements dv). inv H1. 
simpl in H. destruct a. simpl in *.
remember (ve ! p). destruct o. destruct p0.
remember (eqb_type t t0). destruct b0.
symmetry in Heqb0. apply eqb_type_true in Heqb0. subst.
destruct H1. inv H1. specialize (H2 ty). intuition; eauto.

apply IHl; eauto.

simpl in *; congruence.

remember (ge p). destruct o; simpl in *; try congruence. destruct p0.
destruct v; simpl in *; try congruence. remember (eqb_type t t0).
destruct b0; simpl in *; try congruence. symmetry in Heqb0.
 apply eqb_type_true in Heqb0; subst.
simpl in *. destruct H1. inv H1. right. right. exists b. exists i.
intuition. destruct ty; auto. if_tac in H; try congruence.
intuition. destruct H5; auto. destruct H3. rewrite <- Heqo in H3. congruence. 
destruct H3. destruct H3. destruct H3. intuition.
destruct H3. destruct H3; intuition.
apply IHl; auto. destruct t0; auto; simpl in *; congruence.

(*other way now...*)
assert (forall t1 id, In (id,t1) (PTree.elements dv) -> dv ! id = Some t1).
intros. apply PTree.elements_complete. auto.
induction (PTree.elements dv).
auto.

simpl in *. destruct a. 
remember (ve ! p). destruct o. destruct p0.
simpl in *. unfold tc_ve_denote in H.

assert (forall (t1 : type) (id : positive),
     (p, t) = (id, t1) \/ In (id, t1) l -> dv ! id = Some t1) by auto.
specialize (H0 t p). intuition. specialize (H _ _ H0).
destruct H. destruct H. rewrite H in Heqo. inv Heqo.
rewrite eqb_type_refl. simpl. apply IHl. intros. apply H1. auto.

destruct H. destruct H. destruct H. destruct H. destruct H.
destruct H2. rewrite H2 in Heqo. inv Heqo. rewrite eqb_type_refl.
simpl. apply IHl. intros. apply H1. auto.

repeat destruct H. rewrite H2 in Heqo. congruence.

remember (ge p). destruct o. destruct p0. rewrite IHl; auto.
specialize (H0 t p). intuition.
unfold tc_ve_denote in *. edestruct H; eauto.
destruct H1. rewrite <- Heqo in H1. congruence. destruct H1.
repeat destruct H1. destruct H3. rewrite <- Heqo in H1. congruence.

destruct H1. destruct H1. destruct H1. destruct H1.
rewrite <- Heqo0 in H1. inv H1. rewrite eqb_type_refl. simpl. destruct t; auto; congruence.
specialize (H0 t p). intuition. clear H2. unfold tc_ve_denote in *.
specialize (H _ _ H0). destruct H. destruct H. rewrite H in *; congruence.
destruct H. repeat destruct H. destruct H1. rewrite H in *; congruence.
destruct H. destruct H. destruct H. destruct H. rewrite H in *; congruence.

Qed. 

Lemma typecheck_te_eqv : forall t te, typecheck_temp_environ (PTree.elements t) te = true
<-> tc_te_denote te t.
Proof. intros.
split. intros. unfold tc_te_denote. intros.
assert (In (id, (ty,b)) (PTree.elements t)).
apply PTree.elements_correct. auto.
induction (PTree.elements t). simpl in *.

destruct H1. 

simpl in *. destruct a. destruct p0.
remember (te ! p). destruct o; try solve [inv H].
remember (typecheck_val v t0). destruct b1; try congruence.
intuition. inv H2. exists v; auto. 

intros. unfold tc_te_denote in *. 
assert (forall t1 id, In (id,t1) (PTree.elements t) -> t ! id = Some t1).
intros. apply PTree.elements_complete. auto.
induction (PTree.elements t). auto.

simpl in *. 
assert (forall (t1 : type * bool) (id : positive),
     In (id, t1) (a :: l) -> t ! id = Some t1) by auto.
destruct a. destruct p0.
specialize (H0 (t0, b) p). intuition. clear H3.
specialize (H p t0 b). intuition. destruct H2.
destruct H. rewrite H. rewrite H2. apply IHl. intros.
simpl in H1. specialize (H1 t1 id). intuition.

Qed.


Lemma typecheck_environ_sound : forall ge te ve Delta,
typecheck_environ (mkEnviron ge ve te) Delta = true ->
tc_te_denote te (temp_types Delta) /\ tc_ve_denote ve ge (var_types Delta) /\ 
tc_vl_denote ve (var_ids Delta).
Proof.
intros.
unfold typecheck_environ in *. destruct Delta. destruct p.

unfold temp_types in *. simpl in *. repeat rewrite andb_true_iff in *. intuition.
destruct p. simpl in *. apply typecheck_te_eqv; auto.

apply typecheck_ve_eqv; auto.

apply typecheck_vl_eqv; auto.

Qed.


Lemma join_te_denote : forall te1 te2 id b t1,
(join_te te1 te2) ! id = Some (t1,b) ->
(exists b1, te1 ! id = Some (t1, orb b b1)) /\ (exists b2, te2 ! id = Some (t1, orb b b2)).
Proof.
intros.
 
unfold join_te in *. rewrite PTree.fold_spec in *.
rewrite  <- fold_left_rev_right in *.

assert (forall t : type * bool, In (id, t) (rev (PTree.elements te1)) -> te1 ! id = Some t).
intros. apply PTree.elements_complete. apply in_rev. auto.

assert (NOREP := PTree.elements_keys_norepet (te1)).

induction (rev (PTree.elements te1)). simpl in *.
rewrite PTree.gempty in *. congruence.

simpl in *. destruct a. destruct p0. simpl in *.
remember (te2 ! p). destruct o. destruct p0.
destruct (eq_dec t t0). subst. rewrite PTree.gsspec in *.
destruct (peq id p). subst. specialize (H0 (t0,b0)). inv H.

remember (andb b0 b1). destruct b. symmetry in Heqb. 
rewrite andb_true_iff in *. destruct Heqb; subst. 
split; exists false; intuition; eauto.

symmetry in Heqb.
rewrite andb_false_iff in *. destruct Heqb; subst. intuition; eauto.

intuition; eauto.

apply IHl; eauto.

apply IHl; eauto.
apply IHl; eauto.
Qed.

Lemma join_vl_denote :  forall vl1 vl2 id,
In id (join_ve_list vl1 vl2) -> In id vl1 /\ In id vl2.
Proof.
intros. intros.
induction vl1. simpl in *. inv H. simpl in *. if_tac in H. simpl in *; intuition.
subst; auto. intuition.

Qed.



Lemma typecheck_environ_join1:
  forall rho Delta1 Delta2, 
        typecheck_environ rho Delta1 = true ->
        typecheck_environ rho (join_tycon Delta1 Delta2) = true.
Proof. intros.
 unfold typecheck_environ in *. rewrite andb_true_iff in *. intuition.
destruct rho. simpl in *. rewrite andb_true_iff in *; intuition.
rewrite  typecheck_te_eqv in *. clear H1. clear H2.
unfold tc_te_denote in *. intros. unfold temp_types in *.
destruct Delta2. destruct p. destruct p. simpl in *. destruct Delta0.
destruct p. destruct p. simpl in *. apply join_te_denote in H0.
destruct H0. destruct H0. destruct H1. 
eapply H. apply H0.

clear H. clear H1. rewrite typecheck_ve_eqv in *.
destruct Delta1. simpl. destruct p. destruct Delta2. destruct p.
unfold var_types in *. simpl in *. destruct p0.
destruct p. destruct Delta0. destruct p. destruct p.
simpl in *.
unfold tc_ve_denote in *.
intros. apply join_ve_denote2 in H. destruct H.
intuition.

clear H0. rewrite typecheck_vl_eqv in *.
destruct Delta2; destruct Delta0. destruct p.
destruct p. destruct p0. destruct p. unfold ve_of in *; simpl in *.
destruct rho. unfold tc_vl_denote in *. intros.
apply H1.  
apply join_vl_denote in H. intuition.
Qed.

Lemma typecheck_environ_join2:
  forall rho Delta1 Delta2, 
        typecheck_environ rho Delta2 = true ->
        typecheck_environ rho (join_tycon Delta1 Delta2) = true.
Proof.
intros. unfold typecheck_environ in *. repeat rewrite andb_true_iff in *.
intuition.
clear H1. clear H2. rewrite typecheck_te_eqv in *.
unfold tc_te_denote in *; intros. unfold temp_types in *. destruct Delta2.
destruct p. destruct Delta0. destruct p. destruct p0. destruct p. simpl in *.
apply join_te_denote in H0. destruct H0. destruct H0. destruct H1.
destruct rho; simpl in *. eapply H. eauto.

clear H. rewrite typecheck_ve_eqv in *.
destruct Delta1. simpl. destruct p. destruct Delta2. destruct p.
unfold var_types in *.
destruct p0. destruct p. destruct Delta0. destruct p. destruct p.
 simpl in *. unfold tc_ve_denote in *.
intros. apply join_ve_denote2 in H. destruct H.
intuition.

clear H. clear H2. rewrite typecheck_vl_eqv in *.
destruct Delta2; destruct Delta0. destruct p.
destruct p. destruct p0. destruct p. unfold ve_of in *; simpl in *.
destruct rho. unfold tc_vl_denote in *. intros.
apply H1.  
apply join_vl_denote in H. intuition.
Qed.

Lemma typecheck_val_ptr_lemma:
   forall rho Delta id t a init,
   typecheck_environ rho Delta = true ->
   (temp_types Delta) ! id =  Some (Tpointer t a, init) ->
   bool_val (eval_id id rho) (Tpointer t a) = Some true ->
   typecheck_val (eval_id id rho) (Tpointer t a) = true.
Proof. 
intros. unfold bool_val in *. unfold typecheck_val.
unfold eval_id. apply typecheck_environ_sound in H.
destruct H as [? _]. unfold tc_te_denote in *.
edestruct H; eauto. destruct H2. rewrite H2. destruct x; simpl in *; congruence.
Qed. 



Lemma in_fst_in : forall A B (L : list (A*B)) (a:A) (b:B), In (a, b) L  -> In a (map (@fst A B) L) .
Proof.
intros A B L. induction L; intros. auto. simpl in *. inv H. auto. right. eapply IHL. apply H0.
Qed.

Lemma in_rem_in : forall A B C (L : list (A*(B*C))) a b c,
In (a, (b, c)) L -> In (a,b) (map remove_assignedness (L)).
intros A B C L. induction L; intros. inv H. simpl in *.
inv H. left. auto. right. eapply  IHL. eauto.
Qed.


Lemma typecheck_environ_put_te : forall ge te ve Delta id v ,
typecheck_environ (mkEnviron ge ve te) Delta = true ->
(forall t , ((temp_types Delta) ! id = Some t ->
  (typecheck_val v (fst t)) = true)) ->
typecheck_environ (mkEnviron ge ve (PTree.set id v te)) Delta = true.
Proof. 
intros. unfold typecheck_environ in *. simpl in *. repeat rewrite andb_true_iff in *.
intuition. clear H2 H3. destruct Delta. destruct p. destruct p. unfold temp_types in *; simpl in *.
clear t t1 l ve. rewrite typecheck_te_eqv in *. unfold tc_te_denote in *.
intros. edestruct H; eauto. destruct H2. rewrite PTree.gsspec.
if_tac. subst. exists v; intuition. specialize (H0 (ty, b)). apply H0. auto. 

simpl in *. exists x. intuition.
Qed.


Lemma typecheck_environ_put_te' : forall ge te ve Delta id v ,
typecheck_environ (mkEnviron ge ve te) Delta = true ->
(forall t , ((temp_types Delta) ! id = Some t ->
  (typecheck_val v (fst t)) = true)) ->
typecheck_environ (mkEnviron ge ve (PTree.set id v te)) (set_temp_assigned Delta id) = true.
Proof.
intros. 
assert (typecheck_environ (mkEnviron ge ve (PTree.set id v te)) Delta = true).
apply typecheck_environ_put_te; auto.

unfold typecheck_environ in *. simpl in *. repeat rewrite andb_true_iff in *. intuition.

destruct Delta. destruct p. destruct p.  unfold set_temp_assigned. unfold temp_types in *.
clear H4 H3 H5 H6. simpl in *. 
rewrite typecheck_te_eqv in *. unfold tc_te_denote in *. intros. remember (t0 ! id).
destruct o; try congruence; auto. destruct p. simpl in *. rewrite PTree.gsspec in H.
if_tac in H. inv H. eapply H2; eauto.

rewrite PTree.gsspec. if_tac; intuition. eauto.

simpl in *. eapply H2; eauto.

unfold var_types in *. destruct Delta. destruct p. destruct p. simpl in *.
unfold set_temp_assigned. simpl. destruct ((temp_types (t0, t1, t, l))!id).
destruct p. simpl. unfold var_types. auto. auto.

destruct Delta. destruct p. destruct p. simpl in *. unfold set_temp_assigned.
destruct ((temp_types (t0, t1, t, l)) ! id); try destruct p;
unfold var_ids; simpl in *; auto.
Qed. 


Lemma no_rep_in_pair : forall A B L a b b2, list_norepet (map (@fst A B) (L)) ->
  In (a, b) L -> In (a,b2) L -> b = b2.
Proof.
intros A B L. induction L; intros. inv H0. simpl in *.
inv H. intuition.
  destruct a. inv H0. inv H. auto.
 
  destruct H4. destruct a; simpl. inv H. eapply in_fst_in. eauto. 
  
  destruct H4. destruct a; simpl. inv H0. eapply in_fst_in. eauto.

  eapply IHL; eauto.
Qed. 

Lemma type_eq_true : forall a b, proj_sumbool  (type_eq a b) =true  -> a = b.
Proof. intros. destruct (type_eq a b). auto. simpl in H. inv H.
Qed.

Ltac of_bool_destruct :=
match goal with
  | [ |- context[Val.of_bool ?X] ] => destruct X
end.


Lemma classify_add_int_cases_both : forall i1 s1 a1 i2 s2 a2,
exists s3,
classify_add (Tint i1 s1 a1) (Tint i2 s2 a2) 
= add_case_ii s3.
Proof.
intros; destruct i1; destruct s1; destruct i2; destruct s2; eexists;  
unfold classify_add; simpl; eauto.
Qed.

Lemma undef_not_typecheck : forall t, typecheck_val Vundef t = false.
intros.
destruct t; auto.
Qed.

Ltac st:= simpl in *.

Lemma is_true_true : forall b, is_true b -> b = true.
Proof.
auto.
Qed.

Ltac tc_assert_ext := 
repeat match goal with
| [H : _ /\ _ |- _] => destruct H
end.

Ltac revert_all := repeat match goal with
| [H: _ |- _] => revert H
end.

Lemma orb_if : forall {D} b c (d:D) (e:D), (if (b || c) then d else e) = if b then d else if c then d else e.
intros.
remember (b || c). destruct b0; auto. symmetry in Heqb0. rewrite orb_true_iff in Heqb0.
intuition; subst; auto. destruct b; auto. symmetry in Heqb0; rewrite orb_false_iff in Heqb0.
intuition; subst; auto.
Qed.

Lemma andb_if : forall {D} b c (d:D) (e:D), (if (b && c) then d else e) = if b then (if c then d else e) else e.
Proof.
intros.
remember (b&&c). destruct b0; symmetry in Heqb0; try rewrite andb_true_iff in *; try rewrite andb_false_iff in *; if_tac; auto; intuition;
destruct c; auto; intuition.
Qed.

Lemma typecheck_binop_sound:
forall (Delta : tycontext) (rho : environ) (b : binary_operation)
  (e1 e2 : expr) (t : type),
denote_tc_assert (typecheck_expr Delta (Ebinop b e1 e2 t)) rho ->
(denote_tc_assert (typecheck_expr Delta e1) rho ->
 typecheck_val (eval_expr e1 rho) (typeof e1) = true) ->
(denote_tc_assert (typecheck_expr Delta e2) rho ->
 typecheck_val (eval_expr e2 rho) (typeof e2) = true) ->
typecheck_val (eval_expr (Ebinop b e1 e2 t) rho) (typeof (Ebinop b e1 e2 t)) =
true.
Proof.
Admitted.
(*intros. st. intuition.
destruct b; st;
match goal with 
| [ |- typecheck_val ( force_val (?X _ _ _ _)) _ = true ] => unfold X in *
| [ |- typecheck_val ( force_val (?X _ _ _ _ _)) _ = true ] => unfold X in *
| [ |- typecheck_val ( force_val (?X _ _ _ _ _ _)) _ = true ] => unfold X in *
end;

destruct (typeof e1); destruct (typeof e2); st; auto;

try solve [try destruct i; try destruct s; try destruct i0; try destruct s0; 
st;  
destruct (eval_expr rho e1); destruct (eval_expr rho e2); auto; destruct t;
tc_assert_ext; st; auto; repeat (try rewrite orb_if; rewrite andb_if); try repeat if_tac; st; 
try of_bool_destruct; auto].
Qed.*)

Transparent Float.intoffloat.
Transparent Float.intuoffloat.

Ltac unfold_tc_denote :=
unfold denote_tc_nonzero in *;
unfold denote_tc_isptr in *;
unfold denote_tc_ilt in *;
unfold denote_tc_Zle in *;
unfold denote_tc_Zge in *;
unfold denote_tc_samebase in *;
unfold denote_tc_nodivover in *;
unfold denote_tc_initialized in *.

Lemma eval_lvalue_ptr : forall rho e (Delta: tycontext) te ve ge,
mkEnviron ge ve te = rho -> 
tc_ve_denote ve ge (var_types Delta) -> 
denote_tc_assert (typecheck_lvalue Delta e) rho ->
eval_lvalue e rho = Vundef \/ exists base, exists ofs, eval_lvalue e rho  = Vptr base ofs.
Proof. 
intros.
induction e; eauto.
simpl. 
remember ((ve_of rho) ! i). destruct o; try rewrite eqb_type_eq; intuition;
try destruct p; try rewrite eqb_type_eq; simpl; try remember (type_eq t t0); try destruct s;
simpl; try remember (negb (type_is_volatile t0));try destruct b0; auto;
try solve[right; eauto].
remember (ge_of rho i); try rewrite eqb_type_eq; simpl.
destruct o; try rewrite eqb_type_eq; simpl; eauto.
destruct p; try rewrite eqb_type_eq; simpl; eauto.
if_tac; eauto.
unfold tc_ve_denote in *. simpl in H1.
remember ((var_types Delta) ! i).
destruct o. subst. simpl in H1.
try rewrite eqb_type_eq in H1; simpl in *; intuition.
symmetry in Heqo1.
specialize (H0 i t1 Heqo1).
destruct H0. destruct H0. congruence.
destruct H0. destruct H0. destruct H0. destruct H0.
destruct H1; congruence. 

destruct H0. destruct H0. destruct H0. destruct H0.
unfold proj_sumbool in *. destruct (type_eq t t1). subst.
rewrite <- Heqo0 in H0. inv H0. eauto. inv H.

inv H1. simpl in *. intuition. destruct (eval_expr e rho); eauto.

simpl in *. intuition. destruct (eval_lvalue e rho); eauto; intuition.
destruct (typeof e); try congruence. 
destruct (eval_lvalue e rho); intuition. destruct (typeof e); intuition.
destruct (field_offset i f); eauto.
Qed. 


Lemma typecheck_both_sound: 
  forall Delta rho e , 
             typecheck_environ rho Delta = true ->
             (denote_tc_assert (typecheck_expr Delta e) rho ->
             typecheck_val (eval_expr e rho) (typeof e) = true) /\
             (forall pt, 
             denote_tc_assert (typecheck_lvalue Delta e) rho ->
             is_pointer_type pt = true -> 
             typecheck_val (eval_lvalue e rho) pt=true).
Proof.

intros. induction e; split; intros; try solve[subst; auto].

(*Const int*)
simpl. subst; destruct t; auto; simpl in H0; inv H0; intuition.

(*Const float*)
simpl in *. subst; destruct t; intuition. 

(*Var*)
st.  

apply typecheck_environ_sound in H. destruct H.
clear H. destruct H2. clear H2.
unfold tc_ve_denote in *.

remember ((var_types Delta) ! i).
destruct o; try rewrite eqb_type_eq in *; simpl in *; intuition. (*if it isn't in delta, it won't typecheck*)
remember (type_eq t t0). destruct s; intuition. (*pt is type that the var lookup checks as*)
subst. remember (negb(type_is_volatile t0)). destruct b; intuition.
clear H3. symmetry in Heqo.
specialize (H i t0 Heqo).

destruct H as [ [? ?] | [ [? [? [[? ?] [? ?]]]] | ? ]].  
rewrite H in *. rewrite <- Heqb. rewrite eqb_type_refl in *. destruct pt; auto.
remember ((ve_of rho) ! i). destruct o; try rewrite eqb_type_eq in *; simpl in *;  intuition.
inv H3.  rewrite eqb_type_refl. rewrite <- Heqb. destruct pt; auto.
rewrite H. rewrite eqb_type_refl. destruct pt; auto.

destruct H as [? [? [[? ?] ?]]].
rewrite H3. rewrite H. rewrite eqb_type_refl. destruct pt; auto.

(*Temp*)
Focus 1.
simpl in *. destruct rho. apply typecheck_environ_sound in H. intuition.
clear H H3.  
unfold tc_te_denote in *. 
unfold eval_id in *. 

simpl. unfold force_val.
destruct Delta. destruct p. destruct p. 
unfold temp_types in *. simpl in *.
remember (t1 ! i). destruct o.
  symmetry in Heqo.  
  destruct p. specialize (H1 i t3 b Heqo). simpl in *.
  rewrite eqb_type_eq in *. destruct H1 as [? [? ?]].
  rewrite H. if_tac in H0; simpl in *; try solve [inv H0].
  destruct (type_eq t t3); try solve [inv H0]. subst; auto.
  if_tac in H0; inv H0.

(*deref*)  
simpl in *. intuition. specialize (H3 pt).
unfold_tc_denote.
remember (eval_expr e rho); destruct v;
simpl in *;
remember (typeof e); destruct t0; intuition; destruct pt; auto.

(*addrof*)
st. intuition. 
destruct t; auto.


(*Unop*)
intuition; simpl in *. intuition. 
destruct u; simpl in *. 

unfold sem_notbool in *.
remember (typeof e). destruct t0; simpl in *; intuition;
try destruct i; try destruct s; st; destruct (eval_expr e rho); intuition;
try of_bool_destruct; try destruct t; intuition.

unfold sem_notint.

remember (typeof e). destruct t0; simpl in *; intuition;
try destruct i; try destruct s; st; destruct (eval_expr e rho); intuition;
try of_bool_destruct; try destruct t; intuition.


unfold sem_neg.

remember (typeof e). destruct t0; simpl in *; intuition;
try destruct i; try destruct s; st; destruct (eval_expr e rho); intuition;
try of_bool_destruct; try destruct t; intuition.

(*binop*)
repeat rewrite andb_true_iff in *; intuition.
clear H4. clear H2. clear H. 
eapply typecheck_binop_sound; eauto.

(* cast *)
st. intuition.
remember (eval_expr e rho). 
destruct v; intuition; remember (typeof e); destruct t0; intuition; destruct t; intuition;
try destruct i; try destruct i0; try destruct i1; intuition;
unfold sem_cast; unfold classify_cast; unfold cast_float_int;
destruct s; auto; unfold_tc_denote; try unfold Float.intoffloat; try unfold Float.intuoffloat;
st; intuition; unfold_tc_denote; rewrite <- Heqv in *; destruct f; auto;
st; destruct e0; rewrite H1; rewrite H5; auto.

(*condition*)
admit. (*condition might go away*)
(*st. repeat rewrite andb_true_iff in *; intuition.
remember (eval_expr rho e2).
remember (eval_expr rho e3).

destruct (eval_expr rho e1); intuition.
remember (typeof e1); destruct t0; intuition. simpl.
destruct (negb (Int.eq i Int.zero)). destruct v; intuition; remember (typeof e2);
destruct t0; intuition; destruct t; intuition; try destruct i2; try destruct s0; intuition;
try destruct i3; try destruct s0; try destruct s1; try destruct i1; intuition.
destruct v0; intuition; remember (typeof e3); destruct t0; intuition; destruct t; intuition; 
try destruct i2; try destruct s0; intuition;
try destruct i3; try destruct s0; try destruct s1; try destruct i1; intuition.
remember (typeof e1); destruct t0; intuition. simpl.
destruct (negb (Float.cmp Ceq f Float.zero)).
remember (typeof e2). destruct v; destruct t0; destruct t; intuition;
try destruct i0; try destruct s; intuition; try destruct i1; try destruct s0; try destruct i; intuition.
remember (typeof e3). destruct v0; destruct t0; destruct t; intuition; 
try destruct i0; try destruct s; intuition; try destruct i1; try destruct s0; try destruct i; intuition.
remember (typeof e1). unfold bool_val. destruct t0; intuition.*)

(*EField*)
st. intuition. specialize  (H3 pt). intuition. remember rho.
destruct e0.
apply typecheck_environ_sound in H. intuition. clear H4 H8.
rewrite Heqe0 in H0.
assert (PTR := eval_lvalue_ptr _ _ _ _ _ _ Heqe0 H H0).
rewrite Heqe0 in *. clear Heqe0.
intuition. 
remember (eval_lvalue e rho). unfold denote_tc_isptr in *.
destruct v; intuition; try congruence.
remember (eval_lvalue e rho). destruct H4. destruct H4.
destruct v; intuition; try congruence.
inv H4.
destruct (typeof e); intuition. 
destruct (field_offset i f); intuition.

Qed. 

Definition defined_val v :=
match v with
Vundef => False
| _ => True
end.

Lemma typecheck_both_bool_sound : forall Delta rho e,
 typecheck_environ rho Delta = true ->
 (typecheck_b Delta e= true ->
  defined_val (eval_expr e rho) ->
  typecheck_val (eval_expr e rho) (typeof e)=true)
 /\
 (forall pt, tc_might_be_true (typecheck_lvalue Delta e) =true ->
  defined_val (eval_lvalue e rho) ->
  is_pointer_type pt =true ->
  typecheck_val (eval_lvalue e rho) pt=true).
Proof. 
Admitted. (*Not used
intros. unfold typecheck_b. induction e; intuition.

(*int*)
destruct t; auto; st; try congruence.  

(*float*)
destruct t; auto; st; try congruence.

(*var*)
st. remember ((ve_of rho) ! i). destruct o.
  destruct p; try rewrite eqb_type_eq in *; simpl in *; repeat if_tac; destruct pt; auto.

  remember (ge_of rho i). destruct o; try rewrite eqb_type_eq in *; simpl in *.
    destruct p; try rewrite eqb_type_eq in *; simpl in *.
    if_tac. remember ((var_types Delta) ! i).
    destruct o; try rewrite eqb_type_eq in *; simpl in *. subst.
   destruct (type_eq t t1); st; try congruence.
    subst. apply typecheck_environ_sound in H. 
    intuition. clear H3. unfold ve_correct in *.
    rewrite Forall_forall in *. symmetry in Heqo1. 
    apply PTree.elements_correct in Heqo1.
    specialize (H4 (i,t1)). intuition. simpl in H; rewrite <- Heqo in H;
    rewrite <- Heqo0 in H. destruct v; try congruence; auto;
    destruct pt; simpl in *; try congruence. 
    destruct pt; simpl in *; try congruence. intuition.
    intuition. 

(*temp*)
simpl in *. unfold defined_val in *.
unfold eval_id in *. unfold force_val.
 remember ((temp_types Delta) ! i).
destruct o; try rewrite eqb_type_eq in *; simpl in *.
  apply typecheck_environ_sound in H. intuition. 
  remember ((te_of rho) ! i); destruct o; auto. clear H3. symmetry in Heqo.
  apply PTree.elements_correct in Heqo. unfold te_correct in *.
  rewrite Forall_forall in *. specialize (H2 (i,p)). if_tac in H0; intuition.
  st. destruct p. rewrite <- Heqo0 in H. st.
  destruct (type_eq t t0); simpl in *; subst; auto. discriminate.
  if_tac in H0. simpl in H0. inv H0. inv H0.
 
(*deref*)
st. remember (eval_expr rho e). destruct v; auto. 

(*addrof*)
st. rewrite andb_true_iff in *. intuition. specialize (H1 t).
intuition. apply H1. destruct t; auto.

(*unop*)
st. rewrite andb_true_iff in *. intuition. clear H1.
destruct u; st;
match goal with [ |- context[force_val (?H _ _)]] => unfold H in * end;
  remember (typeof e); destruct t0; st; try congruence; 
  try destruct i; try destruct s; st; try congruence; auto;
  destruct (eval_expr rho e); auto; st; try (of_bool_destruct); destruct t; auto;
  st; try congruence.

(*binop*)
admit.

(*cast*)
admit.

(*condition*)
admit.

(*field*)
st. remember (eval_lvalue rho e). destruct v; auto.
remember (typeof e). destruct t0; auto. remember (field_offset i f).
destruct r; auto. 

Qed. (*admits, not done, should work ==================================================================*)
    *)

Lemma typecheck_expr_sound : forall Delta rho e,
 typecheck_environ rho Delta = true -> 
              denote_tc_assert (typecheck_expr Delta e) rho ->
             typecheck_val (eval_expr e rho) (typeof e) = true.
Proof. intros. 
assert (TC := typecheck_both_sound Delta rho e). intuition. Qed.


Lemma typecheck_lvalue_sound : forall Delta rho e,
  typecheck_environ rho Delta = true ->
  denote_tc_assert (typecheck_lvalue Delta e) rho ->
  (forall pt, 
    is_pointer_type pt = true -> 
    typecheck_val (eval_lvalue e rho) pt=true).
intros. edestruct (typecheck_both_sound _ _ e H).
apply H3; eauto.
Qed.

Lemma get_typed_int:
    forall v att, typecheck_val v (Tint I32 Signed att) = true -> 
                      exists i:int, v = Vint i.
intros; destruct v; inv H; eauto.
Qed.

Definition is_ptr_type (ty: type) : bool :=
  match ty with
  | Tpointer _ _ => true
  | Tarray _ _ _ => true
  | Tfunction _ _ => true
  | Tstruct _ _ _ => true
  | Tunion _ _ _ => true
  | _ => false
end.

(*Not going to work because of null pointer
Lemma get_typed_ptr:
   forall v ty, 
                   typecheck_val v ty = true -> 
                   is_ptr_type ty = true ->
                      exists b, exists ofs, v = Vptr b ofs.
Proof.
intros; destruct v; destruct ty; inv H; eauto; inv H0.
Qed.*)




Lemma tc_binaryop_nomem : forall b e1 e2 m1 m2 t rho,
denote_tc_assert (isBinOpResultType b e1 e2 t) rho ->
sem_binary_operation b (eval_expr e1 rho) (typeof e1) (eval_expr e2 rho)
  (typeof e2) (m1) =
sem_binary_operation b (eval_expr e1 rho) (typeof e1) (eval_expr e2 rho)
  (typeof e2) (m2).
Proof.
intros.
destruct b; st; auto;
 unfold sem_cmp; destruct (classify_cmp (typeof e1) (typeof e2));
   try destruct i; try destruct s; auto; contradiction.
Qed. 

Definition some_pt_type := Tpointer Tvoid noattr.

Lemma filter_genv_zero_ofs : forall ge ge2 b i t,
  filter_genv ge = ge2 ->
    (forall id, ge2 id = Some (Vptr b i, t) ->
      i = Int.zero).
Proof.
intros. unfold filter_genv in *. rewrite <- H in H0.
remember (Genv.find_symbol ge id). destruct o. 
destruct (type_of_global ge b0); inv H0; auto.
inv H0.
Qed.

Ltac ftn := try solve [st; try congruence; try contradiction]. 


Lemma eval_binop_relate_fail :
forall (Delta : tycontext) (rho : environ) (b : binary_operation)
  (e1 e2 : expr) (t : type) (m : mem),
typecheck_environ rho Delta = true ->
forall ge : genv,
filter_genv ge = ge_of rho ->
denote_tc_assert (typecheck_expr Delta e2) rho ->
denote_tc_assert (isBinOpResultType b e1 e2 t) rho ->
denote_tc_assert (typecheck_expr Delta e1) rho ->
None =
sem_binary_operation b (eval_expr e1 rho) (typeof e1) (eval_expr e2 rho)
  (typeof e2) (fun (_ : block) (_ : Z) => false) ->
Clight_sem.eval_expr ge (ve_of rho) (te_of rho) m e2 (eval_expr e2 rho) ->
Clight_sem.eval_expr ge (ve_of rho) (te_of rho) m e1 (eval_expr e1 rho) ->
Clight_sem.eval_expr ge (ve_of rho) (te_of rho) m (Ebinop b e1 e2 t) Vundef.
Proof.
Admitted. (*Memory
intros. assert (TC1 := typecheck_expr_sound _ _ _ H H1).
assert (TC2 := typecheck_expr_sound _ _ _ H H3).
st. 
unfold sem_binary_operation in *. destruct b; 
st; 
remember (typeof e1); remember (typeof e2);
remember (eval_expr rho e1); remember (eval_expr rho e2);

(try match goal with
| [H : None = ?X _ _ _ _ |- _] => unfold X in *
| [H : None = ?X _ _ _ _ _ _ |- _ ] => unfold X in *
end; 

destruct v0; destruct t1; ftn; destruct v; destruct t0; ftn;
try destruct i1; try destruct s; ftn; try destruct i2; try destruct s0; ftn;
try destruct i0; ftn; st; try (rewrite <- Heqv in *; intuition);
try rewrite <- Heqv0 in *; intuition; 
try (repeat rewrite andb_if in H4); try (repeat rewrite orb_if in H4); repeat if_tac in H4; ftn).
*)



Lemma eval_both_relate:
  forall Delta ge rho e m,
           filter_genv ge = ge_of rho ->
           typecheck_environ rho Delta = true ->
           (denote_tc_assert (typecheck_expr Delta e) rho ->
             Clight_sem.eval_expr ge (ve_of rho) (te_of rho) m e  (eval_expr e rho))
           /\
           (denote_tc_assert (typecheck_lvalue Delta e) rho ->
             exists b, exists ofs, 
              Clight_sem.eval_lvalue ge (ve_of rho) (te_of rho) m e b ofs /\
              eval_lvalue e rho = Vptr b ofs).
Proof. 
intros. generalize dependent ge. induction e; intros;
try solve[intuition; constructor; auto | subst; inv H1]; intuition.

(* var*)
assert (TC_Sound:= typecheck_lvalue_sound).
specialize (TC_Sound Delta rho (Evar i t) H0 H1).
specialize (TC_Sound some_pt_type).
 
st. remember ((ve_of rho) ! i); destruct o; try destruct p; 
try rewrite eqb_type_eq in *; simpl in *.
destruct (type_eq t t0); simpl in *; intuition.
subst t0. if_tac; intuition.
exists b. exists Int.zero. intuition. constructor. auto.
remember (ge_of rho i). destruct o; try destruct p; auto;
try rewrite eqb_type_eq in *; simpl in *; intuition.
destruct (type_eq t t0); simpl in *. subst t0.

remember ((var_types Delta) ! i). 
destruct o; try rewrite eqb_type_eq in *; simpl in *; intuition.
destruct (type_eq t t0); simpl in *; [ | contradiction]. subst t0.
symmetry in Heqo1. 
apply typecheck_environ_sound in H0.
intuition. unfold tc_ve_denote in *. 
specialize (H0 i t Heqo1). 
rewrite <- Heqo in *. rewrite <- Heqo0 in *. intuition. destruct H5. congruence.
repeat destruct H0. destruct H5. congruence.
 destruct v; intuition. destruct H0. destruct H0.
intuition. congruence. destruct H0. destruct H0. intuition.
inv H0. exists x. exists x0. intuition. destruct rho. simpl in *.
symmetry in Heqo0.
assert (Eq := filter_genv_zero_ofs _ _ x x0 t H _ Heqo0). subst.
apply Clight_sem.eval_Evar_global; auto. 
unfold filter_genv in Heqo0. 
destruct (Genv.find_symbol ge i). destruct ( type_of_global ge b).
inv Heqo0. auto. inv Heqo0. auto. congruence.
unfold filter_genv in Heqo0. destruct (Genv.find_symbol ge i); try congruence.
assert (x = b). destruct (type_of_global ge b); inv Heqo0; auto.
subst. 
destruct (type_of_global ge b). inv Heqo0. auto. inv Heqo0. congruence.
congruence.

(*temp*)
assert (TC:= typecheck_expr_sound).
specialize (TC Delta rho (Etempvar i t)). st. 
intuition.
constructor. unfold eval_id in *. destruct ((te_of rho) ! i); auto. inv H3.

(*deref*)
assert (TC:= typecheck_lvalue_sound _ _ _ H0 H1).
specialize (IHe ge). intuition. simpl in H1.
intuition. simpl. unfold_tc_denote.
 remember (eval_expr e rho); destruct v;
intuition. 
exists b. exists i. st. intuition. constructor.
auto.

(*addrof*)

simpl in H1.
assert (ISPTR := eval_lvalue_ptr rho e Delta (te_of rho) (ve_of rho) (ge_of rho)).
specialize (IHe ge).
assert (mkEnviron (ge_of rho) (ve_of rho) (te_of rho) = rho). destruct rho; auto.
intuition; apply typecheck_environ_sound in H0. intuition. 
simpl. destruct H7. destruct H1. intuition. congruence. 
destruct H7. destruct H1. destruct H1. destruct H8. destruct H8. simpl.
intuition. rewrite H8. constructor. rewrite H8 in H7. inversion H7. auto.

(*unop*)
subst. st. intuition. unfold force_val. remember (sem_unary_operation u (eval_expr e rho) (typeof e)).
destruct o. eapply Clight_sem.eval_Eunop. eapply IHe; eauto. rewrite Heqo. auto.
apply typecheck_expr_sound in H3; auto. unfold sem_unary_operation in *.
destruct u. st. remember (typeof e); destruct t0; try inv H2;
try destruct i;try destruct s; try inv H2; st; destruct t; intuition;
destruct (eval_expr e rho); intuition; unfold sem_notbool in *;
st; inv Heqo. 

st. remember (typeof e). destruct t0;
try destruct i; try destruct s; try inv H3; st; destruct t; intuition;
destruct (eval_expr e rho); intuition; unfold sem_notint in *;
st; inv Heqo. 

st. remember (typeof e). destruct t0;
try destruct i; try destruct s; try inv H3; st; destruct t; intuition;
destruct (eval_expr e rho); intuition; unfold sem_neg in *;
st; inv Heqo.

(*binop*)
subst. st. intuition. unfold force_val.
remember (sem_binary_operation b (eval_expr e1 rho) (typeof e1) (eval_expr e2 rho)
(typeof e2) (fun (_ : block) (_ : Z) => false)).
destruct o. eapply Clight_sem.eval_Ebinop. eapply IHe1; eauto.
eapply IHe2. apply H. apply H3. auto. apply typecheck_expr_sound in H3; auto.
rewrite Heqo.

apply tc_binaryop_nomem with (t:=t); auto.
specialize (IHe1 ge). specialize (IHe2 ge). intuition.
clear H6 H8. 
eapply eval_binop_relate_fail; eauto.

(*Cast*)
subst. assert (TC := typecheck_expr_sound _ _ _ H0 H1).
st. intuition. unfold force_val. remember (sem_cast (eval_expr e rho) (typeof e) t).
destruct o. eapply Clight_sem.eval_Ecast. eapply IHe. auto. apply H2. auto.

specialize (IHe ge). intuition. (*seems too easy, maybe functions are exactly the same?
still suprising to not deal with float case, commented below*)
(*
apply typecheck_expr_sound in H2; auto. 
remember (typeof e). remember (eval_expr rho e). destruct v; intuition; st;
destruct t0; intuition; destruct t; intuition; try destruct i0; try destruct s;
try destruct i1;try destruct s0; intuition;try solve [inv Heqo]; try destruct i; intuition;
st; try rewrite <- Heqv in H3; unfold sem_cast in *;
try solve [st; intuition; try unfold Float.intoffloat in *; try unfold Float.intuoffloat in *;
destruct (Float.Zoffloat f); intuition;
rewrite H1 in Heqo; rewrite H4 in Heqo; st; inv Heqo; 
destruct i; intuition]. inv Heqo. inv Heqo. *)

admit. (*Pass for now, since cond might go away.....======================================================*)

(*Field*)
assert (TC:= typecheck_lvalue_sound _ _ _ H0 H1).
specialize (IHe ge). specialize (TC some_pt_type). intuition. simpl in H1. intuition.
st. remember (eval_lvalue e rho). destruct v; intuition.
remember (typeof e). destruct t0; intuition. remember (field_offset i f).
destruct r; intuition. st. exists b. exists (Int.add i0 (Int.repr z)). 
intuition. eapply Clight_sem.eval_Efield_struct; auto.
destruct H5. destruct H4. intuition. inv H8. 
(*new thing*)
eapply Clight_sem.eval_Elvalue in H5.
apply H5. rewrite <- Heqt0. auto. apply Csem.deref_loc_copy. rewrite <- Heqt0. auto.
eauto. eauto.  
st. exists b. exists i0. intuition. eapply Clight_sem.eval_Efield_union; eauto.

destruct H5. destruct H4. intuition. eapply Clight_sem.eval_Elvalue in H5.
apply H5. rewrite <- Heqt0. auto. inv H8. apply Csem.deref_loc_copy. rewrite <- Heqt0. auto.

Qed. 

Lemma eval_expr_relate:
  forall Delta ge rho e m,
           filter_genv ge = ge_of rho ->
           typecheck_environ rho Delta = true ->
           (denote_tc_assert (typecheck_expr Delta e) rho ->
             Clight_sem.eval_expr ge (ve_of rho) (te_of rho) m e  (eval_expr e rho)).
Proof.
apply eval_both_relate.
Qed.



Lemma eval_lvalue_relate:
  forall Delta ge rho e m,
           filter_genv ge = ge_of rho ->
           typecheck_environ rho Delta = true ->
          
           (denote_tc_assert (typecheck_lvalue Delta e) rho ->
             exists b, exists ofs, 
              Clight_sem.eval_lvalue ge (ve_of rho) (te_of rho) m e b ofs /\
              eval_lvalue e rho = Vptr b ofs).
apply eval_both_relate.
Qed.

Lemma tc_lvalue_nonvol : forall rho Delta e,
(denote_tc_assert (typecheck_lvalue Delta e) rho) ->
type_is_volatile (typeof e) = false.
Proof.
intros.
destruct e; intuition; simpl in *. 

destruct ((var_types Delta) ! i); intuition; simpl in *.
intuition. unfold tc_bool in *. rewrite if_negb in *.
if_tac in H1; simpl in *; intuition.

intuition. unfold tc_bool in *. rewrite if_negb in *.
if_tac in H1; intuition.

intuition. clear - H1. unfold tc_bool in *. rewrite if_negb in *.
if_tac in H1; intuition.
Qed.

