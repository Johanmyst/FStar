open Prims
let (lookup_bvar :
  FStar_Reflection_Types.env ->
    Prims.int -> FStar_Reflection_Types.term FStar_Pervasives_Native.option)
  = fun e -> fun x -> Prims.magic ()
let (lookup_fvar_uinst :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.fv ->
      FStar_Reflection_Types.universe Prims.list ->
        FStar_Reflection_Types.term FStar_Pervasives_Native.option)
  = fun e -> fun x -> fun us -> Prims.magic ()
let (lookup_fvar :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.fv ->
      FStar_Reflection_Types.term FStar_Pervasives_Native.option)
  = fun e -> fun x -> lookup_fvar_uinst e x []
type pp_name_t = (Prims.string, unit) FStar_Sealed_Inhabited.sealed
let (pp_name_default : pp_name_t) = FStar_Sealed_Inhabited.seal "x" "x"
let (seal_pp_name : Prims.string -> pp_name_t) =
  fun x -> FStar_Sealed_Inhabited.seal "x" x
let (mk_binder :
  pp_name_t ->
    FStar_Reflection_Data.var ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Data.aqualv -> FStar_Reflection_Types.binder)
  =
  fun pp_name ->
    fun x ->
      fun ty ->
        fun q ->
          FStar_Reflection_Builtins.pack_binder
            {
              FStar_Reflection_Data.binder_bv =
                (FStar_Reflection_Builtins.pack_bv
                   {
                     FStar_Reflection_Data.bv_ppname = pp_name;
                     FStar_Reflection_Data.bv_index = x
                   });
              FStar_Reflection_Data.binder_qual = q;
              FStar_Reflection_Data.binder_attrs = [];
              FStar_Reflection_Data.binder_sort = ty
            }
let (extend_env :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Data.var ->
      FStar_Reflection_Types.term -> FStar_Reflection_Types.env)
  =
  fun e ->
    fun x ->
      fun ty ->
        FStar_Reflection_Builtins.push_binder e
          (mk_binder (seal_pp_name "x") x ty FStar_Reflection_Data.Q_Explicit)
let (as_binder :
  FStar_Reflection_Data.var ->
    FStar_Reflection_Types.term -> FStar_Reflection_Types.binder)
  =
  fun x ->
    fun ty ->
      mk_binder (seal_pp_name "x") x ty FStar_Reflection_Data.Q_Explicit
let (bv_index : FStar_Reflection_Types.bv -> FStar_Reflection_Data.var) =
  fun x ->
    (FStar_Reflection_Builtins.inspect_bv x).FStar_Reflection_Data.bv_index
let (binder_sort :
  FStar_Reflection_Types.binder -> FStar_Reflection_Types.typ) =
  fun b ->
    (FStar_Reflection_Builtins.inspect_binder b).FStar_Reflection_Data.binder_sort
let (binder_qual :
  FStar_Reflection_Types.binder -> FStar_Reflection_Data.aqualv) =
  fun b ->
    let uu___ = FStar_Reflection_Builtins.inspect_binder b in
    match uu___ with
    | { FStar_Reflection_Data.binder_bv = uu___1;
        FStar_Reflection_Data.binder_qual = q;
        FStar_Reflection_Data.binder_attrs = uu___2;
        FStar_Reflection_Data.binder_sort = uu___3;_} -> q
let (tun : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln FStar_Reflection_Data.Tv_Unknown
let (make_bv : Prims.nat -> FStar_Reflection_Data.bv_view) =
  fun n ->
    {
      FStar_Reflection_Data.bv_ppname = pp_name_default;
      FStar_Reflection_Data.bv_index = n
    }
type subst_elt =
  | DT of Prims.nat * FStar_Reflection_Types.term 
  | NT of FStar_Reflection_Data.var * FStar_Reflection_Types.term 
  | ND of FStar_Reflection_Data.var * Prims.nat 
let (uu___is_DT : subst_elt -> Prims.bool) =
  fun projectee ->
    match projectee with | DT (_0, _1) -> true | uu___ -> false
let (__proj__DT__item___0 : subst_elt -> Prims.nat) =
  fun projectee -> match projectee with | DT (_0, _1) -> _0
let (__proj__DT__item___1 : subst_elt -> FStar_Reflection_Types.term) =
  fun projectee -> match projectee with | DT (_0, _1) -> _1
let (uu___is_NT : subst_elt -> Prims.bool) =
  fun projectee ->
    match projectee with | NT (_0, _1) -> true | uu___ -> false
let (__proj__NT__item___0 : subst_elt -> FStar_Reflection_Data.var) =
  fun projectee -> match projectee with | NT (_0, _1) -> _0
let (__proj__NT__item___1 : subst_elt -> FStar_Reflection_Types.term) =
  fun projectee -> match projectee with | NT (_0, _1) -> _1
let (uu___is_ND : subst_elt -> Prims.bool) =
  fun projectee ->
    match projectee with | ND (_0, _1) -> true | uu___ -> false
let (__proj__ND__item___0 : subst_elt -> FStar_Reflection_Data.var) =
  fun projectee -> match projectee with | ND (_0, _1) -> _0
let (__proj__ND__item___1 : subst_elt -> Prims.nat) =
  fun projectee -> match projectee with | ND (_0, _1) -> _1
let (shift_subst_elt : Prims.nat -> subst_elt -> subst_elt) =
  fun n ->
    fun uu___ ->
      match uu___ with
      | DT (i, t) -> DT ((i + n), t)
      | NT (x, t) -> NT (x, t)
      | ND (x, i) -> ND (x, (i + n))
type subst = subst_elt Prims.list
let (shift_subst_n :
  Prims.nat -> subst_elt Prims.list -> subst_elt Prims.list) =
  fun n -> FStar_List_Tot_Base.map (shift_subst_elt n)
let (shift_subst : subst_elt Prims.list -> subst_elt Prims.list) =
  shift_subst_n Prims.int_one
let (maybe_index_of_term :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.var FStar_Pervasives_Native.option)
  =
  fun x ->
    match FStar_Reflection_Builtins.inspect_ln x with
    | FStar_Reflection_Data.Tv_Var bv ->
        FStar_Pervasives_Native.Some (bv_index bv)
    | uu___ -> FStar_Pervasives_Native.None
let (subst_db :
  FStar_Reflection_Types.bv -> subst -> FStar_Reflection_Types.term) =
  fun bv ->
    fun s ->
      match FStar_List_Tot_Base.find
              (fun uu___ ->
                 match uu___ with
                 | DT (j, uu___1) -> j = (bv_index bv)
                 | uu___1 -> false) s
      with
      | FStar_Pervasives_Native.Some (DT (uu___, t)) ->
          (match maybe_index_of_term t with
           | FStar_Pervasives_Native.None -> t
           | FStar_Pervasives_Native.Some k ->
               FStar_Reflection_Builtins.pack_ln
                 (FStar_Reflection_Data.Tv_Var
                    (FStar_Reflection_Builtins.pack_bv
                       (let uu___1 = FStar_Reflection_Builtins.inspect_bv bv in
                        {
                          FStar_Reflection_Data.bv_ppname =
                            (uu___1.FStar_Reflection_Data.bv_ppname);
                          FStar_Reflection_Data.bv_index = k
                        }))))
      | FStar_Pervasives_Native.None ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_BVar bv)
