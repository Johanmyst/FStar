module Canon

#reset-options "--eager_inference"

//

open FStar.Mul
open FStar.Tactics
open FStar.Tactics.Arith
open FStar.Reflection.Arith

assume val x : int
assume val y : int
assume val z : int

(* val refl : (a:Type) -> (x:a) -> Lemma (x == x) *)
(* let refl a x = () *)

val congl : (#a:Type) -> (x : a) -> (y : a) -> (z : a) -> (x == y) -> (y == z) -> Lemma (x == z)
let congl #a x y z p1 p2 = ()

val congr : (#a:Type) -> (x : a) -> (y : a) -> (z : a) -> (x == y) -> (z == y) -> Lemma (z == x)
let congr #a x y z p1 p2 = ()

assume val p : (y + z == x + y)

val distr : (#x : int) -> (#y : int) -> (#z : int) -> Lemma (x * (y + z) == x * y + x * z)
let distr #x #y #z = ()

val distl : (#x : int) -> (#y : int) -> (#z : int) -> Lemma ((x + y) * z == x * z + y * z)
let distl #x #y #z = ()

val ass_l : (#x : int) -> (#y : int) -> (#z : int) -> Lemma (x + (y + z) == (x + y) + z)
let ass_l #x #y #z = ()

(* // When taking a goal of the form *)
(* //   a * (b + c) = ?u *)
(* // it applies distl to cause ?u to unify to *)
(* //   a * b   +   a * c *)
(* // when it's a different shape, apply refl to unify it to the LHS *)
(* let tau : tactic unit = *)
(*     eg <-- cur_goal; *)
(*     let e, g = eg in *)
(*     match run_tm (is_arith_prop g) with *)
(*     | Inr (CompProp l C_Eq r) -> *)
(*         begin match l with *)
(*         | Mult (Plus a b) c -> *)
(*             apply_lemma (distl _ _ _) *)
(*         | _ -> *)
(*             apply_lemma refl *)
(*         end *)
(*     | _ -> *)
(*         apply_lemma refl *)

val midway : (#a:Type) -> (#x:a) -> (#y:a) -> (z:a) -> squash (x == z) -> squash (z == y) -> Lemma (x == y)
let midway #a #x #y z e1 e2 = ()

val midl : (#x:int) -> (#y:int) -> (#z:int) -> (#w:int) -> (x * z + y * z == w) -> Lemma ((x + y) * z == w)
let midl #x #y #z #w e = ()

val midr : (#x:int) -> (#y:int) -> (#z:int) -> (#w:int) -> (z * x + z * y == w) -> Lemma (z * (x + y) == w)
let midr #x #y #z #w e = ()

let rec canon : unit -> Tac unit = fun () -> (
    simpl;; // Needed to unfold op_Star into op_Multiply...
    eg <-- cur_goal;
    let e, g = eg in
    match term_as_formula g with
    | Comp Eq t l r ->
        begin match run_tm (is_arith_expr l) with
        | Inl s ->
            refl

        | Inr (Plus a (Plus b c)) ->
            apply_lemma (quote ass_l)

        | Inr (Mult (Plus a b) c) ->
            apply_lemma (quote distl)

        | Inr (Mult a (Plus b c)) ->
            apply_lemma (quote distr)

        | Inr _ ->
            refl
        end
    | _ ->
        fail ("impossible: " ^ term_to_string g)
    ) ()

let tau : tactic unit =
    pointwise canon;;
    pointwise canon;;
    pointwise canon;;
    pointwise canon;;
    pointwise canon;;
    pointwise canon;;
    pointwise canon;;
    pointwise canon

let lem1 = assert_by_tactic (dump "BEFORE";; tau;; dump "AFTER") ((x + y) * (z + z) == 2 * z * (y + x))

(* let lem2 = assert_by_tactic (dump "BEFORE";; tau;; dump "AFTER") (x == x) *)

let lemma_mul_5 (a b c d e : int) =
    assert_by_tactic
        (dump "BEFORE";; tau;; dump "AFTER")
        ((a+b+c+d+e)*(a+b+c+d+e) ==
                a * a + a * b + a * c + a * d + a * e
              + b * a + b * b + b * c + b * d + b * e
              + c * a + c * b + c * c + c * d + c * e
              + d * a + d * b + d * c + d * d + d * e
              + e * a + e * b + e * c + e * d + e * e)
