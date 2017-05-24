module FStar.Reflection.Syntax.Lemmas

open FStar.Reflection.Syntax
open FStar.Tactics.Types

val uncurry : ('a -> 'b -> 'c) -> ('a * 'b -> 'c)
let uncurry f (x, y) = f x y

val curry : ('a * 'b -> 'c) -> ('a -> 'b -> 'c)
let curry f x y = f (x, y)

val mk_app_collect_inv_s : (t:term) -> (args:list term) ->
                            Lemma (uncurry mk_app (collect_app' args t) == mk_app t args)
let rec mk_app_collect_inv_s t args =
    match inspect t with
    | Tv_App l r ->
        mk_app_collect_inv_s l (r::args);
        pack_inspect_inv t
    | _ -> ()

val mk_app_collect_inv : (t:term) -> Lemma (uncurry mk_app (collect_app t) == t)
let rec mk_app_collect_inv t = mk_app_collect_inv_s t []

(*
 * The way back is not stricly true: the list of arguments could grow.
 * It's annoying to even state, might do it later
 *)
let rec forall_list (p:'a -> Type) (l:list 'a) : Type =
    match l with
    | [] -> True
    | x::xs -> p x /\ forall_list p xs

val collect_app_order' : (args:list term) -> (tt:term) -> (t:term) ->
            Lemma (requires (forall_list (fun a -> a << tt) args)
                             /\ t << tt)
                  (ensures (forall_list (fun a -> a << tt) (snd (collect_app' args t)))
                           /\ fst (collect_app' args t) << tt)
                  (decreases t)
let rec collect_app_order' args tt t =
    match inspect t with
    | Tv_App l r -> collect_app_order' (r::args) tt l
    | _ -> ()

val collect_app_order : (t:term) ->
            Lemma (ensures (forall (f:term). forall (s:list term). (f,s) == collect_app t ==>
                              (f << t /\ forall_list (fun a -> a << t) (snd (collect_app t)))
                           \/ (f == t /\ s == [])))
let collect_app_order t =
    match inspect t with
    | Tv_App l r -> collect_app_order' [r] t l
    | _ -> ()