let (subst_var :
  FStar_Reflection_Types.bv -> subst -> FStar_Reflection_Types.term) =
  fun bv ->
    fun s ->
      match FStar_List_Tot_Base.find
              (fun uu___ ->
                 match uu___ with
                 | NT (y, uu___1) -> y = (bv_index bv)
                 | ND (y, uu___1) -> y = (bv_index bv)
                 | uu___1 -> false) s
      with
      | FStar_Pervasives_Native.Some (NT (uu___, t)) ->
          (match maybe_index_of_term t with
           | FStar_Pervasives_Native.None -> t
           | FStar_Pervasives_Native.Some k ->
               FStar_Reflection_Builtins.pack_ln
                 (FStar_Reflection_Data.Tv_Var
                    (FStar_Reflection_Builtins.pack_bv
                       (let uu___1 = FStar_Reflection_Builtins.inspect_bv bv in
                        {
                          FStar_Reflection_Data.bv_ppname =
                            (uu___1.FStar_Reflection_Data.bv_ppname);
                          FStar_Reflection_Data.bv_index = k
                        }))))
      | FStar_Pervasives_Native.Some (ND (uu___, i)) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_BVar
               (FStar_Reflection_Builtins.pack_bv
                  (let uu___1 = FStar_Reflection_Builtins.inspect_bv bv in
                   {
                     FStar_Reflection_Data.bv_ppname =
                       (uu___1.FStar_Reflection_Data.bv_ppname);
                     FStar_Reflection_Data.bv_index = i
                   })))
      | FStar_Pervasives_Native.None ->
          FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_Var bv)
let (make_bv_with_name :
  pp_name_t -> Prims.nat -> FStar_Reflection_Data.bv_view) =
  fun s ->
    fun n ->
      {
        FStar_Reflection_Data.bv_ppname = s;
        FStar_Reflection_Data.bv_index = n
      }
let (var_as_bv : Prims.nat -> FStar_Reflection_Types.bv) =
  fun v -> FStar_Reflection_Builtins.pack_bv (make_bv v)
let (var_as_term : FStar_Reflection_Data.var -> FStar_Reflection_Types.term)
  =
  fun v ->
    FStar_Reflection_Builtins.pack_ln
      (FStar_Reflection_Data.Tv_Var (var_as_bv v))
let (binder_of_t_q :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.aqualv -> FStar_Reflection_Types.binder)
  = fun t -> fun q -> mk_binder pp_name_default Prims.int_zero t q
let (mk_abs :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.aqualv ->
      FStar_Reflection_Types.term -> FStar_Reflection_Types.term)
  =
  fun ty ->
    fun qual ->
      fun t ->
        FStar_Reflection_Builtins.pack_ln
          (FStar_Reflection_Data.Tv_Abs ((binder_of_t_q ty qual), t))
let (mk_total : FStar_Reflection_Types.typ -> FStar_Reflection_Types.comp) =
  fun t ->
    FStar_Reflection_Builtins.pack_comp (FStar_Reflection_Data.C_Total t)
let (mk_ghost : FStar_Reflection_Types.typ -> FStar_Reflection_Types.comp) =
  fun t ->
    FStar_Reflection_Builtins.pack_comp (FStar_Reflection_Data.C_GTotal t)
let (mk_arrow :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.aqualv ->
      FStar_Reflection_Types.typ -> FStar_Reflection_Types.term)
  =
  fun ty ->
    fun qual ->
      fun t ->
        FStar_Reflection_Builtins.pack_ln
          (FStar_Reflection_Data.Tv_Arrow
             ((binder_of_t_q ty qual), (mk_total t)))
let (mk_ghost_arrow :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.aqualv ->
      FStar_Reflection_Types.typ -> FStar_Reflection_Types.term)
  =
  fun ty ->
    fun qual ->
      fun t ->
        FStar_Reflection_Builtins.pack_ln
          (FStar_Reflection_Data.Tv_Arrow
             ((binder_of_t_q ty qual), (mk_ghost t)))
let (bound_var : Prims.nat -> FStar_Reflection_Types.term) =
  fun i ->
    FStar_Reflection_Builtins.pack_ln
      (FStar_Reflection_Data.Tv_BVar
         (FStar_Reflection_Builtins.pack_bv (make_bv i)))
let (mk_let :
  pp_name_t ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Types.term -> FStar_Reflection_Types.term)
  =
  fun ppname ->
    fun e1 ->
      fun t1 ->
        fun e2 ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Let
               (false, [],
                 (FStar_Reflection_Builtins.pack_bv
                    (make_bv_with_name ppname Prims.int_zero)), t1, e1, e2))
let (open_with_var : FStar_Reflection_Data.var -> Prims.nat -> subst) =
  fun x ->
    fun i ->
      [DT
         (i,
           (FStar_Reflection_Builtins.pack_ln
              (FStar_Reflection_Data.Tv_Var (var_as_bv x))))]
let (subst_ctx_uvar_and_subst :
  FStar_Reflection_Types.ctx_uvar_and_subst ->
    subst -> FStar_Reflection_Types.ctx_uvar_and_subst)
  = fun uu___ -> fun uu___1 -> Prims.magic ()
let rec (binder_offset_patterns :
  (FStar_Reflection_Data.pattern * Prims.bool) Prims.list -> Prims.nat) =
  fun ps ->
    match ps with
    | [] -> Prims.int_zero
    | (p, b)::ps1 ->
        let n = binder_offset_pattern p in
        let m = binder_offset_patterns ps1 in n + m
and (binder_offset_pattern : FStar_Reflection_Data.pattern -> Prims.nat) =
  fun p ->
    match p with
    | FStar_Reflection_Data.Pat_Constant uu___ -> Prims.int_zero
    | FStar_Reflection_Data.Pat_Dot_Term uu___ -> Prims.int_zero
    | FStar_Reflection_Data.Pat_Var (uu___, uu___1) -> Prims.int_one
    | FStar_Reflection_Data.Pat_Cons (fv, us, pats) ->
        binder_offset_patterns pats
let rec (subst_term :
  FStar_Reflection_Types.term -> subst -> FStar_Reflection_Types.term) =
  fun t ->
    fun ss ->
      match FStar_Reflection_Builtins.inspect_ln t with
      | FStar_Reflection_Data.Tv_UInst (uu___, uu___1) -> t
      | FStar_Reflection_Data.Tv_FVar uu___ -> t
      | FStar_Reflection_Data.Tv_Type uu___ -> t
      | FStar_Reflection_Data.Tv_Const uu___ -> t
      | FStar_Reflection_Data.Tv_Unsupp -> t
      | FStar_Reflection_Data.Tv_Unknown -> t
      | FStar_Reflection_Data.Tv_Var x -> subst_var x ss
      | FStar_Reflection_Data.Tv_BVar j -> subst_db j ss
      | FStar_Reflection_Data.Tv_App (hd, argv) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_App
               ((subst_term hd ss),
                 ((subst_term (FStar_Pervasives_Native.fst argv) ss),
                   (FStar_Pervasives_Native.snd argv))))
      | FStar_Reflection_Data.Tv_Abs (b, body) ->
          let b' = subst_binder b ss in
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Abs
               (b', (subst_term body (shift_subst ss))))
      | FStar_Reflection_Data.Tv_Arrow (b, c) ->
          let b' = subst_binder b ss in
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Arrow
               (b', (subst_comp c (shift_subst ss))))
      | FStar_Reflection_Data.Tv_Refine (bv, sort, f) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Refine
               (bv, (subst_term sort ss), (subst_term f (shift_subst ss))))
      | FStar_Reflection_Data.Tv_Uvar (j, c) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Uvar
               (j, (subst_ctx_uvar_and_subst c ss)))
      | FStar_Reflection_Data.Tv_Let (recf, attrs, bv, ty, def, body) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Let
               (recf, (subst_terms attrs ss), bv, (subst_term ty ss),
                 (if recf
                  then subst_term def (shift_subst ss)
                  else subst_term def ss),
                 (subst_term body (shift_subst ss))))
      | FStar_Reflection_Data.Tv_Match (scr, ret, brs) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_Match
               ((subst_term scr ss),
                 (match ret with
                  | FStar_Pervasives_Native.None ->
                      FStar_Pervasives_Native.None
                  | FStar_Pervasives_Native.Some m ->
                      FStar_Pervasives_Native.Some (subst_match_returns m ss)),
                 (subst_branches brs ss)))
      | FStar_Reflection_Data.Tv_AscribedT (e, t1, tac, b) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_AscribedT
               ((subst_term e ss), (subst_term t1 ss),
                 (match tac with
                  | FStar_Pervasives_Native.None ->
                      FStar_Pervasives_Native.None
                  | FStar_Pervasives_Native.Some tac1 ->
                      FStar_Pervasives_Native.Some (subst_term tac1 ss)), b))
      | FStar_Reflection_Data.Tv_AscribedC (e, c, tac, b) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_AscribedC
               ((subst_term e ss), (subst_comp c ss),
                 (match tac with
                  | FStar_Pervasives_Native.None ->
                      FStar_Pervasives_Native.None
                  | FStar_Pervasives_Native.Some tac1 ->
                      FStar_Pervasives_Native.Some (subst_term tac1 ss)), b))
