Require Import floyd.proofauto.
Require Import sha.sha.
Require Import sha.SHA256.
Require Import sha.spec_sha.
Require Import sha.sha_lemmas.

Local Open Scope logic.

Lemma body_SHA256: semax_body Vprog Gtot f_SHA256 SHA256_spec.
Proof.
start_function.

abbreviate_semax.
name d_ _d.
name n_ _n.
name md_ _md.
name c_ _c.
normalize. rename lvar0 into c.

forward_call (* SHA256_Init(&c); *)
   (c).
rewrite !sepcon_assoc; (* need this with weak canceller *)
 apply sepcon_derives; [apply derives_refl | cancel].

forward_call (* SHA256_Update(&c,d,n); *)
  (init_s256abs,data,c,d,dsh, Zlength data, kv) a.
 repeat split; auto; Omega1.

forward_call (* SHA256_Final(md,&c); *)
    (a,md,c,msh,kv).

forward. (* return; *)
Exists c.
change (Tstruct _SHA256state_st noattr) with t_struct_SHA256state_st.
entailer!.
replace (SHA_256 data) with (sha_finish a); [cancel |].
clear - H1.
autorewrite with sublist in H1.
unfold update_abs in H1. simpl in H1. subst; reflexivity.
Qed.