and (subst_binder :
  FStar_Reflection_Types.binder -> subst -> FStar_Reflection_Types.binder) =
  fun b ->
    fun ss ->
      let bndr = FStar_Reflection_Builtins.inspect_binder b in
      FStar_Reflection_Builtins.pack_binder
        {
          FStar_Reflection_Data.binder_bv =
            (bndr.FStar_Reflection_Data.binder_bv);
          FStar_Reflection_Data.binder_qual =
            (bndr.FStar_Reflection_Data.binder_qual);
          FStar_Reflection_Data.binder_attrs =
            (subst_terms bndr.FStar_Reflection_Data.binder_attrs ss);
          FStar_Reflection_Data.binder_sort =
            (subst_term bndr.FStar_Reflection_Data.binder_sort ss)
        }
and (subst_comp :
  FStar_Reflection_Types.comp -> subst -> FStar_Reflection_Types.comp) =
  fun c ->
    fun ss ->
      match FStar_Reflection_Builtins.inspect_comp c with
      | FStar_Reflection_Data.C_Total t ->
          FStar_Reflection_Builtins.pack_comp
            (FStar_Reflection_Data.C_Total (subst_term t ss))
      | FStar_Reflection_Data.C_GTotal t ->
          FStar_Reflection_Builtins.pack_comp
            (FStar_Reflection_Data.C_GTotal (subst_term t ss))
      | FStar_Reflection_Data.C_Lemma (pre, post, pats) ->
          FStar_Reflection_Builtins.pack_comp
            (FStar_Reflection_Data.C_Lemma
               ((subst_term pre ss), (subst_term post ss),
                 (subst_term pats ss)))
      | FStar_Reflection_Data.C_Eff (us, eff_name, res, args, decrs) ->
          FStar_Reflection_Builtins.pack_comp
            (FStar_Reflection_Data.C_Eff
               (us, eff_name, (subst_term res ss), (subst_args args ss),
                 (subst_terms decrs ss)))
and (subst_terms :
  FStar_Reflection_Types.term Prims.list ->
    subst -> FStar_Reflection_Types.term Prims.list)
  =
  fun ts ->
    fun ss ->
      match ts with
      | [] -> []
      | t::ts1 -> (subst_term t ss) :: (subst_terms ts1 ss)
and (subst_args :
  FStar_Reflection_Data.argv Prims.list ->
    subst -> FStar_Reflection_Data.argv Prims.list)
  =
  fun ts ->
    fun ss ->
      match ts with
      | [] -> []
      | (t, q)::ts1 -> ((subst_term t ss), q) :: (subst_args ts1 ss)
and (subst_patterns :
  (FStar_Reflection_Data.pattern * Prims.bool) Prims.list ->
    subst -> (FStar_Reflection_Data.pattern * Prims.bool) Prims.list)
  =
  fun ps ->
    fun ss ->
      match ps with
      | [] -> ps
      | (p, b)::ps1 ->
          let n = binder_offset_pattern p in
          let p1 = subst_pattern p ss in
          let ps2 = subst_patterns ps1 (shift_subst_n n ss) in (p1, b) :: ps2
and (subst_pattern :
  FStar_Reflection_Data.pattern -> subst -> FStar_Reflection_Data.pattern) =
  fun p ->
    fun ss ->
      match p with
      | FStar_Reflection_Data.Pat_Constant uu___ -> p
      | FStar_Reflection_Data.Pat_Cons (fv, us, pats) ->
          let pats1 = subst_patterns pats ss in
          FStar_Reflection_Data.Pat_Cons (fv, us, pats1)
      | FStar_Reflection_Data.Pat_Var (bv, st) ->
          FStar_Reflection_Data.Pat_Var (bv, st)
      | FStar_Reflection_Data.Pat_Dot_Term topt ->
          FStar_Reflection_Data.Pat_Dot_Term
            ((match topt with
              | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
              | FStar_Pervasives_Native.Some t ->
                  FStar_Pervasives_Native.Some (subst_term t ss)))
and (subst_branch :
  FStar_Reflection_Data.branch -> subst -> FStar_Reflection_Data.branch) =
  fun br ->
    fun ss ->
      let uu___ = br in
      match uu___ with
      | (p, t) ->
          let p1 = subst_pattern p ss in
          let j = binder_offset_pattern p1 in
          let t1 = subst_term t (shift_subst_n j ss) in (p1, t1)
and (subst_branches :
  FStar_Reflection_Data.branch Prims.list ->
    subst -> FStar_Reflection_Data.branch Prims.list)
  =
  fun brs ->
    fun ss ->
      match brs with
      | [] -> []
      | br::brs1 -> (subst_branch br ss) :: (subst_branches brs1 ss)
and (subst_match_returns :
  FStar_Reflection_Types.match_returns_ascription ->
    subst -> FStar_Reflection_Types.match_returns_ascription)
  =
  fun m ->
    fun ss ->
      let uu___ = m in
      match uu___ with
      | (b, (ret, as_, eq)) ->
          let b1 = subst_binder b ss in
          let ret1 =
            match ret with
            | FStar_Pervasives.Inl t ->
                FStar_Pervasives.Inl (subst_term t (shift_subst ss))
            | FStar_Pervasives.Inr c ->
                FStar_Pervasives.Inr (subst_comp c (shift_subst ss)) in
          let as_1 =
            match as_ with
            | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
            | FStar_Pervasives_Native.Some t ->
                FStar_Pervasives_Native.Some (subst_term t (shift_subst ss)) in
          (b1, (ret1, as_1, eq))
let (open_with :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Types.term -> FStar_Reflection_Types.term)
  = fun t -> fun v -> FStar_Reflection_Typing_Builtins.open_with t v
let (open_term :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.var -> FStar_Reflection_Types.term)
  = fun t -> fun v -> FStar_Reflection_Typing_Builtins.open_term t v
let (close_term :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.var -> FStar_Reflection_Types.term)
  = fun t -> fun v -> FStar_Reflection_Typing_Builtins.close_term t v
let (rename :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.var ->
      FStar_Reflection_Data.var -> FStar_Reflection_Types.term)
  = fun t -> fun x -> fun y -> FStar_Reflection_Typing_Builtins.rename t x y
let (constant_as_term :
  FStar_Reflection_Data.vconst -> FStar_Reflection_Types.term) =
  fun v ->
    FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_Const v)
let (unit_exp : FStar_Reflection_Types.term) =
  constant_as_term FStar_Reflection_Data.C_Unit
let (unit_fv : FStar_Reflection_Types.fv) =
  FStar_Reflection_Builtins.pack_fv FStar_Reflection_Const.unit_lid
let (unit_ty : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_FVar unit_fv)
let (bool_fv : FStar_Reflection_Types.fv) =
  FStar_Reflection_Builtins.pack_fv FStar_Reflection_Const.bool_lid
let (bool_ty : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_FVar bool_fv)
let (u_zero : FStar_Reflection_Types.universe) =
  FStar_Reflection_Builtins.pack_universe FStar_Reflection_Data.Uv_Zero
let (u_max :
  FStar_Reflection_Types.universe ->
    FStar_Reflection_Types.universe -> FStar_Reflection_Types.universe)
  =
  fun u1 ->
    fun u2 ->
      FStar_Reflection_Builtins.pack_universe
        (FStar_Reflection_Data.Uv_Max [u1; u2])
let (u_succ :
  FStar_Reflection_Types.universe -> FStar_Reflection_Types.universe) =
  fun u ->
    FStar_Reflection_Builtins.pack_universe (FStar_Reflection_Data.Uv_Succ u)
let (tm_type :
  FStar_Reflection_Types.universe -> FStar_Reflection_Types.term) =
  fun u ->
    FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_Type u)
let (tm_prop : FStar_Reflection_Types.term) =
  let prop_fv =
    FStar_Reflection_Builtins.pack_fv FStar_Reflection_Const.prop_qn in
  FStar_Reflection_Builtins.pack_ln (FStar_Reflection_Data.Tv_FVar prop_fv)
let (eqtype_lid : FStar_Reflection_Types.name) = ["Prims"; "eqtype"]
let (true_bool : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln
    (FStar_Reflection_Data.Tv_Const FStar_Reflection_Data.C_True)
let (false_bool : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln
    (FStar_Reflection_Data.Tv_Const FStar_Reflection_Data.C_False)
let (eq2 :
  FStar_Reflection_Types.universe ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Types.term -> FStar_Reflection_Types.term)
  =
  fun u ->
    fun t ->
      fun v0 ->
        fun v1 ->
          let eq21 =
            FStar_Reflection_Builtins.pack_fv FStar_Reflection_Const.eq2_qn in
          let eq22 =
            FStar_Reflection_Builtins.pack_ln
              (FStar_Reflection_Data.Tv_UInst (eq21, [u])) in
          let h =
            FStar_Reflection_Builtins.pack_ln
              (FStar_Reflection_Data.Tv_App
                 (eq22, (t, FStar_Reflection_Data.Q_Implicit))) in
          let h1 =
            FStar_Reflection_Builtins.pack_ln
              (FStar_Reflection_Data.Tv_App
                 (h, (v0, FStar_Reflection_Data.Q_Explicit))) in
          let h2 =
            FStar_Reflection_Builtins.pack_ln
              (FStar_Reflection_Data.Tv_App
                 (h1, (v1, FStar_Reflection_Data.Q_Explicit))) in
          h2
let (b2t_lid : FStar_Reflection_Types.name) = ["Prims"; "b2t"]
let (b2t_fv : FStar_Reflection_Types.fv) =
  FStar_Reflection_Builtins.pack_fv b2t_lid
let (b2t_ty : FStar_Reflection_Types.term) =
  FStar_Reflection_Builtins.pack_ln
    (FStar_Reflection_Data.Tv_Arrow
       ((as_binder Prims.int_zero bool_ty), (mk_total (tm_type u_zero))))
let rec (freevars :
  FStar_Reflection_Types.term -> FStar_Reflection_Data.var FStar_Set.set) =
  fun e ->
    match FStar_Reflection_Builtins.inspect_ln e with
    | FStar_Reflection_Data.Tv_Uvar (uu___, uu___1) ->
        FStar_Set.complement (FStar_Set.empty ())
    | FStar_Reflection_Data.Tv_UInst (uu___, uu___1) -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_FVar uu___ -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_Type uu___ -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_Const uu___ -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_Unknown -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_Unsupp -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_BVar uu___ -> FStar_Set.empty ()
    | FStar_Reflection_Data.Tv_Var x -> FStar_Set.singleton (bv_index x)
    | FStar_Reflection_Data.Tv_App (e1, (e2, uu___)) ->
        FStar_Set.union (freevars e1) (freevars e2)
    | FStar_Reflection_Data.Tv_Abs (b, body) ->
        FStar_Set.union (freevars_binder b) (freevars body)
    | FStar_Reflection_Data.Tv_Arrow (b, c) ->
        FStar_Set.union (freevars_binder b) (freevars_comp c)
    | FStar_Reflection_Data.Tv_Refine (bv, sort, f) ->
        FStar_Set.union (freevars sort) (freevars f)
    | FStar_Reflection_Data.Tv_Let (recf, attrs, bv, ty, def, body) ->
        FStar_Set.union
          (FStar_Set.union
             (FStar_Set.union (freevars_terms attrs) (freevars ty))
             (freevars def)) (freevars body)
    | FStar_Reflection_Data.Tv_Match (scr, ret, brs) ->
        FStar_Set.union
          (FStar_Set.union (freevars scr)
             (freevars_opt ret freevars_match_returns))
          (freevars_branches brs)
    | FStar_Reflection_Data.Tv_AscribedT (e1, t, tac, b) ->
        FStar_Set.union (FStar_Set.union (freevars e1) (freevars t))
          (freevars_opt tac freevars)
    | FStar_Reflection_Data.Tv_AscribedC (e1, c, tac, b) ->
        FStar_Set.union (FStar_Set.union (freevars e1) (freevars_comp c))
          (freevars_opt tac freevars)
and freevars_opt :
  'a .
    'a FStar_Pervasives_Native.option ->
      ('a -> FStar_Reflection_Data.var FStar_Set.set) ->
        FStar_Reflection_Data.var FStar_Set.set
  =
  fun o ->
    fun f ->
      match o with
      | FStar_Pervasives_Native.None -> FStar_Set.empty ()
      | FStar_Pervasives_Native.Some x -> f x
and (freevars_comp :
  FStar_Reflection_Types.comp -> FStar_Reflection_Data.var FStar_Set.set) =
  fun c ->
    match FStar_Reflection_Builtins.inspect_comp c with
    | FStar_Reflection_Data.C_Total t -> freevars t
    | FStar_Reflection_Data.C_GTotal t -> freevars t
    | FStar_Reflection_Data.C_Lemma (pre, post, pats) ->
        FStar_Set.union (FStar_Set.union (freevars pre) (freevars post))
          (freevars pats)
    | FStar_Reflection_Data.C_Eff (us, eff_name, res, args, decrs) ->
        FStar_Set.union (FStar_Set.union (freevars res) (freevars_args args))
          (freevars_terms decrs)
and (freevars_args :
  FStar_Reflection_Data.argv Prims.list ->
    FStar_Reflection_Data.var FStar_Set.set)
  =
  fun ts ->
    match ts with
    | [] -> FStar_Set.empty ()
    | (t, q)::ts1 -> FStar_Set.union (freevars t) (freevars_args ts1)
and (freevars_terms :
  FStar_Reflection_Types.term Prims.list ->
    FStar_Reflection_Data.var FStar_Set.set)
  =
  fun ts ->
    match ts with
    | [] -> FStar_Set.empty ()
    | t::ts1 -> FStar_Set.union (freevars t) (freevars_terms ts1)
and (freevars_binder :
  FStar_Reflection_Types.binder -> FStar_Reflection_Data.var FStar_Set.set) =
  fun b ->
    let bndr = FStar_Reflection_Builtins.inspect_binder b in
    FStar_Set.union (freevars bndr.FStar_Reflection_Data.binder_sort)
      (freevars_terms bndr.FStar_Reflection_Data.binder_attrs)
and (freevars_pattern :
  FStar_Reflection_Data.pattern -> FStar_Reflection_Data.var FStar_Set.set) =
  fun p ->
    match p with
    | FStar_Reflection_Data.Pat_Constant uu___ -> FStar_Set.empty ()
    | FStar_Reflection_Data.Pat_Cons (fv, us, pats) -> freevars_patterns pats
    | FStar_Reflection_Data.Pat_Var (bv, uu___) -> FStar_Set.empty ()
    | FStar_Reflection_Data.Pat_Dot_Term topt -> freevars_opt topt freevars
and (freevars_patterns :
  (FStar_Reflection_Data.pattern * Prims.bool) Prims.list ->
    FStar_Reflection_Data.var FStar_Set.set)
  =
  fun ps ->
    match ps with
    | [] -> FStar_Set.empty ()
    | (p, b)::ps1 ->
        FStar_Set.union (freevars_pattern p) (freevars_patterns ps1)
and (freevars_branch :
  FStar_Reflection_Data.branch -> FStar_Reflection_Data.var FStar_Set.set) =
  fun br ->
    let uu___ = br in
    match uu___ with
    | (p, t) -> FStar_Set.union (freevars_pattern p) (freevars t)
and (freevars_branches :
  FStar_Reflection_Data.branch Prims.list ->
    FStar_Reflection_Data.var FStar_Set.set)
  =
  fun brs ->
    match brs with
    | [] -> FStar_Set.empty ()
    | hd::tl -> FStar_Set.union (freevars_branch hd) (freevars_branches tl)
and (freevars_match_returns :
  FStar_Reflection_Types.match_returns_ascription ->
    FStar_Reflection_Data.var FStar_Set.set)
  =
  fun m ->
    let uu___ = m in
    match uu___ with
    | (b, (ret, as_, eq)) ->
        let b1 = freevars_binder b in
        let ret1 =
          match ret with
          | FStar_Pervasives.Inl t -> freevars t
          | FStar_Pervasives.Inr c -> freevars_comp c in
        let as_1 = freevars_opt as_ freevars in
        FStar_Set.union (FStar_Set.union b1 ret1) as_1
let rec (ln' : FStar_Reflection_Types.term -> Prims.int -> Prims.bool) =
  fun e ->
    fun n ->
      match FStar_Reflection_Builtins.inspect_ln e with
      | FStar_Reflection_Data.Tv_UInst (uu___, uu___1) -> true
      | FStar_Reflection_Data.Tv_FVar uu___ -> true
      | FStar_Reflection_Data.Tv_Type uu___ -> true
      | FStar_Reflection_Data.Tv_Const uu___ -> true
      | FStar_Reflection_Data.Tv_Unknown -> true
      | FStar_Reflection_Data.Tv_Unsupp -> true
      | FStar_Reflection_Data.Tv_Var uu___ -> true
      | FStar_Reflection_Data.Tv_BVar m -> (bv_index m) <= n
      | FStar_Reflection_Data.Tv_App (e1, (e2, uu___)) ->
          (ln' e1 n) && (ln' e2 n)
      | FStar_Reflection_Data.Tv_Abs (b, body) ->
          (ln'_binder b n) && (ln' body (n + Prims.int_one))
      | FStar_Reflection_Data.Tv_Arrow (b, c) ->
          (ln'_binder b n) && (ln'_comp c (n + Prims.int_one))
      | FStar_Reflection_Data.Tv_Refine (bv, sort, f) ->
          (ln' sort n) && (ln' f (n + Prims.int_one))
      | FStar_Reflection_Data.Tv_Uvar (uu___, uu___1) -> false
      | FStar_Reflection_Data.Tv_Let (recf, attrs, bv, ty, def, body) ->
          (((ln'_terms attrs n) && (ln' ty n)) &&
             (if recf then ln' def (n + Prims.int_one) else ln' def n))
            && (ln' body (n + Prims.int_one))
      | FStar_Reflection_Data.Tv_Match (scr, ret, brs) ->
          ((ln' scr n) &&
             (match ret with
              | FStar_Pervasives_Native.None -> true
              | FStar_Pervasives_Native.Some m -> ln'_match_returns m n))
            && (ln'_branches brs n)
      | FStar_Reflection_Data.Tv_AscribedT (e1, t, tac, b) ->
          ((ln' e1 n) && (ln' t n)) &&
            ((match tac with
              | FStar_Pervasives_Native.None -> true
              | FStar_Pervasives_Native.Some tac1 -> ln' tac1 n))
      | FStar_Reflection_Data.Tv_AscribedC (e1, c, tac, b) ->
          ((ln' e1 n) && (ln'_comp c n)) &&
            ((match tac with
              | FStar_Pervasives_Native.None -> true
              | FStar_Pervasives_Native.Some tac1 -> ln' tac1 n))
and (ln'_comp : FStar_Reflection_Types.comp -> Prims.int -> Prims.bool) =
  fun c ->
    fun i ->
      match FStar_Reflection_Builtins.inspect_comp c with
      | FStar_Reflection_Data.C_Total t -> ln' t i
      | FStar_Reflection_Data.C_GTotal t -> ln' t i
      | FStar_Reflection_Data.C_Lemma (pre, post, pats) ->
          ((ln' pre i) && (ln' post i)) && (ln' pats i)
      | FStar_Reflection_Data.C_Eff (us, eff_name, res, args, decrs) ->
          ((ln' res i) && (ln'_args args i)) && (ln'_terms decrs i)
and (ln'_args :
  FStar_Reflection_Data.argv Prims.list -> Prims.int -> Prims.bool) =
  fun ts ->
    fun i ->
      match ts with
      | [] -> true
      | (t, q)::ts1 -> (ln' t i) && (ln'_args ts1 i)
and (ln'_binder : FStar_Reflection_Types.binder -> Prims.int -> Prims.bool) =
  fun b ->
    fun n ->
      let bndr = FStar_Reflection_Builtins.inspect_binder b in
      (ln' bndr.FStar_Reflection_Data.binder_sort n) &&
        (ln'_terms bndr.FStar_Reflection_Data.binder_attrs n)
and (ln'_terms :
  FStar_Reflection_Types.term Prims.list -> Prims.int -> Prims.bool) =
  fun ts ->
    fun n ->
      match ts with | [] -> true | t::ts1 -> (ln' t n) && (ln'_terms ts1 n)
and (ln'_patterns :
  (FStar_Reflection_Data.pattern * Prims.bool) Prims.list ->
    Prims.int -> Prims.bool)
  =
  fun ps ->
    fun i ->
      match ps with
      | [] -> true
      | (p, b)::ps1 ->
          let b0 = ln'_pattern p i in
          let n = binder_offset_pattern p in
          let b1 = ln'_patterns ps1 (i + n) in b0 && b1
and (ln'_pattern : FStar_Reflection_Data.pattern -> Prims.int -> Prims.bool)
  =
  fun p ->
    fun i ->
      match p with
      | FStar_Reflection_Data.Pat_Constant uu___ -> true
      | FStar_Reflection_Data.Pat_Cons (fv, us, pats) -> ln'_patterns pats i
      | FStar_Reflection_Data.Pat_Var (bv, uu___) -> true
      | FStar_Reflection_Data.Pat_Dot_Term topt ->
          (match topt with
           | FStar_Pervasives_Native.None -> true
           | FStar_Pervasives_Native.Some t -> ln' t i)
and (ln'_branch : FStar_Reflection_Data.branch -> Prims.int -> Prims.bool) =
  fun br ->
    fun i ->
      let uu___ = br in
      match uu___ with
      | (p, t) ->
          let b = ln'_pattern p i in
          let j = binder_offset_pattern p in
          let b' = ln' t (i + j) in b && b'
and (ln'_branches :
  FStar_Reflection_Data.branch Prims.list -> Prims.int -> Prims.bool) =
  fun brs ->
    fun i ->
      match brs with
      | [] -> true
      | br::brs1 -> (ln'_branch br i) && (ln'_branches brs1 i)
and (ln'_match_returns :
  FStar_Reflection_Types.match_returns_ascription -> Prims.int -> Prims.bool)
  =
  fun m ->
    fun i ->
      let uu___ = m in
      match uu___ with
      | (b, (ret, as_, eq)) ->
          let b1 = ln'_binder b i in
          let ret1 =
            match ret with
            | FStar_Pervasives.Inl t -> ln' t (i + Prims.int_one)
            | FStar_Pervasives.Inr c -> ln'_comp c (i + Prims.int_one) in
          let as_1 =
            match as_ with
            | FStar_Pervasives_Native.None -> true
            | FStar_Pervasives_Native.Some t -> ln' t (i + Prims.int_one) in
          (b1 && ret1) && as_1
let (ln : FStar_Reflection_Types.term -> Prims.bool) =
  fun t -> ln' t (Prims.of_int (-1))
let (ln_comp : FStar_Reflection_Types.comp -> Prims.bool) =
  fun c -> ln'_comp c (Prims.of_int (-1))
type term_ctxt =
  | Ctxt_hole 
  | Ctxt_app_head of term_ctxt * FStar_Reflection_Data.argv 
  | Ctxt_app_arg of FStar_Reflection_Types.term *
  FStar_Reflection_Data.aqualv * term_ctxt 
let uu___is_Ctxt_hole uu___ =
  match uu___ with | Ctxt_hole _ -> true | _ -> false
let uu___is_Ctxt_app_head uu___ =
  match uu___ with | Ctxt_app_head _ -> true | _ -> false
let uu___is_Ctxt_app_arg uu___ =
  match uu___ with | Ctxt_app_arg _ -> true | _ -> false
let rec (apply_term_ctxt :
  term_ctxt -> FStar_Reflection_Types.term -> FStar_Reflection_Types.term) =
  fun e ->
    fun t ->
      match e with
      | Ctxt_hole -> t
      | Ctxt_app_head (e1, arg) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_App ((apply_term_ctxt e1 t), arg))
      | Ctxt_app_arg (hd, q, e1) ->
          FStar_Reflection_Builtins.pack_ln
            (FStar_Reflection_Data.Tv_App (hd, ((apply_term_ctxt e1 t), q)))
type ('dummyV0, 'dummyV1) constant_typing =
  | CT_Unit 
  | CT_True 
  | CT_False 
let (uu___is_CT_Unit :
  FStar_Reflection_Data.vconst ->
    FStar_Reflection_Types.term -> (unit, unit) constant_typing -> Prims.bool)
  =
  fun uu___ ->
    fun uu___1 ->
      fun projectee ->
        match projectee with | CT_Unit -> true | uu___2 -> false
let (uu___is_CT_True :
  FStar_Reflection_Data.vconst ->
    FStar_Reflection_Types.term -> (unit, unit) constant_typing -> Prims.bool)
  =
  fun uu___ ->
    fun uu___1 ->
      fun projectee ->
        match projectee with | CT_True -> true | uu___2 -> false
let (uu___is_CT_False :
  FStar_Reflection_Data.vconst ->
    FStar_Reflection_Types.term -> (unit, unit) constant_typing -> Prims.bool)
  =
  fun uu___ ->
    fun uu___1 ->
      fun projectee ->
        match projectee with | CT_False -> true | uu___2 -> false
type ('dummyV0, 'dummyV1) univ_eq =
  | UN_Refl of FStar_Reflection_Types.universe 
  | UN_MaxCongL of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe * FStar_Reflection_Types.universe * (
  unit, unit) univ_eq 
  | UN_MaxCongR of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe * FStar_Reflection_Types.universe * (
  unit, unit) univ_eq 
  | UN_MaxComm of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe 
  | UN_MaxLeq of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe * (unit, unit) univ_leq 
and ('dummyV0, 'dummyV1) univ_leq =
  | UNLEQ_Refl of FStar_Reflection_Types.universe 
  | UNLEQ_Succ of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe * (unit, unit) univ_leq 
  | UNLEQ_Max of FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe 
let uu___is_UN_Refl uu___1 uu___ uu___2 =
  match uu___2 with | UN_Refl _ -> true | _ -> false
let uu___is_UN_MaxCongL uu___1 uu___ uu___2 =
  match uu___2 with | UN_MaxCongL _ -> true | _ -> false
let uu___is_UN_MaxCongR uu___1 uu___ uu___2 =
  match uu___2 with | UN_MaxCongR _ -> true | _ -> false
let uu___is_UN_MaxComm uu___1 uu___ uu___2 =
  match uu___2 with | UN_MaxComm _ -> true | _ -> false
let uu___is_UN_MaxLeq uu___1 uu___ uu___2 =
  match uu___2 with | UN_MaxLeq _ -> true | _ -> false
let uu___is_UNLEQ_Refl uu___1 uu___ uu___2 =
  match uu___2 with | UNLEQ_Refl _ -> true | _ -> false
let uu___is_UNLEQ_Succ uu___1 uu___ uu___2 =
  match uu___2 with | UNLEQ_Succ _ -> true | _ -> false
let uu___is_UNLEQ_Max uu___1 uu___ uu___2 =
  match uu___2 with | UNLEQ_Max _ -> true | _ -> false
let (mk_if :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term -> FStar_Reflection_Types.term)
  =
  fun scrutinee ->
    fun then_ ->
      fun else_ ->
        FStar_Reflection_Builtins.pack_ln
          (FStar_Reflection_Data.Tv_Match
             (scrutinee, FStar_Pervasives_Native.None,
               [((FStar_Reflection_Data.Pat_Constant
                    FStar_Reflection_Data.C_True), then_);
               ((FStar_Reflection_Data.Pat_Constant
                   FStar_Reflection_Data.C_False), else_)]))
type comp_typ =
  (FStar_Tactics_Types.tot_or_ghost * FStar_Reflection_Types.typ)
let (close_comp_typ' :
  comp_typ ->
    FStar_Reflection_Data.var ->
      Prims.nat ->
        (FStar_Tactics_Types.tot_or_ghost * FStar_Reflection_Types.term))
  =
  fun c ->
    fun x ->
      fun i ->
        ((FStar_Pervasives_Native.fst c),
          (subst_term (FStar_Pervasives_Native.snd c) [ND (x, i)]))
let (close_comp_typ :
  comp_typ ->
    FStar_Reflection_Data.var ->
      (FStar_Tactics_Types.tot_or_ghost * FStar_Reflection_Types.term))
  = fun c -> fun x -> close_comp_typ' c x Prims.int_zero
let (open_comp_typ' :
  comp_typ ->
    FStar_Reflection_Data.var ->
      Prims.nat ->
        (FStar_Tactics_Types.tot_or_ghost * FStar_Reflection_Types.term))
  =
  fun c ->
    fun x ->
      fun i ->
        ((FStar_Pervasives_Native.fst c),
          (subst_term (FStar_Pervasives_Native.snd c) (open_with_var x i)))
let (open_comp_typ :
  comp_typ ->
    FStar_Reflection_Data.var ->
      (FStar_Tactics_Types.tot_or_ghost * FStar_Reflection_Types.term))
  = fun c -> fun x -> open_comp_typ' c x Prims.int_zero
let (freevars_comp_typ : comp_typ -> FStar_Reflection_Data.var FStar_Set.set)
  = fun c -> freevars (FStar_Pervasives_Native.snd c)
let (mk_comp : comp_typ -> FStar_Reflection_Types.comp) =
  fun c ->
    match FStar_Pervasives_Native.fst c with
    | FStar_Tactics_Types.E_Total -> mk_total (FStar_Pervasives_Native.snd c)
    | FStar_Tactics_Types.E_Ghost -> mk_ghost (FStar_Pervasives_Native.snd c)
let (mk_arrow_ct :
  FStar_Reflection_Types.term ->
    FStar_Reflection_Data.aqualv -> comp_typ -> FStar_Reflection_Types.term)
  =
  fun ty ->
    fun qual ->
      fun c ->
        FStar_Reflection_Builtins.pack_ln
          (FStar_Reflection_Data.Tv_Arrow
             ((binder_of_t_q ty qual), (mk_comp c)))
type relation =
  | R_Eq 
  | R_Sub 
let (uu___is_R_Eq : relation -> Prims.bool) =
  fun projectee -> match projectee with | R_Eq -> true | uu___ -> false
let (uu___is_R_Sub : relation -> Prims.bool) =
  fun projectee -> match projectee with | R_Sub -> true | uu___ -> false
let (is_non_informative_name : FStar_Reflection_Types.name -> Prims.bool) =
  fun l ->
    ((l = FStar_Reflection_Const.unit_lid) ||
       (l = FStar_Reflection_Const.squash_qn))
      || (l = ["FStar"; "Ghost"; "erased"])
let (is_non_informative_fv : FStar_Reflection_Types.fv -> Prims.bool) =
  fun f -> is_non_informative_name (FStar_Reflection_Builtins.inspect_fv f)
type 'dummyV0 non_informative =
  | Non_informative_type of FStar_Reflection_Types.universe 
  | Non_informative_fv of FStar_Reflection_Types.fv 
  | Non_informative_uinst of FStar_Reflection_Types.fv *
  FStar_Reflection_Types.universe Prims.list 
  | Non_informative_app of FStar_Reflection_Types.term *
  FStar_Reflection_Data.argv * unit non_informative 
  | Non_informative_total_arrow of FStar_Reflection_Types.term *
  FStar_Reflection_Data.aqualv * FStar_Reflection_Types.term * unit
  non_informative 
  | Non_informative_ghost_arrow of FStar_Reflection_Types.term *
  FStar_Reflection_Data.aqualv * FStar_Reflection_Types.term 
let uu___is_Non_informative_type uu___ uu___1 =
  match uu___1 with | Non_informative_type _ -> true | _ -> false
let uu___is_Non_informative_fv uu___ uu___1 =
  match uu___1 with | Non_informative_fv _ -> true | _ -> false
let uu___is_Non_informative_uinst uu___ uu___1 =
  match uu___1 with | Non_informative_uinst _ -> true | _ -> false
let uu___is_Non_informative_app uu___ uu___1 =
  match uu___1 with | Non_informative_app _ -> true | _ -> false
let uu___is_Non_informative_total_arrow uu___ uu___1 =
  match uu___1 with | Non_informative_total_arrow _ -> true | _ -> false
let uu___is_Non_informative_ghost_arrow uu___ uu___1 =
  match uu___1 with | Non_informative_ghost_arrow _ -> true | _ -> false
type ('dummyV0, 'dummyV1, 'dummyV2) typing =
  | T_Token of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  comp_typ * unit 
  | T_Var of FStar_Reflection_Types.env * FStar_Reflection_Types.bv 
  | T_FVar of FStar_Reflection_Types.env * FStar_Reflection_Types.fv 
  | T_UInst of FStar_Reflection_Types.env * FStar_Reflection_Types.fv *
  FStar_Reflection_Types.universe Prims.list 
  | T_Const of FStar_Reflection_Types.env * FStar_Reflection_Data.vconst *
  FStar_Reflection_Types.term * (unit, unit) constant_typing 
  | T_Abs of FStar_Reflection_Types.env * FStar_Reflection_Data.var *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term * comp_typ *
  FStar_Reflection_Types.universe * pp_name_t * FStar_Reflection_Data.aqualv
  * FStar_Tactics_Types.tot_or_ghost * (unit, unit, unit) typing * (unit,
  unit, unit) typing 
  | T_App of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Types.binder *
  FStar_Reflection_Types.term * FStar_Tactics_Types.tot_or_ghost * (unit,
  unit, unit) typing * (unit, unit, unit) typing 
  | T_Let of FStar_Reflection_Types.env * FStar_Reflection_Data.var *
  FStar_Reflection_Types.term * FStar_Reflection_Types.typ *
  FStar_Reflection_Types.term * FStar_Reflection_Types.typ *
  FStar_Tactics_Types.tot_or_ghost * pp_name_t * (unit, unit, unit) typing *
  (unit, unit, unit) typing 
  | T_Arrow of FStar_Reflection_Types.env * FStar_Reflection_Data.var *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term *
  FStar_Reflection_Types.universe * FStar_Reflection_Types.universe *
  pp_name_t * FStar_Reflection_Data.aqualv * FStar_Tactics_Types.tot_or_ghost
  * FStar_Tactics_Types.tot_or_ghost * FStar_Tactics_Types.tot_or_ghost *
  (unit, unit, unit) typing * (unit, unit, unit) typing 
  | T_Refine of FStar_Reflection_Types.env * FStar_Reflection_Data.var *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term *
  FStar_Reflection_Types.universe * FStar_Reflection_Types.universe *
  FStar_Tactics_Types.tot_or_ghost * FStar_Tactics_Types.tot_or_ghost *
  (unit, unit, unit) typing * (unit, unit, unit) typing 
  | T_PropIrrelevance of FStar_Reflection_Types.env *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term *
  FStar_Tactics_Types.tot_or_ghost * FStar_Tactics_Types.tot_or_ghost *
  (unit, unit, unit) typing * (unit, unit, unit) typing 
  | T_Sub of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  comp_typ * comp_typ * (unit, unit, unit) typing * (unit, unit, unit, 
  unit) related_comp 
  | T_If of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Types.universe *
  FStar_Reflection_Data.var * FStar_Tactics_Types.tot_or_ghost *
  FStar_Tactics_Types.tot_or_ghost * (unit, unit, unit) typing * (unit, 
  unit, unit) typing * (unit, unit, unit) typing * (unit, unit, unit) typing 
and ('dummyV0, 'dummyV1, 'dummyV2, 'dummyV3) related =
  | Rel_equiv of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * relation * (unit, unit, unit) equiv 
  | Rel_subtyping_token of FStar_Reflection_Types.env *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term * unit 
  | Rel_arrow of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Data.aqualv * comp_typ *
  comp_typ * relation * FStar_Reflection_Data.var * (unit, unit, unit, 
  unit) related * (unit, unit, unit, unit) related_comp 
  | Rel_abs of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Data.aqualv *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term *
  FStar_Reflection_Data.var * (unit, unit, unit, unit) related * (unit, 
  unit, unit, unit) related 
and ('dummyV0, 'dummyV1, 'dummyV2) equiv =
  | EQ_Refl of FStar_Reflection_Types.env * FStar_Reflection_Types.term 
  | EQ_Sym of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * (unit, unit, unit) equiv 
  | EQ_Trans of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Reflection_Types.term * (unit, 
  unit, unit) equiv * (unit, unit, unit) equiv 
  | EQ_Univ of FStar_Reflection_Types.env * FStar_Reflection_Types.universe *
  FStar_Reflection_Types.universe * (unit, unit) univ_eq 
  | EQ_Beta of FStar_Reflection_Types.env * FStar_Reflection_Types.typ *
  FStar_Reflection_Data.aqualv * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term 
  | EQ_Token of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * unit 
  | EQ_Ctxt of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * term_ctxt * (unit, unit, unit) equiv 
and ('dummyV0, 'dummyV1, 'dummyV2, 'dummyV3) related_comp =
  | Relc_typ of FStar_Reflection_Types.env * FStar_Reflection_Types.term *
  FStar_Reflection_Types.term * FStar_Tactics_Types.tot_or_ghost * relation *
  (unit, unit, unit, unit) related 
  | Relc_total_ghost of FStar_Reflection_Types.env *
  FStar_Reflection_Types.term 
  | Relc_ghost_total of FStar_Reflection_Types.env *
  FStar_Reflection_Types.term * unit non_informative 
let uu___is_T_Token uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Token _ -> true | _ -> false
let uu___is_T_Var uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Var _ -> true | _ -> false
let uu___is_T_FVar uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_FVar _ -> true | _ -> false
let uu___is_T_UInst uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_UInst _ -> true | _ -> false
let uu___is_T_Const uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Const _ -> true | _ -> false
let uu___is_T_Abs uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Abs _ -> true | _ -> false
let uu___is_T_App uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_App _ -> true | _ -> false
let uu___is_T_Let uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Let _ -> true | _ -> false
let uu___is_T_Arrow uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Arrow _ -> true | _ -> false
let uu___is_T_Refine uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Refine _ -> true | _ -> false
let uu___is_T_PropIrrelevance uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_PropIrrelevance _ -> true | _ -> false
let uu___is_T_Sub uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_Sub _ -> true | _ -> false
let uu___is_T_If uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | T_If _ -> true | _ -> false
let uu___is_Rel_equiv uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Rel_equiv _ -> true | _ -> false
let uu___is_Rel_subtyping_token uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Rel_subtyping_token _ -> true | _ -> false
let uu___is_Rel_arrow uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Rel_arrow _ -> true | _ -> false
let uu___is_Rel_abs uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Rel_abs _ -> true | _ -> false
let uu___is_EQ_Refl uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Refl _ -> true | _ -> false
let uu___is_EQ_Sym uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Sym _ -> true | _ -> false
let uu___is_EQ_Trans uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Trans _ -> true | _ -> false
let uu___is_EQ_Univ uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Univ _ -> true | _ -> false
let uu___is_EQ_Beta uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Beta _ -> true | _ -> false
let uu___is_EQ_Token uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Token _ -> true | _ -> false
let uu___is_EQ_Ctxt uu___2 uu___1 uu___ uu___3 =
  match uu___3 with | EQ_Ctxt _ -> true | _ -> false
let uu___is_Relc_typ uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Relc_typ _ -> true | _ -> false
let uu___is_Relc_total_ghost uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Relc_total_ghost _ -> true | _ -> false
let uu___is_Relc_ghost_total uu___3 uu___2 uu___1 uu___ uu___4 =
  match uu___4 with | Relc_ghost_total _ -> true | _ -> false
type ('g, 't1, 't2) sub_typing = (unit, unit, unit, unit) related
type ('g, 'c1, 'c2) sub_comp = (unit, unit, unit, unit) related_comp
type ('g, 'e, 't) tot_typing = (unit, unit, unit) typing
type ('g, 'e, 't) ghost_typing = (unit, unit, unit) typing
type bindings =
  (FStar_Reflection_Data.var * FStar_Reflection_Types.term) Prims.list
let rename_bindings :
  'uuuuu .
    ('uuuuu * FStar_Reflection_Types.term) Prims.list ->
      FStar_Reflection_Data.var ->
        FStar_Reflection_Data.var ->
          ('uuuuu * FStar_Reflection_Types.term) Prims.list
  =
  fun bs ->
    fun x ->
      fun y ->
        FStar_List_Tot_Base.map
          (fun uu___ -> match uu___ with | (v, t) -> (v, (rename t x y))) bs
let rec (extend_env_l :
  FStar_Reflection_Types.env -> bindings -> FStar_Reflection_Types.env) =
  fun g ->
    fun bs ->
      match bs with
      | [] -> g
      | (x, t)::bs1 -> extend_env (extend_env_l g bs1) x t
let (subtyping_token_renaming :
  FStar_Reflection_Types.env ->
    bindings ->
      bindings ->
        FStar_Reflection_Data.var ->
          FStar_Reflection_Data.var ->
            FStar_Reflection_Types.term ->
              FStar_Reflection_Types.term ->
                FStar_Reflection_Types.term ->
                  (unit, unit, unit) FStar_Tactics_Builtins.subtyping_token
                    ->
                    (unit, unit, unit) FStar_Tactics_Builtins.subtyping_token)
  =
  fun g ->
    fun bs0 ->
      fun bs1 ->
        fun x ->
          fun y -> fun t -> fun t0 -> fun t1 -> fun d -> Prims.magic ()
let (subtyping_token_weakening :
  FStar_Reflection_Types.env ->
    bindings ->
      bindings ->
        FStar_Reflection_Data.var ->
          FStar_Reflection_Types.term ->
            FStar_Reflection_Types.term ->
              FStar_Reflection_Types.term ->
                (unit, unit, unit) FStar_Tactics_Builtins.subtyping_token ->
                  (unit, unit, unit) FStar_Tactics_Builtins.subtyping_token)
  =
  fun g ->
    fun bs0 ->
      fun bs1 ->
        fun x -> fun t -> fun t0 -> fun t1 -> fun d -> Prims.magic ()
let (simplify_umax :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.universe ->
        (unit, unit, unit) typing -> (unit, unit, unit) typing)
  =
  fun g ->
    fun t ->
      fun u ->
        fun d ->
          let ue = UN_MaxLeq (u, u, (UNLEQ_Refl u)) in
          T_Sub
            (g, t, (FStar_Tactics_Types.E_Total, (tm_type (u_max u u))),
              (FStar_Tactics_Types.E_Total, (tm_type u)), d,
              (Relc_typ
                 (g, (tm_type (u_max u u)), (tm_type u),
                   FStar_Tactics_Types.E_Total, R_Sub,
                   (Rel_equiv
                      (g, (tm_type (u_max u u)), (tm_type u), R_Sub,
                        (EQ_Univ (g, (u_max u u), u, ue)))))))
let (equiv_abs :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Types.typ ->
          FStar_Reflection_Data.aqualv ->
            FStar_Reflection_Data.var ->
              (unit, unit, unit) equiv -> (unit, unit, unit) equiv)
  =
  fun g ->
    fun e1 ->
      fun e2 ->
        fun uu___ -> fun uu___1 -> fun uu___2 -> fun uu___3 -> Prims.admit ()
let (equiv_arrow :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Types.typ ->
          FStar_Reflection_Data.aqualv ->
            FStar_Reflection_Data.var ->
              (unit, unit, unit) equiv -> (unit, unit, unit) equiv)
  =
  fun g ->
    fun e1 ->
      fun e2 ->
        fun uu___ -> fun uu___1 -> fun uu___2 -> fun uu___3 -> Prims.admit ()
let (equiv_abs_close :
  FStar_Reflection_Types.env ->
    FStar_Reflection_Types.term ->
      FStar_Reflection_Types.term ->
        FStar_Reflection_Types.typ ->
          FStar_Reflection_Data.aqualv ->
            FStar_Reflection_Data.var ->
              (unit, unit, unit) equiv -> (unit, unit, unit) equiv)
  =
  fun g ->
    fun e1 ->
      fun e2 ->
        fun ty ->
          fun q ->
            fun x ->
              fun eq ->
                let eq1 = eq in
                equiv_abs g (subst_term e1 [ND (x, Prims.int_zero)])
                  (subst_term e2 [ND (x, Prims.int_zero)]) ty q x eq1
type 'g fstar_env_fvs = unit
type fstar_env = FStar_Reflection_Types.env
type fstar_top_env = fstar_env
type dsl_tac_t =
  fstar_top_env ->
    ((FStar_Reflection_Types.term * FStar_Reflection_Types.typ), unit)
      FStar_Tactics_Effect.tac_repr