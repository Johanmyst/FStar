open Prims
let add_fuel x tl =
  let uu____16 = FStar_Options.unthrottle_inductives () in
  match uu____16 with | true  -> tl | uu____18 -> x :: tl
let withenv c uu____39 = match uu____39 with | (a,b) -> (a, b, c)
let vargs args =
  FStar_List.filter
    (fun uu___108_74  ->
       match uu___108_74 with
       | (FStar_Util.Inl uu____79,uu____80) -> false
       | uu____83 -> true) args
let subst_lcomp_opt s l =
  match l with
  | Some (FStar_Util.Inl l) ->
      let uu____114 =
        let uu____117 =
          let uu____118 =
            let uu____121 = l.FStar_Syntax_Syntax.comp () in
            FStar_Syntax_Subst.subst_comp s uu____121 in
          FStar_All.pipe_left FStar_Syntax_Util.lcomp_of_comp uu____118 in
        FStar_Util.Inl uu____117 in
      Some uu____114
  | uu____126 -> l
let escape: Prims.string -> Prims.string =
  fun s  -> FStar_Util.replace_char s '\'' '_'
let mk_term_projector_name:
  FStar_Ident.lident -> FStar_Syntax_Syntax.bv -> Prims.string =
  fun lid  ->
    fun a  ->
      let a =
        let uu___132_140 = a in
        let uu____141 =
          FStar_Syntax_Util.unmangle_field_name a.FStar_Syntax_Syntax.ppname in
        {
          FStar_Syntax_Syntax.ppname = uu____141;
          FStar_Syntax_Syntax.index =
            (uu___132_140.FStar_Syntax_Syntax.index);
          FStar_Syntax_Syntax.sort = (uu___132_140.FStar_Syntax_Syntax.sort)
        } in
      let uu____142 =
        FStar_Util.format2 "%s_%s" lid.FStar_Ident.str
          (a.FStar_Syntax_Syntax.ppname).FStar_Ident.idText in
      FStar_All.pipe_left escape uu____142
let primitive_projector_by_pos:
  FStar_TypeChecker_Env.env ->
    FStar_Ident.lident -> Prims.int -> Prims.string
  =
  fun env  ->
    fun lid  ->
      fun i  ->
        let fail uu____155 =
          let uu____156 =
            FStar_Util.format2
              "Projector %s on data constructor %s not found"
              (Prims.string_of_int i) lid.FStar_Ident.str in
          failwith uu____156 in
        let uu____157 = FStar_TypeChecker_Env.lookup_datacon env lid in
        match uu____157 with
        | (uu____160,t) ->
            let uu____162 =
              let uu____163 = FStar_Syntax_Subst.compress t in
              uu____163.FStar_Syntax_Syntax.n in
            (match uu____162 with
             | FStar_Syntax_Syntax.Tm_arrow (bs,c) ->
                 let uu____178 = FStar_Syntax_Subst.open_comp bs c in
                 (match uu____178 with
                  | (binders,uu____182) ->
                      (match (i < (Prims.parse_int "0")) ||
                               (i >= (FStar_List.length binders))
                       with
                       | true  -> fail ()
                       | uu____187 ->
                           let b = FStar_List.nth binders i in
                           mk_term_projector_name lid (Prims.fst b)))
             | uu____193 -> fail ())
let mk_term_projector_name_by_pos:
  FStar_Ident.lident -> Prims.int -> Prims.string =
  fun lid  ->
    fun i  ->
      let uu____200 =
        FStar_Util.format2 "%s_%s" lid.FStar_Ident.str
          (Prims.string_of_int i) in
      FStar_All.pipe_left escape uu____200
let mk_term_projector:
  FStar_Ident.lident -> FStar_Syntax_Syntax.bv -> FStar_SMTEncoding_Term.term
  =
  fun lid  ->
    fun a  ->
      let uu____207 =
        let uu____210 = mk_term_projector_name lid a in
        (uu____210,
          (FStar_SMTEncoding_Term.Arrow
             (FStar_SMTEncoding_Term.Term_sort,
               FStar_SMTEncoding_Term.Term_sort))) in
      FStar_SMTEncoding_Util.mkFreeV uu____207
let mk_term_projector_by_pos:
  FStar_Ident.lident -> Prims.int -> FStar_SMTEncoding_Term.term =
  fun lid  ->
    fun i  ->
      let uu____217 =
        let uu____220 = mk_term_projector_name_by_pos lid i in
        (uu____220,
          (FStar_SMTEncoding_Term.Arrow
             (FStar_SMTEncoding_Term.Term_sort,
               FStar_SMTEncoding_Term.Term_sort))) in
      FStar_SMTEncoding_Util.mkFreeV uu____217
let mk_data_tester env l x =
  FStar_SMTEncoding_Term.mk_tester (escape l.FStar_Ident.str) x
type varops_t =
  {
  push: Prims.unit -> Prims.unit;
  pop: Prims.unit -> Prims.unit;
  mark: Prims.unit -> Prims.unit;
  reset_mark: Prims.unit -> Prims.unit;
  commit_mark: Prims.unit -> Prims.unit;
  new_var: FStar_Ident.ident -> Prims.int -> Prims.string;
  new_fvar: FStar_Ident.lident -> Prims.string;
  fresh: Prims.string -> Prims.string;
  string_const: Prims.string -> FStar_SMTEncoding_Term.term;
  next_id: Prims.unit -> Prims.int;
  mk_unique: Prims.string -> Prims.string;}
let varops: varops_t =
  let initial_ctr = Prims.parse_int "100" in
  let ctr = FStar_Util.mk_ref initial_ctr in
  let new_scope uu____410 =
    let uu____411 = FStar_Util.smap_create (Prims.parse_int "100") in
    let uu____413 = FStar_Util.smap_create (Prims.parse_int "100") in
    (uu____411, uu____413) in
  let scopes =
    let uu____424 = let uu____430 = new_scope () in [uu____430] in
    FStar_Util.mk_ref uu____424 in
  let mk_unique y =
    let y = escape y in
    let y =
      let uu____455 =
        let uu____457 = FStar_ST.read scopes in
        FStar_Util.find_map uu____457
          (fun uu____474  ->
             match uu____474 with
             | (names,uu____481) -> FStar_Util.smap_try_find names y) in
      match uu____455 with
      | None  -> y
      | Some uu____486 ->
          (FStar_Util.incr ctr;
           (let uu____491 =
              let uu____492 =
                let uu____493 = FStar_ST.read ctr in
                Prims.string_of_int uu____493 in
              Prims.strcat "__" uu____492 in
            Prims.strcat y uu____491)) in
    let top_scope =
      let uu____498 =
        let uu____503 = FStar_ST.read scopes in FStar_List.hd uu____503 in
      FStar_All.pipe_left Prims.fst uu____498 in
    FStar_Util.smap_add top_scope y true; y in
  let new_var pp rn =
    FStar_All.pipe_left mk_unique
      (Prims.strcat pp.FStar_Ident.idText
         (Prims.strcat "__" (Prims.string_of_int rn))) in
  let new_fvar lid = mk_unique lid.FStar_Ident.str in
  let next_id uu____542 = FStar_Util.incr ctr; FStar_ST.read ctr in
  let fresh pfx =
    let uu____553 =
      let uu____554 = next_id () in
      FStar_All.pipe_left Prims.string_of_int uu____554 in
    FStar_Util.format2 "%s_%s" pfx uu____553 in
  let string_const s =
    let uu____559 =
      let uu____561 = FStar_ST.read scopes in
      FStar_Util.find_map uu____561
        (fun uu____578  ->
           match uu____578 with
           | (uu____584,strings) -> FStar_Util.smap_try_find strings s) in
    match uu____559 with
    | Some f -> f
    | None  ->
        let id = next_id () in
        let f =
          let uu____593 = FStar_SMTEncoding_Util.mk_String_const id in
          FStar_All.pipe_left FStar_SMTEncoding_Term.boxString uu____593 in
        let top_scope =
          let uu____596 =
            let uu____601 = FStar_ST.read scopes in FStar_List.hd uu____601 in
          FStar_All.pipe_left Prims.snd uu____596 in
        (FStar_Util.smap_add top_scope s f; f) in
  let push uu____629 =
    let uu____630 =
      let uu____636 = new_scope () in
      let uu____641 = FStar_ST.read scopes in uu____636 :: uu____641 in
    FStar_ST.write scopes uu____630 in
  let pop uu____668 =
    let uu____669 =
      let uu____675 = FStar_ST.read scopes in FStar_List.tl uu____675 in
    FStar_ST.write scopes uu____669 in
  let mark uu____702 = push () in
  let reset_mark uu____706 = pop () in
  let commit_mark uu____710 =
    let uu____711 = FStar_ST.read scopes in
    match uu____711 with
    | (hd1,hd2)::(next1,next2)::tl ->
        (FStar_Util.smap_fold hd1
           (fun key  ->
              fun value  -> fun v  -> FStar_Util.smap_add next1 key value) ();
         FStar_Util.smap_fold hd2
           (fun key  ->
              fun value  -> fun v  -> FStar_Util.smap_add next2 key value) ();
         FStar_ST.write scopes ((next1, next2) :: tl))
    | uu____771 -> failwith "Impossible" in
  {
    push;
    pop;
    mark;
    reset_mark;
    commit_mark;
    new_var;
    new_fvar;
    fresh;
    string_const;
    next_id;
    mk_unique
  }
let unmangle: FStar_Syntax_Syntax.bv -> FStar_Syntax_Syntax.bv =
  fun x  ->
    let uu___133_780 = x in
    let uu____781 =
      FStar_Syntax_Util.unmangle_field_name x.FStar_Syntax_Syntax.ppname in
    {
      FStar_Syntax_Syntax.ppname = uu____781;
      FStar_Syntax_Syntax.index = (uu___133_780.FStar_Syntax_Syntax.index);
      FStar_Syntax_Syntax.sort = (uu___133_780.FStar_Syntax_Syntax.sort)
    }
type binding =
  | Binding_var of (FStar_Syntax_Syntax.bv* FStar_SMTEncoding_Term.term)
  | Binding_fvar of (FStar_Ident.lident* Prims.string*
  FStar_SMTEncoding_Term.term Prims.option* FStar_SMTEncoding_Term.term
  Prims.option)
let uu___is_Binding_var: binding -> Prims.bool =
  fun projectee  ->
    match projectee with | Binding_var _0 -> true | uu____802 -> false
let __proj__Binding_var__item___0:
  binding -> (FStar_Syntax_Syntax.bv* FStar_SMTEncoding_Term.term) =
  fun projectee  -> match projectee with | Binding_var _0 -> _0
let uu___is_Binding_fvar: binding -> Prims.bool =
  fun projectee  ->
    match projectee with | Binding_fvar _0 -> true | uu____826 -> false
let __proj__Binding_fvar__item___0:
  binding ->
    (FStar_Ident.lident* Prims.string* FStar_SMTEncoding_Term.term
      Prims.option* FStar_SMTEncoding_Term.term Prims.option)
  = fun projectee  -> match projectee with | Binding_fvar _0 -> _0
let binder_of_eithervar v = (v, None)
type env_t =
  {
  bindings: binding Prims.list;
  depth: Prims.int;
  tcenv: FStar_TypeChecker_Env.env;
  warn: Prims.bool;
  cache:
    (Prims.string* FStar_SMTEncoding_Term.sort Prims.list*
      FStar_SMTEncoding_Term.decl Prims.list) FStar_Util.smap;
  nolabels: Prims.bool;
  use_zfuel_name: Prims.bool;
  encode_non_total_function_typ: Prims.bool;}
let print_env: env_t -> Prims.string =
  fun e  ->
    let uu____945 =
      FStar_All.pipe_right e.bindings
        (FStar_List.map
           (fun uu___109_949  ->
              match uu___109_949 with
              | Binding_var (x,uu____951) ->
                  FStar_Syntax_Print.bv_to_string x
              | Binding_fvar (l,uu____953,uu____954,uu____955) ->
                  FStar_Syntax_Print.lid_to_string l)) in
    FStar_All.pipe_right uu____945 (FStar_String.concat ", ")
let lookup_binding env f = FStar_Util.find_map env.bindings f
let caption_t: env_t -> FStar_Syntax_Syntax.term -> Prims.string Prims.option
  =
  fun env  ->
    fun t  ->
      let uu____988 = FStar_TypeChecker_Env.debug env.tcenv FStar_Options.Low in
      match uu____988 with
      | true  ->
          let uu____990 = FStar_Syntax_Print.term_to_string t in
          Some uu____990
      | uu____991 -> None
let fresh_fvar:
  Prims.string ->
    FStar_SMTEncoding_Term.sort ->
      (Prims.string* FStar_SMTEncoding_Term.term)
  =
  fun x  ->
    fun s  ->
      let xsym = varops.fresh x in
      let uu____1001 = FStar_SMTEncoding_Util.mkFreeV (xsym, s) in
      (xsym, uu____1001)
let gen_term_var:
  env_t ->
    FStar_Syntax_Syntax.bv ->
      (Prims.string* FStar_SMTEncoding_Term.term* env_t)
  =
  fun env  ->
    fun x  ->
      let ysym = Prims.strcat "@x" (Prims.string_of_int env.depth) in
      let y =
        FStar_SMTEncoding_Util.mkFreeV
          (ysym, FStar_SMTEncoding_Term.Term_sort) in
      (ysym, y,
        (let uu___134_1013 = env in
         {
           bindings = ((Binding_var (x, y)) :: (env.bindings));
           depth = (env.depth + (Prims.parse_int "1"));
           tcenv = (uu___134_1013.tcenv);
           warn = (uu___134_1013.warn);
           cache = (uu___134_1013.cache);
           nolabels = (uu___134_1013.nolabels);
           use_zfuel_name = (uu___134_1013.use_zfuel_name);
           encode_non_total_function_typ =
             (uu___134_1013.encode_non_total_function_typ)
         }))
let new_term_constant:
  env_t ->
    FStar_Syntax_Syntax.bv ->
      (Prims.string* FStar_SMTEncoding_Term.term* env_t)
  =
  fun env  ->
    fun x  ->
      let ysym =
        varops.new_var x.FStar_Syntax_Syntax.ppname
          x.FStar_Syntax_Syntax.index in
      let y = FStar_SMTEncoding_Util.mkApp (ysym, []) in
      (ysym, y,
        (let uu___135_1026 = env in
         {
           bindings = ((Binding_var (x, y)) :: (env.bindings));
           depth = (uu___135_1026.depth);
           tcenv = (uu___135_1026.tcenv);
           warn = (uu___135_1026.warn);
           cache = (uu___135_1026.cache);
           nolabels = (uu___135_1026.nolabels);
           use_zfuel_name = (uu___135_1026.use_zfuel_name);
           encode_non_total_function_typ =
             (uu___135_1026.encode_non_total_function_typ)
         }))
let new_term_constant_from_string:
  env_t ->
    FStar_Syntax_Syntax.bv ->
      Prims.string -> (Prims.string* FStar_SMTEncoding_Term.term* env_t)
  =
  fun env  ->
    fun x  ->
      fun str  ->
        let ysym = varops.mk_unique str in
        let y = FStar_SMTEncoding_Util.mkApp (ysym, []) in
        (ysym, y,
          (let uu___136_1042 = env in
           {
             bindings = ((Binding_var (x, y)) :: (env.bindings));
             depth = (uu___136_1042.depth);
             tcenv = (uu___136_1042.tcenv);
             warn = (uu___136_1042.warn);
             cache = (uu___136_1042.cache);
             nolabels = (uu___136_1042.nolabels);
             use_zfuel_name = (uu___136_1042.use_zfuel_name);
             encode_non_total_function_typ =
               (uu___136_1042.encode_non_total_function_typ)
           }))
let push_term_var:
  env_t -> FStar_Syntax_Syntax.bv -> FStar_SMTEncoding_Term.term -> env_t =
  fun env  ->
    fun x  ->
      fun t  ->
        let uu___137_1052 = env in
        {
          bindings = ((Binding_var (x, t)) :: (env.bindings));
          depth = (uu___137_1052.depth);
          tcenv = (uu___137_1052.tcenv);
          warn = (uu___137_1052.warn);
          cache = (uu___137_1052.cache);
          nolabels = (uu___137_1052.nolabels);
          use_zfuel_name = (uu___137_1052.use_zfuel_name);
          encode_non_total_function_typ =
            (uu___137_1052.encode_non_total_function_typ)
        }
let lookup_term_var:
  env_t -> FStar_Syntax_Syntax.bv -> FStar_SMTEncoding_Term.term =
  fun env  ->
    fun a  ->
      let aux a' =
        lookup_binding env
          (fun uu___110_1068  ->
             match uu___110_1068 with
             | Binding_var (b,t) when FStar_Syntax_Syntax.bv_eq b a' ->
                 Some (b, t)
             | uu____1076 -> None) in
      let uu____1079 = aux a in
      match uu____1079 with
      | None  ->
          let a2 = unmangle a in
          let uu____1086 = aux a2 in
          (match uu____1086 with
           | None  ->
               let uu____1092 =
                 let uu____1093 = FStar_Syntax_Print.bv_to_string a2 in
                 let uu____1094 = print_env env in
                 FStar_Util.format2
                   "Bound term variable not found (after unmangling): %s in environment: %s"
                   uu____1093 uu____1094 in
               failwith uu____1092
           | Some (b,t) -> t)
      | Some (b,t) -> t
let new_term_constant_and_tok_from_lid:
  env_t -> FStar_Ident.lident -> (Prims.string* Prims.string* env_t) =
  fun env  ->
    fun x  ->
      let fname = varops.new_fvar x in
      let ftok = Prims.strcat fname "@tok" in
      let uu____1114 =
        let uu___138_1115 = env in
        let uu____1116 =
          let uu____1118 =
            let uu____1119 =
              let uu____1126 =
                let uu____1128 = FStar_SMTEncoding_Util.mkApp (ftok, []) in
                FStar_All.pipe_left (fun _0_29  -> Some _0_29) uu____1128 in
              (x, fname, uu____1126, None) in
            Binding_fvar uu____1119 in
          uu____1118 :: (env.bindings) in
        {
          bindings = uu____1116;
          depth = (uu___138_1115.depth);
          tcenv = (uu___138_1115.tcenv);
          warn = (uu___138_1115.warn);
          cache = (uu___138_1115.cache);
          nolabels = (uu___138_1115.nolabels);
          use_zfuel_name = (uu___138_1115.use_zfuel_name);
          encode_non_total_function_typ =
            (uu___138_1115.encode_non_total_function_typ)
        } in
      (fname, ftok, uu____1114)
let try_lookup_lid:
  env_t ->
    FStar_Ident.lident ->
      (Prims.string* FStar_SMTEncoding_Term.term Prims.option*
        FStar_SMTEncoding_Term.term Prims.option) Prims.option
  =
  fun env  ->
    fun a  ->
      lookup_binding env
        (fun uu___111_1150  ->
           match uu___111_1150 with
           | Binding_fvar (b,t1,t2,t3) when FStar_Ident.lid_equals b a ->
               Some (t1, t2, t3)
           | uu____1172 -> None)
let contains_name: env_t -> Prims.string -> Prims.bool =
  fun env  ->
    fun s  ->
      let uu____1184 =
        lookup_binding env
          (fun uu___112_1186  ->
             match uu___112_1186 with
             | Binding_fvar (b,t1,t2,t3) when b.FStar_Ident.str = s ->
                 Some ()
             | uu____1196 -> None) in
      FStar_All.pipe_right uu____1184 FStar_Option.isSome
let lookup_lid:
  env_t ->
    FStar_Ident.lident ->
      (Prims.string* FStar_SMTEncoding_Term.term Prims.option*
        FStar_SMTEncoding_Term.term Prims.option)
  =
  fun env  ->
    fun a  ->
      let uu____1209 = try_lookup_lid env a in
      match uu____1209 with
      | None  ->
          let uu____1226 =
            let uu____1227 = FStar_Syntax_Print.lid_to_string a in
            FStar_Util.format1 "Name not found: %s" uu____1227 in
          failwith uu____1226
      | Some s -> s
let push_free_var:
  env_t ->
    FStar_Ident.lident ->
      Prims.string -> FStar_SMTEncoding_Term.term Prims.option -> env_t
  =
  fun env  ->
    fun x  ->
      fun fname  ->
        fun ftok  ->
          let uu___139_1258 = env in
          {
            bindings = ((Binding_fvar (x, fname, ftok, None)) ::
              (env.bindings));
            depth = (uu___139_1258.depth);
            tcenv = (uu___139_1258.tcenv);
            warn = (uu___139_1258.warn);
            cache = (uu___139_1258.cache);
            nolabels = (uu___139_1258.nolabels);
            use_zfuel_name = (uu___139_1258.use_zfuel_name);
            encode_non_total_function_typ =
              (uu___139_1258.encode_non_total_function_typ)
          }
let push_zfuel_name: env_t -> FStar_Ident.lident -> Prims.string -> env_t =
  fun env  ->
    fun x  ->
      fun f  ->
        let uu____1270 = lookup_lid env x in
        match uu____1270 with
        | (t1,t2,uu____1278) ->
            let t3 =
              let uu____1284 =
                let uu____1288 =
                  let uu____1290 = FStar_SMTEncoding_Util.mkApp ("ZFuel", []) in
                  [uu____1290] in
                (f, uu____1288) in
              FStar_SMTEncoding_Util.mkApp uu____1284 in
            let uu___140_1293 = env in
            {
              bindings = ((Binding_fvar (x, t1, t2, (Some t3))) ::
                (env.bindings));
              depth = (uu___140_1293.depth);
              tcenv = (uu___140_1293.tcenv);
              warn = (uu___140_1293.warn);
              cache = (uu___140_1293.cache);
              nolabels = (uu___140_1293.nolabels);
              use_zfuel_name = (uu___140_1293.use_zfuel_name);
              encode_non_total_function_typ =
                (uu___140_1293.encode_non_total_function_typ)
            }
let try_lookup_free_var:
  env_t -> FStar_Ident.lident -> FStar_SMTEncoding_Term.term Prims.option =
  fun env  ->
    fun l  ->
      let uu____1303 = try_lookup_lid env l in
      match uu____1303 with
      | None  -> None
      | Some (name,sym,zf_opt) ->
          (match zf_opt with
           | Some f when env.use_zfuel_name -> Some f
           | uu____1330 ->
               (match sym with
                | Some t ->
                    (match t.FStar_SMTEncoding_Term.tm with
                     | FStar_SMTEncoding_Term.App (uu____1335,fuel::[]) ->
                         let uu____1338 =
                           let uu____1339 =
                             let uu____1340 =
                               FStar_SMTEncoding_Term.fv_of_term fuel in
                             FStar_All.pipe_right uu____1340 Prims.fst in
                           FStar_Util.starts_with uu____1339 "fuel" in
                         (match uu____1338 with
                          | true  ->
                              let uu____1342 =
                                let uu____1343 =
                                  FStar_SMTEncoding_Util.mkFreeV
                                    (name, FStar_SMTEncoding_Term.Term_sort) in
                                FStar_SMTEncoding_Term.mk_ApplyTF uu____1343
                                  fuel in
                              FStar_All.pipe_left (fun _0_30  -> Some _0_30)
                                uu____1342
                          | uu____1345 -> Some t)
                     | uu____1346 -> Some t)
                | uu____1347 -> None))
let lookup_free_var env a =
  let uu____1365 = try_lookup_free_var env a.FStar_Syntax_Syntax.v in
  match uu____1365 with
  | Some t -> t
  | None  ->
      let uu____1368 =
        let uu____1369 =
          FStar_Syntax_Print.lid_to_string a.FStar_Syntax_Syntax.v in
        FStar_Util.format1 "Name not found: %s" uu____1369 in
      failwith uu____1368
let lookup_free_var_name env a =
  let uu____1386 = lookup_lid env a.FStar_Syntax_Syntax.v in
  match uu____1386 with | (x,uu____1393,uu____1394) -> x
let lookup_free_var_sym env a =
  let uu____1418 = lookup_lid env a.FStar_Syntax_Syntax.v in
  match uu____1418 with
  | (name,sym,zf_opt) ->
      (match zf_opt with
       | Some
           { FStar_SMTEncoding_Term.tm = FStar_SMTEncoding_Term.App (g,zf);
             FStar_SMTEncoding_Term.freevars = uu____1439;
             FStar_SMTEncoding_Term.rng = uu____1440;_}
           when env.use_zfuel_name -> (g, zf)
       | uu____1448 ->
           (match sym with
            | None  -> ((FStar_SMTEncoding_Term.Var name), [])
            | Some sym ->
                (match sym.FStar_SMTEncoding_Term.tm with
                 | FStar_SMTEncoding_Term.App (g,fuel::[]) -> (g, [fuel])
                 | uu____1462 -> ((FStar_SMTEncoding_Term.Var name), []))))
let tok_of_name:
  env_t -> Prims.string -> FStar_SMTEncoding_Term.term Prims.option =
  fun env  ->
    fun nm  ->
      FStar_Util.find_map env.bindings
        (fun uu___113_1471  ->
           match uu___113_1471 with
           | Binding_fvar (uu____1473,nm',tok,uu____1476) when nm = nm' ->
               tok
           | uu____1481 -> None)
let mkForall_fuel' n uu____1498 =
  match uu____1498 with
  | (pats,vars,body) ->
      let fallback uu____1514 =
        FStar_SMTEncoding_Util.mkForall (pats, vars, body) in
      let uu____1517 = FStar_Options.unthrottle_inductives () in
      (match uu____1517 with
       | true  -> fallback ()
       | uu____1518 ->
           let uu____1519 = fresh_fvar "f" FStar_SMTEncoding_Term.Fuel_sort in
           (match uu____1519 with
            | (fsym,fterm) ->
                let add_fuel tms =
                  FStar_All.pipe_right tms
                    (FStar_List.map
                       (fun p  ->
                          match p.FStar_SMTEncoding_Term.tm with
                          | FStar_SMTEncoding_Term.App
                              (FStar_SMTEncoding_Term.Var "HasType",args) ->
                              FStar_SMTEncoding_Util.mkApp
                                ("HasTypeFuel", (fterm :: args))
                          | uu____1538 -> p)) in
                let pats = FStar_List.map add_fuel pats in
                let body =
                  match body.FStar_SMTEncoding_Term.tm with
                  | FStar_SMTEncoding_Term.App
                      (FStar_SMTEncoding_Term.Imp ,guard::body'::[]) ->
                      let guard =
                        match guard.FStar_SMTEncoding_Term.tm with
                        | FStar_SMTEncoding_Term.App
                            (FStar_SMTEncoding_Term.And ,guards) ->
                            let uu____1552 = add_fuel guards in
                            FStar_SMTEncoding_Util.mk_and_l uu____1552
                        | uu____1554 ->
                            let uu____1555 = add_fuel [guard] in
                            FStar_All.pipe_right uu____1555 FStar_List.hd in
                      FStar_SMTEncoding_Util.mkImp (guard, body')
                  | uu____1558 -> body in
                let vars = (fsym, FStar_SMTEncoding_Term.Fuel_sort) :: vars in
                FStar_SMTEncoding_Util.mkForall (pats, vars, body)))
let mkForall_fuel:
  (FStar_SMTEncoding_Term.pat Prims.list Prims.list*
    FStar_SMTEncoding_Term.fvs* FStar_SMTEncoding_Term.term) ->
    FStar_SMTEncoding_Term.term
  = mkForall_fuel' (Prims.parse_int "1")
let head_normal: env_t -> FStar_Syntax_Syntax.term -> Prims.bool =
  fun env  ->
    fun t  ->
      let t = FStar_Syntax_Util.unmeta t in
      match t.FStar_Syntax_Syntax.n with
      | FStar_Syntax_Syntax.Tm_arrow _
        |FStar_Syntax_Syntax.Tm_refine _
         |FStar_Syntax_Syntax.Tm_bvar _
          |FStar_Syntax_Syntax.Tm_uvar _
           |FStar_Syntax_Syntax.Tm_abs _|FStar_Syntax_Syntax.Tm_constant _
          -> true
      | FStar_Syntax_Syntax.Tm_fvar fv|FStar_Syntax_Syntax.Tm_app
        ({ FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_fvar fv;
           FStar_Syntax_Syntax.tk = _; FStar_Syntax_Syntax.pos = _;
           FStar_Syntax_Syntax.vars = _;_},_)
          ->
          let uu____1602 =
            FStar_TypeChecker_Env.lookup_definition
              [FStar_TypeChecker_Env.Eager_unfolding_only] env.tcenv
              (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          FStar_All.pipe_right uu____1602 FStar_Option.isNone
      | uu____1615 -> false
let head_redex: env_t -> FStar_Syntax_Syntax.term -> Prims.bool =
  fun env  ->
    fun t  ->
      let uu____1622 =
        let uu____1623 = FStar_Syntax_Util.un_uinst t in
        uu____1623.FStar_Syntax_Syntax.n in
      match uu____1622 with
      | FStar_Syntax_Syntax.Tm_abs
          (uu____1626,uu____1627,Some (FStar_Util.Inr (l,flags))) ->
          ((FStar_Ident.lid_equals l FStar_Syntax_Const.effect_Tot_lid) ||
             (FStar_Ident.lid_equals l FStar_Syntax_Const.effect_GTot_lid))
            ||
            (FStar_List.existsb
               (fun uu___114_1656  ->
                  match uu___114_1656 with
                  | FStar_Syntax_Syntax.TOTAL  -> true
                  | uu____1657 -> false) flags)
      | FStar_Syntax_Syntax.Tm_abs
          (uu____1658,uu____1659,Some (FStar_Util.Inl lc)) ->
          FStar_Syntax_Util.is_tot_or_gtot_lcomp lc
      | FStar_Syntax_Syntax.Tm_fvar fv ->
          let uu____1686 =
            FStar_TypeChecker_Env.lookup_definition
              [FStar_TypeChecker_Env.Eager_unfolding_only] env.tcenv
              (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          FStar_All.pipe_right uu____1686 FStar_Option.isSome
      | uu____1699 -> false
let whnf: env_t -> FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term =
  fun env  ->
    fun t  ->
      let uu____1706 = head_normal env t in
      match uu____1706 with
      | true  -> t
      | uu____1707 ->
          FStar_TypeChecker_Normalize.normalize
            [FStar_TypeChecker_Normalize.Beta;
            FStar_TypeChecker_Normalize.WHNF;
            FStar_TypeChecker_Normalize.Exclude
              FStar_TypeChecker_Normalize.Zeta;
            FStar_TypeChecker_Normalize.Eager_unfolding;
            FStar_TypeChecker_Normalize.EraseUniverses] env.tcenv t
let norm: env_t -> FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term =
  fun env  ->
    fun t  ->
      FStar_TypeChecker_Normalize.normalize
        [FStar_TypeChecker_Normalize.Beta;
        FStar_TypeChecker_Normalize.Exclude FStar_TypeChecker_Normalize.Zeta;
        FStar_TypeChecker_Normalize.Eager_unfolding;
        FStar_TypeChecker_Normalize.EraseUniverses] env.tcenv t
let trivial_post: FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term =
  fun t  ->
    let uu____1717 =
      let uu____1721 = FStar_Syntax_Syntax.null_binder t in [uu____1721] in
    let uu____1722 =
      FStar_Syntax_Syntax.fvar FStar_Syntax_Const.true_lid
        FStar_Syntax_Syntax.Delta_constant None in
    FStar_Syntax_Util.abs uu____1717 uu____1722 None
let mk_Apply:
  FStar_SMTEncoding_Term.term ->
    (Prims.string* FStar_SMTEncoding_Term.sort) Prims.list ->
      FStar_SMTEncoding_Term.term
  =
  fun e  ->
    fun vars  ->
      FStar_All.pipe_right vars
        (FStar_List.fold_left
           (fun out  ->
              fun var  ->
                match Prims.snd var with
                | FStar_SMTEncoding_Term.Fuel_sort  ->
                    let uu____1749 = FStar_SMTEncoding_Util.mkFreeV var in
                    FStar_SMTEncoding_Term.mk_ApplyTF out uu____1749
                | s ->
                    let uu____1752 = FStar_SMTEncoding_Util.mkFreeV var in
                    FStar_SMTEncoding_Util.mk_ApplyTT out uu____1752) e)
let mk_Apply_args:
  FStar_SMTEncoding_Term.term ->
    FStar_SMTEncoding_Term.term Prims.list -> FStar_SMTEncoding_Term.term
  =
  fun e  ->
    fun args  ->
      FStar_All.pipe_right args
        (FStar_List.fold_left FStar_SMTEncoding_Util.mk_ApplyTT e)
let is_app: FStar_SMTEncoding_Term.op -> Prims.bool =
  fun uu___115_1764  ->
    match uu___115_1764 with
    | FStar_SMTEncoding_Term.Var "ApplyTT"|FStar_SMTEncoding_Term.Var
      "ApplyTF" -> true
    | uu____1765 -> false
let is_eta:
  env_t ->
    FStar_SMTEncoding_Term.fv Prims.list ->
      FStar_SMTEncoding_Term.term -> FStar_SMTEncoding_Term.term Prims.option
  =
  fun env  ->
    fun vars  ->
      fun t  ->
        let rec aux t xs =
          match ((t.FStar_SMTEncoding_Term.tm), xs) with
          | (FStar_SMTEncoding_Term.App
             (app,f::{
                       FStar_SMTEncoding_Term.tm =
                         FStar_SMTEncoding_Term.FreeV y;
                       FStar_SMTEncoding_Term.freevars = uu____1793;
                       FStar_SMTEncoding_Term.rng = uu____1794;_}::[]),x::xs)
              when (is_app app) && (FStar_SMTEncoding_Term.fv_eq x y) ->
              aux f xs
          | (FStar_SMTEncoding_Term.App
             (FStar_SMTEncoding_Term.Var f,args),uu____1808) ->
              let uu____1813 =
                ((FStar_List.length args) = (FStar_List.length vars)) &&
                  (FStar_List.forall2
                     (fun a  ->
                        fun v  ->
                          match a.FStar_SMTEncoding_Term.tm with
                          | FStar_SMTEncoding_Term.FreeV fv ->
                              FStar_SMTEncoding_Term.fv_eq fv v
                          | uu____1823 -> false) args vars) in
              (match uu____1813 with
               | true  -> tok_of_name env f
               | uu____1825 -> None)
          | (uu____1826,[]) ->
              let fvs = FStar_SMTEncoding_Term.free_variables t in
              let uu____1829 =
                FStar_All.pipe_right fvs
                  (FStar_List.for_all
                     (fun fv  ->
                        let uu____1831 =
                          FStar_Util.for_some
                            (FStar_SMTEncoding_Term.fv_eq fv) vars in
                        Prims.op_Negation uu____1831)) in
              (match uu____1829 with | true  -> Some t | uu____1833 -> None)
          | uu____1834 -> None in
        aux t (FStar_List.rev vars)
let reify_body:
  FStar_TypeChecker_Env.env ->
    FStar_Syntax_Syntax.term -> FStar_Syntax_Syntax.term
  =
  fun env  ->
    fun t  ->
      let tm = FStar_Syntax_Util.mk_reify t in
      let tm' =
        FStar_TypeChecker_Normalize.normalize
          [FStar_TypeChecker_Normalize.Beta;
          FStar_TypeChecker_Normalize.Reify;
          FStar_TypeChecker_Normalize.Eager_unfolding;
          FStar_TypeChecker_Normalize.EraseUniverses;
          FStar_TypeChecker_Normalize.AllowUnboundUniverses] env tm in
      (let uu____1849 =
         FStar_All.pipe_left (FStar_TypeChecker_Env.debug env)
           (FStar_Options.Other "SMTEncodingReify") in
       match uu____1849 with
       | true  ->
           let uu____1850 = FStar_Syntax_Print.term_to_string tm in
           let uu____1851 = FStar_Syntax_Print.term_to_string tm' in
           FStar_Util.print2 "Reified body %s \nto %s\n" uu____1850
             uu____1851
       | uu____1852 -> ());
      tm'
type label = (FStar_SMTEncoding_Term.fv* Prims.string* FStar_Range.range)
type labels = label Prims.list
type pattern =
  {
  pat_vars: (FStar_Syntax_Syntax.bv* FStar_SMTEncoding_Term.fv) Prims.list;
  pat_term:
    Prims.unit ->
      (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t);
  guard: FStar_SMTEncoding_Term.term -> FStar_SMTEncoding_Term.term;
  projections:
    FStar_SMTEncoding_Term.term ->
      (FStar_Syntax_Syntax.bv* FStar_SMTEncoding_Term.term) Prims.list;}
exception Let_rec_unencodeable
let uu___is_Let_rec_unencodeable: Prims.exn -> Prims.bool =
  fun projectee  ->
    match projectee with
    | Let_rec_unencodeable  -> true
    | uu____1933 -> false
let encode_const: FStar_Const.sconst -> FStar_SMTEncoding_Term.term =
  fun uu___116_1936  ->
    match uu___116_1936 with
    | FStar_Const.Const_unit  -> FStar_SMTEncoding_Term.mk_Term_unit
    | FStar_Const.Const_bool (true ) ->
        FStar_SMTEncoding_Term.boxBool FStar_SMTEncoding_Util.mkTrue
    | FStar_Const.Const_bool (false ) ->
        FStar_SMTEncoding_Term.boxBool FStar_SMTEncoding_Util.mkFalse
    | FStar_Const.Const_char c ->
        let uu____1938 =
          let uu____1942 =
            let uu____1944 =
              let uu____1945 =
                FStar_SMTEncoding_Util.mkInteger' (FStar_Util.int_of_char c) in
              FStar_SMTEncoding_Term.boxInt uu____1945 in
            [uu____1944] in
          ("FStar.Char.Char", uu____1942) in
        FStar_SMTEncoding_Util.mkApp uu____1938
    | FStar_Const.Const_int (i,None ) ->
        let uu____1953 = FStar_SMTEncoding_Util.mkInteger i in
        FStar_SMTEncoding_Term.boxInt uu____1953
    | FStar_Const.Const_int (i,Some uu____1955) ->
        failwith "Machine integers should be desugared"
    | FStar_Const.Const_string (bytes,uu____1964) ->
        let uu____1967 = FStar_All.pipe_left FStar_Util.string_of_bytes bytes in
        varops.string_const uu____1967
    | FStar_Const.Const_range r -> FStar_SMTEncoding_Term.mk_Range_const
    | FStar_Const.Const_effect  -> FStar_SMTEncoding_Term.mk_Term_type
    | c ->
        let uu____1971 =
          let uu____1972 = FStar_Syntax_Print.const_to_string c in
          FStar_Util.format1 "Unhandled constant: %s" uu____1972 in
        failwith uu____1971
let as_function_typ:
  env_t ->
    (FStar_Syntax_Syntax.term',FStar_Syntax_Syntax.term')
      FStar_Syntax_Syntax.syntax -> FStar_Syntax_Syntax.term
  =
  fun env  ->
    fun t0  ->
      let rec aux norm t =
        let t = FStar_Syntax_Subst.compress t in
        match t.FStar_Syntax_Syntax.n with
        | FStar_Syntax_Syntax.Tm_arrow uu____1991 -> t
        | FStar_Syntax_Syntax.Tm_refine uu____1999 ->
            let uu____2004 = FStar_Syntax_Util.unrefine t in
            aux true uu____2004
        | uu____2005 ->
            (match norm with
             | true  -> let uu____2006 = whnf env t in aux false uu____2006
             | uu____2007 ->
                 let uu____2008 =
                   let uu____2009 =
                     FStar_Range.string_of_range t0.FStar_Syntax_Syntax.pos in
                   let uu____2010 = FStar_Syntax_Print.term_to_string t0 in
                   FStar_Util.format2 "(%s) Expected a function typ; got %s"
                     uu____2009 uu____2010 in
                 failwith uu____2008) in
      aux true t0
let curried_arrow_formals_comp:
  FStar_Syntax_Syntax.term ->
    (FStar_Syntax_Syntax.binders* FStar_Syntax_Syntax.comp)
  =
  fun k  ->
    let k = FStar_Syntax_Subst.compress k in
    match k.FStar_Syntax_Syntax.n with
    | FStar_Syntax_Syntax.Tm_arrow (bs,c) ->
        FStar_Syntax_Subst.open_comp bs c
    | uu____2031 ->
        let uu____2032 = FStar_Syntax_Syntax.mk_Total k in ([], uu____2032)
let rec encode_binders:
  FStar_SMTEncoding_Term.term Prims.option ->
    FStar_Syntax_Syntax.binders ->
      env_t ->
        (FStar_SMTEncoding_Term.fv Prims.list* FStar_SMTEncoding_Term.term
          Prims.list* env_t* FStar_SMTEncoding_Term.decls_t*
          FStar_Syntax_Syntax.bv Prims.list)
  =
  fun fuel_opt  ->
    fun bs  ->
      fun env  ->
        (let uu____2175 =
           FStar_TypeChecker_Env.debug env.tcenv FStar_Options.Low in
         match uu____2175 with
         | true  ->
             let uu____2176 = FStar_Syntax_Print.binders_to_string ", " bs in
             FStar_Util.print1 "Encoding binders %s\n" uu____2176
         | uu____2177 -> ());
        (let uu____2178 =
           FStar_All.pipe_right bs
             (FStar_List.fold_left
                (fun uu____2214  ->
                   fun b  ->
                     match uu____2214 with
                     | (vars,guards,env,decls,names) ->
                         let uu____2257 =
                           let x = unmangle (Prims.fst b) in
                           let uu____2266 = gen_term_var env x in
                           match uu____2266 with
                           | (xxsym,xx,env') ->
                               let uu____2280 =
                                 let uu____2283 =
                                   norm env x.FStar_Syntax_Syntax.sort in
                                 encode_term_pred fuel_opt uu____2283 env xx in
                               (match uu____2280 with
                                | (guard_x_t,decls') ->
                                    ((xxsym,
                                       FStar_SMTEncoding_Term.Term_sort),
                                      guard_x_t, env', decls', x)) in
                         (match uu____2257 with
                          | (v,g,env,decls',n) ->
                              ((v :: vars), (g :: guards), env,
                                (FStar_List.append decls decls'), (n ::
                                names)))) ([], [], env, [], [])) in
         match uu____2178 with
         | (vars,guards,env,decls,names) ->
             ((FStar_List.rev vars), (FStar_List.rev guards), env, decls,
               (FStar_List.rev names)))
and encode_term_pred:
  FStar_SMTEncoding_Term.term Prims.option ->
    FStar_Syntax_Syntax.typ ->
      env_t ->
        FStar_SMTEncoding_Term.term ->
          (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun fuel_opt  ->
    fun t  ->
      fun env  ->
        fun e  ->
          let uu____2371 = encode_term t env in
          match uu____2371 with
          | (t,decls) ->
              let uu____2378 =
                FStar_SMTEncoding_Term.mk_HasTypeWithFuel fuel_opt e t in
              (uu____2378, decls)
and encode_term_pred':
  FStar_SMTEncoding_Term.term Prims.option ->
    FStar_Syntax_Syntax.typ ->
      env_t ->
        FStar_SMTEncoding_Term.term ->
          (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun fuel_opt  ->
    fun t  ->
      fun env  ->
        fun e  ->
          let uu____2386 = encode_term t env in
          match uu____2386 with
          | (t,decls) ->
              (match fuel_opt with
               | None  ->
                   let uu____2395 = FStar_SMTEncoding_Term.mk_HasTypeZ e t in
                   (uu____2395, decls)
               | Some f ->
                   let uu____2397 =
                     FStar_SMTEncoding_Term.mk_HasTypeFuel f e t in
                   (uu____2397, decls))
and encode_term:
  FStar_Syntax_Syntax.typ ->
    env_t -> (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun t  ->
    fun env  ->
      let t0 = FStar_Syntax_Subst.compress t in
      (let uu____2404 =
         FStar_All.pipe_left (FStar_TypeChecker_Env.debug env.tcenv)
           (FStar_Options.Other "SMTEncoding") in
       match uu____2404 with
       | true  ->
           let uu____2405 = FStar_Syntax_Print.tag_of_term t in
           let uu____2406 = FStar_Syntax_Print.tag_of_term t0 in
           let uu____2407 = FStar_Syntax_Print.term_to_string t0 in
           FStar_Util.print3 "(%s) (%s)   %s\n" uu____2405 uu____2406
             uu____2407
       | uu____2408 -> ());
      (match t0.FStar_Syntax_Syntax.n with
       | FStar_Syntax_Syntax.Tm_delayed _|FStar_Syntax_Syntax.Tm_unknown  ->
           let uu____2412 =
             let uu____2413 =
               FStar_All.pipe_left FStar_Range.string_of_range
                 t.FStar_Syntax_Syntax.pos in
             let uu____2414 = FStar_Syntax_Print.tag_of_term t0 in
             let uu____2415 = FStar_Syntax_Print.term_to_string t0 in
             let uu____2416 = FStar_Syntax_Print.term_to_string t in
             FStar_Util.format4 "(%s) Impossible: %s\n%s\n%s\n" uu____2413
               uu____2414 uu____2415 uu____2416 in
           failwith uu____2412
       | FStar_Syntax_Syntax.Tm_bvar x ->
           let uu____2420 =
             let uu____2421 = FStar_Syntax_Print.bv_to_string x in
             FStar_Util.format1 "Impossible: locally nameless; got %s"
               uu____2421 in
           failwith uu____2420
       | FStar_Syntax_Syntax.Tm_ascribed (t,k,uu____2426) ->
           encode_term t env
       | FStar_Syntax_Syntax.Tm_meta (t,uu____2446) -> encode_term t env
       | FStar_Syntax_Syntax.Tm_name x ->
           let t = lookup_term_var env x in (t, [])
       | FStar_Syntax_Syntax.Tm_fvar v ->
           let uu____2455 = lookup_free_var env v.FStar_Syntax_Syntax.fv_name in
           (uu____2455, [])
       | FStar_Syntax_Syntax.Tm_type uu____2461 ->
           (FStar_SMTEncoding_Term.mk_Term_type, [])
       | FStar_Syntax_Syntax.Tm_uinst (t,uu____2464) -> encode_term t env
       | FStar_Syntax_Syntax.Tm_constant c ->
           let uu____2470 = encode_const c in (uu____2470, [])
       | FStar_Syntax_Syntax.Tm_arrow (binders,c) ->
           let uu____2484 = FStar_Syntax_Subst.open_comp binders c in
           (match uu____2484 with
            | (binders,res) ->
                let uu____2491 =
                  (env.encode_non_total_function_typ &&
                     (FStar_Syntax_Util.is_pure_or_ghost_comp res))
                    || (FStar_Syntax_Util.is_tot_or_gtot_comp res) in
                (match uu____2491 with
                 | true  ->
                     let uu____2494 = encode_binders None binders env in
                     (match uu____2494 with
                      | (vars,guards,env',decls,uu____2509) ->
                          let fsym =
                            let uu____2519 = varops.fresh "f" in
                            (uu____2519, FStar_SMTEncoding_Term.Term_sort) in
                          let f = FStar_SMTEncoding_Util.mkFreeV fsym in
                          let app = mk_Apply f vars in
                          let uu____2522 =
                            FStar_TypeChecker_Util.pure_or_ghost_pre_and_post
                              (let uu___141_2526 = env.tcenv in
                               {
                                 FStar_TypeChecker_Env.solver =
                                   (uu___141_2526.FStar_TypeChecker_Env.solver);
                                 FStar_TypeChecker_Env.range =
                                   (uu___141_2526.FStar_TypeChecker_Env.range);
                                 FStar_TypeChecker_Env.curmodule =
                                   (uu___141_2526.FStar_TypeChecker_Env.curmodule);
                                 FStar_TypeChecker_Env.gamma =
                                   (uu___141_2526.FStar_TypeChecker_Env.gamma);
                                 FStar_TypeChecker_Env.gamma_cache =
                                   (uu___141_2526.FStar_TypeChecker_Env.gamma_cache);
                                 FStar_TypeChecker_Env.modules =
                                   (uu___141_2526.FStar_TypeChecker_Env.modules);
                                 FStar_TypeChecker_Env.expected_typ =
                                   (uu___141_2526.FStar_TypeChecker_Env.expected_typ);
                                 FStar_TypeChecker_Env.sigtab =
                                   (uu___141_2526.FStar_TypeChecker_Env.sigtab);
                                 FStar_TypeChecker_Env.is_pattern =
                                   (uu___141_2526.FStar_TypeChecker_Env.is_pattern);
                                 FStar_TypeChecker_Env.instantiate_imp =
                                   (uu___141_2526.FStar_TypeChecker_Env.instantiate_imp);
                                 FStar_TypeChecker_Env.effects =
                                   (uu___141_2526.FStar_TypeChecker_Env.effects);
                                 FStar_TypeChecker_Env.generalize =
                                   (uu___141_2526.FStar_TypeChecker_Env.generalize);
                                 FStar_TypeChecker_Env.letrecs =
                                   (uu___141_2526.FStar_TypeChecker_Env.letrecs);
                                 FStar_TypeChecker_Env.top_level =
                                   (uu___141_2526.FStar_TypeChecker_Env.top_level);
                                 FStar_TypeChecker_Env.check_uvars =
                                   (uu___141_2526.FStar_TypeChecker_Env.check_uvars);
                                 FStar_TypeChecker_Env.use_eq =
                                   (uu___141_2526.FStar_TypeChecker_Env.use_eq);
                                 FStar_TypeChecker_Env.is_iface =
                                   (uu___141_2526.FStar_TypeChecker_Env.is_iface);
                                 FStar_TypeChecker_Env.admit =
                                   (uu___141_2526.FStar_TypeChecker_Env.admit);
                                 FStar_TypeChecker_Env.lax = true;
                                 FStar_TypeChecker_Env.lax_universes =
                                   (uu___141_2526.FStar_TypeChecker_Env.lax_universes);
                                 FStar_TypeChecker_Env.type_of =
                                   (uu___141_2526.FStar_TypeChecker_Env.type_of);
                                 FStar_TypeChecker_Env.universe_of =
                                   (uu___141_2526.FStar_TypeChecker_Env.universe_of);
                                 FStar_TypeChecker_Env.use_bv_sorts =
                                   (uu___141_2526.FStar_TypeChecker_Env.use_bv_sorts);
                                 FStar_TypeChecker_Env.qname_and_index =
                                   (uu___141_2526.FStar_TypeChecker_Env.qname_and_index)
                               }) res in
                          (match uu____2522 with
                           | (pre_opt,res_t) ->
                               let uu____2533 =
                                 encode_term_pred None res_t env' app in
                               (match uu____2533 with
                                | (res_pred,decls') ->
                                    let uu____2540 =
                                      match pre_opt with
                                      | None  ->
                                          let uu____2547 =
                                            FStar_SMTEncoding_Util.mk_and_l
                                              guards in
                                          (uu____2547, [])
                                      | Some pre ->
                                          let uu____2550 =
                                            encode_formula pre env' in
                                          (match uu____2550 with
                                           | (guard,decls0) ->
                                               let uu____2558 =
                                                 FStar_SMTEncoding_Util.mk_and_l
                                                   (guard :: guards) in
                                               (uu____2558, decls0)) in
                                    (match uu____2540 with
                                     | (guards,guard_decls) ->
                                         let t_interp =
                                           let uu____2566 =
                                             let uu____2572 =
                                               FStar_SMTEncoding_Util.mkImp
                                                 (guards, res_pred) in
                                             ([[app]], vars, uu____2572) in
                                           FStar_SMTEncoding_Util.mkForall
                                             uu____2566 in
                                         let cvars =
                                           let uu____2582 =
                                             FStar_SMTEncoding_Term.free_variables
                                               t_interp in
                                           FStar_All.pipe_right uu____2582
                                             (FStar_List.filter
                                                (fun uu____2588  ->
                                                   match uu____2588 with
                                                   | (x,uu____2592) ->
                                                       x <> (Prims.fst fsym))) in
                                         let tkey =
                                           FStar_SMTEncoding_Util.mkForall
                                             ([], (fsym :: cvars), t_interp) in
                                         let tkey_hash =
                                           FStar_SMTEncoding_Term.hash_of_term
                                             tkey in
                                         let uu____2603 =
                                           FStar_Util.smap_try_find env.cache
                                             tkey_hash in
                                         (match uu____2603 with
                                          | Some (t',sorts,uu____2619) ->
                                              let uu____2629 =
                                                let uu____2630 =
                                                  let uu____2634 =
                                                    FStar_All.pipe_right
                                                      cvars
                                                      (FStar_List.map
                                                         FStar_SMTEncoding_Util.mkFreeV) in
                                                  (t', uu____2634) in
                                                FStar_SMTEncoding_Util.mkApp
                                                  uu____2630 in
                                              (uu____2629, [])
                                          | None  ->
                                              let tsym =
                                                let uu____2650 =
                                                  let uu____2651 =
                                                    FStar_Util.digest_of_string
                                                      tkey_hash in
                                                  Prims.strcat "Tm_arrow_"
                                                    uu____2651 in
                                                varops.mk_unique uu____2650 in
                                              let cvar_sorts =
                                                FStar_List.map Prims.snd
                                                  cvars in
                                              let caption =
                                                let uu____2658 =
                                                  FStar_Options.log_queries
                                                    () in
                                                match uu____2658 with
                                                | true  ->
                                                    let uu____2660 =
                                                      FStar_TypeChecker_Normalize.term_to_string
                                                        env.tcenv t0 in
                                                    Some uu____2660
                                                | uu____2661 -> None in
                                              let tdecl =
                                                FStar_SMTEncoding_Term.DeclFun
                                                  (tsym, cvar_sorts,
                                                    FStar_SMTEncoding_Term.Term_sort,
                                                    caption) in
                                              let t =
                                                let uu____2666 =
                                                  let uu____2670 =
                                                    FStar_List.map
                                                      FStar_SMTEncoding_Util.mkFreeV
                                                      cvars in
                                                  (tsym, uu____2670) in
                                                FStar_SMTEncoding_Util.mkApp
                                                  uu____2666 in
                                              let t_has_kind =
                                                FStar_SMTEncoding_Term.mk_HasType
                                                  t
                                                  FStar_SMTEncoding_Term.mk_Term_type in
                                              let k_assumption =
                                                let a_name =
                                                  Some
                                                    (Prims.strcat "kinding_"
                                                       tsym) in
                                                let uu____2679 =
                                                  let uu____2684 =
                                                    FStar_SMTEncoding_Util.mkForall
                                                      ([[t_has_kind]], cvars,
                                                        t_has_kind) in
                                                  (uu____2684, a_name,
                                                    a_name) in
                                                FStar_SMTEncoding_Term.Assume
                                                  uu____2679 in
                                              let f_has_t =
                                                FStar_SMTEncoding_Term.mk_HasType
                                                  f t in
                                              let f_has_t_z =
                                                FStar_SMTEncoding_Term.mk_HasTypeZ
                                                  f t in
                                              let pre_typing =
                                                let a_name =
                                                  Some
                                                    (Prims.strcat
                                                       "pre_typing_" tsym) in
                                                let uu____2699 =
                                                  let uu____2704 =
                                                    let uu____2705 =
                                                      let uu____2711 =
                                                        let uu____2712 =
                                                          let uu____2715 =
                                                            let uu____2716 =
                                                              FStar_SMTEncoding_Term.mk_PreType
                                                                f in
                                                            FStar_SMTEncoding_Term.mk_tester
                                                              "Tm_arrow"
                                                              uu____2716 in
                                                          (f_has_t,
                                                            uu____2715) in
                                                        FStar_SMTEncoding_Util.mkImp
                                                          uu____2712 in
                                                      ([[f_has_t]], (fsym ::
                                                        cvars), uu____2711) in
                                                    mkForall_fuel uu____2705 in
                                                  (uu____2704,
                                                    (Some
                                                       "pre-typing for functions"),
                                                    a_name) in
                                                FStar_SMTEncoding_Term.Assume
                                                  uu____2699 in
                                              let t_interp =
                                                let a_name =
                                                  Some
                                                    (Prims.strcat
                                                       "interpretation_" tsym) in
                                                let uu____2731 =
                                                  let uu____2736 =
                                                    let uu____2737 =
                                                      let uu____2743 =
                                                        FStar_SMTEncoding_Util.mkIff
                                                          (f_has_t_z,
                                                            t_interp) in
                                                      ([[f_has_t_z]], (fsym
                                                        :: cvars),
                                                        uu____2743) in
                                                    FStar_SMTEncoding_Util.mkForall
                                                      uu____2737 in
                                                  (uu____2736, a_name,
                                                    a_name) in
                                                FStar_SMTEncoding_Term.Assume
                                                  uu____2731 in
                                              let t_decls =
                                                FStar_List.append (tdecl ::
                                                  decls)
                                                  (FStar_List.append decls'
                                                     (FStar_List.append
                                                        guard_decls
                                                        [k_assumption;
                                                        pre_typing;
                                                        t_interp])) in
                                              (FStar_Util.smap_add env.cache
                                                 tkey_hash
                                                 (tsym, cvar_sorts, t_decls);
                                               (t, t_decls)))))))
                 | uu____2766 ->
                     let tsym = varops.fresh "Non_total_Tm_arrow" in
                     let tdecl =
                       FStar_SMTEncoding_Term.DeclFun
                         (tsym, [], FStar_SMTEncoding_Term.Term_sort, None) in
                     let t = FStar_SMTEncoding_Util.mkApp (tsym, []) in
                     let t_kinding =
                       let a_name =
                         Some
                           (Prims.strcat "non_total_function_typing_" tsym) in
                       let uu____2776 =
                         let uu____2781 =
                           FStar_SMTEncoding_Term.mk_HasType t
                             FStar_SMTEncoding_Term.mk_Term_type in
                         (uu____2781, (Some "Typing for non-total arrows"),
                           a_name) in
                       FStar_SMTEncoding_Term.Assume uu____2776 in
                     let fsym = ("f", FStar_SMTEncoding_Term.Term_sort) in
                     let f = FStar_SMTEncoding_Util.mkFreeV fsym in
                     let f_has_t = FStar_SMTEncoding_Term.mk_HasType f t in
                     let t_interp =
                       let a_name = Some (Prims.strcat "pre_typing_" tsym) in
                       let uu____2792 =
                         let uu____2797 =
                           let uu____2798 =
                             let uu____2804 =
                               let uu____2805 =
                                 let uu____2808 =
                                   let uu____2809 =
                                     FStar_SMTEncoding_Term.mk_PreType f in
                                   FStar_SMTEncoding_Term.mk_tester
                                     "Tm_arrow" uu____2809 in
                                 (f_has_t, uu____2808) in
                               FStar_SMTEncoding_Util.mkImp uu____2805 in
                             ([[f_has_t]], [fsym], uu____2804) in
                           mkForall_fuel uu____2798 in
                         (uu____2797, a_name, a_name) in
                       FStar_SMTEncoding_Term.Assume uu____2792 in
                     (t, [tdecl; t_kinding; t_interp])))
       | FStar_Syntax_Syntax.Tm_refine uu____2824 ->
           let uu____2829 =
             let uu____2832 =
               FStar_TypeChecker_Normalize.normalize_refinement
                 [FStar_TypeChecker_Normalize.WHNF;
                 FStar_TypeChecker_Normalize.EraseUniverses] env.tcenv t0 in
             match uu____2832 with
             | { FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_refine (x,f);
                 FStar_Syntax_Syntax.tk = uu____2837;
                 FStar_Syntax_Syntax.pos = uu____2838;
                 FStar_Syntax_Syntax.vars = uu____2839;_} ->
                 let uu____2846 = FStar_Syntax_Subst.open_term [(x, None)] f in
                 (match uu____2846 with
                  | (b,f) ->
                      let uu____2860 =
                        let uu____2861 = FStar_List.hd b in
                        Prims.fst uu____2861 in
                      (uu____2860, f))
             | uu____2866 -> failwith "impossible" in
           (match uu____2829 with
            | (x,f) ->
                let uu____2873 = encode_term x.FStar_Syntax_Syntax.sort env in
                (match uu____2873 with
                 | (base_t,decls) ->
                     let uu____2880 = gen_term_var env x in
                     (match uu____2880 with
                      | (x,xtm,env') ->
                          let uu____2889 = encode_formula f env' in
                          (match uu____2889 with
                           | (refinement,decls') ->
                               let uu____2896 =
                                 fresh_fvar "f"
                                   FStar_SMTEncoding_Term.Fuel_sort in
                               (match uu____2896 with
                                | (fsym,fterm) ->
                                    let encoding =
                                      let uu____2904 =
                                        let uu____2907 =
                                          FStar_SMTEncoding_Term.mk_HasTypeWithFuel
                                            (Some fterm) xtm base_t in
                                        (uu____2907, refinement) in
                                      FStar_SMTEncoding_Util.mkAnd uu____2904 in
                                    let cvars =
                                      let uu____2912 =
                                        FStar_SMTEncoding_Term.free_variables
                                          encoding in
                                      FStar_All.pipe_right uu____2912
                                        (FStar_List.filter
                                           (fun uu____2918  ->
                                              match uu____2918 with
                                              | (y,uu____2922) ->
                                                  (y <> x) && (y <> fsym))) in
                                    let xfv =
                                      (x, FStar_SMTEncoding_Term.Term_sort) in
                                    let ffv =
                                      (fsym,
                                        FStar_SMTEncoding_Term.Fuel_sort) in
                                    let tkey =
                                      FStar_SMTEncoding_Util.mkForall
                                        ([], (ffv :: xfv :: cvars), encoding) in
                                    let tkey_hash =
                                      FStar_SMTEncoding_Term.hash_of_term
                                        tkey in
                                    let uu____2941 =
                                      FStar_Util.smap_try_find env.cache
                                        tkey_hash in
                                    (match uu____2941 with
                                     | Some (t,uu____2956,uu____2957) ->
                                         let uu____2967 =
                                           let uu____2968 =
                                             let uu____2972 =
                                               FStar_All.pipe_right cvars
                                                 (FStar_List.map
                                                    FStar_SMTEncoding_Util.mkFreeV) in
                                             (t, uu____2972) in
                                           FStar_SMTEncoding_Util.mkApp
                                             uu____2968 in
                                         (uu____2967, [])
                                     | None  ->
                                         let tsym =
                                           let uu____2988 =
                                             let uu____2989 =
                                               FStar_Util.digest_of_string
                                                 tkey_hash in
                                             Prims.strcat "Tm_refine_"
                                               uu____2989 in
                                           varops.mk_unique uu____2988 in
                                         let cvar_sorts =
                                           FStar_List.map Prims.snd cvars in
                                         let tdecl =
                                           FStar_SMTEncoding_Term.DeclFun
                                             (tsym, cvar_sorts,
                                               FStar_SMTEncoding_Term.Term_sort,
                                               None) in
                                         let t =
                                           let uu____2998 =
                                             let uu____3002 =
                                               FStar_List.map
                                                 FStar_SMTEncoding_Util.mkFreeV
                                                 cvars in
                                             (tsym, uu____3002) in
                                           FStar_SMTEncoding_Util.mkApp
                                             uu____2998 in
                                         let x_has_t =
                                           FStar_SMTEncoding_Term.mk_HasTypeWithFuel
                                             (Some fterm) xtm t in
                                         let t_has_kind =
                                           FStar_SMTEncoding_Term.mk_HasType
                                             t
                                             FStar_SMTEncoding_Term.mk_Term_type in
                                         let t_haseq_base =
                                           FStar_SMTEncoding_Term.mk_haseq
                                             base_t in
                                         let t_haseq_ref =
                                           FStar_SMTEncoding_Term.mk_haseq t in
                                         let t_haseq =
                                           let uu____3012 =
                                             let uu____3017 =
                                               let uu____3018 =
                                                 let uu____3024 =
                                                   FStar_SMTEncoding_Util.mkIff
                                                     (t_haseq_ref,
                                                       t_haseq_base) in
                                                 ([[t_haseq_ref]], cvars,
                                                   uu____3024) in
                                               FStar_SMTEncoding_Util.mkForall
                                                 uu____3018 in
                                             (uu____3017,
                                               (Some
                                                  (Prims.strcat "haseq for "
                                                     tsym)),
                                               (Some
                                                  (Prims.strcat "haseq" tsym))) in
                                           FStar_SMTEncoding_Term.Assume
                                             uu____3012 in
                                         let t_kinding =
                                           let uu____3035 =
                                             let uu____3040 =
                                               FStar_SMTEncoding_Util.mkForall
                                                 ([[t_has_kind]], cvars,
                                                   t_has_kind) in
                                             (uu____3040,
                                               (Some "refinement kinding"),
                                               (Some
                                                  (Prims.strcat
                                                     "refinement_kinding_"
                                                     tsym))) in
                                           FStar_SMTEncoding_Term.Assume
                                             uu____3035 in
                                         let t_interp =
                                           let uu____3051 =
                                             let uu____3056 =
                                               let uu____3057 =
                                                 let uu____3063 =
                                                   FStar_SMTEncoding_Util.mkIff
                                                     (x_has_t, encoding) in
                                                 ([[x_has_t]], (ffv :: xfv ::
                                                   cvars), uu____3063) in
                                               FStar_SMTEncoding_Util.mkForall
                                                 uu____3057 in
                                             let uu____3075 =
                                               let uu____3077 =
                                                 FStar_Syntax_Print.term_to_string
                                                   t0 in
                                               Some uu____3077 in
                                             (uu____3056, uu____3075,
                                               (Some
                                                  (Prims.strcat
                                                     "refinement_interpretation_"
                                                     tsym))) in
                                           FStar_SMTEncoding_Term.Assume
                                             uu____3051 in
                                         let t_decls =
                                           FStar_List.append decls
                                             (FStar_List.append decls'
                                                [tdecl;
                                                t_kinding;
                                                t_interp;
                                                t_haseq]) in
                                         (FStar_Util.smap_add env.cache
                                            tkey_hash
                                            (tsym, cvar_sorts, t_decls);
                                          (t, t_decls))))))))
       | FStar_Syntax_Syntax.Tm_uvar (uv,k) ->
           let ttm =
             let uu____3106 = FStar_Unionfind.uvar_id uv in
             FStar_SMTEncoding_Util.mk_Term_uvar uu____3106 in
           let uu____3110 = encode_term_pred None k env ttm in
           (match uu____3110 with
            | (t_has_k,decls) ->
                let d =
                  let uu____3118 =
                    let uu____3123 =
                      let uu____3125 =
                        let uu____3126 =
                          let uu____3127 =
                            let uu____3128 = FStar_Unionfind.uvar_id uv in
                            FStar_All.pipe_left FStar_Util.string_of_int
                              uu____3128 in
                          FStar_Util.format1 "uvar_typing_%s" uu____3127 in
                        varops.mk_unique uu____3126 in
                      Some uu____3125 in
                    (t_has_k, (Some "Uvar typing"), uu____3123) in
                  FStar_SMTEncoding_Term.Assume uu____3118 in
                (ttm, (FStar_List.append decls [d])))
       | FStar_Syntax_Syntax.Tm_app uu____3135 ->
           let uu____3145 = FStar_Syntax_Util.head_and_args t0 in
           (match uu____3145 with
            | (head,args_e) ->
                let uu____3173 =
                  let uu____3181 =
                    let uu____3182 = FStar_Syntax_Subst.compress head in
                    uu____3182.FStar_Syntax_Syntax.n in
                  (uu____3181, args_e) in
                (match uu____3173 with
                 | (uu____3192,uu____3193) when head_redex env head ->
                     let uu____3204 = whnf env t in
                     encode_term uu____3204 env
                 | (FStar_Syntax_Syntax.Tm_uinst
                    ({
                       FStar_Syntax_Syntax.n = FStar_Syntax_Syntax.Tm_fvar fv;
                       FStar_Syntax_Syntax.tk = _;
                       FStar_Syntax_Syntax.pos = _;
                       FStar_Syntax_Syntax.vars = _;_},_),_::(v1,_)::
                    (v2,_)::[])
                   |(FStar_Syntax_Syntax.Tm_fvar fv,_::(v1,_)::(v2,_)::[])
                     when
                     FStar_Syntax_Syntax.fv_eq_lid fv
                       FStar_Syntax_Const.lexcons_lid
                     ->
                     let uu____3278 = encode_term v1 env in
                     (match uu____3278 with
                      | (v1,decls1) ->
                          let uu____3285 = encode_term v2 env in
                          (match uu____3285 with
                           | (v2,decls2) ->
                               let uu____3292 =
                                 FStar_SMTEncoding_Util.mk_LexCons v1 v2 in
                               (uu____3292,
                                 (FStar_List.append decls1 decls2))))
                 | (FStar_Syntax_Syntax.Tm_constant (FStar_Const.Const_reify
                    ),uu____3294) ->
                     let e0 =
                       let uu____3308 =
                         let uu____3311 =
                           let uu____3312 =
                             let uu____3322 =
                               let uu____3328 = FStar_List.hd args_e in
                               [uu____3328] in
                             (head, uu____3322) in
                           FStar_Syntax_Syntax.Tm_app uu____3312 in
                         FStar_Syntax_Syntax.mk uu____3311 in
                       uu____3308 None head.FStar_Syntax_Syntax.pos in
                     ((let uu____3361 =
                         FStar_All.pipe_left
                           (FStar_TypeChecker_Env.debug env.tcenv)
                           (FStar_Options.Other "SMTEncodingReify") in
                       match uu____3361 with
                       | true  ->
                           let uu____3362 =
                             FStar_Syntax_Print.term_to_string e0 in
                           FStar_Util.print1 "Trying to normalize %s\n"
                             uu____3362
                       | uu____3363 -> ());
                      (let e0 =
                         FStar_TypeChecker_Normalize.normalize
                           [FStar_TypeChecker_Normalize.Beta;
                           FStar_TypeChecker_Normalize.Reify;
                           FStar_TypeChecker_Normalize.Eager_unfolding;
                           FStar_TypeChecker_Normalize.EraseUniverses;
                           FStar_TypeChecker_Normalize.AllowUnboundUniverses]
                           env.tcenv e0 in
                       (let uu____3366 =
                          FStar_All.pipe_left
                            (FStar_TypeChecker_Env.debug env.tcenv)
                            (FStar_Options.Other "SMTEncodingReify") in
                        match uu____3366 with
                        | true  ->
                            let uu____3367 =
                              FStar_Syntax_Print.term_to_string e0 in
                            FStar_Util.print1 "Result of normalization %s\n"
                              uu____3367
                        | uu____3368 -> ());
                       (let e0 =
                          let uu____3370 =
                            let uu____3371 =
                              let uu____3372 = FStar_Syntax_Subst.compress e0 in
                              uu____3372.FStar_Syntax_Syntax.n in
                            match uu____3371 with
                            | FStar_Syntax_Syntax.Tm_app uu____3375 -> false
                            | uu____3385 -> true in
                          match uu____3370 with
                          | true  -> e0
                          | uu____3386 ->
                              let uu____3387 =
                                FStar_Syntax_Util.head_and_args e0 in
                              (match uu____3387 with
                               | (head,args) ->
                                   let uu____3413 =
                                     let uu____3414 =
                                       let uu____3415 =
                                         FStar_Syntax_Subst.compress head in
                                       uu____3415.FStar_Syntax_Syntax.n in
                                     match uu____3414 with
                                     | FStar_Syntax_Syntax.Tm_constant
                                         (FStar_Const.Const_reify ) -> true
                                     | uu____3418 -> false in
                                   (match uu____3413 with
                                    | true  ->
                                        (match args with
                                         | x::[] -> Prims.fst x
                                         | uu____3434 ->
                                             failwith
                                               "Impossible : Reify applied to multiple arguments after normalization.")
                                    | uu____3440 -> e0)) in
                        let e =
                          match args_e with
                          | uu____3442::[] -> e0
                          | uu____3455 ->
                              let uu____3461 =
                                let uu____3464 =
                                  let uu____3465 =
                                    let uu____3475 = FStar_List.tl args_e in
                                    (e0, uu____3475) in
                                  FStar_Syntax_Syntax.Tm_app uu____3465 in
                                FStar_Syntax_Syntax.mk uu____3464 in
                              uu____3461 None t0.FStar_Syntax_Syntax.pos in
                        encode_term e env)))
                 | (FStar_Syntax_Syntax.Tm_constant
                    (FStar_Const.Const_reflect
                    uu____3498),(arg,uu____3500)::[]) -> encode_term arg env
                 | uu____3518 ->
                     let uu____3526 = encode_args args_e env in
                     (match uu____3526 with
                      | (args,decls) ->
                          let encode_partial_app ht_opt =
                            let uu____3559 = encode_term head env in
                            match uu____3559 with
                            | (head,decls') ->
                                let app_tm = mk_Apply_args head args in
                                (match ht_opt with
                                 | None  ->
                                     (app_tm,
                                       (FStar_List.append decls decls'))
                                 | Some (formals,c) ->
                                     let uu____3598 =
                                       FStar_Util.first_N
                                         (FStar_List.length args_e) formals in
                                     (match uu____3598 with
                                      | (formals,rest) ->
                                          let subst =
                                            FStar_List.map2
                                              (fun uu____3640  ->
                                                 fun uu____3641  ->
                                                   match (uu____3640,
                                                           uu____3641)
                                                   with
                                                   | ((bv,uu____3655),
                                                      (a,uu____3657)) ->
                                                       FStar_Syntax_Syntax.NT
                                                         (bv, a)) formals
                                              args_e in
                                          let ty =
                                            let uu____3671 =
                                              FStar_Syntax_Util.arrow rest c in
                                            FStar_All.pipe_right uu____3671
                                              (FStar_Syntax_Subst.subst subst) in
                                          let uu____3676 =
                                            encode_term_pred None ty env
                                              app_tm in
                                          (match uu____3676 with
                                           | (has_type,decls'') ->
                                               let cvars =
                                                 FStar_SMTEncoding_Term.free_variables
                                                   has_type in
                                               let e_typing =
                                                 let uu____3686 =
                                                   let uu____3691 =
                                                     FStar_SMTEncoding_Util.mkForall
                                                       ([[has_type]], cvars,
                                                         has_type) in
                                                   let uu____3696 =
                                                     let uu____3698 =
                                                       let uu____3699 =
                                                         let uu____3700 =
                                                           let uu____3701 =
                                                             FStar_SMTEncoding_Term.hash_of_term
                                                               app_tm in
                                                           FStar_Util.digest_of_string
                                                             uu____3701 in
                                                         Prims.strcat
                                                           "partial_app_typing_"
                                                           uu____3700 in
                                                       varops.mk_unique
                                                         uu____3699 in
                                                     Some uu____3698 in
                                                   (uu____3691,
                                                     (Some
                                                        "Partial app typing"),
                                                     uu____3696) in
                                                 FStar_SMTEncoding_Term.Assume
                                                   uu____3686 in
                                               (app_tm,
                                                 (FStar_List.append decls
                                                    (FStar_List.append decls'
                                                       (FStar_List.append
                                                          decls'' [e_typing]))))))) in
                          let encode_full_app fv =
                            let uu____3719 = lookup_free_var_sym env fv in
                            match uu____3719 with
                            | (fname,fuel_args) ->
                                let tm =
                                  FStar_SMTEncoding_Util.mkApp'
                                    (fname,
                                      (FStar_List.append fuel_args args)) in
                                (tm, decls) in
                          let head = FStar_Syntax_Subst.compress head in
                          let head_type =
                            match head.FStar_Syntax_Syntax.n with
                            | FStar_Syntax_Syntax.Tm_uinst
                              ({
                                 FStar_Syntax_Syntax.n =
                                   FStar_Syntax_Syntax.Tm_name x;
                                 FStar_Syntax_Syntax.tk = _;
                                 FStar_Syntax_Syntax.pos = _;
                                 FStar_Syntax_Syntax.vars = _;_},_)
                              |FStar_Syntax_Syntax.Tm_name x ->
                                Some (x.FStar_Syntax_Syntax.sort)
                            | FStar_Syntax_Syntax.Tm_uinst
                              ({
                                 FStar_Syntax_Syntax.n =
                                   FStar_Syntax_Syntax.Tm_fvar fv;
                                 FStar_Syntax_Syntax.tk = _;
                                 FStar_Syntax_Syntax.pos = _;
                                 FStar_Syntax_Syntax.vars = _;_},_)
                              |FStar_Syntax_Syntax.Tm_fvar fv ->
                                let uu____3757 =
                                  let uu____3758 =
                                    FStar_TypeChecker_Env.lookup_lid
                                      env.tcenv
                                      (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                                  FStar_All.pipe_right uu____3758 Prims.snd in
                                Some uu____3757
                            | FStar_Syntax_Syntax.Tm_ascribed
                                (uu____3767,FStar_Util.Inl t,uu____3769) ->
                                Some t
                            | FStar_Syntax_Syntax.Tm_ascribed
                                (uu____3790,FStar_Util.Inr c,uu____3792) ->
                                Some (FStar_Syntax_Util.comp_result c)
                            | uu____3813 -> None in
                          (match head_type with
                           | None  -> encode_partial_app None
                           | Some head_type ->
                               let head_type =
                                 let uu____3833 =
                                   FStar_TypeChecker_Normalize.normalize_refinement
                                     [FStar_TypeChecker_Normalize.WHNF;
                                     FStar_TypeChecker_Normalize.EraseUniverses]
                                     env.tcenv head_type in
                                 FStar_All.pipe_left
                                   FStar_Syntax_Util.unrefine uu____3833 in
                               let uu____3834 =
                                 curried_arrow_formals_comp head_type in
                               (match uu____3834 with
                                | (formals,c) ->
                                    (match head.FStar_Syntax_Syntax.n with
                                     | FStar_Syntax_Syntax.Tm_uinst
                                       ({
                                          FStar_Syntax_Syntax.n =
                                            FStar_Syntax_Syntax.Tm_fvar fv;
                                          FStar_Syntax_Syntax.tk = _;
                                          FStar_Syntax_Syntax.pos = _;
                                          FStar_Syntax_Syntax.vars = _;_},_)
                                       |FStar_Syntax_Syntax.Tm_fvar fv when
                                         (FStar_List.length formals) =
                                           (FStar_List.length args)
                                         ->
                                         encode_full_app
                                           fv.FStar_Syntax_Syntax.fv_name
                                     | uu____3859 ->
                                         (match (FStar_List.length formals) >
                                                  (FStar_List.length args)
                                          with
                                          | true  ->
                                              encode_partial_app
                                                (Some (formals, c))
                                          | uu____3871 ->
                                              encode_partial_app None)))))))
       | FStar_Syntax_Syntax.Tm_abs (bs,body,lopt) ->
           let uu____3904 = FStar_Syntax_Subst.open_term' bs body in
           (match uu____3904 with
            | (bs,body,opening) ->
                let fallback uu____3919 =
                  let f = varops.fresh "Tm_abs" in
                  let decl =
                    FStar_SMTEncoding_Term.DeclFun
                      (f, [], FStar_SMTEncoding_Term.Term_sort,
                        (Some "Imprecise function encoding")) in
                  let uu____3924 =
                    FStar_SMTEncoding_Util.mkFreeV
                      (f, FStar_SMTEncoding_Term.Term_sort) in
                  (uu____3924, [decl]) in
                let is_impure lc =
                  match lc with
                  | FStar_Util.Inl lc ->
                      let uu____3935 =
                        FStar_Syntax_Util.is_pure_or_ghost_lcomp lc in
                      Prims.op_Negation uu____3935
                  | FStar_Util.Inr (eff,uu____3937) ->
                      let uu____3943 =
                        FStar_TypeChecker_Util.is_pure_or_ghost_effect
                          env.tcenv eff in
                      FStar_All.pipe_right uu____3943 Prims.op_Negation in
                let reify_comp_and_body env c body =
                  let reified_body = reify_body env.tcenv body in
                  let c =
                    match c with
                    | FStar_Util.Inl lc ->
                        let typ =
                          let uu____3988 = lc.FStar_Syntax_Syntax.comp () in
                          FStar_TypeChecker_Env.reify_comp
                            (let uu___142_3989 = env.tcenv in
                             {
                               FStar_TypeChecker_Env.solver =
                                 (uu___142_3989.FStar_TypeChecker_Env.solver);
                               FStar_TypeChecker_Env.range =
                                 (uu___142_3989.FStar_TypeChecker_Env.range);
                               FStar_TypeChecker_Env.curmodule =
                                 (uu___142_3989.FStar_TypeChecker_Env.curmodule);
                               FStar_TypeChecker_Env.gamma =
                                 (uu___142_3989.FStar_TypeChecker_Env.gamma);
                               FStar_TypeChecker_Env.gamma_cache =
                                 (uu___142_3989.FStar_TypeChecker_Env.gamma_cache);
                               FStar_TypeChecker_Env.modules =
                                 (uu___142_3989.FStar_TypeChecker_Env.modules);
                               FStar_TypeChecker_Env.expected_typ =
                                 (uu___142_3989.FStar_TypeChecker_Env.expected_typ);
                               FStar_TypeChecker_Env.sigtab =
                                 (uu___142_3989.FStar_TypeChecker_Env.sigtab);
                               FStar_TypeChecker_Env.is_pattern =
                                 (uu___142_3989.FStar_TypeChecker_Env.is_pattern);
                               FStar_TypeChecker_Env.instantiate_imp =
                                 (uu___142_3989.FStar_TypeChecker_Env.instantiate_imp);
                               FStar_TypeChecker_Env.effects =
                                 (uu___142_3989.FStar_TypeChecker_Env.effects);
                               FStar_TypeChecker_Env.generalize =
                                 (uu___142_3989.FStar_TypeChecker_Env.generalize);
                               FStar_TypeChecker_Env.letrecs =
                                 (uu___142_3989.FStar_TypeChecker_Env.letrecs);
                               FStar_TypeChecker_Env.top_level =
                                 (uu___142_3989.FStar_TypeChecker_Env.top_level);
                               FStar_TypeChecker_Env.check_uvars =
                                 (uu___142_3989.FStar_TypeChecker_Env.check_uvars);
                               FStar_TypeChecker_Env.use_eq =
                                 (uu___142_3989.FStar_TypeChecker_Env.use_eq);
                               FStar_TypeChecker_Env.is_iface =
                                 (uu___142_3989.FStar_TypeChecker_Env.is_iface);
                               FStar_TypeChecker_Env.admit =
                                 (uu___142_3989.FStar_TypeChecker_Env.admit);
                               FStar_TypeChecker_Env.lax = true;
                               FStar_TypeChecker_Env.lax_universes =
                                 (uu___142_3989.FStar_TypeChecker_Env.lax_universes);
                               FStar_TypeChecker_Env.type_of =
                                 (uu___142_3989.FStar_TypeChecker_Env.type_of);
                               FStar_TypeChecker_Env.universe_of =
                                 (uu___142_3989.FStar_TypeChecker_Env.universe_of);
                               FStar_TypeChecker_Env.use_bv_sorts =
                                 (uu___142_3989.FStar_TypeChecker_Env.use_bv_sorts);
                               FStar_TypeChecker_Env.qname_and_index =
                                 (uu___142_3989.FStar_TypeChecker_Env.qname_and_index)
                             }) uu____3988 FStar_Syntax_Syntax.U_unknown in
                        let uu____3990 =
                          let uu____3991 = FStar_Syntax_Syntax.mk_Total typ in
                          FStar_Syntax_Util.lcomp_of_comp uu____3991 in
                        FStar_Util.Inl uu____3990
                    | FStar_Util.Inr (eff_name,uu____3998) -> c in
                  (c, reified_body) in
                let codomain_eff lc =
                  match lc with
                  | FStar_Util.Inl lc ->
                      let uu____4029 =
                        let uu____4030 = lc.FStar_Syntax_Syntax.comp () in
                        FStar_Syntax_Subst.subst_comp opening uu____4030 in
                      FStar_All.pipe_right uu____4029
                        (fun _0_31  -> Some _0_31)
                  | FStar_Util.Inr (eff,flags) ->
                      let new_uvar uu____4042 =
                        let uu____4043 =
                          FStar_TypeChecker_Rel.new_uvar
                            FStar_Range.dummyRange []
                            FStar_Syntax_Util.ktype0 in
                        FStar_All.pipe_right uu____4043 Prims.fst in
                      (match FStar_Ident.lid_equals eff
                               FStar_Syntax_Const.effect_Tot_lid
                       with
                       | true  ->
                           let uu____4051 =
                             let uu____4052 = new_uvar () in
                             FStar_Syntax_Syntax.mk_Total uu____4052 in
                           FStar_All.pipe_right uu____4051
                             (fun _0_32  -> Some _0_32)
                       | uu____4054 ->
                           (match FStar_Ident.lid_equals eff
                                    FStar_Syntax_Const.effect_GTot_lid
                            with
                            | true  ->
                                let uu____4056 =
                                  let uu____4057 = new_uvar () in
                                  FStar_Syntax_Syntax.mk_GTotal uu____4057 in
                                FStar_All.pipe_right uu____4056
                                  (fun _0_33  -> Some _0_33)
                            | uu____4059 -> None)) in
                (match lopt with
                 | None  ->
                     ((let uu____4068 =
                         let uu____4069 =
                           FStar_Syntax_Print.term_to_string t0 in
                         FStar_Util.format1
                           "Losing precision when encoding a function literal: %s\n(Unnannotated abstraction in the compiler ?)"
                           uu____4069 in
                       FStar_Errors.warn t0.FStar_Syntax_Syntax.pos
                         uu____4068);
                      fallback ())
                 | Some lc ->
                     let lc = lc in
                     let uu____4084 =
                       (is_impure lc) &&
                         (let uu____4085 =
                            FStar_TypeChecker_Env.is_reifiable env.tcenv lc in
                          Prims.op_Negation uu____4085) in
                     (match uu____4084 with
                      | true  -> fallback ()
                      | uu____4088 ->
                          let uu____4089 = encode_binders None bs env in
                          (match uu____4089 with
                           | (vars,guards,envbody,decls,uu____4104) ->
                               let uu____4111 =
                                 let uu____4119 =
                                   FStar_TypeChecker_Env.is_reifiable
                                     env.tcenv lc in
                                 match uu____4119 with
                                 | true  ->
                                     reify_comp_and_body envbody lc body
                                 | uu____4127 -> (lc, body) in
                               (match uu____4111 with
                                | (lc,body) ->
                                    let uu____4144 = encode_term body envbody in
                                    (match uu____4144 with
                                     | (body,decls') ->
                                         let key_body =
                                           let uu____4152 =
                                             let uu____4158 =
                                               let uu____4159 =
                                                 let uu____4162 =
                                                   FStar_SMTEncoding_Util.mk_and_l
                                                     guards in
                                                 (uu____4162, body) in
                                               FStar_SMTEncoding_Util.mkImp
                                                 uu____4159 in
                                             ([], vars, uu____4158) in
                                           FStar_SMTEncoding_Util.mkForall
                                             uu____4152 in
                                         let cvars =
                                           FStar_SMTEncoding_Term.free_variables
                                             key_body in
                                         let tkey =
                                           FStar_SMTEncoding_Util.mkForall
                                             ([], cvars, key_body) in
                                         let tkey_hash =
                                           FStar_SMTEncoding_Term.hash_of_term
                                             tkey in
                                         let uu____4173 =
                                           FStar_Util.smap_try_find env.cache
                                             tkey_hash in
                                         (match uu____4173 with
                                          | Some (t,uu____4188,uu____4189) ->
                                              let uu____4199 =
                                                let uu____4200 =
                                                  let uu____4204 =
                                                    FStar_List.map
                                                      FStar_SMTEncoding_Util.mkFreeV
                                                      cvars in
                                                  (t, uu____4204) in
                                                FStar_SMTEncoding_Util.mkApp
                                                  uu____4200 in
                                              (uu____4199, [])
                                          | None  ->
                                              let uu____4215 =
                                                is_eta env vars body in
                                              (match uu____4215 with
                                               | Some t -> (t, [])
                                               | None  ->
                                                   let cvar_sorts =
                                                     FStar_List.map Prims.snd
                                                       cvars in
                                                   let fsym =
                                                     let uu____4226 =
                                                       let uu____4227 =
                                                         FStar_Util.digest_of_string
                                                           tkey_hash in
                                                       Prims.strcat "Tm_abs_"
                                                         uu____4227 in
                                                     varops.mk_unique
                                                       uu____4226 in
                                                   let fdecl =
                                                     FStar_SMTEncoding_Term.DeclFun
                                                       (fsym, cvar_sorts,
                                                         FStar_SMTEncoding_Term.Term_sort,
                                                         None) in
                                                   let f =
                                                     let uu____4232 =
                                                       let uu____4236 =
                                                         FStar_List.map
                                                           FStar_SMTEncoding_Util.mkFreeV
                                                           cvars in
                                                       (fsym, uu____4236) in
                                                     FStar_SMTEncoding_Util.mkApp
                                                       uu____4232 in
                                                   let app = mk_Apply f vars in
                                                   let typing_f =
                                                     let uu____4244 =
                                                       codomain_eff lc in
                                                     match uu____4244 with
                                                     | None  -> []
                                                     | Some c ->
                                                         let tfun =
                                                           FStar_Syntax_Util.arrow
                                                             bs c in
                                                         let uu____4251 =
                                                           encode_term_pred
                                                             None tfun env f in
                                                         (match uu____4251
                                                          with
                                                          | (f_has_t,decls'')
                                                              ->
                                                              let a_name =
                                                                Some
                                                                  (Prims.strcat
                                                                    "typing_"
                                                                    fsym) in
                                                              let uu____4259
                                                                =
                                                                let uu____4261
                                                                  =
                                                                  let uu____4262
                                                                    =
                                                                    let uu____4267
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    ([[f]],
                                                                    cvars,
                                                                    f_has_t) in
                                                                    (uu____4267,
                                                                    a_name,
                                                                    a_name) in
                                                                  FStar_SMTEncoding_Term.Assume
                                                                    uu____4262 in
                                                                [uu____4261] in
                                                              FStar_List.append
                                                                decls''
                                                                uu____4259) in
                                                   let interp_f =
                                                     let a_name =
                                                       Some
                                                         (Prims.strcat
                                                            "interpretation_"
                                                            fsym) in
                                                     let uu____4277 =
                                                       let uu____4282 =
                                                         let uu____4283 =
                                                           let uu____4289 =
                                                             FStar_SMTEncoding_Util.mkEq
                                                               (app, body) in
                                                           ([[app]],
                                                             (FStar_List.append
                                                                vars cvars),
                                                             uu____4289) in
                                                         FStar_SMTEncoding_Util.mkForall
                                                           uu____4283 in
                                                       (uu____4282, a_name,
                                                         a_name) in
                                                     FStar_SMTEncoding_Term.Assume
                                                       uu____4277 in
                                                   let f_decls =
                                                     FStar_List.append decls
                                                       (FStar_List.append
                                                          decls'
                                                          (FStar_List.append
                                                             (fdecl ::
                                                             typing_f)
                                                             [interp_f])) in
                                                   (FStar_Util.smap_add
                                                      env.cache tkey_hash
                                                      (fsym, cvar_sorts,
                                                        f_decls);
                                                    (f, f_decls))))))))))
       | FStar_Syntax_Syntax.Tm_let
           ((uu____4308,{
                          FStar_Syntax_Syntax.lbname = FStar_Util.Inr
                            uu____4309;
                          FStar_Syntax_Syntax.lbunivs = uu____4310;
                          FStar_Syntax_Syntax.lbtyp = uu____4311;
                          FStar_Syntax_Syntax.lbeff = uu____4312;
                          FStar_Syntax_Syntax.lbdef = uu____4313;_}::uu____4314),uu____4315)
           -> failwith "Impossible: already handled by encoding of Sig_let"
       | FStar_Syntax_Syntax.Tm_let
           ((false
             ,{ FStar_Syntax_Syntax.lbname = FStar_Util.Inl x;
                FStar_Syntax_Syntax.lbunivs = uu____4333;
                FStar_Syntax_Syntax.lbtyp = t1;
                FStar_Syntax_Syntax.lbeff = uu____4335;
                FStar_Syntax_Syntax.lbdef = e1;_}::[]),e2)
           -> encode_let x t1 e1 e2 env encode_term
       | FStar_Syntax_Syntax.Tm_let uu____4351 ->
           (FStar_Errors.diag t0.FStar_Syntax_Syntax.pos
              "Non-top-level recursive functions are not yet fully encoded to the SMT solver; you may not be able to prove some facts";
            (let e = varops.fresh "let-rec" in
             let decl_e =
               FStar_SMTEncoding_Term.DeclFun
                 (e, [], FStar_SMTEncoding_Term.Term_sort, None) in
             let uu____4364 =
               FStar_SMTEncoding_Util.mkFreeV
                 (e, FStar_SMTEncoding_Term.Term_sort) in
             (uu____4364, [decl_e])))
       | FStar_Syntax_Syntax.Tm_match (e,pats) ->
           encode_match e pats FStar_SMTEncoding_Term.mk_Term_unit env
             encode_term)
and encode_let:
  FStar_Syntax_Syntax.bv ->
    FStar_Syntax_Syntax.typ ->
      FStar_Syntax_Syntax.term ->
        FStar_Syntax_Syntax.term ->
          env_t ->
            (FStar_Syntax_Syntax.term ->
               env_t ->
                 (FStar_SMTEncoding_Term.term*
                   FStar_SMTEncoding_Term.decls_t))
              ->
              (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun x  ->
    fun t1  ->
      fun e1  ->
        fun e2  ->
          fun env  ->
            fun encode_body  ->
              let uu____4406 = encode_term e1 env in
              match uu____4406 with
              | (ee1,decls1) ->
                  let uu____4413 =
                    FStar_Syntax_Subst.open_term [(x, None)] e2 in
                  (match uu____4413 with
                   | (xs,e2) ->
                       let uu____4427 = FStar_List.hd xs in
                       (match uu____4427 with
                        | (x,uu____4435) ->
                            let env' = push_term_var env x ee1 in
                            let uu____4437 = encode_body e2 env' in
                            (match uu____4437 with
                             | (ee2,decls2) ->
                                 (ee2, (FStar_List.append decls1 decls2)))))
and encode_match:
  FStar_Syntax_Syntax.term ->
    FStar_Syntax_Syntax.branch Prims.list ->
      FStar_SMTEncoding_Term.term ->
        env_t ->
          (FStar_Syntax_Syntax.term ->
             env_t ->
               (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t))
            -> (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun e  ->
    fun pats  ->
      fun default_case  ->
        fun env  ->
          fun encode_br  ->
            let uu____4459 =
              let uu____4463 =
                let uu____4464 =
                  (FStar_Syntax_Syntax.mk FStar_Syntax_Syntax.Tm_unknown)
                    None FStar_Range.dummyRange in
                FStar_Syntax_Syntax.null_bv uu____4464 in
              gen_term_var env uu____4463 in
            match uu____4459 with
            | (scrsym,scr',env) ->
                let uu____4478 = encode_term e env in
                (match uu____4478 with
                 | (scr,decls) ->
                     let uu____4485 =
                       let encode_branch b uu____4501 =
                         match uu____4501 with
                         | (else_case,decls) ->
                             let uu____4512 =
                               FStar_Syntax_Subst.open_branch b in
                             (match uu____4512 with
                              | (p,w,br) ->
                                  let patterns = encode_pat env p in
                                  FStar_List.fold_right
                                    (fun uu____4542  ->
                                       fun uu____4543  ->
                                         match (uu____4542, uu____4543) with
                                         | ((env0,pattern),(else_case,decls))
                                             ->
                                             let guard = pattern.guard scr' in
                                             let projections =
                                               pattern.projections scr' in
                                             let env =
                                               FStar_All.pipe_right
                                                 projections
                                                 (FStar_List.fold_left
                                                    (fun env  ->
                                                       fun uu____4580  ->
                                                         match uu____4580
                                                         with
                                                         | (x,t) ->
                                                             push_term_var
                                                               env x t) env) in
                                             let uu____4585 =
                                               match w with
                                               | None  -> (guard, [])
                                               | Some w ->
                                                   let uu____4600 =
                                                     encode_term w env in
                                                   (match uu____4600 with
                                                    | (w,decls2) ->
                                                        let uu____4608 =
                                                          let uu____4609 =
                                                            let uu____4612 =
                                                              let uu____4613
                                                                =
                                                                let uu____4616
                                                                  =
                                                                  FStar_SMTEncoding_Term.boxBool
                                                                    FStar_SMTEncoding_Util.mkTrue in
                                                                (w,
                                                                  uu____4616) in
                                                              FStar_SMTEncoding_Util.mkEq
                                                                uu____4613 in
                                                            (guard,
                                                              uu____4612) in
                                                          FStar_SMTEncoding_Util.mkAnd
                                                            uu____4609 in
                                                        (uu____4608, decls2)) in
                                             (match uu____4585 with
                                              | (guard,decls2) ->
                                                  let uu____4624 =
                                                    encode_br br env in
                                                  (match uu____4624 with
                                                   | (br,decls3) ->
                                                       let uu____4632 =
                                                         FStar_SMTEncoding_Util.mkITE
                                                           (guard, br,
                                                             else_case) in
                                                       (uu____4632,
                                                         (FStar_List.append
                                                            decls
                                                            (FStar_List.append
                                                               decls2 decls3))))))
                                    patterns (else_case, decls)) in
                       FStar_List.fold_right encode_branch pats
                         (default_case, decls) in
                     (match uu____4485 with
                      | (match_tm,decls) ->
                          let uu____4644 =
                            FStar_SMTEncoding_Term.mkLet'
                              ([((scrsym, FStar_SMTEncoding_Term.Term_sort),
                                  scr)], match_tm) FStar_Range.dummyRange in
                          (uu____4644, decls)))
and encode_pat:
  env_t -> FStar_Syntax_Syntax.pat -> (env_t* pattern) Prims.list =
  fun env  ->
    fun pat  ->
      match pat.FStar_Syntax_Syntax.v with
      | FStar_Syntax_Syntax.Pat_disj ps ->
          FStar_List.map (encode_one_pat env) ps
      | uu____4675 -> let uu____4676 = encode_one_pat env pat in [uu____4676]
and encode_one_pat: env_t -> FStar_Syntax_Syntax.pat -> (env_t* pattern) =
  fun env  ->
    fun pat  ->
      (let uu____4688 =
         FStar_TypeChecker_Env.debug env.tcenv FStar_Options.Low in
       match uu____4688 with
       | true  ->
           let uu____4689 = FStar_Syntax_Print.pat_to_string pat in
           FStar_Util.print1 "Encoding pattern %s\n" uu____4689
       | uu____4690 -> ());
      (let uu____4691 = FStar_TypeChecker_Util.decorated_pattern_as_term pat in
       match uu____4691 with
       | (vars,pat_term) ->
           let uu____4701 =
             FStar_All.pipe_right vars
               (FStar_List.fold_left
                  (fun uu____4724  ->
                     fun v  ->
                       match uu____4724 with
                       | (env,vars) ->
                           let uu____4752 = gen_term_var env v in
                           (match uu____4752 with
                            | (xx,uu____4764,env) ->
                                (env,
                                  ((v,
                                     (xx, FStar_SMTEncoding_Term.Term_sort))
                                  :: vars)))) (env, [])) in
           (match uu____4701 with
            | (env,vars) ->
                let rec mk_guard pat scrutinee =
                  match pat.FStar_Syntax_Syntax.v with
                  | FStar_Syntax_Syntax.Pat_disj uu____4811 ->
                      failwith "Impossible"
                  | FStar_Syntax_Syntax.Pat_var _
                    |FStar_Syntax_Syntax.Pat_wild _
                     |FStar_Syntax_Syntax.Pat_dot_term _ ->
                      FStar_SMTEncoding_Util.mkTrue
                  | FStar_Syntax_Syntax.Pat_constant c ->
                      let uu____4819 =
                        let uu____4822 = encode_const c in
                        (scrutinee, uu____4822) in
                      FStar_SMTEncoding_Util.mkEq uu____4819
                  | FStar_Syntax_Syntax.Pat_cons (f,args) ->
                      let is_f =
                        let tc_name =
                          FStar_TypeChecker_Env.typ_of_datacon env.tcenv
                            (f.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                        let uu____4841 =
                          FStar_TypeChecker_Env.datacons_of_typ env.tcenv
                            tc_name in
                        match uu____4841 with
                        | (uu____4845,uu____4846::[]) ->
                            FStar_SMTEncoding_Util.mkTrue
                        | uu____4848 ->
                            mk_data_tester env
                              (f.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                              scrutinee in
                      let sub_term_guards =
                        FStar_All.pipe_right args
                          (FStar_List.mapi
                             (fun i  ->
                                fun uu____4869  ->
                                  match uu____4869 with
                                  | (arg,uu____4875) ->
                                      let proj =
                                        primitive_projector_by_pos env.tcenv
                                          (f.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                                          i in
                                      let uu____4885 =
                                        FStar_SMTEncoding_Util.mkApp
                                          (proj, [scrutinee]) in
                                      mk_guard arg uu____4885)) in
                      FStar_SMTEncoding_Util.mk_and_l (is_f ::
                        sub_term_guards) in
                let rec mk_projections pat scrutinee =
                  match pat.FStar_Syntax_Syntax.v with
                  | FStar_Syntax_Syntax.Pat_disj uu____4904 ->
                      failwith "Impossible"
                  | FStar_Syntax_Syntax.Pat_dot_term (x,_)
                    |FStar_Syntax_Syntax.Pat_var x
                     |FStar_Syntax_Syntax.Pat_wild x -> [(x, scrutinee)]
                  | FStar_Syntax_Syntax.Pat_constant uu____4919 -> []
                  | FStar_Syntax_Syntax.Pat_cons (f,args) ->
                      let uu____4934 =
                        FStar_All.pipe_right args
                          (FStar_List.mapi
                             (fun i  ->
                                fun uu____4956  ->
                                  match uu____4956 with
                                  | (arg,uu____4965) ->
                                      let proj =
                                        primitive_projector_by_pos env.tcenv
                                          (f.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v
                                          i in
                                      let uu____4975 =
                                        FStar_SMTEncoding_Util.mkApp
                                          (proj, [scrutinee]) in
                                      mk_projections arg uu____4975)) in
                      FStar_All.pipe_right uu____4934 FStar_List.flatten in
                let pat_term uu____4991 = encode_term pat_term env in
                let pattern =
                  {
                    pat_vars = vars;
                    pat_term;
                    guard = (mk_guard pat);
                    projections = (mk_projections pat)
                  } in
                (env, pattern)))
and encode_args:
  FStar_Syntax_Syntax.args ->
    env_t ->
      (FStar_SMTEncoding_Term.term Prims.list*
        FStar_SMTEncoding_Term.decls_t)
  =
  fun l  ->
    fun env  ->
      let uu____4998 =
        FStar_All.pipe_right l
          (FStar_List.fold_left
             (fun uu____5013  ->
                fun uu____5014  ->
                  match (uu____5013, uu____5014) with
                  | ((tms,decls),(t,uu____5034)) ->
                      let uu____5045 = encode_term t env in
                      (match uu____5045 with
                       | (t,decls') ->
                           ((t :: tms), (FStar_List.append decls decls'))))
             ([], [])) in
      match uu____4998 with | (l,decls) -> ((FStar_List.rev l), decls)
and encode_function_type_as_formula:
  FStar_SMTEncoding_Term.term Prims.option ->
    FStar_Syntax_Syntax.term Prims.option ->
      FStar_Syntax_Syntax.typ ->
        env_t ->
          (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun induction_on  ->
    fun new_pats  ->
      fun t  ->
        fun env  ->
          let list_elements e =
            let uu____5083 = FStar_Syntax_Util.list_elements e in
            match uu____5083 with
            | Some l -> l
            | None  ->
                (FStar_Errors.warn e.FStar_Syntax_Syntax.pos
                   "SMT pattern is not a list literal; ignoring the pattern";
                 []) in
          let one_pat p =
            let uu____5101 =
              let uu____5111 = FStar_Syntax_Util.unmeta p in
              FStar_All.pipe_right uu____5111 FStar_Syntax_Util.head_and_args in
            match uu____5101 with
            | (head,args) ->
                let uu____5142 =
                  let uu____5150 =
                    let uu____5151 = FStar_Syntax_Util.un_uinst head in
                    uu____5151.FStar_Syntax_Syntax.n in
                  (uu____5150, args) in
                (match uu____5142 with
                 | (FStar_Syntax_Syntax.Tm_fvar
                    fv,(uu____5165,uu____5166)::(e,uu____5168)::[]) when
                     FStar_Syntax_Syntax.fv_eq_lid fv
                       FStar_Syntax_Const.smtpat_lid
                     -> (e, None)
                 | (FStar_Syntax_Syntax.Tm_fvar fv,(e,uu____5199)::[]) when
                     FStar_Syntax_Syntax.fv_eq_lid fv
                       FStar_Syntax_Const.smtpatT_lid
                     -> (e, None)
                 | uu____5220 -> failwith "Unexpected pattern term") in
          let lemma_pats p =
            let elts = list_elements p in
            let smt_pat_or t =
              let uu____5253 =
                let uu____5263 = FStar_Syntax_Util.unmeta t in
                FStar_All.pipe_right uu____5263
                  FStar_Syntax_Util.head_and_args in
              match uu____5253 with
              | (head,args) ->
                  let uu____5292 =
                    let uu____5300 =
                      let uu____5301 = FStar_Syntax_Util.un_uinst head in
                      uu____5301.FStar_Syntax_Syntax.n in
                    (uu____5300, args) in
                  (match uu____5292 with
                   | (FStar_Syntax_Syntax.Tm_fvar fv,(e,uu____5314)::[]) when
                       FStar_Syntax_Syntax.fv_eq_lid fv
                         FStar_Syntax_Const.smtpatOr_lid
                       -> Some e
                   | uu____5334 -> None) in
            match elts with
            | t::[] ->
                let uu____5352 = smt_pat_or t in
                (match uu____5352 with
                 | Some e ->
                     let uu____5368 = list_elements e in
                     FStar_All.pipe_right uu____5368
                       (FStar_List.map
                          (fun branch  ->
                             let uu____5385 = list_elements branch in
                             FStar_All.pipe_right uu____5385
                               (FStar_List.map one_pat)))
                 | uu____5399 ->
                     let uu____5403 =
                       FStar_All.pipe_right elts (FStar_List.map one_pat) in
                     [uu____5403])
            | uu____5434 ->
                let uu____5436 =
                  FStar_All.pipe_right elts (FStar_List.map one_pat) in
                [uu____5436] in
          let uu____5467 =
            let uu____5483 =
              let uu____5484 = FStar_Syntax_Subst.compress t in
              uu____5484.FStar_Syntax_Syntax.n in
            match uu____5483 with
            | FStar_Syntax_Syntax.Tm_arrow (binders,c) ->
                let uu____5514 = FStar_Syntax_Subst.open_comp binders c in
                (match uu____5514 with
                 | (binders,c) ->
                     (match c.FStar_Syntax_Syntax.n with
                      | FStar_Syntax_Syntax.Comp
                          { FStar_Syntax_Syntax.comp_univs = uu____5549;
                            FStar_Syntax_Syntax.effect_name = uu____5550;
                            FStar_Syntax_Syntax.result_typ = uu____5551;
                            FStar_Syntax_Syntax.effect_args =
                              (pre,uu____5553)::(post,uu____5555)::(pats,uu____5557)::[];
                            FStar_Syntax_Syntax.flags = uu____5558;_}
                          ->
                          let pats' =
                            match new_pats with
                            | Some new_pats' -> new_pats'
                            | None  -> pats in
                          let uu____5592 = lemma_pats pats' in
                          (binders, pre, post, uu____5592)
                      | uu____5611 -> failwith "impos"))
            | uu____5627 -> failwith "Impos" in
          match uu____5467 with
          | (binders,pre,post,patterns) ->
              let uu____5671 = encode_binders None binders env in
              (match uu____5671 with
               | (vars,guards,env,decls,uu____5686) ->
                   let uu____5693 =
                     let uu____5700 =
                       FStar_All.pipe_right patterns
                         (FStar_List.map
                            (fun branch  ->
                               let uu____5731 =
                                 let uu____5736 =
                                   FStar_All.pipe_right branch
                                     (FStar_List.map
                                        (fun uu____5752  ->
                                           match uu____5752 with
                                           | (t,uu____5759) ->
                                               encode_term t
                                                 (let uu___143_5762 = env in
                                                  {
                                                    bindings =
                                                      (uu___143_5762.bindings);
                                                    depth =
                                                      (uu___143_5762.depth);
                                                    tcenv =
                                                      (uu___143_5762.tcenv);
                                                    warn =
                                                      (uu___143_5762.warn);
                                                    cache =
                                                      (uu___143_5762.cache);
                                                    nolabels =
                                                      (uu___143_5762.nolabels);
                                                    use_zfuel_name = true;
                                                    encode_non_total_function_typ
                                                      =
                                                      (uu___143_5762.encode_non_total_function_typ)
                                                  }))) in
                                 FStar_All.pipe_right uu____5736
                                   FStar_List.unzip in
                               match uu____5731 with
                               | (pats,decls) -> (pats, decls))) in
                     FStar_All.pipe_right uu____5700 FStar_List.unzip in
                   (match uu____5693 with
                    | (pats,decls') ->
                        let decls' = FStar_List.flatten decls' in
                        let pats =
                          match induction_on with
                          | None  -> pats
                          | Some e ->
                              (match vars with
                               | [] -> pats
                               | l::[] ->
                                   FStar_All.pipe_right pats
                                     (FStar_List.map
                                        (fun p  ->
                                           let uu____5826 =
                                             let uu____5827 =
                                               FStar_SMTEncoding_Util.mkFreeV
                                                 l in
                                             FStar_SMTEncoding_Util.mk_Precedes
                                               uu____5827 e in
                                           uu____5826 :: p))
                               | uu____5828 ->
                                   let rec aux tl vars =
                                     match vars with
                                     | [] ->
                                         FStar_All.pipe_right pats
                                           (FStar_List.map
                                              (fun p  ->
                                                 let uu____5857 =
                                                   FStar_SMTEncoding_Util.mk_Precedes
                                                     tl e in
                                                 uu____5857 :: p))
                                     | (x,FStar_SMTEncoding_Term.Term_sort )::vars
                                         ->
                                         let uu____5865 =
                                           let uu____5866 =
                                             FStar_SMTEncoding_Util.mkFreeV
                                               (x,
                                                 FStar_SMTEncoding_Term.Term_sort) in
                                           FStar_SMTEncoding_Util.mk_LexCons
                                             uu____5866 tl in
                                         aux uu____5865 vars
                                     | uu____5867 -> pats in
                                   let uu____5871 =
                                     FStar_SMTEncoding_Util.mkFreeV
                                       ("Prims.LexTop",
                                         FStar_SMTEncoding_Term.Term_sort) in
                                   aux uu____5871 vars) in
                        let env =
                          let uu___144_5873 = env in
                          {
                            bindings = (uu___144_5873.bindings);
                            depth = (uu___144_5873.depth);
                            tcenv = (uu___144_5873.tcenv);
                            warn = (uu___144_5873.warn);
                            cache = (uu___144_5873.cache);
                            nolabels = true;
                            use_zfuel_name = (uu___144_5873.use_zfuel_name);
                            encode_non_total_function_typ =
                              (uu___144_5873.encode_non_total_function_typ)
                          } in
                        let uu____5874 =
                          let uu____5877 = FStar_Syntax_Util.unmeta pre in
                          encode_formula uu____5877 env in
                        (match uu____5874 with
                         | (pre,decls'') ->
                             let uu____5882 =
                               let uu____5885 = FStar_Syntax_Util.unmeta post in
                               encode_formula uu____5885 env in
                             (match uu____5882 with
                              | (post,decls''') ->
                                  let decls =
                                    FStar_List.append decls
                                      (FStar_List.append
                                         (FStar_List.flatten decls')
                                         (FStar_List.append decls'' decls''')) in
                                  let uu____5892 =
                                    let uu____5893 =
                                      let uu____5899 =
                                        let uu____5900 =
                                          let uu____5903 =
                                            FStar_SMTEncoding_Util.mk_and_l
                                              (pre :: guards) in
                                          (uu____5903, post) in
                                        FStar_SMTEncoding_Util.mkImp
                                          uu____5900 in
                                      (pats, vars, uu____5899) in
                                    FStar_SMTEncoding_Util.mkForall
                                      uu____5893 in
                                  (uu____5892, decls)))))
and encode_formula:
  FStar_Syntax_Syntax.typ ->
    env_t -> (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decls_t)
  =
  fun phi  ->
    fun env  ->
      let debug phi =
        let uu____5916 =
          FStar_All.pipe_left (FStar_TypeChecker_Env.debug env.tcenv)
            (FStar_Options.Other "SMTEncoding") in
        match uu____5916 with
        | true  ->
            let uu____5917 = FStar_Syntax_Print.tag_of_term phi in
            let uu____5918 = FStar_Syntax_Print.term_to_string phi in
            FStar_Util.print2 "Formula (%s)  %s\n" uu____5917 uu____5918
        | uu____5919 -> () in
      let enc f r l =
        let uu____5945 =
          FStar_Util.fold_map
            (fun decls  ->
               fun x  ->
                 let uu____5958 = encode_term (Prims.fst x) env in
                 match uu____5958 with
                 | (t,decls') -> ((FStar_List.append decls decls'), t)) [] l in
        match uu____5945 with
        | (decls,args) ->
            let uu____5975 =
              let uu___145_5976 = f args in
              {
                FStar_SMTEncoding_Term.tm =
                  (uu___145_5976.FStar_SMTEncoding_Term.tm);
                FStar_SMTEncoding_Term.freevars =
                  (uu___145_5976.FStar_SMTEncoding_Term.freevars);
                FStar_SMTEncoding_Term.rng = r
              } in
            (uu____5975, decls) in
      let const_op f r uu____5995 = let uu____5998 = f r in (uu____5998, []) in
      let un_op f l =
        let uu____6014 = FStar_List.hd l in FStar_All.pipe_left f uu____6014 in
      let bin_op f uu___117_6027 =
        match uu___117_6027 with
        | t1::t2::[] -> f (t1, t2)
        | uu____6035 -> failwith "Impossible" in
      let enc_prop_c f r l =
        let uu____6062 =
          FStar_Util.fold_map
            (fun decls  ->
               fun uu____6071  ->
                 match uu____6071 with
                 | (t,uu____6079) ->
                     let uu____6080 = encode_formula t env in
                     (match uu____6080 with
                      | (phi,decls') ->
                          ((FStar_List.append decls decls'), phi))) [] l in
        match uu____6062 with
        | (decls,phis) ->
            let uu____6097 =
              let uu___146_6098 = f phis in
              {
                FStar_SMTEncoding_Term.tm =
                  (uu___146_6098.FStar_SMTEncoding_Term.tm);
                FStar_SMTEncoding_Term.freevars =
                  (uu___146_6098.FStar_SMTEncoding_Term.freevars);
                FStar_SMTEncoding_Term.rng = r
              } in
            (uu____6097, decls) in
      let eq_op r uu___118_6114 =
        match uu___118_6114 with
        | _::e1::e2::[]|_::_::e1::e2::[] ->
            let uu____6174 = enc (bin_op FStar_SMTEncoding_Util.mkEq) in
            uu____6174 r [e1; e2]
        | l ->
            let uu____6194 = enc (bin_op FStar_SMTEncoding_Util.mkEq) in
            uu____6194 r l in
      let mk_imp r uu___119_6213 =
        match uu___119_6213 with
        | (lhs,uu____6217)::(rhs,uu____6219)::[] ->
            let uu____6240 = encode_formula rhs env in
            (match uu____6240 with
             | (l1,decls1) ->
                 (match l1.FStar_SMTEncoding_Term.tm with
                  | FStar_SMTEncoding_Term.App
                      (FStar_SMTEncoding_Term.TrueOp ,uu____6249) ->
                      (l1, decls1)
                  | uu____6252 ->
                      let uu____6253 = encode_formula lhs env in
                      (match uu____6253 with
                       | (l2,decls2) ->
                           let uu____6260 =
                             FStar_SMTEncoding_Term.mkImp (l2, l1) r in
                           (uu____6260, (FStar_List.append decls1 decls2)))))
        | uu____6262 -> failwith "impossible" in
      let mk_ite r uu___120_6277 =
        match uu___120_6277 with
        | (guard,uu____6281)::(_then,uu____6283)::(_else,uu____6285)::[] ->
            let uu____6314 = encode_formula guard env in
            (match uu____6314 with
             | (g,decls1) ->
                 let uu____6321 = encode_formula _then env in
                 (match uu____6321 with
                  | (t,decls2) ->
                      let uu____6328 = encode_formula _else env in
                      (match uu____6328 with
                       | (e,decls3) ->
                           let res = FStar_SMTEncoding_Term.mkITE (g, t, e) r in
                           (res,
                             (FStar_List.append decls1
                                (FStar_List.append decls2 decls3))))))
        | uu____6337 -> failwith "impossible" in
      let unboxInt_l f l =
        let uu____6356 = FStar_List.map FStar_SMTEncoding_Term.unboxInt l in
        f uu____6356 in
      let connectives =
        let uu____6368 =
          let uu____6377 = enc_prop_c (bin_op FStar_SMTEncoding_Util.mkAnd) in
          (FStar_Syntax_Const.and_lid, uu____6377) in
        let uu____6390 =
          let uu____6400 =
            let uu____6409 = enc_prop_c (bin_op FStar_SMTEncoding_Util.mkOr) in
            (FStar_Syntax_Const.or_lid, uu____6409) in
          let uu____6422 =
            let uu____6432 =
              let uu____6442 =
                let uu____6451 =
                  enc_prop_c (bin_op FStar_SMTEncoding_Util.mkIff) in
                (FStar_Syntax_Const.iff_lid, uu____6451) in
              let uu____6464 =
                let uu____6474 =
                  let uu____6484 =
                    let uu____6493 =
                      enc_prop_c (un_op FStar_SMTEncoding_Util.mkNot) in
                    (FStar_Syntax_Const.not_lid, uu____6493) in
                  [uu____6484;
                  (FStar_Syntax_Const.eq2_lid, eq_op);
                  (FStar_Syntax_Const.eq3_lid, eq_op);
                  (FStar_Syntax_Const.true_lid,
                    (const_op FStar_SMTEncoding_Term.mkTrue));
                  (FStar_Syntax_Const.false_lid,
                    (const_op FStar_SMTEncoding_Term.mkFalse))] in
                (FStar_Syntax_Const.ite_lid, mk_ite) :: uu____6474 in
              uu____6442 :: uu____6464 in
            (FStar_Syntax_Const.imp_lid, mk_imp) :: uu____6432 in
          uu____6400 :: uu____6422 in
        uu____6368 :: uu____6390 in
      let rec fallback phi =
        match phi.FStar_Syntax_Syntax.n with
        | FStar_Syntax_Syntax.Tm_meta
            (phi',FStar_Syntax_Syntax.Meta_labeled (msg,r,b)) ->
            let uu____6655 = encode_formula phi' env in
            (match uu____6655 with
             | (phi,decls) ->
                 let uu____6662 =
                   FStar_SMTEncoding_Term.mk
                     (FStar_SMTEncoding_Term.Labeled (phi, msg, r)) r in
                 (uu____6662, decls))
        | FStar_Syntax_Syntax.Tm_meta uu____6663 ->
            let uu____6668 = FStar_Syntax_Util.unmeta phi in
            encode_formula uu____6668 env
        | FStar_Syntax_Syntax.Tm_match (e,pats) ->
            let uu____6697 =
              encode_match e pats FStar_SMTEncoding_Util.mkFalse env
                encode_formula in
            (match uu____6697 with | (t,decls) -> (t, decls))
        | FStar_Syntax_Syntax.Tm_let
            ((false
              ,{ FStar_Syntax_Syntax.lbname = FStar_Util.Inl x;
                 FStar_Syntax_Syntax.lbunivs = uu____6705;
                 FStar_Syntax_Syntax.lbtyp = t1;
                 FStar_Syntax_Syntax.lbeff = uu____6707;
                 FStar_Syntax_Syntax.lbdef = e1;_}::[]),e2)
            ->
            let uu____6723 = encode_let x t1 e1 e2 env encode_formula in
            (match uu____6723 with | (t,decls) -> (t, decls))
        | FStar_Syntax_Syntax.Tm_app (head,args) ->
            let head = FStar_Syntax_Util.un_uinst head in
            (match ((head.FStar_Syntax_Syntax.n), args) with
             | (FStar_Syntax_Syntax.Tm_fvar
                fv,uu____6755::(x,uu____6757)::(t,uu____6759)::[]) when
                 FStar_Syntax_Syntax.fv_eq_lid fv
                   FStar_Syntax_Const.has_type_lid
                 ->
                 let uu____6793 = encode_term x env in
                 (match uu____6793 with
                  | (x,decls) ->
                      let uu____6800 = encode_term t env in
                      (match uu____6800 with
                       | (t,decls') ->
                           let uu____6807 =
                             FStar_SMTEncoding_Term.mk_HasType x t in
                           (uu____6807, (FStar_List.append decls decls'))))
             | (FStar_Syntax_Syntax.Tm_fvar
                fv,(r,uu____6811)::(msg,uu____6813)::(phi,uu____6815)::[])
                 when
                 FStar_Syntax_Syntax.fv_eq_lid fv
                   FStar_Syntax_Const.labeled_lid
                 ->
                 let uu____6849 =
                   let uu____6852 =
                     let uu____6853 = FStar_Syntax_Subst.compress r in
                     uu____6853.FStar_Syntax_Syntax.n in
                   let uu____6856 =
                     let uu____6857 = FStar_Syntax_Subst.compress msg in
                     uu____6857.FStar_Syntax_Syntax.n in
                   (uu____6852, uu____6856) in
                 (match uu____6849 with
                  | (FStar_Syntax_Syntax.Tm_constant (FStar_Const.Const_range
                     r),FStar_Syntax_Syntax.Tm_constant
                     (FStar_Const.Const_string (s,uu____6864))) ->
                      let phi =
                        (FStar_Syntax_Syntax.mk
                           (FStar_Syntax_Syntax.Tm_meta
                              (phi,
                                (FStar_Syntax_Syntax.Meta_labeled
                                   ((FStar_Util.string_of_unicode s), r,
                                     false))))) None r in
                      fallback phi
                  | uu____6880 -> fallback phi)
             | uu____6883 when head_redex env head ->
                 let uu____6891 = whnf env phi in
                 encode_formula uu____6891 env
             | uu____6892 ->
                 let uu____6900 = encode_term phi env in
                 (match uu____6900 with
                  | (tt,decls) ->
                      let uu____6907 =
                        FStar_SMTEncoding_Term.mk_Valid
                          (let uu___147_6908 = tt in
                           {
                             FStar_SMTEncoding_Term.tm =
                               (uu___147_6908.FStar_SMTEncoding_Term.tm);
                             FStar_SMTEncoding_Term.freevars =
                               (uu___147_6908.FStar_SMTEncoding_Term.freevars);
                             FStar_SMTEncoding_Term.rng =
                               (phi.FStar_Syntax_Syntax.pos)
                           }) in
                      (uu____6907, decls)))
        | uu____6911 ->
            let uu____6912 = encode_term phi env in
            (match uu____6912 with
             | (tt,decls) ->
                 let uu____6919 =
                   FStar_SMTEncoding_Term.mk_Valid
                     (let uu___148_6920 = tt in
                      {
                        FStar_SMTEncoding_Term.tm =
                          (uu___148_6920.FStar_SMTEncoding_Term.tm);
                        FStar_SMTEncoding_Term.freevars =
                          (uu___148_6920.FStar_SMTEncoding_Term.freevars);
                        FStar_SMTEncoding_Term.rng =
                          (phi.FStar_Syntax_Syntax.pos)
                      }) in
                 (uu____6919, decls)) in
      let encode_q_body env bs ps body =
        let uu____6947 = encode_binders None bs env in
        match uu____6947 with
        | (vars,guards,env,decls,uu____6969) ->
            let uu____6976 =
              let uu____6983 =
                FStar_All.pipe_right ps
                  (FStar_List.map
                     (fun p  ->
                        let uu____7006 =
                          let uu____7011 =
                            FStar_All.pipe_right p
                              (FStar_List.map
                                 (fun uu____7025  ->
                                    match uu____7025 with
                                    | (t,uu____7031) ->
                                        encode_term t
                                          (let uu___149_7032 = env in
                                           {
                                             bindings =
                                               (uu___149_7032.bindings);
                                             depth = (uu___149_7032.depth);
                                             tcenv = (uu___149_7032.tcenv);
                                             warn = (uu___149_7032.warn);
                                             cache = (uu___149_7032.cache);
                                             nolabels =
                                               (uu___149_7032.nolabels);
                                             use_zfuel_name = true;
                                             encode_non_total_function_typ =
                                               (uu___149_7032.encode_non_total_function_typ)
                                           }))) in
                          FStar_All.pipe_right uu____7011 FStar_List.unzip in
                        match uu____7006 with
                        | (p,decls) -> (p, (FStar_List.flatten decls)))) in
              FStar_All.pipe_right uu____6983 FStar_List.unzip in
            (match uu____6976 with
             | (pats,decls') ->
                 let uu____7084 = encode_formula body env in
                 (match uu____7084 with
                  | (body,decls'') ->
                      let guards =
                        match pats with
                        | ({
                             FStar_SMTEncoding_Term.tm =
                               FStar_SMTEncoding_Term.App
                               (FStar_SMTEncoding_Term.Var gf,p::[]);
                             FStar_SMTEncoding_Term.freevars = uu____7103;
                             FStar_SMTEncoding_Term.rng = uu____7104;_}::[])::[]
                            when
                            (FStar_Ident.text_of_lid
                               FStar_Syntax_Const.guard_free)
                              = gf
                            -> []
                        | uu____7112 -> guards in
                      let uu____7115 = FStar_SMTEncoding_Util.mk_and_l guards in
                      (vars, pats, uu____7115, body,
                        (FStar_List.append decls
                           (FStar_List.append (FStar_List.flatten decls')
                              decls''))))) in
      debug phi;
      (let phi = FStar_Syntax_Util.unascribe phi in
       let check_pattern_vars vars pats =
         let pats =
           FStar_All.pipe_right pats
             (FStar_List.map
                (fun uu____7149  ->
                   match uu____7149 with
                   | (x,uu____7153) ->
                       FStar_TypeChecker_Normalize.normalize
                         [FStar_TypeChecker_Normalize.Beta;
                         FStar_TypeChecker_Normalize.AllowUnboundUniverses;
                         FStar_TypeChecker_Normalize.EraseUniverses]
                         env.tcenv x)) in
         match pats with
         | [] -> ()
         | hd::tl ->
             let pat_vars =
               let uu____7159 = FStar_Syntax_Free.names hd in
               FStar_List.fold_left
                 (fun out  ->
                    fun x  ->
                      let uu____7165 = FStar_Syntax_Free.names x in
                      FStar_Util.set_union out uu____7165) uu____7159 tl in
             let uu____7167 =
               FStar_All.pipe_right vars
                 (FStar_Util.find_opt
                    (fun uu____7179  ->
                       match uu____7179 with
                       | (b,uu____7183) ->
                           let uu____7184 = FStar_Util.set_mem b pat_vars in
                           Prims.op_Negation uu____7184)) in
             (match uu____7167 with
              | None  -> ()
              | Some (x,uu____7188) ->
                  let pos =
                    FStar_List.fold_left
                      (fun out  ->
                         fun t  ->
                           FStar_Range.union_ranges out
                             t.FStar_Syntax_Syntax.pos)
                      hd.FStar_Syntax_Syntax.pos tl in
                  let uu____7198 =
                    let uu____7199 = FStar_Syntax_Print.bv_to_string x in
                    FStar_Util.format1
                      "SMT pattern misses at least one bound variable: %s"
                      uu____7199 in
                  FStar_Errors.warn pos uu____7198) in
       let uu____7200 = FStar_Syntax_Util.destruct_typ_as_formula phi in
       match uu____7200 with
       | None  -> fallback phi
       | Some (FStar_Syntax_Util.BaseConn (op,arms)) ->
           let uu____7206 =
             FStar_All.pipe_right connectives
               (FStar_List.tryFind
                  (fun uu____7242  ->
                     match uu____7242 with
                     | (l,uu____7252) -> FStar_Ident.lid_equals op l)) in
           (match uu____7206 with
            | None  -> fallback phi
            | Some (uu____7275,f) -> f phi.FStar_Syntax_Syntax.pos arms)
       | Some (FStar_Syntax_Util.QAll (vars,pats,body)) ->
           (FStar_All.pipe_right pats
              (FStar_List.iter (check_pattern_vars vars));
            (let uu____7304 = encode_q_body env vars pats body in
             match uu____7304 with
             | (vars,pats,guard,body,decls) ->
                 let tm =
                   let uu____7330 =
                     let uu____7336 =
                       FStar_SMTEncoding_Util.mkImp (guard, body) in
                     (pats, vars, uu____7336) in
                   FStar_SMTEncoding_Term.mkForall uu____7330
                     phi.FStar_Syntax_Syntax.pos in
                 (tm, decls)))
       | Some (FStar_Syntax_Util.QEx (vars,pats,body)) ->
           (FStar_All.pipe_right pats
              (FStar_List.iter (check_pattern_vars vars));
            (let uu____7348 = encode_q_body env vars pats body in
             match uu____7348 with
             | (vars,pats,guard,body,decls) ->
                 let uu____7373 =
                   let uu____7374 =
                     let uu____7380 =
                       FStar_SMTEncoding_Util.mkAnd (guard, body) in
                     (pats, vars, uu____7380) in
                   FStar_SMTEncoding_Term.mkExists uu____7374
                     phi.FStar_Syntax_Syntax.pos in
                 (uu____7373, decls))))
type prims_t =
  {
  mk:
    FStar_Ident.lident ->
      Prims.string ->
        (FStar_SMTEncoding_Term.term* FStar_SMTEncoding_Term.decl Prims.list);
  is: FStar_Ident.lident -> Prims.bool;}
let prims: prims_t =
  let uu____7429 = fresh_fvar "a" FStar_SMTEncoding_Term.Term_sort in
  match uu____7429 with
  | (asym,a) ->
      let uu____7434 = fresh_fvar "x" FStar_SMTEncoding_Term.Term_sort in
      (match uu____7434 with
       | (xsym,x) ->
           let uu____7439 = fresh_fvar "y" FStar_SMTEncoding_Term.Term_sort in
           (match uu____7439 with
            | (ysym,y) ->
                let quant vars body x =
                  let xname_decl =
                    let uu____7469 =
                      let uu____7475 =
                        FStar_All.pipe_right vars (FStar_List.map Prims.snd) in
                      (x, uu____7475, FStar_SMTEncoding_Term.Term_sort, None) in
                    FStar_SMTEncoding_Term.DeclFun uu____7469 in
                  let xtok = Prims.strcat x "@tok" in
                  let xtok_decl =
                    FStar_SMTEncoding_Term.DeclFun
                      (xtok, [], FStar_SMTEncoding_Term.Term_sort, None) in
                  let xapp =
                    let uu____7490 =
                      let uu____7494 =
                        FStar_List.map FStar_SMTEncoding_Util.mkFreeV vars in
                      (x, uu____7494) in
                    FStar_SMTEncoding_Util.mkApp uu____7490 in
                  let xtok = FStar_SMTEncoding_Util.mkApp (xtok, []) in
                  let xtok_app = mk_Apply xtok vars in
                  let uu____7502 =
                    let uu____7504 =
                      let uu____7506 =
                        let uu____7508 =
                          let uu____7509 =
                            let uu____7514 =
                              let uu____7515 =
                                let uu____7521 =
                                  FStar_SMTEncoding_Util.mkEq (xapp, body) in
                                ([[xapp]], vars, uu____7521) in
                              FStar_SMTEncoding_Util.mkForall uu____7515 in
                            (uu____7514, None,
                              (Some (Prims.strcat "primitive_" x))) in
                          FStar_SMTEncoding_Term.Assume uu____7509 in
                        let uu____7531 =
                          let uu____7533 =
                            let uu____7534 =
                              let uu____7539 =
                                let uu____7540 =
                                  let uu____7546 =
                                    FStar_SMTEncoding_Util.mkEq
                                      (xtok_app, xapp) in
                                  ([[xtok_app]], vars, uu____7546) in
                                FStar_SMTEncoding_Util.mkForall uu____7540 in
                              (uu____7539,
                                (Some "Name-token correspondence"),
                                (Some
                                   (Prims.strcat "token_correspondence_" x))) in
                            FStar_SMTEncoding_Term.Assume uu____7534 in
                          [uu____7533] in
                        uu____7508 :: uu____7531 in
                      xtok_decl :: uu____7506 in
                    xname_decl :: uu____7504 in
                  (xtok, uu____7502) in
                let axy =
                  [(asym, FStar_SMTEncoding_Term.Term_sort);
                  (xsym, FStar_SMTEncoding_Term.Term_sort);
                  (ysym, FStar_SMTEncoding_Term.Term_sort)] in
                let xy =
                  [(xsym, FStar_SMTEncoding_Term.Term_sort);
                  (ysym, FStar_SMTEncoding_Term.Term_sort)] in
                let qx = [(xsym, FStar_SMTEncoding_Term.Term_sort)] in
                let prims =
                  let uu____7596 =
                    let uu____7604 =
                      let uu____7610 =
                        let uu____7611 = FStar_SMTEncoding_Util.mkEq (x, y) in
                        FStar_All.pipe_left FStar_SMTEncoding_Term.boxBool
                          uu____7611 in
                      quant axy uu____7610 in
                    (FStar_Syntax_Const.op_Eq, uu____7604) in
                  let uu____7617 =
                    let uu____7626 =
                      let uu____7634 =
                        let uu____7640 =
                          let uu____7641 =
                            let uu____7642 =
                              FStar_SMTEncoding_Util.mkEq (x, y) in
                            FStar_SMTEncoding_Util.mkNot uu____7642 in
                          FStar_All.pipe_left FStar_SMTEncoding_Term.boxBool
                            uu____7641 in
                        quant axy uu____7640 in
                      (FStar_Syntax_Const.op_notEq, uu____7634) in
                    let uu____7648 =
                      let uu____7657 =
                        let uu____7665 =
                          let uu____7671 =
                            let uu____7672 =
                              let uu____7673 =
                                let uu____7676 =
                                  FStar_SMTEncoding_Term.unboxInt x in
                                let uu____7677 =
                                  FStar_SMTEncoding_Term.unboxInt y in
                                (uu____7676, uu____7677) in
                              FStar_SMTEncoding_Util.mkLT uu____7673 in
                            FStar_All.pipe_left
                              FStar_SMTEncoding_Term.boxBool uu____7672 in
                          quant xy uu____7671 in
                        (FStar_Syntax_Const.op_LT, uu____7665) in
                      let uu____7683 =
                        let uu____7692 =
                          let uu____7700 =
                            let uu____7706 =
                              let uu____7707 =
                                let uu____7708 =
                                  let uu____7711 =
                                    FStar_SMTEncoding_Term.unboxInt x in
                                  let uu____7712 =
                                    FStar_SMTEncoding_Term.unboxInt y in
                                  (uu____7711, uu____7712) in
                                FStar_SMTEncoding_Util.mkLTE uu____7708 in
                              FStar_All.pipe_left
                                FStar_SMTEncoding_Term.boxBool uu____7707 in
                            quant xy uu____7706 in
                          (FStar_Syntax_Const.op_LTE, uu____7700) in
                        let uu____7718 =
                          let uu____7727 =
                            let uu____7735 =
                              let uu____7741 =
                                let uu____7742 =
                                  let uu____7743 =
                                    let uu____7746 =
                                      FStar_SMTEncoding_Term.unboxInt x in
                                    let uu____7747 =
                                      FStar_SMTEncoding_Term.unboxInt y in
                                    (uu____7746, uu____7747) in
                                  FStar_SMTEncoding_Util.mkGT uu____7743 in
                                FStar_All.pipe_left
                                  FStar_SMTEncoding_Term.boxBool uu____7742 in
                              quant xy uu____7741 in
                            (FStar_Syntax_Const.op_GT, uu____7735) in
                          let uu____7753 =
                            let uu____7762 =
                              let uu____7770 =
                                let uu____7776 =
                                  let uu____7777 =
                                    let uu____7778 =
                                      let uu____7781 =
                                        FStar_SMTEncoding_Term.unboxInt x in
                                      let uu____7782 =
                                        FStar_SMTEncoding_Term.unboxInt y in
                                      (uu____7781, uu____7782) in
                                    FStar_SMTEncoding_Util.mkGTE uu____7778 in
                                  FStar_All.pipe_left
                                    FStar_SMTEncoding_Term.boxBool uu____7777 in
                                quant xy uu____7776 in
                              (FStar_Syntax_Const.op_GTE, uu____7770) in
                            let uu____7788 =
                              let uu____7797 =
                                let uu____7805 =
                                  let uu____7811 =
                                    let uu____7812 =
                                      let uu____7813 =
                                        let uu____7816 =
                                          FStar_SMTEncoding_Term.unboxInt x in
                                        let uu____7817 =
                                          FStar_SMTEncoding_Term.unboxInt y in
                                        (uu____7816, uu____7817) in
                                      FStar_SMTEncoding_Util.mkSub uu____7813 in
                                    FStar_All.pipe_left
                                      FStar_SMTEncoding_Term.boxInt
                                      uu____7812 in
                                  quant xy uu____7811 in
                                (FStar_Syntax_Const.op_Subtraction,
                                  uu____7805) in
                              let uu____7823 =
                                let uu____7832 =
                                  let uu____7840 =
                                    let uu____7846 =
                                      let uu____7847 =
                                        let uu____7848 =
                                          FStar_SMTEncoding_Term.unboxInt x in
                                        FStar_SMTEncoding_Util.mkMinus
                                          uu____7848 in
                                      FStar_All.pipe_left
                                        FStar_SMTEncoding_Term.boxInt
                                        uu____7847 in
                                    quant qx uu____7846 in
                                  (FStar_Syntax_Const.op_Minus, uu____7840) in
                                let uu____7854 =
                                  let uu____7863 =
                                    let uu____7871 =
                                      let uu____7877 =
                                        let uu____7878 =
                                          let uu____7879 =
                                            let uu____7882 =
                                              FStar_SMTEncoding_Term.unboxInt
                                                x in
                                            let uu____7883 =
                                              FStar_SMTEncoding_Term.unboxInt
                                                y in
                                            (uu____7882, uu____7883) in
                                          FStar_SMTEncoding_Util.mkAdd
                                            uu____7879 in
                                        FStar_All.pipe_left
                                          FStar_SMTEncoding_Term.boxInt
                                          uu____7878 in
                                      quant xy uu____7877 in
                                    (FStar_Syntax_Const.op_Addition,
                                      uu____7871) in
                                  let uu____7889 =
                                    let uu____7898 =
                                      let uu____7906 =
                                        let uu____7912 =
                                          let uu____7913 =
                                            let uu____7914 =
                                              let uu____7917 =
                                                FStar_SMTEncoding_Term.unboxInt
                                                  x in
                                              let uu____7918 =
                                                FStar_SMTEncoding_Term.unboxInt
                                                  y in
                                              (uu____7917, uu____7918) in
                                            FStar_SMTEncoding_Util.mkMul
                                              uu____7914 in
                                          FStar_All.pipe_left
                                            FStar_SMTEncoding_Term.boxInt
                                            uu____7913 in
                                        quant xy uu____7912 in
                                      (FStar_Syntax_Const.op_Multiply,
                                        uu____7906) in
                                    let uu____7924 =
                                      let uu____7933 =
                                        let uu____7941 =
                                          let uu____7947 =
                                            let uu____7948 =
                                              let uu____7949 =
                                                let uu____7952 =
                                                  FStar_SMTEncoding_Term.unboxInt
                                                    x in
                                                let uu____7953 =
                                                  FStar_SMTEncoding_Term.unboxInt
                                                    y in
                                                (uu____7952, uu____7953) in
                                              FStar_SMTEncoding_Util.mkDiv
                                                uu____7949 in
                                            FStar_All.pipe_left
                                              FStar_SMTEncoding_Term.boxInt
                                              uu____7948 in
                                          quant xy uu____7947 in
                                        (FStar_Syntax_Const.op_Division,
                                          uu____7941) in
                                      let uu____7959 =
                                        let uu____7968 =
                                          let uu____7976 =
                                            let uu____7982 =
                                              let uu____7983 =
                                                let uu____7984 =
                                                  let uu____7987 =
                                                    FStar_SMTEncoding_Term.unboxInt
                                                      x in
                                                  let uu____7988 =
                                                    FStar_SMTEncoding_Term.unboxInt
                                                      y in
                                                  (uu____7987, uu____7988) in
                                                FStar_SMTEncoding_Util.mkMod
                                                  uu____7984 in
                                              FStar_All.pipe_left
                                                FStar_SMTEncoding_Term.boxInt
                                                uu____7983 in
                                            quant xy uu____7982 in
                                          (FStar_Syntax_Const.op_Modulus,
                                            uu____7976) in
                                        let uu____7994 =
                                          let uu____8003 =
                                            let uu____8011 =
                                              let uu____8017 =
                                                let uu____8018 =
                                                  let uu____8019 =
                                                    let uu____8022 =
                                                      FStar_SMTEncoding_Term.unboxBool
                                                        x in
                                                    let uu____8023 =
                                                      FStar_SMTEncoding_Term.unboxBool
                                                        y in
                                                    (uu____8022, uu____8023) in
                                                  FStar_SMTEncoding_Util.mkAnd
                                                    uu____8019 in
                                                FStar_All.pipe_left
                                                  FStar_SMTEncoding_Term.boxBool
                                                  uu____8018 in
                                              quant xy uu____8017 in
                                            (FStar_Syntax_Const.op_And,
                                              uu____8011) in
                                          let uu____8029 =
                                            let uu____8038 =
                                              let uu____8046 =
                                                let uu____8052 =
                                                  let uu____8053 =
                                                    let uu____8054 =
                                                      let uu____8057 =
                                                        FStar_SMTEncoding_Term.unboxBool
                                                          x in
                                                      let uu____8058 =
                                                        FStar_SMTEncoding_Term.unboxBool
                                                          y in
                                                      (uu____8057,
                                                        uu____8058) in
                                                    FStar_SMTEncoding_Util.mkOr
                                                      uu____8054 in
                                                  FStar_All.pipe_left
                                                    FStar_SMTEncoding_Term.boxBool
                                                    uu____8053 in
                                                quant xy uu____8052 in
                                              (FStar_Syntax_Const.op_Or,
                                                uu____8046) in
                                            let uu____8064 =
                                              let uu____8073 =
                                                let uu____8081 =
                                                  let uu____8087 =
                                                    let uu____8088 =
                                                      let uu____8089 =
                                                        FStar_SMTEncoding_Term.unboxBool
                                                          x in
                                                      FStar_SMTEncoding_Util.mkNot
                                                        uu____8089 in
                                                    FStar_All.pipe_left
                                                      FStar_SMTEncoding_Term.boxBool
                                                      uu____8088 in
                                                  quant qx uu____8087 in
                                                (FStar_Syntax_Const.op_Negation,
                                                  uu____8081) in
                                              [uu____8073] in
                                            uu____8038 :: uu____8064 in
                                          uu____8003 :: uu____8029 in
                                        uu____7968 :: uu____7994 in
                                      uu____7933 :: uu____7959 in
                                    uu____7898 :: uu____7924 in
                                  uu____7863 :: uu____7889 in
                                uu____7832 :: uu____7854 in
                              uu____7797 :: uu____7823 in
                            uu____7762 :: uu____7788 in
                          uu____7727 :: uu____7753 in
                        uu____7692 :: uu____7718 in
                      uu____7657 :: uu____7683 in
                    uu____7626 :: uu____7648 in
                  uu____7596 :: uu____7617 in
                let mk l v =
                  let uu____8217 =
                    let uu____8222 =
                      FStar_All.pipe_right prims
                        (FStar_List.find
                           (fun uu____8254  ->
                              match uu____8254 with
                              | (l',uu____8263) ->
                                  FStar_Ident.lid_equals l l')) in
                    FStar_All.pipe_right uu____8222
                      (FStar_Option.map
                         (fun uu____8296  ->
                            match uu____8296 with | (uu____8307,b) -> b v)) in
                  FStar_All.pipe_right uu____8217 FStar_Option.get in
                let is l =
                  FStar_All.pipe_right prims
                    (FStar_Util.for_some
                       (fun uu____8348  ->
                          match uu____8348 with
                          | (l',uu____8357) -> FStar_Ident.lid_equals l l')) in
                { mk; is }))
let pretype_axiom:
  FStar_SMTEncoding_Term.term ->
    (Prims.string* FStar_SMTEncoding_Term.sort) Prims.list ->
      FStar_SMTEncoding_Term.decl
  =
  fun tapp  ->
    fun vars  ->
      let uu____8380 = fresh_fvar "x" FStar_SMTEncoding_Term.Term_sort in
      match uu____8380 with
      | (xxsym,xx) ->
          let uu____8385 = fresh_fvar "f" FStar_SMTEncoding_Term.Fuel_sort in
          (match uu____8385 with
           | (ffsym,ff) ->
               let xx_has_type =
                 FStar_SMTEncoding_Term.mk_HasTypeFuel ff xx tapp in
               let tapp_hash = FStar_SMTEncoding_Term.hash_of_term tapp in
               let uu____8392 =
                 let uu____8397 =
                   let uu____8398 =
                     let uu____8404 =
                       let uu____8405 =
                         let uu____8408 =
                           let uu____8409 =
                             let uu____8412 =
                               FStar_SMTEncoding_Util.mkApp ("PreType", [xx]) in
                             (tapp, uu____8412) in
                           FStar_SMTEncoding_Util.mkEq uu____8409 in
                         (xx_has_type, uu____8408) in
                       FStar_SMTEncoding_Util.mkImp uu____8405 in
                     ([[xx_has_type]],
                       ((xxsym, FStar_SMTEncoding_Term.Term_sort) ::
                       (ffsym, FStar_SMTEncoding_Term.Fuel_sort) :: vars),
                       uu____8404) in
                   FStar_SMTEncoding_Util.mkForall uu____8398 in
                 let uu____8425 =
                   let uu____8427 =
                     let uu____8428 =
                       let uu____8429 = FStar_Util.digest_of_string tapp_hash in
                       Prims.strcat "pretyping_" uu____8429 in
                     varops.mk_unique uu____8428 in
                   Some uu____8427 in
                 (uu____8397, (Some "pretyping"), uu____8425) in
               FStar_SMTEncoding_Term.Assume uu____8392)
let primitive_type_axioms:
  FStar_TypeChecker_Env.env ->
    FStar_Ident.lident ->
      Prims.string ->
        FStar_SMTEncoding_Term.term -> FStar_SMTEncoding_Term.decl Prims.list
  =
  let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
  let x = FStar_SMTEncoding_Util.mkFreeV xx in
  let yy = ("y", FStar_SMTEncoding_Term.Term_sort) in
  let y = FStar_SMTEncoding_Util.mkFreeV yy in
  let mk_unit env nm tt =
    let typing_pred = FStar_SMTEncoding_Term.mk_HasType x tt in
    let uu____8460 =
      let uu____8461 =
        let uu____8466 =
          FStar_SMTEncoding_Term.mk_HasType
            FStar_SMTEncoding_Term.mk_Term_unit tt in
        (uu____8466, (Some "unit typing"), (Some "unit_typing")) in
      FStar_SMTEncoding_Term.Assume uu____8461 in
    let uu____8469 =
      let uu____8471 =
        let uu____8472 =
          let uu____8477 =
            let uu____8478 =
              let uu____8484 =
                let uu____8485 =
                  let uu____8488 =
                    FStar_SMTEncoding_Util.mkEq
                      (x, FStar_SMTEncoding_Term.mk_Term_unit) in
                  (typing_pred, uu____8488) in
                FStar_SMTEncoding_Util.mkImp uu____8485 in
              ([[typing_pred]], [xx], uu____8484) in
            mkForall_fuel uu____8478 in
          (uu____8477, (Some "unit inversion"), (Some "unit_inversion")) in
        FStar_SMTEncoding_Term.Assume uu____8472 in
      [uu____8471] in
    uu____8460 :: uu____8469 in
  let mk_bool env nm tt =
    let typing_pred = FStar_SMTEncoding_Term.mk_HasType x tt in
    let bb = ("b", FStar_SMTEncoding_Term.Bool_sort) in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let uu____8517 =
      let uu____8518 =
        let uu____8523 =
          let uu____8524 =
            let uu____8530 =
              let uu____8533 =
                let uu____8535 = FStar_SMTEncoding_Term.boxBool b in
                [uu____8535] in
              [uu____8533] in
            let uu____8538 =
              let uu____8539 = FStar_SMTEncoding_Term.boxBool b in
              FStar_SMTEncoding_Term.mk_HasType uu____8539 tt in
            (uu____8530, [bb], uu____8538) in
          FStar_SMTEncoding_Util.mkForall uu____8524 in
        (uu____8523, (Some "bool typing"), (Some "bool_typing")) in
      FStar_SMTEncoding_Term.Assume uu____8518 in
    let uu____8551 =
      let uu____8553 =
        let uu____8554 =
          let uu____8559 =
            let uu____8560 =
              let uu____8566 =
                let uu____8567 =
                  let uu____8570 =
                    FStar_SMTEncoding_Term.mk_tester "BoxBool" x in
                  (typing_pred, uu____8570) in
                FStar_SMTEncoding_Util.mkImp uu____8567 in
              ([[typing_pred]], [xx], uu____8566) in
            mkForall_fuel uu____8560 in
          (uu____8559, (Some "bool inversion"), (Some "bool_inversion")) in
        FStar_SMTEncoding_Term.Assume uu____8554 in
      [uu____8553] in
    uu____8517 :: uu____8551 in
  let mk_int env nm tt =
    let typing_pred = FStar_SMTEncoding_Term.mk_HasType x tt in
    let typing_pred_y = FStar_SMTEncoding_Term.mk_HasType y tt in
    let aa = ("a", FStar_SMTEncoding_Term.Int_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let bb = ("b", FStar_SMTEncoding_Term.Int_sort) in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let precedes =
      let uu____8605 =
        let uu____8606 =
          let uu____8610 =
            let uu____8612 =
              let uu____8614 =
                let uu____8616 = FStar_SMTEncoding_Term.boxInt a in
                let uu____8617 =
                  let uu____8619 = FStar_SMTEncoding_Term.boxInt b in
                  [uu____8619] in
                uu____8616 :: uu____8617 in
              tt :: uu____8614 in
            tt :: uu____8612 in
          ("Prims.Precedes", uu____8610) in
        FStar_SMTEncoding_Util.mkApp uu____8606 in
      FStar_All.pipe_left FStar_SMTEncoding_Term.mk_Valid uu____8605 in
    let precedes_y_x =
      let uu____8622 = FStar_SMTEncoding_Util.mkApp ("Precedes", [y; x]) in
      FStar_All.pipe_left FStar_SMTEncoding_Term.mk_Valid uu____8622 in
    let uu____8624 =
      let uu____8625 =
        let uu____8630 =
          let uu____8631 =
            let uu____8637 =
              let uu____8640 =
                let uu____8642 = FStar_SMTEncoding_Term.boxInt b in
                [uu____8642] in
              [uu____8640] in
            let uu____8645 =
              let uu____8646 = FStar_SMTEncoding_Term.boxInt b in
              FStar_SMTEncoding_Term.mk_HasType uu____8646 tt in
            (uu____8637, [bb], uu____8645) in
          FStar_SMTEncoding_Util.mkForall uu____8631 in
        (uu____8630, (Some "int typing"), (Some "int_typing")) in
      FStar_SMTEncoding_Term.Assume uu____8625 in
    let uu____8658 =
      let uu____8660 =
        let uu____8661 =
          let uu____8666 =
            let uu____8667 =
              let uu____8673 =
                let uu____8674 =
                  let uu____8677 =
                    FStar_SMTEncoding_Term.mk_tester "BoxInt" x in
                  (typing_pred, uu____8677) in
                FStar_SMTEncoding_Util.mkImp uu____8674 in
              ([[typing_pred]], [xx], uu____8673) in
            mkForall_fuel uu____8667 in
          (uu____8666, (Some "int inversion"), (Some "int_inversion")) in
        FStar_SMTEncoding_Term.Assume uu____8661 in
      let uu____8691 =
        let uu____8693 =
          let uu____8694 =
            let uu____8699 =
              let uu____8700 =
                let uu____8706 =
                  let uu____8707 =
                    let uu____8710 =
                      let uu____8711 =
                        let uu____8713 =
                          let uu____8715 =
                            let uu____8717 =
                              let uu____8718 =
                                let uu____8721 =
                                  FStar_SMTEncoding_Term.unboxInt x in
                                let uu____8722 =
                                  FStar_SMTEncoding_Util.mkInteger'
                                    (Prims.parse_int "0") in
                                (uu____8721, uu____8722) in
                              FStar_SMTEncoding_Util.mkGT uu____8718 in
                            let uu____8723 =
                              let uu____8725 =
                                let uu____8726 =
                                  let uu____8729 =
                                    FStar_SMTEncoding_Term.unboxInt y in
                                  let uu____8730 =
                                    FStar_SMTEncoding_Util.mkInteger'
                                      (Prims.parse_int "0") in
                                  (uu____8729, uu____8730) in
                                FStar_SMTEncoding_Util.mkGTE uu____8726 in
                              let uu____8731 =
                                let uu____8733 =
                                  let uu____8734 =
                                    let uu____8737 =
                                      FStar_SMTEncoding_Term.unboxInt y in
                                    let uu____8738 =
                                      FStar_SMTEncoding_Term.unboxInt x in
                                    (uu____8737, uu____8738) in
                                  FStar_SMTEncoding_Util.mkLT uu____8734 in
                                [uu____8733] in
                              uu____8725 :: uu____8731 in
                            uu____8717 :: uu____8723 in
                          typing_pred_y :: uu____8715 in
                        typing_pred :: uu____8713 in
                      FStar_SMTEncoding_Util.mk_and_l uu____8711 in
                    (uu____8710, precedes_y_x) in
                  FStar_SMTEncoding_Util.mkImp uu____8707 in
                ([[typing_pred; typing_pred_y; precedes_y_x]], [xx; yy],
                  uu____8706) in
              mkForall_fuel uu____8700 in
            (uu____8699, (Some "well-founded ordering on nat (alt)"),
              (Some "well-founded-ordering-on-nat")) in
          FStar_SMTEncoding_Term.Assume uu____8694 in
        [uu____8693] in
      uu____8660 :: uu____8691 in
    uu____8624 :: uu____8658 in
  let mk_str env nm tt =
    let typing_pred = FStar_SMTEncoding_Term.mk_HasType x tt in
    let bb = ("b", FStar_SMTEncoding_Term.String_sort) in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let uu____8769 =
      let uu____8770 =
        let uu____8775 =
          let uu____8776 =
            let uu____8782 =
              let uu____8785 =
                let uu____8787 = FStar_SMTEncoding_Term.boxString b in
                [uu____8787] in
              [uu____8785] in
            let uu____8790 =
              let uu____8791 = FStar_SMTEncoding_Term.boxString b in
              FStar_SMTEncoding_Term.mk_HasType uu____8791 tt in
            (uu____8782, [bb], uu____8790) in
          FStar_SMTEncoding_Util.mkForall uu____8776 in
        (uu____8775, (Some "string typing"), (Some "string_typing")) in
      FStar_SMTEncoding_Term.Assume uu____8770 in
    let uu____8803 =
      let uu____8805 =
        let uu____8806 =
          let uu____8811 =
            let uu____8812 =
              let uu____8818 =
                let uu____8819 =
                  let uu____8822 =
                    FStar_SMTEncoding_Term.mk_tester "BoxString" x in
                  (typing_pred, uu____8822) in
                FStar_SMTEncoding_Util.mkImp uu____8819 in
              ([[typing_pred]], [xx], uu____8818) in
            mkForall_fuel uu____8812 in
          (uu____8811, (Some "string inversion"), (Some "string_inversion")) in
        FStar_SMTEncoding_Term.Assume uu____8806 in
      [uu____8805] in
    uu____8769 :: uu____8803 in
  let mk_ref env reft_name uu____8845 =
    let r = ("r", FStar_SMTEncoding_Term.Ref_sort) in
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let refa =
      let uu____8856 =
        let uu____8860 =
          let uu____8862 = FStar_SMTEncoding_Util.mkFreeV aa in [uu____8862] in
        (reft_name, uu____8860) in
      FStar_SMTEncoding_Util.mkApp uu____8856 in
    let refb =
      let uu____8865 =
        let uu____8869 =
          let uu____8871 = FStar_SMTEncoding_Util.mkFreeV bb in [uu____8871] in
        (reft_name, uu____8869) in
      FStar_SMTEncoding_Util.mkApp uu____8865 in
    let typing_pred = FStar_SMTEncoding_Term.mk_HasType x refa in
    let typing_pred_b = FStar_SMTEncoding_Term.mk_HasType x refb in
    let uu____8875 =
      let uu____8876 =
        let uu____8881 =
          let uu____8882 =
            let uu____8888 =
              let uu____8889 =
                let uu____8892 = FStar_SMTEncoding_Term.mk_tester "BoxRef" x in
                (typing_pred, uu____8892) in
              FStar_SMTEncoding_Util.mkImp uu____8889 in
            ([[typing_pred]], [xx; aa], uu____8888) in
          mkForall_fuel uu____8882 in
        (uu____8881, (Some "ref inversion"), (Some "ref_inversion")) in
      FStar_SMTEncoding_Term.Assume uu____8876 in
    let uu____8908 =
      let uu____8910 =
        let uu____8911 =
          let uu____8916 =
            let uu____8917 =
              let uu____8923 =
                let uu____8924 =
                  let uu____8927 =
                    FStar_SMTEncoding_Util.mkAnd (typing_pred, typing_pred_b) in
                  let uu____8928 =
                    let uu____8929 =
                      let uu____8932 = FStar_SMTEncoding_Util.mkFreeV aa in
                      let uu____8933 = FStar_SMTEncoding_Util.mkFreeV bb in
                      (uu____8932, uu____8933) in
                    FStar_SMTEncoding_Util.mkEq uu____8929 in
                  (uu____8927, uu____8928) in
                FStar_SMTEncoding_Util.mkImp uu____8924 in
              ([[typing_pred; typing_pred_b]], [xx; aa; bb], uu____8923) in
            mkForall_fuel' (Prims.parse_int "2") uu____8917 in
          (uu____8916, (Some "ref typing is injective"),
            (Some "ref_injectivity")) in
        FStar_SMTEncoding_Term.Assume uu____8911 in
      [uu____8910] in
    uu____8875 :: uu____8908 in
  let mk_true_interp env nm true_tm =
    let valid = FStar_SMTEncoding_Util.mkApp ("Valid", [true_tm]) in
    [FStar_SMTEncoding_Term.Assume
       (valid, (Some "True interpretation"), (Some "true_interp"))] in
  let mk_false_interp env nm false_tm =
    let valid = FStar_SMTEncoding_Util.mkApp ("Valid", [false_tm]) in
    let uu____8977 =
      let uu____8978 =
        let uu____8983 =
          FStar_SMTEncoding_Util.mkIff
            (FStar_SMTEncoding_Util.mkFalse, valid) in
        (uu____8983, (Some "False interpretation"), (Some "false_interp")) in
      FStar_SMTEncoding_Term.Assume uu____8978 in
    [uu____8977] in
  let mk_and_interp env conj uu____8995 =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let valid =
      let uu____9005 =
        let uu____9009 =
          let uu____9011 = FStar_SMTEncoding_Util.mkApp (conj, [a; b]) in
          [uu____9011] in
        ("Valid", uu____9009) in
      FStar_SMTEncoding_Util.mkApp uu____9005 in
    let valid_a = FStar_SMTEncoding_Util.mkApp ("Valid", [a]) in
    let valid_b = FStar_SMTEncoding_Util.mkApp ("Valid", [b]) in
    let uu____9018 =
      let uu____9019 =
        let uu____9024 =
          let uu____9025 =
            let uu____9031 =
              let uu____9032 =
                let uu____9035 =
                  FStar_SMTEncoding_Util.mkAnd (valid_a, valid_b) in
                (uu____9035, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9032 in
            ([[valid]], [aa; bb], uu____9031) in
          FStar_SMTEncoding_Util.mkForall uu____9025 in
        (uu____9024, (Some "/\\ interpretation"), (Some "l_and-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9019 in
    [uu____9018] in
  let mk_or_interp env disj uu____9060 =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let valid =
      let uu____9070 =
        let uu____9074 =
          let uu____9076 = FStar_SMTEncoding_Util.mkApp (disj, [a; b]) in
          [uu____9076] in
        ("Valid", uu____9074) in
      FStar_SMTEncoding_Util.mkApp uu____9070 in
    let valid_a = FStar_SMTEncoding_Util.mkApp ("Valid", [a]) in
    let valid_b = FStar_SMTEncoding_Util.mkApp ("Valid", [b]) in
    let uu____9083 =
      let uu____9084 =
        let uu____9089 =
          let uu____9090 =
            let uu____9096 =
              let uu____9097 =
                let uu____9100 =
                  FStar_SMTEncoding_Util.mkOr (valid_a, valid_b) in
                (uu____9100, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9097 in
            ([[valid]], [aa; bb], uu____9096) in
          FStar_SMTEncoding_Util.mkForall uu____9090 in
        (uu____9089, (Some "\\/ interpretation"), (Some "l_or-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9084 in
    [uu____9083] in
  let mk_eq2_interp env eq2 tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
    let yy = ("y", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let x = FStar_SMTEncoding_Util.mkFreeV xx in
    let y = FStar_SMTEncoding_Util.mkFreeV yy in
    let valid =
      let uu____9139 =
        let uu____9143 =
          let uu____9145 = FStar_SMTEncoding_Util.mkApp (eq2, [a; x; y]) in
          [uu____9145] in
        ("Valid", uu____9143) in
      FStar_SMTEncoding_Util.mkApp uu____9139 in
    let uu____9148 =
      let uu____9149 =
        let uu____9154 =
          let uu____9155 =
            let uu____9161 =
              let uu____9162 =
                let uu____9165 = FStar_SMTEncoding_Util.mkEq (x, y) in
                (uu____9165, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9162 in
            ([[valid]], [aa; xx; yy], uu____9161) in
          FStar_SMTEncoding_Util.mkForall uu____9155 in
        (uu____9154, (Some "Eq2 interpretation"), (Some "eq2-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9149 in
    [uu____9148] in
  let mk_eq3_interp env eq3 tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
    let yy = ("y", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let x = FStar_SMTEncoding_Util.mkFreeV xx in
    let y = FStar_SMTEncoding_Util.mkFreeV yy in
    let valid =
      let uu____9210 =
        let uu____9214 =
          let uu____9216 = FStar_SMTEncoding_Util.mkApp (eq3, [a; b; x; y]) in
          [uu____9216] in
        ("Valid", uu____9214) in
      FStar_SMTEncoding_Util.mkApp uu____9210 in
    let uu____9219 =
      let uu____9220 =
        let uu____9225 =
          let uu____9226 =
            let uu____9232 =
              let uu____9233 =
                let uu____9236 = FStar_SMTEncoding_Util.mkEq (x, y) in
                (uu____9236, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9233 in
            ([[valid]], [aa; bb; xx; yy], uu____9232) in
          FStar_SMTEncoding_Util.mkForall uu____9226 in
        (uu____9225, (Some "Eq3 interpretation"), (Some "eq3-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9220 in
    [uu____9219] in
  let mk_imp_interp env imp tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let valid =
      let uu____9275 =
        let uu____9279 =
          let uu____9281 = FStar_SMTEncoding_Util.mkApp (imp, [a; b]) in
          [uu____9281] in
        ("Valid", uu____9279) in
      FStar_SMTEncoding_Util.mkApp uu____9275 in
    let valid_a = FStar_SMTEncoding_Util.mkApp ("Valid", [a]) in
    let valid_b = FStar_SMTEncoding_Util.mkApp ("Valid", [b]) in
    let uu____9288 =
      let uu____9289 =
        let uu____9294 =
          let uu____9295 =
            let uu____9301 =
              let uu____9302 =
                let uu____9305 =
                  FStar_SMTEncoding_Util.mkImp (valid_a, valid_b) in
                (uu____9305, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9302 in
            ([[valid]], [aa; bb], uu____9301) in
          FStar_SMTEncoding_Util.mkForall uu____9295 in
        (uu____9294, (Some "==> interpretation"), (Some "l_imp-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9289 in
    [uu____9288] in
  let mk_iff_interp env iff tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let valid =
      let uu____9340 =
        let uu____9344 =
          let uu____9346 = FStar_SMTEncoding_Util.mkApp (iff, [a; b]) in
          [uu____9346] in
        ("Valid", uu____9344) in
      FStar_SMTEncoding_Util.mkApp uu____9340 in
    let valid_a = FStar_SMTEncoding_Util.mkApp ("Valid", [a]) in
    let valid_b = FStar_SMTEncoding_Util.mkApp ("Valid", [b]) in
    let uu____9353 =
      let uu____9354 =
        let uu____9359 =
          let uu____9360 =
            let uu____9366 =
              let uu____9367 =
                let uu____9370 =
                  FStar_SMTEncoding_Util.mkIff (valid_a, valid_b) in
                (uu____9370, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9367 in
            ([[valid]], [aa; bb], uu____9366) in
          FStar_SMTEncoding_Util.mkForall uu____9360 in
        (uu____9359, (Some "<==> interpretation"), (Some "l_iff-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9354 in
    [uu____9353] in
  let mk_not_interp env l_not tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let valid =
      let uu____9401 =
        let uu____9405 =
          let uu____9407 = FStar_SMTEncoding_Util.mkApp (l_not, [a]) in
          [uu____9407] in
        ("Valid", uu____9405) in
      FStar_SMTEncoding_Util.mkApp uu____9401 in
    let not_valid_a =
      let uu____9411 = FStar_SMTEncoding_Util.mkApp ("Valid", [a]) in
      FStar_All.pipe_left FStar_SMTEncoding_Util.mkNot uu____9411 in
    let uu____9413 =
      let uu____9414 =
        let uu____9419 =
          let uu____9420 =
            let uu____9426 =
              FStar_SMTEncoding_Util.mkIff (not_valid_a, valid) in
            ([[valid]], [aa], uu____9426) in
          FStar_SMTEncoding_Util.mkForall uu____9420 in
        (uu____9419, (Some "not interpretation"), (Some "l_not-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9414 in
    [uu____9413] in
  let mk_forall_interp env for_all tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let x = FStar_SMTEncoding_Util.mkFreeV xx in
    let valid =
      let uu____9463 =
        let uu____9467 =
          let uu____9469 = FStar_SMTEncoding_Util.mkApp (for_all, [a; b]) in
          [uu____9469] in
        ("Valid", uu____9467) in
      FStar_SMTEncoding_Util.mkApp uu____9463 in
    let valid_b_x =
      let uu____9473 =
        let uu____9477 =
          let uu____9479 = FStar_SMTEncoding_Util.mk_ApplyTT b x in
          [uu____9479] in
        ("Valid", uu____9477) in
      FStar_SMTEncoding_Util.mkApp uu____9473 in
    let uu____9481 =
      let uu____9482 =
        let uu____9487 =
          let uu____9488 =
            let uu____9494 =
              let uu____9495 =
                let uu____9498 =
                  let uu____9499 =
                    let uu____9505 =
                      let uu____9508 =
                        let uu____9510 =
                          FStar_SMTEncoding_Term.mk_HasTypeZ x a in
                        [uu____9510] in
                      [uu____9508] in
                    let uu____9513 =
                      let uu____9514 =
                        let uu____9517 =
                          FStar_SMTEncoding_Term.mk_HasTypeZ x a in
                        (uu____9517, valid_b_x) in
                      FStar_SMTEncoding_Util.mkImp uu____9514 in
                    (uu____9505, [xx], uu____9513) in
                  FStar_SMTEncoding_Util.mkForall uu____9499 in
                (uu____9498, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9495 in
            ([[valid]], [aa; bb], uu____9494) in
          FStar_SMTEncoding_Util.mkForall uu____9488 in
        (uu____9487, (Some "forall interpretation"), (Some "forall-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9482 in
    [uu____9481] in
  let mk_exists_interp env for_some tt =
    let aa = ("a", FStar_SMTEncoding_Term.Term_sort) in
    let bb = ("b", FStar_SMTEncoding_Term.Term_sort) in
    let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
    let a = FStar_SMTEncoding_Util.mkFreeV aa in
    let b = FStar_SMTEncoding_Util.mkFreeV bb in
    let x = FStar_SMTEncoding_Util.mkFreeV xx in
    let valid =
      let uu____9565 =
        let uu____9569 =
          let uu____9571 = FStar_SMTEncoding_Util.mkApp (for_some, [a; b]) in
          [uu____9571] in
        ("Valid", uu____9569) in
      FStar_SMTEncoding_Util.mkApp uu____9565 in
    let valid_b_x =
      let uu____9575 =
        let uu____9579 =
          let uu____9581 = FStar_SMTEncoding_Util.mk_ApplyTT b x in
          [uu____9581] in
        ("Valid", uu____9579) in
      FStar_SMTEncoding_Util.mkApp uu____9575 in
    let uu____9583 =
      let uu____9584 =
        let uu____9589 =
          let uu____9590 =
            let uu____9596 =
              let uu____9597 =
                let uu____9600 =
                  let uu____9601 =
                    let uu____9607 =
                      let uu____9610 =
                        let uu____9612 =
                          FStar_SMTEncoding_Term.mk_HasTypeZ x a in
                        [uu____9612] in
                      [uu____9610] in
                    let uu____9615 =
                      let uu____9616 =
                        let uu____9619 =
                          FStar_SMTEncoding_Term.mk_HasTypeZ x a in
                        (uu____9619, valid_b_x) in
                      FStar_SMTEncoding_Util.mkImp uu____9616 in
                    (uu____9607, [xx], uu____9615) in
                  FStar_SMTEncoding_Util.mkExists uu____9601 in
                (uu____9600, valid) in
              FStar_SMTEncoding_Util.mkIff uu____9597 in
            ([[valid]], [aa; bb], uu____9596) in
          FStar_SMTEncoding_Util.mkForall uu____9590 in
        (uu____9589, (Some "exists interpretation"), (Some "exists-interp")) in
      FStar_SMTEncoding_Term.Assume uu____9584 in
    [uu____9583] in
  let mk_range_interp env range tt =
    let range_ty = FStar_SMTEncoding_Util.mkApp (range, []) in
    let uu____9656 =
      let uu____9657 =
        let uu____9662 =
          FStar_SMTEncoding_Term.mk_HasTypeZ
            FStar_SMTEncoding_Term.mk_Range_const range_ty in
        let uu____9663 =
          let uu____9665 = varops.mk_unique "typing_range_const" in
          Some uu____9665 in
        (uu____9662, (Some "Range_const typing"), uu____9663) in
      FStar_SMTEncoding_Term.Assume uu____9657 in
    [uu____9656] in
  let prims =
    [(FStar_Syntax_Const.unit_lid, mk_unit);
    (FStar_Syntax_Const.bool_lid, mk_bool);
    (FStar_Syntax_Const.int_lid, mk_int);
    (FStar_Syntax_Const.string_lid, mk_str);
    (FStar_Syntax_Const.ref_lid, mk_ref);
    (FStar_Syntax_Const.true_lid, mk_true_interp);
    (FStar_Syntax_Const.false_lid, mk_false_interp);
    (FStar_Syntax_Const.and_lid, mk_and_interp);
    (FStar_Syntax_Const.or_lid, mk_or_interp);
    (FStar_Syntax_Const.eq2_lid, mk_eq2_interp);
    (FStar_Syntax_Const.eq3_lid, mk_eq3_interp);
    (FStar_Syntax_Const.imp_lid, mk_imp_interp);
    (FStar_Syntax_Const.iff_lid, mk_iff_interp);
    (FStar_Syntax_Const.not_lid, mk_not_interp);
    (FStar_Syntax_Const.forall_lid, mk_forall_interp);
    (FStar_Syntax_Const.exists_lid, mk_exists_interp);
    (FStar_Syntax_Const.range_lid, mk_range_interp)] in
  fun env  ->
    fun t  ->
      fun s  ->
        fun tt  ->
          let uu____9928 =
            FStar_Util.find_opt
              (fun uu____9946  ->
                 match uu____9946 with
                 | (l,uu____9956) -> FStar_Ident.lid_equals l t) prims in
          match uu____9928 with
          | None  -> []
          | Some (uu____9978,f) -> f env s tt
let encode_smt_lemma:
  env_t ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.typ -> FStar_SMTEncoding_Term.decl Prims.list
  =
  fun env  ->
    fun fv  ->
      fun t  ->
        let lid = (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
        let uu____10015 = encode_function_type_as_formula None None t env in
        match uu____10015 with
        | (form,decls) ->
            FStar_List.append decls
              [FStar_SMTEncoding_Term.Assume
                 (form, (Some (Prims.strcat "Lemma: " lid.FStar_Ident.str)),
                   (Some (Prims.strcat "lemma_" lid.FStar_Ident.str)))]
let encode_free_var:
  env_t ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.term ->
        FStar_Syntax_Syntax.term ->
          FStar_Syntax_Syntax.qualifier Prims.list ->
            (FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun fv  ->
      fun tt  ->
        fun t_norm  ->
          fun quals  ->
            let lid = (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
            let uu____10048 =
              (let uu____10049 =
                 (FStar_Syntax_Util.is_pure_or_ghost_function t_norm) ||
                   (FStar_TypeChecker_Env.is_reifiable_function env.tcenv
                      t_norm) in
               FStar_All.pipe_left Prims.op_Negation uu____10049) ||
                (FStar_Syntax_Util.is_lemma t_norm) in
            match uu____10048 with
            | true  ->
                let uu____10053 = new_term_constant_and_tok_from_lid env lid in
                (match uu____10053 with
                 | (vname,vtok,env) ->
                     let arg_sorts =
                       let uu____10065 =
                         let uu____10066 = FStar_Syntax_Subst.compress t_norm in
                         uu____10066.FStar_Syntax_Syntax.n in
                       match uu____10065 with
                       | FStar_Syntax_Syntax.Tm_arrow (binders,uu____10071)
                           ->
                           FStar_All.pipe_right binders
                             (FStar_List.map
                                (fun uu____10088  ->
                                   FStar_SMTEncoding_Term.Term_sort))
                       | uu____10091 -> [] in
                     let d =
                       FStar_SMTEncoding_Term.DeclFun
                         (vname, arg_sorts, FStar_SMTEncoding_Term.Term_sort,
                           (Some
                              "Uninterpreted function symbol for impure function")) in
                     let dd =
                       FStar_SMTEncoding_Term.DeclFun
                         (vtok, [], FStar_SMTEncoding_Term.Term_sort,
                           (Some "Uninterpreted name for impure function")) in
                     ([d; dd], env))
            | uu____10099 ->
                let uu____10100 = prims.is lid in
                (match uu____10100 with
                 | true  ->
                     let vname = varops.new_fvar lid in
                     let uu____10105 = prims.mk lid vname in
                     (match uu____10105 with
                      | (tok,definition) ->
                          let env = push_free_var env lid vname (Some tok) in
                          (definition, env))
                 | uu____10118 ->
                     let encode_non_total_function_typ =
                       lid.FStar_Ident.nsstr <> "Prims" in
                     let uu____10120 =
                       let uu____10126 = curried_arrow_formals_comp t_norm in
                       match uu____10126 with
                       | (args,comp) ->
                           let comp =
                             let uu____10137 =
                               FStar_TypeChecker_Env.is_reifiable_comp
                                 env.tcenv comp in
                             match uu____10137 with
                             | true  ->
                                 let uu____10138 =
                                   FStar_TypeChecker_Env.reify_comp
                                     (let uu___150_10139 = env.tcenv in
                                      {
                                        FStar_TypeChecker_Env.solver =
                                          (uu___150_10139.FStar_TypeChecker_Env.solver);
                                        FStar_TypeChecker_Env.range =
                                          (uu___150_10139.FStar_TypeChecker_Env.range);
                                        FStar_TypeChecker_Env.curmodule =
                                          (uu___150_10139.FStar_TypeChecker_Env.curmodule);
                                        FStar_TypeChecker_Env.gamma =
                                          (uu___150_10139.FStar_TypeChecker_Env.gamma);
                                        FStar_TypeChecker_Env.gamma_cache =
                                          (uu___150_10139.FStar_TypeChecker_Env.gamma_cache);
                                        FStar_TypeChecker_Env.modules =
                                          (uu___150_10139.FStar_TypeChecker_Env.modules);
                                        FStar_TypeChecker_Env.expected_typ =
                                          (uu___150_10139.FStar_TypeChecker_Env.expected_typ);
                                        FStar_TypeChecker_Env.sigtab =
                                          (uu___150_10139.FStar_TypeChecker_Env.sigtab);
                                        FStar_TypeChecker_Env.is_pattern =
                                          (uu___150_10139.FStar_TypeChecker_Env.is_pattern);
                                        FStar_TypeChecker_Env.instantiate_imp
                                          =
                                          (uu___150_10139.FStar_TypeChecker_Env.instantiate_imp);
                                        FStar_TypeChecker_Env.effects =
                                          (uu___150_10139.FStar_TypeChecker_Env.effects);
                                        FStar_TypeChecker_Env.generalize =
                                          (uu___150_10139.FStar_TypeChecker_Env.generalize);
                                        FStar_TypeChecker_Env.letrecs =
                                          (uu___150_10139.FStar_TypeChecker_Env.letrecs);
                                        FStar_TypeChecker_Env.top_level =
                                          (uu___150_10139.FStar_TypeChecker_Env.top_level);
                                        FStar_TypeChecker_Env.check_uvars =
                                          (uu___150_10139.FStar_TypeChecker_Env.check_uvars);
                                        FStar_TypeChecker_Env.use_eq =
                                          (uu___150_10139.FStar_TypeChecker_Env.use_eq);
                                        FStar_TypeChecker_Env.is_iface =
                                          (uu___150_10139.FStar_TypeChecker_Env.is_iface);
                                        FStar_TypeChecker_Env.admit =
                                          (uu___150_10139.FStar_TypeChecker_Env.admit);
                                        FStar_TypeChecker_Env.lax = true;
                                        FStar_TypeChecker_Env.lax_universes =
                                          (uu___150_10139.FStar_TypeChecker_Env.lax_universes);
                                        FStar_TypeChecker_Env.type_of =
                                          (uu___150_10139.FStar_TypeChecker_Env.type_of);
                                        FStar_TypeChecker_Env.universe_of =
                                          (uu___150_10139.FStar_TypeChecker_Env.universe_of);
                                        FStar_TypeChecker_Env.use_bv_sorts =
                                          (uu___150_10139.FStar_TypeChecker_Env.use_bv_sorts);
                                        FStar_TypeChecker_Env.qname_and_index
                                          =
                                          (uu___150_10139.FStar_TypeChecker_Env.qname_and_index)
                                      }) comp FStar_Syntax_Syntax.U_unknown in
                                 FStar_Syntax_Syntax.mk_Total uu____10138
                             | uu____10140 -> comp in
                           (match encode_non_total_function_typ with
                            | true  ->
                                let uu____10146 =
                                  FStar_TypeChecker_Util.pure_or_ghost_pre_and_post
                                    env.tcenv comp in
                                (args, uu____10146)
                            | uu____10153 ->
                                (args,
                                  (None,
                                    (FStar_Syntax_Util.comp_result comp)))) in
                     (match uu____10120 with
                      | (formals,(pre_opt,res_t)) ->
                          let uu____10173 =
                            new_term_constant_and_tok_from_lid env lid in
                          (match uu____10173 with
                           | (vname,vtok,env) ->
                               let vtok_tm =
                                 match formals with
                                 | [] ->
                                     FStar_SMTEncoding_Util.mkFreeV
                                       (vname,
                                         FStar_SMTEncoding_Term.Term_sort)
                                 | uu____10186 ->
                                     FStar_SMTEncoding_Util.mkApp (vtok, []) in
                               let mk_disc_proj_axioms guard encoded_res_t
                                 vapp vars =
                                 FStar_All.pipe_right quals
                                   (FStar_List.collect
                                      (fun uu___121_10210  ->
                                         match uu___121_10210 with
                                         | FStar_Syntax_Syntax.Discriminator
                                             d ->
                                             let uu____10213 =
                                               FStar_Util.prefix vars in
                                             (match uu____10213 with
                                              | (uu____10224,(xxsym,uu____10226))
                                                  ->
                                                  let xx =
                                                    FStar_SMTEncoding_Util.mkFreeV
                                                      (xxsym,
                                                        FStar_SMTEncoding_Term.Term_sort) in
                                                  let uu____10236 =
                                                    let uu____10237 =
                                                      let uu____10242 =
                                                        let uu____10243 =
                                                          let uu____10249 =
                                                            let uu____10250 =
                                                              let uu____10253
                                                                =
                                                                let uu____10254
                                                                  =
                                                                  FStar_SMTEncoding_Term.mk_tester
                                                                    (
                                                                    escape
                                                                    d.FStar_Ident.str)
                                                                    xx in
                                                                FStar_All.pipe_left
                                                                  FStar_SMTEncoding_Term.boxBool
                                                                  uu____10254 in
                                                              (vapp,
                                                                uu____10253) in
                                                            FStar_SMTEncoding_Util.mkEq
                                                              uu____10250 in
                                                          ([[vapp]], vars,
                                                            uu____10249) in
                                                        FStar_SMTEncoding_Util.mkForall
                                                          uu____10243 in
                                                      (uu____10242,
                                                        (Some
                                                           "Discriminator equation"),
                                                        (Some
                                                           (Prims.strcat
                                                              "disc_equation_"
                                                              (escape
                                                                 d.FStar_Ident.str)))) in
                                                    FStar_SMTEncoding_Term.Assume
                                                      uu____10237 in
                                                  [uu____10236])
                                         | FStar_Syntax_Syntax.Projector
                                             (d,f) ->
                                             let uu____10266 =
                                               FStar_Util.prefix vars in
                                             (match uu____10266 with
                                              | (uu____10277,(xxsym,uu____10279))
                                                  ->
                                                  let xx =
                                                    FStar_SMTEncoding_Util.mkFreeV
                                                      (xxsym,
                                                        FStar_SMTEncoding_Term.Term_sort) in
                                                  let f =
                                                    {
                                                      FStar_Syntax_Syntax.ppname
                                                        = f;
                                                      FStar_Syntax_Syntax.index
                                                        =
                                                        (Prims.parse_int "0");
                                                      FStar_Syntax_Syntax.sort
                                                        =
                                                        FStar_Syntax_Syntax.tun
                                                    } in
                                                  let tp_name =
                                                    mk_term_projector_name d
                                                      f in
                                                  let prim_app =
                                                    FStar_SMTEncoding_Util.mkApp
                                                      (tp_name, [xx]) in
                                                  let uu____10293 =
                                                    let uu____10294 =
                                                      let uu____10299 =
                                                        let uu____10300 =
                                                          let uu____10306 =
                                                            FStar_SMTEncoding_Util.mkEq
                                                              (vapp,
                                                                prim_app) in
                                                          ([[vapp]], vars,
                                                            uu____10306) in
                                                        FStar_SMTEncoding_Util.mkForall
                                                          uu____10300 in
                                                      (uu____10299,
                                                        (Some
                                                           "Projector equation"),
                                                        (Some
                                                           (Prims.strcat
                                                              "proj_equation_"
                                                              tp_name))) in
                                                    FStar_SMTEncoding_Term.Assume
                                                      uu____10294 in
                                                  [uu____10293])
                                         | uu____10316 -> [])) in
                               let uu____10317 =
                                 encode_binders None formals env in
                               (match uu____10317 with
                                | (vars,guards,env',decls1,uu____10333) ->
                                    let uu____10340 =
                                      match pre_opt with
                                      | None  ->
                                          let uu____10345 =
                                            FStar_SMTEncoding_Util.mk_and_l
                                              guards in
                                          (uu____10345, decls1)
                                      | Some p ->
                                          let uu____10347 =
                                            encode_formula p env' in
                                          (match uu____10347 with
                                           | (g,ds) ->
                                               let uu____10354 =
                                                 FStar_SMTEncoding_Util.mk_and_l
                                                   (g :: guards) in
                                               (uu____10354,
                                                 (FStar_List.append decls1 ds))) in
                                    (match uu____10340 with
                                     | (guard,decls1) ->
                                         let vtok_app = mk_Apply vtok_tm vars in
                                         let vapp =
                                           let uu____10363 =
                                             let uu____10367 =
                                               FStar_List.map
                                                 FStar_SMTEncoding_Util.mkFreeV
                                                 vars in
                                             (vname, uu____10367) in
                                           FStar_SMTEncoding_Util.mkApp
                                             uu____10363 in
                                         let uu____10372 =
                                           let vname_decl =
                                             let uu____10377 =
                                               let uu____10383 =
                                                 FStar_All.pipe_right formals
                                                   (FStar_List.map
                                                      (fun uu____10388  ->
                                                         FStar_SMTEncoding_Term.Term_sort)) in
                                               (vname, uu____10383,
                                                 FStar_SMTEncoding_Term.Term_sort,
                                                 None) in
                                             FStar_SMTEncoding_Term.DeclFun
                                               uu____10377 in
                                           let uu____10393 =
                                             let env =
                                               let uu___151_10397 = env in
                                               {
                                                 bindings =
                                                   (uu___151_10397.bindings);
                                                 depth =
                                                   (uu___151_10397.depth);
                                                 tcenv =
                                                   (uu___151_10397.tcenv);
                                                 warn = (uu___151_10397.warn);
                                                 cache =
                                                   (uu___151_10397.cache);
                                                 nolabels =
                                                   (uu___151_10397.nolabels);
                                                 use_zfuel_name =
                                                   (uu___151_10397.use_zfuel_name);
                                                 encode_non_total_function_typ
                                               } in
                                             let uu____10398 =
                                               let uu____10399 =
                                                 head_normal env tt in
                                               Prims.op_Negation uu____10399 in
                                             match uu____10398 with
                                             | true  ->
                                                 encode_term_pred None tt env
                                                   vtok_tm
                                             | uu____10402 ->
                                                 encode_term_pred None t_norm
                                                   env vtok_tm in
                                           match uu____10393 with
                                           | (tok_typing,decls2) ->
                                               let tok_typing =
                                                 FStar_SMTEncoding_Term.Assume
                                                   (tok_typing,
                                                     (Some
                                                        "function token typing"),
                                                     (Some
                                                        (Prims.strcat
                                                           "function_token_typing_"
                                                           vname))) in
                                               let uu____10411 =
                                                 match formals with
                                                 | [] ->
                                                     let uu____10420 =
                                                       let uu____10421 =
                                                         let uu____10423 =
                                                           FStar_SMTEncoding_Util.mkFreeV
                                                             (vname,
                                                               FStar_SMTEncoding_Term.Term_sort) in
                                                         FStar_All.pipe_left
                                                           (fun _0_34  ->
                                                              Some _0_34)
                                                           uu____10423 in
                                                       push_free_var env lid
                                                         vname uu____10421 in
                                                     ((FStar_List.append
                                                         decls2 [tok_typing]),
                                                       uu____10420)
                                                 | uu____10426 ->
                                                     let vtok_decl =
                                                       FStar_SMTEncoding_Term.DeclFun
                                                         (vtok, [],
                                                           FStar_SMTEncoding_Term.Term_sort,
                                                           None) in
                                                     let vtok_fresh =
                                                       let uu____10431 =
                                                         varops.next_id () in
                                                       FStar_SMTEncoding_Term.fresh_token
                                                         (vtok,
                                                           FStar_SMTEncoding_Term.Term_sort)
                                                         uu____10431 in
                                                     let name_tok_corr =
                                                       let uu____10433 =
                                                         let uu____10438 =
                                                           let uu____10439 =
                                                             let uu____10445
                                                               =
                                                               FStar_SMTEncoding_Util.mkEq
                                                                 (vtok_app,
                                                                   vapp) in
                                                             ([[vtok_app];
                                                              [vapp]], vars,
                                                               uu____10445) in
                                                           FStar_SMTEncoding_Util.mkForall
                                                             uu____10439 in
                                                         (uu____10438,
                                                           (Some
                                                              "Name-token correspondence"),
                                                           (Some
                                                              (Prims.strcat
                                                                 "token_correspondence_"
                                                                 vname))) in
                                                       FStar_SMTEncoding_Term.Assume
                                                         uu____10433 in
                                                     ((FStar_List.append
                                                         decls2
                                                         [vtok_decl;
                                                         vtok_fresh;
                                                         name_tok_corr;
                                                         tok_typing]), env) in
                                               (match uu____10411 with
                                                | (tok_decl,env) ->
                                                    ((vname_decl ::
                                                      tok_decl), env)) in
                                         (match uu____10372 with
                                          | (decls2,env) ->
                                              let uu____10470 =
                                                let res_t =
                                                  FStar_Syntax_Subst.compress
                                                    res_t in
                                                let uu____10475 =
                                                  encode_term res_t env' in
                                                match uu____10475 with
                                                | (encoded_res_t,decls) ->
                                                    let uu____10483 =
                                                      FStar_SMTEncoding_Term.mk_HasType
                                                        vapp encoded_res_t in
                                                    (encoded_res_t,
                                                      uu____10483, decls) in
                                              (match uu____10470 with
                                               | (encoded_res_t,ty_pred,decls3)
                                                   ->
                                                   let typingAx =
                                                     let uu____10491 =
                                                       let uu____10496 =
                                                         let uu____10497 =
                                                           let uu____10503 =
                                                             FStar_SMTEncoding_Util.mkImp
                                                               (guard,
                                                                 ty_pred) in
                                                           ([[vapp]], vars,
                                                             uu____10503) in
                                                         FStar_SMTEncoding_Util.mkForall
                                                           uu____10497 in
                                                       (uu____10496,
                                                         (Some
                                                            "free var typing"),
                                                         (Some
                                                            (Prims.strcat
                                                               "typing_"
                                                               vname))) in
                                                     FStar_SMTEncoding_Term.Assume
                                                       uu____10491 in
                                                   let freshness =
                                                     let uu____10513 =
                                                       FStar_All.pipe_right
                                                         quals
                                                         (FStar_List.contains
                                                            FStar_Syntax_Syntax.New) in
                                                     match uu____10513 with
                                                     | true  ->
                                                         let uu____10516 =
                                                           let uu____10517 =
                                                             let uu____10523
                                                               =
                                                               FStar_All.pipe_right
                                                                 vars
                                                                 (FStar_List.map
                                                                    Prims.snd) in
                                                             let uu____10529
                                                               =
                                                               varops.next_id
                                                                 () in
                                                             (vname,
                                                               uu____10523,
                                                               FStar_SMTEncoding_Term.Term_sort,
                                                               uu____10529) in
                                                           FStar_SMTEncoding_Term.fresh_constructor
                                                             uu____10517 in
                                                         let uu____10531 =
                                                           let uu____10533 =
                                                             pretype_axiom
                                                               vapp vars in
                                                           [uu____10533] in
                                                         uu____10516 ::
                                                           uu____10531
                                                     | uu____10534 -> [] in
                                                   let g =
                                                     let uu____10537 =
                                                       let uu____10539 =
                                                         let uu____10541 =
                                                           let uu____10543 =
                                                             let uu____10545
                                                               =
                                                               mk_disc_proj_axioms
                                                                 guard
                                                                 encoded_res_t
                                                                 vapp vars in
                                                             typingAx ::
                                                               uu____10545 in
                                                           FStar_List.append
                                                             freshness
                                                             uu____10543 in
                                                         FStar_List.append
                                                           decls3 uu____10541 in
                                                       FStar_List.append
                                                         decls2 uu____10539 in
                                                     FStar_List.append decls1
                                                       uu____10537 in
                                                   (g, env))))))))
let declare_top_level_let:
  env_t ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.term ->
        FStar_Syntax_Syntax.term ->
          ((Prims.string* FStar_SMTEncoding_Term.term Prims.option)*
            FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun x  ->
      fun t  ->
        fun t_norm  ->
          let uu____10567 =
            try_lookup_lid env
              (x.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          match uu____10567 with
          | None  ->
              let uu____10590 = encode_free_var env x t t_norm [] in
              (match uu____10590 with
               | (decls,env) ->
                   let uu____10605 =
                     lookup_lid env
                       (x.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                   (match uu____10605 with
                    | (n,x',uu____10624) -> ((n, x'), decls, env)))
          | Some (n,x,uu____10636) -> ((n, x), [], env)
let encode_top_level_val:
  env_t ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.term ->
        FStar_Syntax_Syntax.qualifier Prims.list ->
          (FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun lid  ->
      fun t  ->
        fun quals  ->
          let tt = norm env t in
          let uu____10669 = encode_free_var env lid t tt quals in
          match uu____10669 with
          | (decls,env) ->
              let uu____10680 = FStar_Syntax_Util.is_smt_lemma t in
              (match uu____10680 with
               | true  ->
                   let uu____10684 =
                     let uu____10686 = encode_smt_lemma env lid tt in
                     FStar_List.append decls uu____10686 in
                   (uu____10684, env)
               | uu____10689 -> (decls, env))
let encode_top_level_vals:
  env_t ->
    FStar_Syntax_Syntax.letbinding Prims.list ->
      FStar_Syntax_Syntax.qualifier Prims.list ->
        (FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun bindings  ->
      fun quals  ->
        FStar_All.pipe_right bindings
          (FStar_List.fold_left
             (fun uu____10714  ->
                fun lb  ->
                  match uu____10714 with
                  | (decls,env) ->
                      let uu____10726 =
                        let uu____10730 =
                          FStar_Util.right lb.FStar_Syntax_Syntax.lbname in
                        encode_top_level_val env uu____10730
                          lb.FStar_Syntax_Syntax.lbtyp quals in
                      (match uu____10726 with
                       | (decls',env) ->
                           ((FStar_List.append decls decls'), env)))
             ([], env))
let encode_top_level_let:
  env_t ->
    (Prims.bool* FStar_Syntax_Syntax.letbinding Prims.list) ->
      FStar_Syntax_Syntax.qualifier Prims.list ->
        (FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun uu____10754  ->
      fun quals  ->
        match uu____10754 with
        | (is_rec,bindings) ->
            let eta_expand binders formals body t =
              let nbinders = FStar_List.length binders in
              let uu____10803 = FStar_Util.first_N nbinders formals in
              match uu____10803 with
              | (formals,extra_formals) ->
                  let subst =
                    FStar_List.map2
                      (fun uu____10843  ->
                         fun uu____10844  ->
                           match (uu____10843, uu____10844) with
                           | ((formal,uu____10854),(binder,uu____10856)) ->
                               let uu____10861 =
                                 let uu____10866 =
                                   FStar_Syntax_Syntax.bv_to_name binder in
                                 (formal, uu____10866) in
                               FStar_Syntax_Syntax.NT uu____10861) formals
                      binders in
                  let extra_formals =
                    let uu____10871 =
                      FStar_All.pipe_right extra_formals
                        (FStar_List.map
                           (fun uu____10885  ->
                              match uu____10885 with
                              | (x,i) ->
                                  let uu____10892 =
                                    let uu___152_10893 = x in
                                    let uu____10894 =
                                      FStar_Syntax_Subst.subst subst
                                        x.FStar_Syntax_Syntax.sort in
                                    {
                                      FStar_Syntax_Syntax.ppname =
                                        (uu___152_10893.FStar_Syntax_Syntax.ppname);
                                      FStar_Syntax_Syntax.index =
                                        (uu___152_10893.FStar_Syntax_Syntax.index);
                                      FStar_Syntax_Syntax.sort = uu____10894
                                    } in
                                  (uu____10892, i))) in
                    FStar_All.pipe_right uu____10871
                      FStar_Syntax_Util.name_binders in
                  let body =
                    let uu____10906 =
                      let uu____10908 =
                        let uu____10909 = FStar_Syntax_Subst.subst subst t in
                        uu____10909.FStar_Syntax_Syntax.n in
                      FStar_All.pipe_left (fun _0_35  -> Some _0_35)
                        uu____10908 in
                    let uu____10913 =
                      let uu____10914 = FStar_Syntax_Subst.compress body in
                      let uu____10915 =
                        let uu____10916 =
                          FStar_Syntax_Util.args_of_binders extra_formals in
                        FStar_All.pipe_left Prims.snd uu____10916 in
                      FStar_Syntax_Syntax.extend_app_n uu____10914
                        uu____10915 in
                    uu____10913 uu____10906 body.FStar_Syntax_Syntax.pos in
                  ((FStar_List.append binders extra_formals), body) in
            let destruct_bound_function flid t_norm e =
              let get_result_type c =
                let uu____10958 =
                  FStar_TypeChecker_Env.is_reifiable_comp env.tcenv c in
                match uu____10958 with
                | true  ->
                    FStar_TypeChecker_Env.reify_comp
                      (let uu___153_10959 = env.tcenv in
                       {
                         FStar_TypeChecker_Env.solver =
                           (uu___153_10959.FStar_TypeChecker_Env.solver);
                         FStar_TypeChecker_Env.range =
                           (uu___153_10959.FStar_TypeChecker_Env.range);
                         FStar_TypeChecker_Env.curmodule =
                           (uu___153_10959.FStar_TypeChecker_Env.curmodule);
                         FStar_TypeChecker_Env.gamma =
                           (uu___153_10959.FStar_TypeChecker_Env.gamma);
                         FStar_TypeChecker_Env.gamma_cache =
                           (uu___153_10959.FStar_TypeChecker_Env.gamma_cache);
                         FStar_TypeChecker_Env.modules =
                           (uu___153_10959.FStar_TypeChecker_Env.modules);
                         FStar_TypeChecker_Env.expected_typ =
                           (uu___153_10959.FStar_TypeChecker_Env.expected_typ);
                         FStar_TypeChecker_Env.sigtab =
                           (uu___153_10959.FStar_TypeChecker_Env.sigtab);
                         FStar_TypeChecker_Env.is_pattern =
                           (uu___153_10959.FStar_TypeChecker_Env.is_pattern);
                         FStar_TypeChecker_Env.instantiate_imp =
                           (uu___153_10959.FStar_TypeChecker_Env.instantiate_imp);
                         FStar_TypeChecker_Env.effects =
                           (uu___153_10959.FStar_TypeChecker_Env.effects);
                         FStar_TypeChecker_Env.generalize =
                           (uu___153_10959.FStar_TypeChecker_Env.generalize);
                         FStar_TypeChecker_Env.letrecs =
                           (uu___153_10959.FStar_TypeChecker_Env.letrecs);
                         FStar_TypeChecker_Env.top_level =
                           (uu___153_10959.FStar_TypeChecker_Env.top_level);
                         FStar_TypeChecker_Env.check_uvars =
                           (uu___153_10959.FStar_TypeChecker_Env.check_uvars);
                         FStar_TypeChecker_Env.use_eq =
                           (uu___153_10959.FStar_TypeChecker_Env.use_eq);
                         FStar_TypeChecker_Env.is_iface =
                           (uu___153_10959.FStar_TypeChecker_Env.is_iface);
                         FStar_TypeChecker_Env.admit =
                           (uu___153_10959.FStar_TypeChecker_Env.admit);
                         FStar_TypeChecker_Env.lax = true;
                         FStar_TypeChecker_Env.lax_universes =
                           (uu___153_10959.FStar_TypeChecker_Env.lax_universes);
                         FStar_TypeChecker_Env.type_of =
                           (uu___153_10959.FStar_TypeChecker_Env.type_of);
                         FStar_TypeChecker_Env.universe_of =
                           (uu___153_10959.FStar_TypeChecker_Env.universe_of);
                         FStar_TypeChecker_Env.use_bv_sorts =
                           (uu___153_10959.FStar_TypeChecker_Env.use_bv_sorts);
                         FStar_TypeChecker_Env.qname_and_index =
                           (uu___153_10959.FStar_TypeChecker_Env.qname_and_index)
                       }) c FStar_Syntax_Syntax.U_unknown
                | uu____10960 -> FStar_Syntax_Util.comp_result c in
              let rec aux norm t_norm =
                let uu____10980 = FStar_Syntax_Util.abs_formals e in
                match uu____10980 with
                | (binders,body,lopt) ->
                    (match binders with
                     | uu____11029::uu____11030 ->
                         let uu____11038 =
                           let uu____11039 =
                             FStar_Syntax_Subst.compress t_norm in
                           uu____11039.FStar_Syntax_Syntax.n in
                         (match uu____11038 with
                          | FStar_Syntax_Syntax.Tm_arrow (formals,c) ->
                              let uu____11066 =
                                FStar_Syntax_Subst.open_comp formals c in
                              (match uu____11066 with
                               | (formals,c) ->
                                   let nformals = FStar_List.length formals in
                                   let nbinders = FStar_List.length binders in
                                   let tres = get_result_type c in
                                   let uu____11092 =
                                     (nformals < nbinders) &&
                                       (FStar_Syntax_Util.is_total_comp c) in
                                   (match uu____11092 with
                                    | true  ->
                                        let uu____11110 =
                                          FStar_Util.first_N nformals binders in
                                        (match uu____11110 with
                                         | (bs0,rest) ->
                                             let c =
                                               let subst =
                                                 FStar_List.map2
                                                   (fun uu____11156  ->
                                                      fun uu____11157  ->
                                                        match (uu____11156,
                                                                uu____11157)
                                                        with
                                                        | ((x,uu____11167),
                                                           (b,uu____11169))
                                                            ->
                                                            let uu____11174 =
                                                              let uu____11179
                                                                =
                                                                FStar_Syntax_Syntax.bv_to_name
                                                                  b in
                                                              (x,
                                                                uu____11179) in
                                                            FStar_Syntax_Syntax.NT
                                                              uu____11174)
                                                   formals bs0 in
                                               FStar_Syntax_Subst.subst_comp
                                                 subst c in
                                             let body =
                                               FStar_Syntax_Util.abs rest
                                                 body lopt in
                                             let uu____11181 =
                                               let uu____11192 =
                                                 get_result_type c in
                                               (bs0, body, bs0, uu____11192) in
                                             (uu____11181, false))
                                    | uu____11209 ->
                                        (match nformals > nbinders with
                                         | true  ->
                                             let uu____11227 =
                                               eta_expand binders formals
                                                 body tres in
                                             (match uu____11227 with
                                              | (binders,body) ->
                                                  ((binders, body, formals,
                                                     tres), false))
                                         | uu____11273 ->
                                             ((binders, body, formals, tres),
                                               false))))
                          | FStar_Syntax_Syntax.Tm_refine (x,uu____11279) ->
                              let uu____11284 =
                                let uu____11295 =
                                  aux norm x.FStar_Syntax_Syntax.sort in
                                Prims.fst uu____11295 in
                              (uu____11284, true)
                          | uu____11328 when Prims.op_Negation norm ->
                              let t_norm =
                                FStar_TypeChecker_Normalize.normalize
                                  [FStar_TypeChecker_Normalize.AllowUnboundUniverses;
                                  FStar_TypeChecker_Normalize.Beta;
                                  FStar_TypeChecker_Normalize.WHNF;
                                  FStar_TypeChecker_Normalize.Exclude
                                    FStar_TypeChecker_Normalize.Zeta;
                                  FStar_TypeChecker_Normalize.UnfoldUntil
                                    FStar_Syntax_Syntax.Delta_constant;
                                  FStar_TypeChecker_Normalize.EraseUniverses]
                                  env.tcenv t_norm in
                              aux true t_norm
                          | uu____11330 ->
                              let uu____11331 =
                                let uu____11332 =
                                  FStar_Syntax_Print.term_to_string e in
                                let uu____11333 =
                                  FStar_Syntax_Print.term_to_string t_norm in
                                FStar_Util.format3
                                  "Impossible! let-bound lambda %s = %s has a type that's not a function: %s\n"
                                  flid.FStar_Ident.str uu____11332
                                  uu____11333 in
                              failwith uu____11331)
                     | uu____11346 ->
                         let uu____11347 =
                           let uu____11348 =
                             FStar_Syntax_Subst.compress t_norm in
                           uu____11348.FStar_Syntax_Syntax.n in
                         (match uu____11347 with
                          | FStar_Syntax_Syntax.Tm_arrow (formals,c) ->
                              let uu____11375 =
                                FStar_Syntax_Subst.open_comp formals c in
                              (match uu____11375 with
                               | (formals,c) ->
                                   let tres = get_result_type c in
                                   let uu____11393 =
                                     eta_expand [] formals e tres in
                                   (match uu____11393 with
                                    | (binders,body) ->
                                        ((binders, body, formals, tres),
                                          false)))
                          | uu____11441 -> (([], e, [], t_norm), false))) in
              aux false t_norm in
            (try
               let uu____11469 =
                 FStar_All.pipe_right bindings
                   (FStar_Util.for_all
                      (fun lb  ->
                         FStar_Syntax_Util.is_lemma
                           lb.FStar_Syntax_Syntax.lbtyp)) in
               match uu____11469 with
               | true  -> encode_top_level_vals env bindings quals
               | uu____11475 ->
                   let uu____11476 =
                     FStar_All.pipe_right bindings
                       (FStar_List.fold_left
                          (fun uu____11517  ->
                             fun lb  ->
                               match uu____11517 with
                               | (toks,typs,decls,env) ->
                                   ((let uu____11568 =
                                       FStar_Syntax_Util.is_lemma
                                         lb.FStar_Syntax_Syntax.lbtyp in
                                     match uu____11568 with
                                     | true  ->
                                         Prims.raise Let_rec_unencodeable
                                     | uu____11569 -> ());
                                    (let t_norm =
                                       whnf env lb.FStar_Syntax_Syntax.lbtyp in
                                     let uu____11571 =
                                       let uu____11579 =
                                         FStar_Util.right
                                           lb.FStar_Syntax_Syntax.lbname in
                                       declare_top_level_let env uu____11579
                                         lb.FStar_Syntax_Syntax.lbtyp t_norm in
                                     match uu____11571 with
                                     | (tok,decl,env) ->
                                         let uu____11604 =
                                           let uu____11611 =
                                             let uu____11617 =
                                               FStar_Util.right
                                                 lb.FStar_Syntax_Syntax.lbname in
                                             (uu____11617, tok) in
                                           uu____11611 :: toks in
                                         (uu____11604, (t_norm :: typs),
                                           (decl :: decls), env))))
                          ([], [], [], env)) in
                   (match uu____11476 with
                    | (toks,typs,decls,env) ->
                        let toks = FStar_List.rev toks in
                        let decls =
                          FStar_All.pipe_right (FStar_List.rev decls)
                            FStar_List.flatten in
                        let typs = FStar_List.rev typs in
                        let mk_app curry f ftok vars =
                          match vars with
                          | [] ->
                              FStar_SMTEncoding_Util.mkFreeV
                                (f, FStar_SMTEncoding_Term.Term_sort)
                          | uu____11719 ->
                              (match curry with
                               | true  ->
                                   (match ftok with
                                    | Some ftok -> mk_Apply ftok vars
                                    | None  ->
                                        let uu____11724 =
                                          FStar_SMTEncoding_Util.mkFreeV
                                            (f,
                                              FStar_SMTEncoding_Term.Term_sort) in
                                        mk_Apply uu____11724 vars)
                               | uu____11725 ->
                                   let uu____11726 =
                                     let uu____11730 =
                                       FStar_List.map
                                         FStar_SMTEncoding_Util.mkFreeV vars in
                                     (f, uu____11730) in
                                   FStar_SMTEncoding_Util.mkApp uu____11726) in
                        let uu____11735 =
                          (FStar_All.pipe_right quals
                             (FStar_Util.for_some
                                (fun uu___122_11737  ->
                                   match uu___122_11737 with
                                   | FStar_Syntax_Syntax.HasMaskedEffect  ->
                                       true
                                   | uu____11738 -> false)))
                            ||
                            (FStar_All.pipe_right typs
                               (FStar_Util.for_some
                                  (fun t  ->
                                     let uu____11741 =
                                       (FStar_Syntax_Util.is_pure_or_ghost_function
                                          t)
                                         ||
                                         (FStar_TypeChecker_Env.is_reifiable_function
                                            env.tcenv t) in
                                     FStar_All.pipe_left Prims.op_Negation
                                       uu____11741))) in
                        (match uu____11735 with
                         | true  -> (decls, env)
                         | uu____11746 ->
                             (match Prims.op_Negation is_rec with
                              | true  ->
                                  (match (bindings, typs, toks) with
                                   | ({
                                        FStar_Syntax_Syntax.lbname =
                                          uu____11761;
                                        FStar_Syntax_Syntax.lbunivs = uvs;
                                        FStar_Syntax_Syntax.lbtyp =
                                          uu____11763;
                                        FStar_Syntax_Syntax.lbeff =
                                          uu____11764;
                                        FStar_Syntax_Syntax.lbdef = e;_}::[],t_norm::[],
                                      (flid_fv,(f,ftok))::[]) ->
                                       let flid =
                                         (flid_fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                                       let uu____11805 =
                                         FStar_Syntax_Subst.univ_var_opening
                                           uvs in
                                       (match uu____11805 with
                                        | (univ_subst,univ_vars) ->
                                            let env' =
                                              let uu___156_11820 = env in
                                              let uu____11821 =
                                                FStar_TypeChecker_Env.push_univ_vars
                                                  env.tcenv univ_vars in
                                              {
                                                bindings =
                                                  (uu___156_11820.bindings);
                                                depth =
                                                  (uu___156_11820.depth);
                                                tcenv = uu____11821;
                                                warn = (uu___156_11820.warn);
                                                cache =
                                                  (uu___156_11820.cache);
                                                nolabels =
                                                  (uu___156_11820.nolabels);
                                                use_zfuel_name =
                                                  (uu___156_11820.use_zfuel_name);
                                                encode_non_total_function_typ
                                                  =
                                                  (uu___156_11820.encode_non_total_function_typ)
                                              } in
                                            let t_norm =
                                              FStar_Syntax_Subst.subst
                                                univ_subst t_norm in
                                            let e =
                                              let uu____11824 =
                                                FStar_Syntax_Subst.subst
                                                  univ_subst e in
                                              FStar_Syntax_Subst.compress
                                                uu____11824 in
                                            let uu____11825 =
                                              destruct_bound_function flid
                                                t_norm e in
                                            (match uu____11825 with
                                             | ((binders,body,uu____11837,uu____11838),curry)
                                                 ->
                                                 ((let uu____11845 =
                                                     FStar_All.pipe_left
                                                       (FStar_TypeChecker_Env.debug
                                                          env.tcenv)
                                                       (FStar_Options.Other
                                                          "SMTEncoding") in
                                                   match uu____11845 with
                                                   | true  ->
                                                       let uu____11846 =
                                                         FStar_Syntax_Print.binders_to_string
                                                           ", " binders in
                                                       let uu____11847 =
                                                         FStar_Syntax_Print.term_to_string
                                                           body in
                                                       FStar_Util.print2
                                                         "Encoding let : binders=[%s], body=%s\n"
                                                         uu____11846
                                                         uu____11847
                                                   | uu____11848 -> ());
                                                  (let uu____11849 =
                                                     encode_binders None
                                                       binders env' in
                                                   match uu____11849 with
                                                   | (vars,guards,env',binder_decls,uu____11865)
                                                       ->
                                                       let body =
                                                         let uu____11873 =
                                                           FStar_TypeChecker_Env.is_reifiable_function
                                                             env'.tcenv
                                                             t_norm in
                                                         match uu____11873
                                                         with
                                                         | true  ->
                                                             reify_body
                                                               env'.tcenv
                                                               body
                                                         | uu____11874 ->
                                                             body in
                                                       let app =
                                                         mk_app curry f ftok
                                                           vars in
                                                       let uu____11876 =
                                                         let uu____11881 =
                                                           FStar_All.pipe_right
                                                             quals
                                                             (FStar_List.contains
                                                                FStar_Syntax_Syntax.Logic) in
                                                         match uu____11881
                                                         with
                                                         | true  ->
                                                             let uu____11887
                                                               =
                                                               FStar_SMTEncoding_Term.mk_Valid
                                                                 app in
                                                             let uu____11888
                                                               =
                                                               encode_formula
                                                                 body env' in
                                                             (uu____11887,
                                                               uu____11888)
                                                         | uu____11893 ->
                                                             let uu____11894
                                                               =
                                                               encode_term
                                                                 body env' in
                                                             (app,
                                                               uu____11894) in
                                                       (match uu____11876
                                                        with
                                                        | (app,(body,decls2))
                                                            ->
                                                            let eqn =
                                                              let uu____11908
                                                                =
                                                                let uu____11913
                                                                  =
                                                                  let uu____11914
                                                                    =
                                                                    let uu____11920
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (app,
                                                                    body) in
                                                                    ([[app]],
                                                                    vars,
                                                                    uu____11920) in
                                                                  FStar_SMTEncoding_Util.mkForall
                                                                    uu____11914 in
                                                                let uu____11926
                                                                  =
                                                                  let uu____11928
                                                                    =
                                                                    FStar_Util.format1
                                                                    "Equation for %s"
                                                                    flid.FStar_Ident.str in
                                                                  Some
                                                                    uu____11928 in
                                                                (uu____11913,
                                                                  uu____11926,
                                                                  (Some
                                                                    (Prims.strcat
                                                                    "equation_"
                                                                    f))) in
                                                              FStar_SMTEncoding_Term.Assume
                                                                uu____11908 in
                                                            let uu____11931 =
                                                              let uu____11933
                                                                =
                                                                let uu____11935
                                                                  =
                                                                  let uu____11937
                                                                    =
                                                                    let uu____11939
                                                                    =
                                                                    primitive_type_axioms
                                                                    env.tcenv
                                                                    flid f
                                                                    app in
                                                                    FStar_List.append
                                                                    [eqn]
                                                                    uu____11939 in
                                                                  FStar_List.append
                                                                    decls2
                                                                    uu____11937 in
                                                                FStar_List.append
                                                                  binder_decls
                                                                  uu____11935 in
                                                              FStar_List.append
                                                                decls
                                                                uu____11933 in
                                                            (uu____11931,
                                                              env))))))
                                   | uu____11942 -> failwith "Impossible")
                              | uu____11957 ->
                                  let fuel =
                                    let uu____11961 = varops.fresh "fuel" in
                                    (uu____11961,
                                      FStar_SMTEncoding_Term.Fuel_sort) in
                                  let fuel_tm =
                                    FStar_SMTEncoding_Util.mkFreeV fuel in
                                  let env0 = env in
                                  let uu____11964 =
                                    FStar_All.pipe_right toks
                                      (FStar_List.fold_left
                                         (fun uu____12003  ->
                                            fun uu____12004  ->
                                              match (uu____12003,
                                                      uu____12004)
                                              with
                                              | ((gtoks,env),(flid_fv,
                                                              (f,ftok)))
                                                  ->
                                                  let flid =
                                                    (flid_fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                                                  let g =
                                                    let uu____12086 =
                                                      FStar_Ident.lid_add_suffix
                                                        flid
                                                        "fuel_instrumented" in
                                                    varops.new_fvar
                                                      uu____12086 in
                                                  let gtok =
                                                    let uu____12088 =
                                                      FStar_Ident.lid_add_suffix
                                                        flid
                                                        "fuel_instrumented_token" in
                                                    varops.new_fvar
                                                      uu____12088 in
                                                  let env =
                                                    let uu____12090 =
                                                      let uu____12092 =
                                                        FStar_SMTEncoding_Util.mkApp
                                                          (g, [fuel_tm]) in
                                                      FStar_All.pipe_left
                                                        (fun _0_36  ->
                                                           Some _0_36)
                                                        uu____12092 in
                                                    push_free_var env flid
                                                      gtok uu____12090 in
                                                  (((flid, f, ftok, g, gtok)
                                                    :: gtoks), env))
                                         ([], env)) in
                                  (match uu____11964 with
                                   | (gtoks,env) ->
                                       let gtoks = FStar_List.rev gtoks in
                                       let encode_one_binding env0
                                         uu____12176 t_norm uu____12178 =
                                         match (uu____12176, uu____12178)
                                         with
                                         | ((flid,f,ftok,g,gtok),{
                                                                   FStar_Syntax_Syntax.lbname
                                                                    = lbn;
                                                                   FStar_Syntax_Syntax.lbunivs
                                                                    = uvs;
                                                                   FStar_Syntax_Syntax.lbtyp
                                                                    =
                                                                    uu____12203;
                                                                   FStar_Syntax_Syntax.lbeff
                                                                    =
                                                                    uu____12204;
                                                                   FStar_Syntax_Syntax.lbdef
                                                                    = e;_})
                                             ->
                                             let uu____12221 =
                                               FStar_Syntax_Subst.univ_var_opening
                                                 uvs in
                                             (match uu____12221 with
                                              | (univ_subst,univ_vars) ->
                                                  let env' =
                                                    let uu___157_12238 = env in
                                                    let uu____12239 =
                                                      FStar_TypeChecker_Env.push_univ_vars
                                                        env.tcenv univ_vars in
                                                    {
                                                      bindings =
                                                        (uu___157_12238.bindings);
                                                      depth =
                                                        (uu___157_12238.depth);
                                                      tcenv = uu____12239;
                                                      warn =
                                                        (uu___157_12238.warn);
                                                      cache =
                                                        (uu___157_12238.cache);
                                                      nolabels =
                                                        (uu___157_12238.nolabels);
                                                      use_zfuel_name =
                                                        (uu___157_12238.use_zfuel_name);
                                                      encode_non_total_function_typ
                                                        =
                                                        (uu___157_12238.encode_non_total_function_typ)
                                                    } in
                                                  let t_norm =
                                                    FStar_Syntax_Subst.subst
                                                      univ_subst t_norm in
                                                  let e =
                                                    FStar_Syntax_Subst.subst
                                                      univ_subst e in
                                                  ((let uu____12243 =
                                                      FStar_All.pipe_left
                                                        (FStar_TypeChecker_Env.debug
                                                           env0.tcenv)
                                                        (FStar_Options.Other
                                                           "SMTEncoding") in
                                                    match uu____12243 with
                                                    | true  ->
                                                        let uu____12244 =
                                                          FStar_Syntax_Print.lbname_to_string
                                                            lbn in
                                                        let uu____12245 =
                                                          FStar_Syntax_Print.term_to_string
                                                            t_norm in
                                                        let uu____12246 =
                                                          FStar_Syntax_Print.term_to_string
                                                            e in
                                                        FStar_Util.print3
                                                          "Encoding let rec %s : %s = %s\n"
                                                          uu____12244
                                                          uu____12245
                                                          uu____12246
                                                    | uu____12247 -> ());
                                                   (let uu____12248 =
                                                      destruct_bound_function
                                                        flid t_norm e in
                                                    match uu____12248 with
                                                    | ((binders,body,formals,tres),curry)
                                                        ->
                                                        ((let uu____12270 =
                                                            FStar_All.pipe_left
                                                              (FStar_TypeChecker_Env.debug
                                                                 env0.tcenv)
                                                              (FStar_Options.Other
                                                                 "SMTEncoding") in
                                                          match uu____12270
                                                          with
                                                          | true  ->
                                                              let uu____12271
                                                                =
                                                                FStar_Syntax_Print.binders_to_string
                                                                  ", "
                                                                  binders in
                                                              let uu____12272
                                                                =
                                                                FStar_Syntax_Print.term_to_string
                                                                  body in
                                                              let uu____12273
                                                                =
                                                                FStar_Syntax_Print.binders_to_string
                                                                  ", "
                                                                  formals in
                                                              let uu____12274
                                                                =
                                                                FStar_Syntax_Print.term_to_string
                                                                  tres in
                                                              FStar_Util.print4
                                                                "Encoding let rec: binders=[%s], body=%s, formals=[%s], tres=%s\n"
                                                                uu____12271
                                                                uu____12272
                                                                uu____12273
                                                                uu____12274
                                                          | uu____12275 -> ());
                                                         (match curry with
                                                          | true  ->
                                                              failwith
                                                                "Unexpected type of let rec in SMT Encoding; expected it to be annotated with an arrow type"
                                                          | uu____12277 -> ());
                                                         (let uu____12278 =
                                                            encode_binders
                                                              None binders
                                                              env' in
                                                          match uu____12278
                                                          with
                                                          | (vars,guards,env',binder_decls,uu____12296)
                                                              ->
                                                              let decl_g =
                                                                let uu____12304
                                                                  =
                                                                  let uu____12310
                                                                    =
                                                                    let uu____12312
                                                                    =
                                                                    FStar_List.map
                                                                    Prims.snd
                                                                    vars in
                                                                    FStar_SMTEncoding_Term.Fuel_sort
                                                                    ::
                                                                    uu____12312 in
                                                                  (g,
                                                                    uu____12310,
                                                                    FStar_SMTEncoding_Term.Term_sort,
                                                                    (
                                                                    Some
                                                                    "Fuel-instrumented function name")) in
                                                                FStar_SMTEncoding_Term.DeclFun
                                                                  uu____12304 in
                                                              let env0 =
                                                                push_zfuel_name
                                                                  env0 flid g in
                                                              let decl_g_tok
                                                                =
                                                                FStar_SMTEncoding_Term.DeclFun
                                                                  (gtok, [],
                                                                    FStar_SMTEncoding_Term.Term_sort,
                                                                    (
                                                                    Some
                                                                    "Token for fuel-instrumented partial applications")) in
                                                              let vars_tm =
                                                                FStar_List.map
                                                                  FStar_SMTEncoding_Util.mkFreeV
                                                                  vars in
                                                              let app =
                                                                let uu____12327
                                                                  =
                                                                  let uu____12331
                                                                    =
                                                                    FStar_List.map
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    vars in
                                                                  (f,
                                                                    uu____12331) in
                                                                FStar_SMTEncoding_Util.mkApp
                                                                  uu____12327 in
                                                              let gsapp =
                                                                let uu____12337
                                                                  =
                                                                  let uu____12341
                                                                    =
                                                                    let uu____12343
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    ("SFuel",
                                                                    [fuel_tm]) in
                                                                    uu____12343
                                                                    ::
                                                                    vars_tm in
                                                                  (g,
                                                                    uu____12341) in
                                                                FStar_SMTEncoding_Util.mkApp
                                                                  uu____12337 in
                                                              let gmax =
                                                                let uu____12347
                                                                  =
                                                                  let uu____12351
                                                                    =
                                                                    let uu____12353
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    ("MaxFuel",
                                                                    []) in
                                                                    uu____12353
                                                                    ::
                                                                    vars_tm in
                                                                  (g,
                                                                    uu____12351) in
                                                                FStar_SMTEncoding_Util.mkApp
                                                                  uu____12347 in
                                                              let body =
                                                                let uu____12357
                                                                  =
                                                                  FStar_TypeChecker_Env.is_reifiable_function
                                                                    env'.tcenv
                                                                    t_norm in
                                                                match uu____12357
                                                                with
                                                                | true  ->
                                                                    reify_body
                                                                    env'.tcenv
                                                                    body
                                                                | uu____12358
                                                                    -> body in
                                                              let uu____12359
                                                                =
                                                                encode_term
                                                                  body env' in
                                                              (match uu____12359
                                                               with
                                                               | (body_tm,decls2)
                                                                   ->
                                                                   let eqn_g
                                                                    =
                                                                    let uu____12370
                                                                    =
                                                                    let uu____12375
                                                                    =
                                                                    let uu____12376
                                                                    =
                                                                    let uu____12384
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (gsapp,
                                                                    body_tm) in
                                                                    ([
                                                                    [gsapp]],
                                                                    (Some
                                                                    (Prims.parse_int
                                                                    "0")),
                                                                    (fuel ::
                                                                    vars),
                                                                    uu____12384) in
                                                                    FStar_SMTEncoding_Util.mkForall'
                                                                    uu____12376 in
                                                                    let uu____12395
                                                                    =
                                                                    let uu____12397
                                                                    =
                                                                    FStar_Util.format1
                                                                    "Equation for fuel-instrumented recursive function: %s"
                                                                    flid.FStar_Ident.str in
                                                                    Some
                                                                    uu____12397 in
                                                                    (uu____12375,
                                                                    uu____12395,
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "equation_with_fuel_"
                                                                    g))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____12370 in
                                                                   let eqn_f
                                                                    =
                                                                    let uu____12401
                                                                    =
                                                                    let uu____12406
                                                                    =
                                                                    let uu____12407
                                                                    =
                                                                    let uu____12413
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (app,
                                                                    gmax) in
                                                                    ([[app]],
                                                                    vars,
                                                                    uu____12413) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____12407 in
                                                                    (uu____12406,
                                                                    (Some
                                                                    "Correspondence of recursive function to instrumented version"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "fuel_correspondence_"
                                                                    g))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____12401 in
                                                                   let eqn_g'
                                                                    =
                                                                    let uu____12422
                                                                    =
                                                                    let uu____12427
                                                                    =
                                                                    let uu____12428
                                                                    =
                                                                    let uu____12434
                                                                    =
                                                                    let uu____12435
                                                                    =
                                                                    let uu____12438
                                                                    =
                                                                    let uu____12439
                                                                    =
                                                                    let uu____12443
                                                                    =
                                                                    let uu____12445
                                                                    =
                                                                    FStar_SMTEncoding_Term.n_fuel
                                                                    (Prims.parse_int
                                                                    "0") in
                                                                    uu____12445
                                                                    ::
                                                                    vars_tm in
                                                                    (g,
                                                                    uu____12443) in
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    uu____12439 in
                                                                    (gsapp,
                                                                    uu____12438) in
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    uu____12435 in
                                                                    ([
                                                                    [gsapp]],
                                                                    (fuel ::
                                                                    vars),
                                                                    uu____12434) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____12428 in
                                                                    (uu____12427,
                                                                    (Some
                                                                    "Fuel irrelevance"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "fuel_irrelevance_"
                                                                    g))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____12422 in
                                                                   let uu____12458
                                                                    =
                                                                    let uu____12463
                                                                    =
                                                                    encode_binders
                                                                    None
                                                                    formals
                                                                    env0 in
                                                                    match uu____12463
                                                                    with
                                                                    | 
                                                                    (vars,v_guards,env,binder_decls,uu____12480)
                                                                    ->
                                                                    let vars_tm
                                                                    =
                                                                    FStar_List.map
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    vars in
                                                                    let gapp
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    (g,
                                                                    (fuel_tm
                                                                    ::
                                                                    vars_tm)) in
                                                                    let tok_corr
                                                                    =
                                                                    let tok_app
                                                                    =
                                                                    let uu____12495
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    (gtok,
                                                                    FStar_SMTEncoding_Term.Term_sort) in
                                                                    mk_Apply
                                                                    uu____12495
                                                                    (fuel ::
                                                                    vars) in
                                                                    let uu____12498
                                                                    =
                                                                    let uu____12503
                                                                    =
                                                                    let uu____12504
                                                                    =
                                                                    let uu____12510
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (tok_app,
                                                                    gapp) in
                                                                    ([
                                                                    [tok_app]],
                                                                    (fuel ::
                                                                    vars),
                                                                    uu____12510) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____12504 in
                                                                    (uu____12503,
                                                                    (Some
                                                                    "Fuel token correspondence"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "fuel_token_correspondence_"
                                                                    gtok))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____12498 in
                                                                    let uu____12522
                                                                    =
                                                                    let uu____12526
                                                                    =
                                                                    encode_term_pred
                                                                    None tres
                                                                    env gapp in
                                                                    match uu____12526
                                                                    with
                                                                    | 
                                                                    (g_typing,d3)
                                                                    ->
                                                                    let uu____12534
                                                                    =
                                                                    let uu____12536
                                                                    =
                                                                    let uu____12537
                                                                    =
                                                                    let uu____12542
                                                                    =
                                                                    let uu____12543
                                                                    =
                                                                    let uu____12549
                                                                    =
                                                                    let uu____12550
                                                                    =
                                                                    let uu____12553
                                                                    =
                                                                    FStar_SMTEncoding_Util.mk_and_l
                                                                    v_guards in
                                                                    (uu____12553,
                                                                    g_typing) in
                                                                    FStar_SMTEncoding_Util.mkImp
                                                                    uu____12550 in
                                                                    ([[gapp]],
                                                                    (fuel ::
                                                                    vars),
                                                                    uu____12549) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____12543 in
                                                                    (uu____12542,
                                                                    (Some
                                                                    "Typing correspondence of token to term"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "token_correspondence_"
                                                                    g))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____12537 in
                                                                    [uu____12536] in
                                                                    (d3,
                                                                    uu____12534) in
                                                                    (match uu____12522
                                                                    with
                                                                    | 
                                                                    (aux_decls,typing_corr)
                                                                    ->
                                                                    ((FStar_List.append
                                                                    binder_decls
                                                                    aux_decls),
                                                                    (FStar_List.append
                                                                    typing_corr
                                                                    [tok_corr]))) in
                                                                   (match uu____12458
                                                                    with
                                                                    | 
                                                                    (aux_decls,g_typing)
                                                                    ->
                                                                    ((FStar_List.append
                                                                    binder_decls
                                                                    (FStar_List.append
                                                                    decls2
                                                                    (FStar_List.append
                                                                    aux_decls
                                                                    [decl_g;
                                                                    decl_g_tok]))),
                                                                    (FStar_List.append
                                                                    [eqn_g;
                                                                    eqn_g';
                                                                    eqn_f]
                                                                    g_typing),
                                                                    env0)))))))) in
                                       let uu____12589 =
                                         let uu____12596 =
                                           FStar_List.zip3 gtoks typs
                                             bindings in
                                         FStar_List.fold_left
                                           (fun uu____12628  ->
                                              fun uu____12629  ->
                                                match (uu____12628,
                                                        uu____12629)
                                                with
                                                | ((decls,eqns,env0),
                                                   (gtok,ty,lb)) ->
                                                    let uu____12705 =
                                                      encode_one_binding env0
                                                        gtok ty lb in
                                                    (match uu____12705 with
                                                     | (decls',eqns',env0) ->
                                                         ((decls' :: decls),
                                                           (FStar_List.append
                                                              eqns' eqns),
                                                           env0)))
                                           ([decls], [], env0) uu____12596 in
                                       (match uu____12589 with
                                        | (decls,eqns,env0) ->
                                            let uu____12745 =
                                              let isDeclFun uu___123_12753 =
                                                match uu___123_12753 with
                                                | FStar_SMTEncoding_Term.DeclFun
                                                    uu____12754 -> true
                                                | uu____12760 -> false in
                                              let uu____12761 =
                                                FStar_All.pipe_right decls
                                                  FStar_List.flatten in
                                              FStar_All.pipe_right
                                                uu____12761
                                                (FStar_List.partition
                                                   isDeclFun) in
                                            (match uu____12745 with
                                             | (prefix_decls,rest) ->
                                                 let eqns =
                                                   FStar_List.rev eqns in
                                                 ((FStar_List.append
                                                     prefix_decls
                                                     (FStar_List.append rest
                                                        eqns)), env0)))))))
             with
             | Let_rec_unencodeable  ->
                 let msg =
                   let uu____12788 =
                     FStar_All.pipe_right bindings
                       (FStar_List.map
                          (fun lb  ->
                             FStar_Syntax_Print.lbname_to_string
                               lb.FStar_Syntax_Syntax.lbname)) in
                   FStar_All.pipe_right uu____12788
                     (FStar_String.concat " and ") in
                 let decl =
                   FStar_SMTEncoding_Term.Caption
                     (Prims.strcat "let rec unencodeable: Skipping: " msg) in
                 ([decl], env))
let rec encode_sigelt:
  env_t ->
    FStar_Syntax_Syntax.sigelt -> (FStar_SMTEncoding_Term.decls_t* env_t)
  =
  fun env  ->
    fun se  ->
      (let uu____12821 =
         FStar_All.pipe_left (FStar_TypeChecker_Env.debug env.tcenv)
           (FStar_Options.Other "SMTEncoding") in
       match uu____12821 with
       | true  ->
           let uu____12822 = FStar_Syntax_Print.sigelt_to_string se in
           FStar_All.pipe_left (FStar_Util.print1 ">>>>Encoding [%s]\n")
             uu____12822
       | uu____12823 -> ());
      (let nm =
         let uu____12825 = FStar_Syntax_Util.lid_of_sigelt se in
         match uu____12825 with | None  -> "" | Some l -> l.FStar_Ident.str in
       let uu____12828 = encode_sigelt' env se in
       match uu____12828 with
       | (g,e) ->
           (match g with
            | [] ->
                let uu____12837 =
                  let uu____12839 =
                    let uu____12840 = FStar_Util.format1 "<Skipped %s/>" nm in
                    FStar_SMTEncoding_Term.Caption uu____12840 in
                  [uu____12839] in
                (uu____12837, e)
            | uu____12842 ->
                let uu____12843 =
                  let uu____12845 =
                    let uu____12847 =
                      let uu____12848 =
                        FStar_Util.format1 "<Start encoding %s>" nm in
                      FStar_SMTEncoding_Term.Caption uu____12848 in
                    uu____12847 :: g in
                  let uu____12849 =
                    let uu____12851 =
                      let uu____12852 =
                        FStar_Util.format1 "</end encoding %s>" nm in
                      FStar_SMTEncoding_Term.Caption uu____12852 in
                    [uu____12851] in
                  FStar_List.append uu____12845 uu____12849 in
                (uu____12843, e)))
and encode_sigelt':
  env_t ->
    FStar_Syntax_Syntax.sigelt -> (FStar_SMTEncoding_Term.decls_t* env_t)
  =
  fun env  ->
    fun se  ->
      match se with
      | FStar_Syntax_Syntax.Sig_new_effect_for_free uu____12860 ->
          failwith "impossible -- removed by tc.fs"
      | FStar_Syntax_Syntax.Sig_pragma _
        |FStar_Syntax_Syntax.Sig_main _
         |FStar_Syntax_Syntax.Sig_effect_abbrev _
          |FStar_Syntax_Syntax.Sig_sub_effect _ -> ([], env)
      | FStar_Syntax_Syntax.Sig_new_effect (ed,uu____12871) ->
          let uu____12872 =
            let uu____12873 =
              FStar_All.pipe_right ed.FStar_Syntax_Syntax.qualifiers
                (FStar_List.contains FStar_Syntax_Syntax.Reifiable) in
            FStar_All.pipe_right uu____12873 Prims.op_Negation in
          (match uu____12872 with
           | true  -> ([], env)
           | uu____12878 ->
               let close_effect_params tm =
                 match ed.FStar_Syntax_Syntax.binders with
                 | [] -> tm
                 | uu____12893 ->
                     let uu____12894 =
                       let uu____12897 =
                         let uu____12898 =
                           let uu____12913 =
                             FStar_All.pipe_left (fun _0_37  -> Some _0_37)
                               (FStar_Util.Inr
                                  (FStar_Syntax_Const.effect_Tot_lid,
                                    [FStar_Syntax_Syntax.TOTAL])) in
                           ((ed.FStar_Syntax_Syntax.binders), tm,
                             uu____12913) in
                         FStar_Syntax_Syntax.Tm_abs uu____12898 in
                       FStar_Syntax_Syntax.mk uu____12897 in
                     uu____12894 None tm.FStar_Syntax_Syntax.pos in
               let encode_action env a =
                 let uu____12966 =
                   new_term_constant_and_tok_from_lid env
                     a.FStar_Syntax_Syntax.action_name in
                 match uu____12966 with
                 | (aname,atok,env) ->
                     let uu____12976 =
                       FStar_Syntax_Util.arrow_formals_comp
                         a.FStar_Syntax_Syntax.action_typ in
                     (match uu____12976 with
                      | (formals,uu____12986) ->
                          let uu____12993 =
                            let uu____12996 =
                              close_effect_params
                                a.FStar_Syntax_Syntax.action_defn in
                            encode_term uu____12996 env in
                          (match uu____12993 with
                           | (tm,decls) ->
                               let a_decls =
                                 let uu____13004 =
                                   let uu____13005 =
                                     let uu____13011 =
                                       FStar_All.pipe_right formals
                                         (FStar_List.map
                                            (fun uu____13019  ->
                                               FStar_SMTEncoding_Term.Term_sort)) in
                                     (aname, uu____13011,
                                       FStar_SMTEncoding_Term.Term_sort,
                                       (Some "Action")) in
                                   FStar_SMTEncoding_Term.DeclFun uu____13005 in
                                 [uu____13004;
                                 FStar_SMTEncoding_Term.DeclFun
                                   (atok, [],
                                     FStar_SMTEncoding_Term.Term_sort,
                                     (Some "Action token"))] in
                               let uu____13026 =
                                 let aux uu____13055 uu____13056 =
                                   match (uu____13055, uu____13056) with
                                   | ((bv,uu____13083),(env,acc_sorts,acc))
                                       ->
                                       let uu____13104 = gen_term_var env bv in
                                       (match uu____13104 with
                                        | (xxsym,xx,env) ->
                                            (env,
                                              ((xxsym,
                                                 FStar_SMTEncoding_Term.Term_sort)
                                              :: acc_sorts), (xx :: acc))) in
                                 FStar_List.fold_right aux formals
                                   (env, [], []) in
                               (match uu____13026 with
                                | (uu____13142,xs_sorts,xs) ->
                                    let app =
                                      FStar_SMTEncoding_Util.mkApp
                                        (aname, xs) in
                                    let a_eq =
                                      let uu____13156 =
                                        let uu____13161 =
                                          let uu____13162 =
                                            let uu____13168 =
                                              let uu____13169 =
                                                let uu____13172 =
                                                  mk_Apply tm xs_sorts in
                                                (app, uu____13172) in
                                              FStar_SMTEncoding_Util.mkEq
                                                uu____13169 in
                                            ([[app]], xs_sorts, uu____13168) in
                                          FStar_SMTEncoding_Util.mkForall
                                            uu____13162 in
                                        (uu____13161,
                                          (Some "Action equality"),
                                          (Some
                                             (Prims.strcat aname "_equality"))) in
                                      FStar_SMTEncoding_Term.Assume
                                        uu____13156 in
                                    let tok_correspondence =
                                      let tok_term =
                                        FStar_SMTEncoding_Util.mkFreeV
                                          (atok,
                                            FStar_SMTEncoding_Term.Term_sort) in
                                      let tok_app =
                                        mk_Apply tok_term xs_sorts in
                                      let uu____13185 =
                                        let uu____13190 =
                                          let uu____13191 =
                                            let uu____13197 =
                                              FStar_SMTEncoding_Util.mkEq
                                                (tok_app, app) in
                                            ([[tok_app]], xs_sorts,
                                              uu____13197) in
                                          FStar_SMTEncoding_Util.mkForall
                                            uu____13191 in
                                        (uu____13190,
                                          (Some "Action token correspondence"),
                                          (Some
                                             (Prims.strcat aname
                                                "_token_correspondence"))) in
                                      FStar_SMTEncoding_Term.Assume
                                        uu____13185 in
                                    (env,
                                      (FStar_List.append decls
                                         (FStar_List.append a_decls
                                            [a_eq; tok_correspondence])))))) in
               let uu____13208 =
                 FStar_Util.fold_map encode_action env
                   ed.FStar_Syntax_Syntax.actions in
               (match uu____13208 with
                | (env,decls2) -> ((FStar_List.flatten decls2), env)))
      | FStar_Syntax_Syntax.Sig_declare_typ
          (lid,uu____13224,uu____13225,uu____13226,uu____13227) when
          FStar_Ident.lid_equals lid FStar_Syntax_Const.precedes_lid ->
          let uu____13230 = new_term_constant_and_tok_from_lid env lid in
          (match uu____13230 with | (tname,ttok,env) -> ([], env))
      | FStar_Syntax_Syntax.Sig_declare_typ
          (lid,uu____13241,t,quals,uu____13244) ->
          let will_encode_definition =
            let uu____13248 =
              FStar_All.pipe_right quals
                (FStar_Util.for_some
                   (fun uu___124_13250  ->
                      match uu___124_13250 with
                      | FStar_Syntax_Syntax.Assumption 
                        |FStar_Syntax_Syntax.Projector _
                         |FStar_Syntax_Syntax.Discriminator _
                          |FStar_Syntax_Syntax.Irreducible  -> true
                      | uu____13253 -> false)) in
            Prims.op_Negation uu____13248 in
          (match will_encode_definition with
           | true  -> ([], env)
           | uu____13257 ->
               let fv =
                 FStar_Syntax_Syntax.lid_as_fv lid
                   FStar_Syntax_Syntax.Delta_constant None in
               let uu____13259 = encode_top_level_val env fv t quals in
               (match uu____13259 with
                | (decls,env) ->
                    let tname = lid.FStar_Ident.str in
                    let tsym =
                      FStar_SMTEncoding_Util.mkFreeV
                        (tname, FStar_SMTEncoding_Term.Term_sort) in
                    let uu____13271 =
                      let uu____13273 =
                        primitive_type_axioms env.tcenv lid tname tsym in
                      FStar_List.append decls uu____13273 in
                    (uu____13271, env)))
      | FStar_Syntax_Syntax.Sig_assume (l,f,uu____13278,uu____13279) ->
          let uu____13282 = encode_formula f env in
          (match uu____13282 with
           | (f,decls) ->
               let g =
                 let uu____13291 =
                   let uu____13292 =
                     let uu____13297 =
                       let uu____13299 =
                         let uu____13300 = FStar_Syntax_Print.lid_to_string l in
                         FStar_Util.format1 "Assumption: %s" uu____13300 in
                       Some uu____13299 in
                     let uu____13301 =
                       let uu____13303 =
                         varops.mk_unique
                           (Prims.strcat "assumption_" l.FStar_Ident.str) in
                       Some uu____13303 in
                     (f, uu____13297, uu____13301) in
                   FStar_SMTEncoding_Term.Assume uu____13292 in
                 [uu____13291] in
               ((FStar_List.append decls g), env))
      | FStar_Syntax_Syntax.Sig_let (lbs,r,uu____13309,quals,uu____13311)
          when
          FStar_All.pipe_right quals
            (FStar_List.contains FStar_Syntax_Syntax.Irreducible)
          ->
          let uu____13319 =
            FStar_Util.fold_map
              (fun env  ->
                 fun lb  ->
                   let lid =
                     let uu____13326 =
                       let uu____13331 =
                         FStar_Util.right lb.FStar_Syntax_Syntax.lbname in
                       uu____13331.FStar_Syntax_Syntax.fv_name in
                     uu____13326.FStar_Syntax_Syntax.v in
                   let uu____13335 =
                     let uu____13336 =
                       FStar_TypeChecker_Env.try_lookup_val_decl env.tcenv
                         lid in
                     FStar_All.pipe_left FStar_Option.isNone uu____13336 in
                   match uu____13335 with
                   | true  ->
                       let val_decl =
                         FStar_Syntax_Syntax.Sig_declare_typ
                           (lid, (lb.FStar_Syntax_Syntax.lbunivs),
                             (lb.FStar_Syntax_Syntax.lbtyp), quals, r) in
                       let uu____13355 = encode_sigelt' env val_decl in
                       (match uu____13355 with | (decls,env) -> (env, decls))
                   | uu____13362 -> (env, [])) env (Prims.snd lbs) in
          (match uu____13319 with
           | (env,decls) -> ((FStar_List.flatten decls), env))
      | FStar_Syntax_Syntax.Sig_let
          ((uu____13372,{ FStar_Syntax_Syntax.lbname = FStar_Util.Inr b2t;
                          FStar_Syntax_Syntax.lbunivs = uu____13374;
                          FStar_Syntax_Syntax.lbtyp = uu____13375;
                          FStar_Syntax_Syntax.lbeff = uu____13376;
                          FStar_Syntax_Syntax.lbdef = uu____13377;_}::[]),uu____13378,uu____13379,uu____13380,uu____13381)
          when FStar_Syntax_Syntax.fv_eq_lid b2t FStar_Syntax_Const.b2t_lid
          ->
          let uu____13397 =
            new_term_constant_and_tok_from_lid env
              (b2t.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          (match uu____13397 with
           | (tname,ttok,env) ->
               let xx = ("x", FStar_SMTEncoding_Term.Term_sort) in
               let x = FStar_SMTEncoding_Util.mkFreeV xx in
               let valid_b2t_x =
                 let uu____13415 =
                   let uu____13419 =
                     let uu____13421 =
                       FStar_SMTEncoding_Util.mkApp ("Prims.b2t", [x]) in
                     [uu____13421] in
                   ("Valid", uu____13419) in
                 FStar_SMTEncoding_Util.mkApp uu____13415 in
               let decls =
                 let uu____13426 =
                   let uu____13428 =
                     let uu____13429 =
                       let uu____13434 =
                         let uu____13435 =
                           let uu____13441 =
                             let uu____13442 =
                               let uu____13445 =
                                 FStar_SMTEncoding_Util.mkApp
                                   ("BoxBool_proj_0", [x]) in
                               (valid_b2t_x, uu____13445) in
                             FStar_SMTEncoding_Util.mkEq uu____13442 in
                           ([[valid_b2t_x]], [xx], uu____13441) in
                         FStar_SMTEncoding_Util.mkForall uu____13435 in
                       (uu____13434, (Some "b2t def"), (Some "b2t_def")) in
                     FStar_SMTEncoding_Term.Assume uu____13429 in
                   [uu____13428] in
                 (FStar_SMTEncoding_Term.DeclFun
                    (tname, [FStar_SMTEncoding_Term.Term_sort],
                      FStar_SMTEncoding_Term.Term_sort, None))
                   :: uu____13426 in
               (decls, env))
      | FStar_Syntax_Syntax.Sig_let
          (uu____13463,uu____13464,uu____13465,quals,uu____13467) when
          FStar_All.pipe_right quals
            (FStar_Util.for_some
               (fun uu___125_13475  ->
                  match uu___125_13475 with
                  | FStar_Syntax_Syntax.Discriminator uu____13476 -> true
                  | uu____13477 -> false))
          -> ([], env)
      | FStar_Syntax_Syntax.Sig_let
          (uu____13479,uu____13480,lids,quals,uu____13483) when
          (FStar_All.pipe_right lids
             (FStar_Util.for_some
                (fun l  ->
                   let uu____13492 =
                     let uu____13493 = FStar_List.hd l.FStar_Ident.ns in
                     uu____13493.FStar_Ident.idText in
                   uu____13492 = "Prims")))
            &&
            (FStar_All.pipe_right quals
               (FStar_Util.for_some
                  (fun uu___126_13495  ->
                     match uu___126_13495 with
                     | FStar_Syntax_Syntax.Unfold_for_unification_and_vcgen 
                         -> true
                     | uu____13496 -> false)))
          -> ([], env)
      | FStar_Syntax_Syntax.Sig_let
          ((false ,lb::[]),uu____13499,uu____13500,quals,uu____13502) when
          FStar_All.pipe_right quals
            (FStar_Util.for_some
               (fun uu___127_13514  ->
                  match uu___127_13514 with
                  | FStar_Syntax_Syntax.Projector uu____13515 -> true
                  | uu____13518 -> false))
          ->
          let fv = FStar_Util.right lb.FStar_Syntax_Syntax.lbname in
          let l = (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          let uu____13525 = try_lookup_free_var env l in
          (match uu____13525 with
           | Some uu____13529 -> ([], env)
           | None  ->
               let se =
                 FStar_Syntax_Syntax.Sig_declare_typ
                   (l, (lb.FStar_Syntax_Syntax.lbunivs),
                     (lb.FStar_Syntax_Syntax.lbtyp), quals,
                     (FStar_Ident.range_of_lid l)) in
               encode_sigelt env se)
      | FStar_Syntax_Syntax.Sig_let
          ((is_rec,bindings),uu____13538,uu____13539,quals,uu____13541) ->
          encode_top_level_let env (is_rec, bindings) quals
      | FStar_Syntax_Syntax.Sig_bundle
          (ses,uu____13555,uu____13556,uu____13557) ->
          let uu____13564 = encode_signature env ses in
          (match uu____13564 with
           | (g,env) ->
               let uu____13574 =
                 FStar_All.pipe_right g
                   (FStar_List.partition
                      (fun uu___128_13584  ->
                         match uu___128_13584 with
                         | FStar_SMTEncoding_Term.Assume
                             (uu____13585,Some "inversion axiom",uu____13586)
                             -> false
                         | uu____13590 -> true)) in
               (match uu____13574 with
                | (g',inversions) ->
                    let uu____13599 =
                      FStar_All.pipe_right g'
                        (FStar_List.partition
                           (fun uu___129_13609  ->
                              match uu___129_13609 with
                              | FStar_SMTEncoding_Term.DeclFun uu____13610 ->
                                  true
                              | uu____13616 -> false)) in
                    (match uu____13599 with
                     | (decls,rest) ->
                         ((FStar_List.append decls
                             (FStar_List.append rest inversions)), env))))
      | FStar_Syntax_Syntax.Sig_inductive_typ
          (t,uu____13627,tps,k,uu____13630,datas,quals,uu____13633) ->
          let is_logical =
            FStar_All.pipe_right quals
              (FStar_Util.for_some
                 (fun uu___130_13642  ->
                    match uu___130_13642 with
                    | FStar_Syntax_Syntax.Logic 
                      |FStar_Syntax_Syntax.Assumption  -> true
                    | uu____13643 -> false)) in
          let constructor_or_logic_type_decl c =
            match is_logical with
            | true  ->
                let uu____13666 = c in
                (match uu____13666 with
                 | (name,args,uu____13678,uu____13679,uu____13680) ->
                     let uu____13687 =
                       let uu____13688 =
                         let uu____13694 =
                           FStar_All.pipe_right args
                             (FStar_List.map Prims.snd) in
                         (name, uu____13694,
                           FStar_SMTEncoding_Term.Term_sort, None) in
                       FStar_SMTEncoding_Term.DeclFun uu____13688 in
                     [uu____13687])
            | uu____13704 -> FStar_SMTEncoding_Term.constructor_to_decl c in
          let inversion_axioms tapp vars =
            let uu____13719 =
              FStar_All.pipe_right datas
                (FStar_Util.for_some
                   (fun l  ->
                      let uu____13722 =
                        FStar_TypeChecker_Env.try_lookup_lid env.tcenv l in
                      FStar_All.pipe_right uu____13722 FStar_Option.isNone)) in
            match uu____13719 with
            | true  -> []
            | uu____13732 ->
                let uu____13733 =
                  fresh_fvar "x" FStar_SMTEncoding_Term.Term_sort in
                (match uu____13733 with
                 | (xxsym,xx) ->
                     let uu____13739 =
                       FStar_All.pipe_right datas
                         (FStar_List.fold_left
                            (fun uu____13750  ->
                               fun l  ->
                                 match uu____13750 with
                                 | (out,decls) ->
                                     let uu____13762 =
                                       FStar_TypeChecker_Env.lookup_datacon
                                         env.tcenv l in
                                     (match uu____13762 with
                                      | (uu____13768,data_t) ->
                                          let uu____13770 =
                                            FStar_Syntax_Util.arrow_formals
                                              data_t in
                                          (match uu____13770 with
                                           | (args,res) ->
                                               let indices =
                                                 let uu____13799 =
                                                   let uu____13800 =
                                                     FStar_Syntax_Subst.compress
                                                       res in
                                                   uu____13800.FStar_Syntax_Syntax.n in
                                                 match uu____13799 with
                                                 | FStar_Syntax_Syntax.Tm_app
                                                     (uu____13808,indices) ->
                                                     indices
                                                 | uu____13824 -> [] in
                                               let env =
                                                 FStar_All.pipe_right args
                                                   (FStar_List.fold_left
                                                      (fun env  ->
                                                         fun uu____13836  ->
                                                           match uu____13836
                                                           with
                                                           | (x,uu____13840)
                                                               ->
                                                               let uu____13841
                                                                 =
                                                                 let uu____13842
                                                                   =
                                                                   let uu____13846
                                                                    =
                                                                    mk_term_projector_name
                                                                    l x in
                                                                   (uu____13846,
                                                                    [xx]) in
                                                                 FStar_SMTEncoding_Util.mkApp
                                                                   uu____13842 in
                                                               push_term_var
                                                                 env x
                                                                 uu____13841)
                                                      env) in
                                               let uu____13848 =
                                                 encode_args indices env in
                                               (match uu____13848 with
                                                | (indices,decls') ->
                                                    ((match (FStar_List.length
                                                               indices)
                                                              <>
                                                              (FStar_List.length
                                                                 vars)
                                                      with
                                                      | true  ->
                                                          failwith
                                                            "Impossible"
                                                      | uu____13866 -> ());
                                                     (let eqs =
                                                        let uu____13868 =
                                                          FStar_List.map2
                                                            (fun v  ->
                                                               fun a  ->
                                                                 let uu____13876
                                                                   =
                                                                   let uu____13879
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    v in
                                                                   (uu____13879,
                                                                    a) in
                                                                 FStar_SMTEncoding_Util.mkEq
                                                                   uu____13876)
                                                            vars indices in
                                                        FStar_All.pipe_right
                                                          uu____13868
                                                          FStar_SMTEncoding_Util.mk_and_l in
                                                      let uu____13881 =
                                                        let uu____13882 =
                                                          let uu____13885 =
                                                            let uu____13886 =
                                                              let uu____13889
                                                                =
                                                                mk_data_tester
                                                                  env l xx in
                                                              (uu____13889,
                                                                eqs) in
                                                            FStar_SMTEncoding_Util.mkAnd
                                                              uu____13886 in
                                                          (out, uu____13885) in
                                                        FStar_SMTEncoding_Util.mkOr
                                                          uu____13882 in
                                                      (uu____13881,
                                                        (FStar_List.append
                                                           decls decls'))))))))
                            (FStar_SMTEncoding_Util.mkFalse, [])) in
                     (match uu____13739 with
                      | (data_ax,decls) ->
                          let uu____13897 =
                            fresh_fvar "f" FStar_SMTEncoding_Term.Fuel_sort in
                          (match uu____13897 with
                           | (ffsym,ff) ->
                               let fuel_guarded_inversion =
                                 let xx_has_type_sfuel =
                                   match (FStar_List.length datas) >
                                           (Prims.parse_int "1")
                                   with
                                   | true  ->
                                       let uu____13908 =
                                         FStar_SMTEncoding_Util.mkApp
                                           ("SFuel", [ff]) in
                                       FStar_SMTEncoding_Term.mk_HasTypeFuel
                                         uu____13908 xx tapp
                                   | uu____13910 ->
                                       FStar_SMTEncoding_Term.mk_HasTypeFuel
                                         ff xx tapp in
                                 let uu____13911 =
                                   let uu____13916 =
                                     let uu____13917 =
                                       let uu____13923 =
                                         add_fuel
                                           (ffsym,
                                             FStar_SMTEncoding_Term.Fuel_sort)
                                           ((xxsym,
                                              FStar_SMTEncoding_Term.Term_sort)
                                           :: vars) in
                                       let uu____13931 =
                                         FStar_SMTEncoding_Util.mkImp
                                           (xx_has_type_sfuel, data_ax) in
                                       ([[xx_has_type_sfuel]], uu____13923,
                                         uu____13931) in
                                     FStar_SMTEncoding_Util.mkForall
                                       uu____13917 in
                                   let uu____13939 =
                                     let uu____13941 =
                                       varops.mk_unique
                                         (Prims.strcat
                                            "fuel_guarded_inversion_"
                                            t.FStar_Ident.str) in
                                     Some uu____13941 in
                                   (uu____13916, (Some "inversion axiom"),
                                     uu____13939) in
                                 FStar_SMTEncoding_Term.Assume uu____13911 in
                               let pattern_guarded_inversion =
                                 let uu____13946 =
                                   (contains_name env "Prims.inversion") &&
                                     ((FStar_List.length datas) >
                                        (Prims.parse_int "1")) in
                                 match uu____13946 with
                                 | true  ->
                                     let xx_has_type_fuel =
                                       FStar_SMTEncoding_Term.mk_HasTypeFuel
                                         ff xx tapp in
                                     let pattern_guard =
                                       FStar_SMTEncoding_Util.mkApp
                                         ("Prims.inversion", [tapp]) in
                                     let uu____13954 =
                                       let uu____13955 =
                                         let uu____13960 =
                                           let uu____13961 =
                                             let uu____13967 =
                                               add_fuel
                                                 (ffsym,
                                                   FStar_SMTEncoding_Term.Fuel_sort)
                                                 ((xxsym,
                                                    FStar_SMTEncoding_Term.Term_sort)
                                                 :: vars) in
                                             let uu____13975 =
                                               FStar_SMTEncoding_Util.mkImp
                                                 (xx_has_type_fuel, data_ax) in
                                             ([[xx_has_type_fuel;
                                               pattern_guard]], uu____13967,
                                               uu____13975) in
                                           FStar_SMTEncoding_Util.mkForall
                                             uu____13961 in
                                         let uu____13983 =
                                           let uu____13985 =
                                             varops.mk_unique
                                               (Prims.strcat
                                                  "pattern_guarded_inversion_"
                                                  t.FStar_Ident.str) in
                                           Some uu____13985 in
                                         (uu____13960,
                                           (Some "inversion axiom"),
                                           uu____13983) in
                                       FStar_SMTEncoding_Term.Assume
                                         uu____13955 in
                                     [uu____13954]
                                 | uu____13988 -> [] in
                               FStar_List.append decls
                                 (FStar_List.append [fuel_guarded_inversion]
                                    pattern_guarded_inversion)))) in
          let uu____13989 =
            let uu____13997 =
              let uu____13998 = FStar_Syntax_Subst.compress k in
              uu____13998.FStar_Syntax_Syntax.n in
            match uu____13997 with
            | FStar_Syntax_Syntax.Tm_arrow (formals,kres) ->
                ((FStar_List.append tps formals),
                  (FStar_Syntax_Util.comp_result kres))
            | uu____14027 -> (tps, k) in
          (match uu____13989 with
           | (formals,res) ->
               let uu____14042 = FStar_Syntax_Subst.open_term formals res in
               (match uu____14042 with
                | (formals,res) ->
                    let uu____14049 = encode_binders None formals env in
                    (match uu____14049 with
                     | (vars,guards,env',binder_decls,uu____14064) ->
                         let uu____14071 =
                           new_term_constant_and_tok_from_lid env t in
                         (match uu____14071 with
                          | (tname,ttok,env) ->
                              let ttok_tm =
                                FStar_SMTEncoding_Util.mkApp (ttok, []) in
                              let guard =
                                FStar_SMTEncoding_Util.mk_and_l guards in
                              let tapp =
                                let uu____14084 =
                                  let uu____14088 =
                                    FStar_List.map
                                      FStar_SMTEncoding_Util.mkFreeV vars in
                                  (tname, uu____14088) in
                                FStar_SMTEncoding_Util.mkApp uu____14084 in
                              let uu____14093 =
                                let tname_decl =
                                  let uu____14099 =
                                    let uu____14108 =
                                      FStar_All.pipe_right vars
                                        (FStar_List.map
                                           (fun uu____14120  ->
                                              match uu____14120 with
                                              | (n,s) ->
                                                  ((Prims.strcat tname n), s))) in
                                    let uu____14127 = varops.next_id () in
                                    (tname, uu____14108,
                                      FStar_SMTEncoding_Term.Term_sort,
                                      uu____14127, false) in
                                  constructor_or_logic_type_decl uu____14099 in
                                let uu____14131 =
                                  match vars with
                                  | [] ->
                                      let uu____14138 =
                                        let uu____14139 =
                                          let uu____14141 =
                                            FStar_SMTEncoding_Util.mkApp
                                              (tname, []) in
                                          FStar_All.pipe_left
                                            (fun _0_38  -> Some _0_38)
                                            uu____14141 in
                                        push_free_var env t tname uu____14139 in
                                      ([], uu____14138)
                                  | uu____14145 ->
                                      let ttok_decl =
                                        FStar_SMTEncoding_Term.DeclFun
                                          (ttok, [],
                                            FStar_SMTEncoding_Term.Term_sort,
                                            (Some "token")) in
                                      let ttok_fresh =
                                        let uu____14151 = varops.next_id () in
                                        FStar_SMTEncoding_Term.fresh_token
                                          (ttok,
                                            FStar_SMTEncoding_Term.Term_sort)
                                          uu____14151 in
                                      let ttok_app = mk_Apply ttok_tm vars in
                                      let pats = [[ttok_app]; [tapp]] in
                                      let name_tok_corr =
                                        let uu____14160 =
                                          let uu____14165 =
                                            let uu____14166 =
                                              let uu____14174 =
                                                FStar_SMTEncoding_Util.mkEq
                                                  (ttok_app, tapp) in
                                              (pats, None, vars, uu____14174) in
                                            FStar_SMTEncoding_Util.mkForall'
                                              uu____14166 in
                                          (uu____14165,
                                            (Some "name-token correspondence"),
                                            (Some
                                               (Prims.strcat
                                                  "token_correspondence_"
                                                  ttok))) in
                                        FStar_SMTEncoding_Term.Assume
                                          uu____14160 in
                                      ([ttok_decl; ttok_fresh; name_tok_corr],
                                        env) in
                                match uu____14131 with
                                | (tok_decls,env) ->
                                    ((FStar_List.append tname_decl tok_decls),
                                      env) in
                              (match uu____14093 with
                               | (decls,env) ->
                                   let kindingAx =
                                     let uu____14198 =
                                       encode_term_pred None res env' tapp in
                                     match uu____14198 with
                                     | (k,decls) ->
                                         let karr =
                                           match (FStar_List.length formals)
                                                   > (Prims.parse_int "0")
                                           with
                                           | true  ->
                                               let uu____14212 =
                                                 let uu____14213 =
                                                   let uu____14218 =
                                                     let uu____14219 =
                                                       FStar_SMTEncoding_Term.mk_PreType
                                                         ttok_tm in
                                                     FStar_SMTEncoding_Term.mk_tester
                                                       "Tm_arrow" uu____14219 in
                                                   (uu____14218,
                                                     (Some "kinding"),
                                                     (Some
                                                        (Prims.strcat
                                                           "pre_kinding_"
                                                           ttok))) in
                                                 FStar_SMTEncoding_Term.Assume
                                                   uu____14213 in
                                               [uu____14212]
                                           | uu____14222 -> [] in
                                         let uu____14223 =
                                           let uu____14225 =
                                             let uu____14227 =
                                               let uu____14228 =
                                                 let uu____14233 =
                                                   let uu____14234 =
                                                     let uu____14240 =
                                                       FStar_SMTEncoding_Util.mkImp
                                                         (guard, k) in
                                                     ([[tapp]], vars,
                                                       uu____14240) in
                                                   FStar_SMTEncoding_Util.mkForall
                                                     uu____14234 in
                                                 (uu____14233, None,
                                                   (Some
                                                      (Prims.strcat
                                                         "kinding_" ttok))) in
                                               FStar_SMTEncoding_Term.Assume
                                                 uu____14228 in
                                             [uu____14227] in
                                           FStar_List.append karr uu____14225 in
                                         FStar_List.append decls uu____14223 in
                                   let aux =
                                     let uu____14250 =
                                       let uu____14252 =
                                         inversion_axioms tapp vars in
                                       let uu____14254 =
                                         let uu____14256 =
                                           pretype_axiom tapp vars in
                                         [uu____14256] in
                                       FStar_List.append uu____14252
                                         uu____14254 in
                                     FStar_List.append kindingAx uu____14250 in
                                   let g =
                                     FStar_List.append decls
                                       (FStar_List.append binder_decls aux) in
                                   (g, env))))))
      | FStar_Syntax_Syntax.Sig_datacon
          (d,uu____14261,uu____14262,uu____14263,uu____14264,uu____14265,uu____14266,uu____14267)
          when FStar_Ident.lid_equals d FStar_Syntax_Const.lexcons_lid ->
          ([], env)
      | FStar_Syntax_Syntax.Sig_datacon
          (d,uu____14274,t,uu____14276,n_tps,quals,uu____14279,drange) ->
          let uu____14285 = new_term_constant_and_tok_from_lid env d in
          (match uu____14285 with
           | (ddconstrsym,ddtok,env) ->
               let ddtok_tm = FStar_SMTEncoding_Util.mkApp (ddtok, []) in
               let uu____14296 = FStar_Syntax_Util.arrow_formals t in
               (match uu____14296 with
                | (formals,t_res) ->
                    let uu____14318 =
                      fresh_fvar "f" FStar_SMTEncoding_Term.Fuel_sort in
                    (match uu____14318 with
                     | (fuel_var,fuel_tm) ->
                         let s_fuel_tm =
                           FStar_SMTEncoding_Util.mkApp ("SFuel", [fuel_tm]) in
                         let uu____14327 =
                           encode_binders (Some fuel_tm) formals env in
                         (match uu____14327 with
                          | (vars,guards,env',binder_decls,names) ->
                              let projectors =
                                FStar_All.pipe_right names
                                  (FStar_List.map
                                     (fun x  ->
                                        let uu____14360 =
                                          mk_term_projector_name d x in
                                        (uu____14360,
                                          FStar_SMTEncoding_Term.Term_sort))) in
                              let datacons =
                                let uu____14362 =
                                  let uu____14371 = varops.next_id () in
                                  (ddconstrsym, projectors,
                                    FStar_SMTEncoding_Term.Term_sort,
                                    uu____14371, true) in
                                FStar_All.pipe_right uu____14362
                                  FStar_SMTEncoding_Term.constructor_to_decl in
                              let app = mk_Apply ddtok_tm vars in
                              let guard =
                                FStar_SMTEncoding_Util.mk_and_l guards in
                              let xvars =
                                FStar_List.map FStar_SMTEncoding_Util.mkFreeV
                                  vars in
                              let dapp =
                                FStar_SMTEncoding_Util.mkApp
                                  (ddconstrsym, xvars) in
                              let uu____14391 =
                                encode_term_pred None t env ddtok_tm in
                              (match uu____14391 with
                               | (tok_typing,decls3) ->
                                   let uu____14398 =
                                     encode_binders (Some fuel_tm) formals
                                       env in
                                   (match uu____14398 with
                                    | (vars',guards',env'',decls_formals,uu____14413)
                                        ->
                                        let uu____14420 =
                                          let xvars =
                                            FStar_List.map
                                              FStar_SMTEncoding_Util.mkFreeV
                                              vars' in
                                          let dapp =
                                            FStar_SMTEncoding_Util.mkApp
                                              (ddconstrsym, xvars) in
                                          encode_term_pred (Some fuel_tm)
                                            t_res env'' dapp in
                                        (match uu____14420 with
                                         | (ty_pred',decls_pred) ->
                                             let guard' =
                                               FStar_SMTEncoding_Util.mk_and_l
                                                 guards' in
                                             let proxy_fresh =
                                               match formals with
                                               | [] -> []
                                               | uu____14439 ->
                                                   let uu____14443 =
                                                     let uu____14444 =
                                                       varops.next_id () in
                                                     FStar_SMTEncoding_Term.fresh_token
                                                       (ddtok,
                                                         FStar_SMTEncoding_Term.Term_sort)
                                                       uu____14444 in
                                                   [uu____14443] in
                                             let encode_elim uu____14451 =
                                               let uu____14452 =
                                                 FStar_Syntax_Util.head_and_args
                                                   t_res in
                                               match uu____14452 with
                                               | (head,args) ->
                                                   let uu____14481 =
                                                     let uu____14482 =
                                                       FStar_Syntax_Subst.compress
                                                         head in
                                                     uu____14482.FStar_Syntax_Syntax.n in
                                                   (match uu____14481 with
                                                    | FStar_Syntax_Syntax.Tm_uinst
                                                      ({
                                                         FStar_Syntax_Syntax.n
                                                           =
                                                           FStar_Syntax_Syntax.Tm_fvar
                                                           fv;
                                                         FStar_Syntax_Syntax.tk
                                                           = _;
                                                         FStar_Syntax_Syntax.pos
                                                           = _;
                                                         FStar_Syntax_Syntax.vars
                                                           = _;_},_)
                                                      |FStar_Syntax_Syntax.Tm_fvar
                                                      fv ->
                                                        let encoded_head =
                                                          lookup_free_var_name
                                                            env'
                                                            fv.FStar_Syntax_Syntax.fv_name in
                                                        let uu____14500 =
                                                          encode_args args
                                                            env' in
                                                        (match uu____14500
                                                         with
                                                         | (encoded_args,arg_decls)
                                                             ->
                                                             let uu____14511
                                                               =
                                                               FStar_List.fold_left
                                                                 (fun
                                                                    uu____14522
                                                                     ->
                                                                    fun arg 
                                                                    ->
                                                                    match uu____14522
                                                                    with
                                                                    | 
                                                                    (env,arg_vars,eqns)
                                                                    ->
                                                                    let uu____14541
                                                                    =
                                                                    let uu____14545
                                                                    =
                                                                    FStar_Syntax_Syntax.new_bv
                                                                    None
                                                                    FStar_Syntax_Syntax.tun in
                                                                    gen_term_var
                                                                    env
                                                                    uu____14545 in
                                                                    (match uu____14541
                                                                    with
                                                                    | 
                                                                    (uu____14551,xv,env)
                                                                    ->
                                                                    let uu____14554
                                                                    =
                                                                    let uu____14556
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (arg, xv) in
                                                                    uu____14556
                                                                    :: eqns in
                                                                    (env, (xv
                                                                    ::
                                                                    arg_vars),
                                                                    uu____14554)))
                                                                 (env', [],
                                                                   [])
                                                                 encoded_args in
                                                             (match uu____14511
                                                              with
                                                              | (uu____14564,arg_vars,eqns)
                                                                  ->
                                                                  let arg_vars
                                                                    =
                                                                    FStar_List.rev
                                                                    arg_vars in
                                                                  let ty =
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    (encoded_head,
                                                                    arg_vars) in
                                                                  let xvars =
                                                                    FStar_List.map
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    vars in
                                                                  let dapp =
                                                                    FStar_SMTEncoding_Util.mkApp
                                                                    (ddconstrsym,
                                                                    xvars) in
                                                                  let ty_pred
                                                                    =
                                                                    FStar_SMTEncoding_Term.mk_HasTypeWithFuel
                                                                    (Some
                                                                    s_fuel_tm)
                                                                    dapp ty in
                                                                  let arg_binders
                                                                    =
                                                                    FStar_List.map
                                                                    FStar_SMTEncoding_Term.fv_of_term
                                                                    arg_vars in
                                                                  let typing_inversion
                                                                    =
                                                                    let uu____14585
                                                                    =
                                                                    let uu____14590
                                                                    =
                                                                    let uu____14591
                                                                    =
                                                                    let uu____14597
                                                                    =
                                                                    add_fuel
                                                                    (fuel_var,
                                                                    FStar_SMTEncoding_Term.Fuel_sort)
                                                                    (FStar_List.append
                                                                    vars
                                                                    arg_binders) in
                                                                    let uu____14603
                                                                    =
                                                                    let uu____14604
                                                                    =
                                                                    let uu____14607
                                                                    =
                                                                    FStar_SMTEncoding_Util.mk_and_l
                                                                    (FStar_List.append
                                                                    eqns
                                                                    guards) in
                                                                    (ty_pred,
                                                                    uu____14607) in
                                                                    FStar_SMTEncoding_Util.mkImp
                                                                    uu____14604 in
                                                                    ([
                                                                    [ty_pred]],
                                                                    uu____14597,
                                                                    uu____14603) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____14591 in
                                                                    (uu____14590,
                                                                    (Some
                                                                    "data constructor typing elim"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "data_elim_"
                                                                    ddconstrsym))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____14585 in
                                                                  let subterm_ordering
                                                                    =
                                                                    match 
                                                                    FStar_Ident.lid_equals
                                                                    d
                                                                    FStar_Syntax_Const.lextop_lid
                                                                    with
                                                                    | 
                                                                    true  ->
                                                                    let x =
                                                                    let uu____14621
                                                                    =
                                                                    varops.fresh
                                                                    "x" in
                                                                    (uu____14621,
                                                                    FStar_SMTEncoding_Term.Term_sort) in
                                                                    let xtm =
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    x in
                                                                    let uu____14623
                                                                    =
                                                                    let uu____14628
                                                                    =
                                                                    let uu____14629
                                                                    =
                                                                    let uu____14635
                                                                    =
                                                                    let uu____14638
                                                                    =
                                                                    let uu____14640
                                                                    =
                                                                    FStar_SMTEncoding_Util.mk_Precedes
                                                                    xtm dapp in
                                                                    [uu____14640] in
                                                                    [uu____14638] in
                                                                    let uu____14643
                                                                    =
                                                                    let uu____14644
                                                                    =
                                                                    let uu____14647
                                                                    =
                                                                    FStar_SMTEncoding_Term.mk_tester
                                                                    "LexCons"
                                                                    xtm in
                                                                    let uu____14648
                                                                    =
                                                                    FStar_SMTEncoding_Util.mk_Precedes
                                                                    xtm dapp in
                                                                    (uu____14647,
                                                                    uu____14648) in
                                                                    FStar_SMTEncoding_Util.mkImp
                                                                    uu____14644 in
                                                                    (uu____14635,
                                                                    [x],
                                                                    uu____14643) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____14629 in
                                                                    let uu____14658
                                                                    =
                                                                    let uu____14660
                                                                    =
                                                                    varops.mk_unique
                                                                    "lextop" in
                                                                    Some
                                                                    uu____14660 in
                                                                    (uu____14628,
                                                                    (Some
                                                                    "lextop is top"),
                                                                    uu____14658) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____14623
                                                                    | 
                                                                    uu____14663
                                                                    ->
                                                                    let prec
                                                                    =
                                                                    FStar_All.pipe_right
                                                                    vars
                                                                    (FStar_List.collect
                                                                    (fun v 
                                                                    ->
                                                                    match 
                                                                    Prims.snd
                                                                    v
                                                                    with
                                                                    | 
                                                                    FStar_SMTEncoding_Term.Fuel_sort
                                                                     -> []
                                                                    | 
                                                                    FStar_SMTEncoding_Term.Term_sort
                                                                     ->
                                                                    let uu____14674
                                                                    =
                                                                    let uu____14675
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkFreeV
                                                                    v in
                                                                    FStar_SMTEncoding_Util.mk_Precedes
                                                                    uu____14675
                                                                    dapp in
                                                                    [uu____14674]
                                                                    | 
                                                                    uu____14676
                                                                    ->
                                                                    failwith
                                                                    "unexpected sort")) in
                                                                    let uu____14678
                                                                    =
                                                                    let uu____14683
                                                                    =
                                                                    let uu____14684
                                                                    =
                                                                    let uu____14690
                                                                    =
                                                                    add_fuel
                                                                    (fuel_var,
                                                                    FStar_SMTEncoding_Term.Fuel_sort)
                                                                    (FStar_List.append
                                                                    vars
                                                                    arg_binders) in
                                                                    let uu____14696
                                                                    =
                                                                    let uu____14697
                                                                    =
                                                                    let uu____14700
                                                                    =
                                                                    FStar_SMTEncoding_Util.mk_and_l
                                                                    prec in
                                                                    (ty_pred,
                                                                    uu____14700) in
                                                                    FStar_SMTEncoding_Util.mkImp
                                                                    uu____14697 in
                                                                    ([
                                                                    [ty_pred]],
                                                                    uu____14690,
                                                                    uu____14696) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____14684 in
                                                                    (uu____14683,
                                                                    (Some
                                                                    "subterm ordering"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "subterm_ordering_"
                                                                    ddconstrsym))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____14678 in
                                                                  (arg_decls,
                                                                    [typing_inversion;
                                                                    subterm_ordering])))
                                                    | uu____14711 ->
                                                        ((let uu____14713 =
                                                            let uu____14714 =
                                                              FStar_Syntax_Print.lid_to_string
                                                                d in
                                                            let uu____14715 =
                                                              FStar_Syntax_Print.term_to_string
                                                                head in
                                                            FStar_Util.format2
                                                              "Constructor %s builds an unexpected type %s\n"
                                                              uu____14714
                                                              uu____14715 in
                                                          FStar_Errors.warn
                                                            drange
                                                            uu____14713);
                                                         ([], []))) in
                                             let uu____14718 = encode_elim () in
                                             (match uu____14718 with
                                              | (decls2,elim) ->
                                                  let g =
                                                    let uu____14730 =
                                                      let uu____14732 =
                                                        let uu____14734 =
                                                          let uu____14736 =
                                                            let uu____14738 =
                                                              let uu____14739
                                                                =
                                                                let uu____14745
                                                                  =
                                                                  let uu____14747
                                                                    =
                                                                    let uu____14748
                                                                    =
                                                                    FStar_Syntax_Print.lid_to_string
                                                                    d in
                                                                    FStar_Util.format1
                                                                    "data constructor proxy: %s"
                                                                    uu____14748 in
                                                                  Some
                                                                    uu____14747 in
                                                                (ddtok, [],
                                                                  FStar_SMTEncoding_Term.Term_sort,
                                                                  uu____14745) in
                                                              FStar_SMTEncoding_Term.DeclFun
                                                                uu____14739 in
                                                            [uu____14738] in
                                                          let uu____14751 =
                                                            let uu____14753 =
                                                              let uu____14755
                                                                =
                                                                let uu____14757
                                                                  =
                                                                  let uu____14759
                                                                    =
                                                                    let uu____14761
                                                                    =
                                                                    let uu____14763
                                                                    =
                                                                    let uu____14764
                                                                    =
                                                                    let uu____14769
                                                                    =
                                                                    let uu____14770
                                                                    =
                                                                    let uu____14776
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkEq
                                                                    (app,
                                                                    dapp) in
                                                                    ([[app]],
                                                                    vars,
                                                                    uu____14776) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____14770 in
                                                                    (uu____14769,
                                                                    (Some
                                                                    "equality for proxy"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "equality_tok_"
                                                                    ddtok))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____14764 in
                                                                    let uu____14784
                                                                    =
                                                                    let uu____14786
                                                                    =
                                                                    let uu____14787
                                                                    =
                                                                    let uu____14792
                                                                    =
                                                                    let uu____14793
                                                                    =
                                                                    let uu____14799
                                                                    =
                                                                    add_fuel
                                                                    (fuel_var,
                                                                    FStar_SMTEncoding_Term.Fuel_sort)
                                                                    vars' in
                                                                    let uu____14805
                                                                    =
                                                                    FStar_SMTEncoding_Util.mkImp
                                                                    (guard',
                                                                    ty_pred') in
                                                                    ([
                                                                    [ty_pred']],
                                                                    uu____14799,
                                                                    uu____14805) in
                                                                    FStar_SMTEncoding_Util.mkForall
                                                                    uu____14793 in
                                                                    (uu____14792,
                                                                    (Some
                                                                    "data constructor typing intro"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "data_typing_intro_"
                                                                    ddtok))) in
                                                                    FStar_SMTEncoding_Term.Assume
                                                                    uu____14787 in
                                                                    [uu____14786] in
                                                                    uu____14763
                                                                    ::
                                                                    uu____14784 in
                                                                    (FStar_SMTEncoding_Term.Assume
                                                                    (tok_typing,
                                                                    (Some
                                                                    "typing for data constructor proxy"),
                                                                    (Some
                                                                    (Prims.strcat
                                                                    "typing_tok_"
                                                                    ddtok))))
                                                                    ::
                                                                    uu____14761 in
                                                                  FStar_List.append
                                                                    uu____14759
                                                                    elim in
                                                                FStar_List.append
                                                                  decls_pred
                                                                  uu____14757 in
                                                              FStar_List.append
                                                                decls_formals
                                                                uu____14755 in
                                                            FStar_List.append
                                                              proxy_fresh
                                                              uu____14753 in
                                                          FStar_List.append
                                                            uu____14736
                                                            uu____14751 in
                                                        FStar_List.append
                                                          decls3 uu____14734 in
                                                      FStar_List.append
                                                        decls2 uu____14732 in
                                                    FStar_List.append
                                                      binder_decls
                                                      uu____14730 in
                                                  ((FStar_List.append
                                                      datacons g), env)))))))))
and encode_signature:
  env_t ->
    FStar_Syntax_Syntax.sigelt Prims.list ->
      (FStar_SMTEncoding_Term.decl Prims.list* env_t)
  =
  fun env  ->
    fun ses  ->
      FStar_All.pipe_right ses
        (FStar_List.fold_left
           (fun uu____14828  ->
              fun se  ->
                match uu____14828 with
                | (g,env) ->
                    let uu____14840 = encode_sigelt env se in
                    (match uu____14840 with
                     | (g',env) -> ((FStar_List.append g g'), env)))
           ([], env))
let encode_env_bindings:
  env_t ->
    FStar_TypeChecker_Env.binding Prims.list ->
      (FStar_SMTEncoding_Term.decls_t* env_t)
  =
  fun env  ->
    fun bindings  ->
      let encode_binding b uu____14876 =
        match uu____14876 with
        | (i,decls,env) ->
            (match b with
             | FStar_TypeChecker_Env.Binding_univ uu____14894 ->
                 ((i + (Prims.parse_int "1")), [], env)
             | FStar_TypeChecker_Env.Binding_var x ->
                 let t1 =
                   FStar_TypeChecker_Normalize.normalize
                     [FStar_TypeChecker_Normalize.Beta;
                     FStar_TypeChecker_Normalize.Eager_unfolding;
                     FStar_TypeChecker_Normalize.Simplify;
                     FStar_TypeChecker_Normalize.EraseUniverses] env.tcenv
                     x.FStar_Syntax_Syntax.sort in
                 ((let uu____14899 =
                     FStar_All.pipe_left
                       (FStar_TypeChecker_Env.debug env.tcenv)
                       (FStar_Options.Other "SMTEncoding") in
                   match uu____14899 with
                   | true  ->
                       let uu____14900 = FStar_Syntax_Print.bv_to_string x in
                       let uu____14901 =
                         FStar_Syntax_Print.term_to_string
                           x.FStar_Syntax_Syntax.sort in
                       let uu____14902 = FStar_Syntax_Print.term_to_string t1 in
                       FStar_Util.print3 "Normalized %s : %s to %s\n"
                         uu____14900 uu____14901 uu____14902
                   | uu____14903 -> ());
                  (let uu____14904 = encode_term t1 env in
                   match uu____14904 with
                   | (t,decls') ->
                       let t_hash = FStar_SMTEncoding_Term.hash_of_term t in
                       let uu____14914 =
                         let uu____14918 =
                           let uu____14919 =
                             let uu____14920 =
                               FStar_Util.digest_of_string t_hash in
                             Prims.strcat uu____14920
                               (Prims.strcat "_" (Prims.string_of_int i)) in
                           Prims.strcat "x_" uu____14919 in
                         new_term_constant_from_string env x uu____14918 in
                       (match uu____14914 with
                        | (xxsym,xx,env') ->
                            let t =
                              FStar_SMTEncoding_Term.mk_HasTypeWithFuel None
                                xx t in
                            let caption =
                              let uu____14931 = FStar_Options.log_queries () in
                              match uu____14931 with
                              | true  ->
                                  let uu____14933 =
                                    let uu____14934 =
                                      FStar_Syntax_Print.bv_to_string x in
                                    let uu____14935 =
                                      FStar_Syntax_Print.term_to_string
                                        x.FStar_Syntax_Syntax.sort in
                                    let uu____14936 =
                                      FStar_Syntax_Print.term_to_string t1 in
                                    FStar_Util.format3 "%s : %s (%s)"
                                      uu____14934 uu____14935 uu____14936 in
                                  Some uu____14933
                              | uu____14937 -> None in
                            let ax =
                              let a_name =
                                Some (Prims.strcat "binder_" xxsym) in
                              FStar_SMTEncoding_Term.Assume
                                (t, a_name, a_name) in
                            let g =
                              FStar_List.append
                                [FStar_SMTEncoding_Term.DeclFun
                                   (xxsym, [],
                                     FStar_SMTEncoding_Term.Term_sort,
                                     caption)]
                                (FStar_List.append decls' [ax]) in
                            ((i + (Prims.parse_int "1")),
                              (FStar_List.append decls g), env'))))
             | FStar_TypeChecker_Env.Binding_lid (x,(uu____14949,t)) ->
                 let t_norm = whnf env t in
                 let fv =
                   FStar_Syntax_Syntax.lid_as_fv x
                     FStar_Syntax_Syntax.Delta_constant None in
                 let uu____14958 = encode_free_var env fv t t_norm [] in
                 (match uu____14958 with
                  | (g,env') ->
                      ((i + (Prims.parse_int "1")),
                        (FStar_List.append decls g), env'))
             | FStar_TypeChecker_Env.Binding_sig_inst (_,se,_)
               |FStar_TypeChecker_Env.Binding_sig (_,se) ->
                 let uu____14977 = encode_sigelt env se in
                 (match uu____14977 with
                  | (g,env') ->
                      ((i + (Prims.parse_int "1")),
                        (FStar_List.append decls g), env'))) in
      let uu____14987 =
        FStar_List.fold_right encode_binding bindings
          ((Prims.parse_int "0"), [], env) in
      match uu____14987 with | (uu____14999,decls,env) -> (decls, env)
let encode_labels labs =
  let prefix =
    FStar_All.pipe_right labs
      (FStar_List.map
         (fun uu____15044  ->
            match uu____15044 with
            | (l,uu____15051,uu____15052) ->
                FStar_SMTEncoding_Term.DeclFun
                  ((Prims.fst l), [], FStar_SMTEncoding_Term.Bool_sort, None))) in
  let suffix =
    FStar_All.pipe_right labs
      (FStar_List.collect
         (fun uu____15073  ->
            match uu____15073 with
            | (l,uu____15081,uu____15082) ->
                let uu____15087 =
                  FStar_All.pipe_left
                    (fun _0_39  -> FStar_SMTEncoding_Term.Echo _0_39)
                    (Prims.fst l) in
                let uu____15088 =
                  let uu____15090 =
                    let uu____15091 = FStar_SMTEncoding_Util.mkFreeV l in
                    FStar_SMTEncoding_Term.Eval uu____15091 in
                  [uu____15090] in
                uu____15087 :: uu____15088)) in
  (prefix, suffix)
let last_env: env_t Prims.list FStar_ST.ref = FStar_Util.mk_ref []
let init_env: FStar_TypeChecker_Env.env -> Prims.unit =
  fun tcenv  ->
    let uu____15102 =
      let uu____15104 =
        let uu____15105 = FStar_Util.smap_create (Prims.parse_int "100") in
        {
          bindings = [];
          depth = (Prims.parse_int "0");
          tcenv;
          warn = true;
          cache = uu____15105;
          nolabels = false;
          use_zfuel_name = false;
          encode_non_total_function_typ = true
        } in
      [uu____15104] in
    FStar_ST.write last_env uu____15102
let get_env: FStar_TypeChecker_Env.env -> env_t =
  fun tcenv  ->
    let uu____15123 = FStar_ST.read last_env in
    match uu____15123 with
    | [] -> failwith "No env; call init first!"
    | e::uu____15129 ->
        let uu___158_15131 = e in
        {
          bindings = (uu___158_15131.bindings);
          depth = (uu___158_15131.depth);
          tcenv;
          warn = (uu___158_15131.warn);
          cache = (uu___158_15131.cache);
          nolabels = (uu___158_15131.nolabels);
          use_zfuel_name = (uu___158_15131.use_zfuel_name);
          encode_non_total_function_typ =
            (uu___158_15131.encode_non_total_function_typ)
        }
let set_env: env_t -> Prims.unit =
  fun env  ->
    let uu____15135 = FStar_ST.read last_env in
    match uu____15135 with
    | [] -> failwith "Empty env stack"
    | uu____15140::tl -> FStar_ST.write last_env (env :: tl)
let push_env: Prims.unit -> Prims.unit =
  fun uu____15148  ->
    let uu____15149 = FStar_ST.read last_env in
    match uu____15149 with
    | [] -> failwith "Empty env stack"
    | hd::tl ->
        let refs = FStar_Util.smap_copy hd.cache in
        let top =
          let uu___159_15170 = hd in
          {
            bindings = (uu___159_15170.bindings);
            depth = (uu___159_15170.depth);
            tcenv = (uu___159_15170.tcenv);
            warn = (uu___159_15170.warn);
            cache = refs;
            nolabels = (uu___159_15170.nolabels);
            use_zfuel_name = (uu___159_15170.use_zfuel_name);
            encode_non_total_function_typ =
              (uu___159_15170.encode_non_total_function_typ)
          } in
        FStar_ST.write last_env (top :: hd :: tl)
let pop_env: Prims.unit -> Prims.unit =
  fun uu____15176  ->
    let uu____15177 = FStar_ST.read last_env in
    match uu____15177 with
    | [] -> failwith "Popping an empty stack"
    | uu____15182::tl -> FStar_ST.write last_env tl
let mark_env: Prims.unit -> Prims.unit = fun uu____15190  -> push_env ()
let reset_mark_env: Prims.unit -> Prims.unit = fun uu____15193  -> pop_env ()
let commit_mark_env: Prims.unit -> Prims.unit =
  fun uu____15196  ->
    let uu____15197 = FStar_ST.read last_env in
    match uu____15197 with
    | hd::uu____15203::tl -> FStar_ST.write last_env (hd :: tl)
    | uu____15209 -> failwith "Impossible"
let init: FStar_TypeChecker_Env.env -> Prims.unit =
  fun tcenv  ->
    init_env tcenv;
    FStar_SMTEncoding_Z3.init ();
    FStar_SMTEncoding_Z3.giveZ3 [FStar_SMTEncoding_Term.DefPrelude]
let push: Prims.string -> Prims.unit =
  fun msg  -> push_env (); varops.push (); FStar_SMTEncoding_Z3.push msg
let pop: Prims.string -> Prims.unit =
  fun msg  -> pop_env (); varops.pop (); FStar_SMTEncoding_Z3.pop msg
let mark: Prims.string -> Prims.unit =
  fun msg  -> mark_env (); varops.mark (); FStar_SMTEncoding_Z3.mark msg
let reset_mark: Prims.string -> Prims.unit =
  fun msg  ->
    reset_mark_env ();
    varops.reset_mark ();
    FStar_SMTEncoding_Z3.reset_mark msg
let commit_mark: Prims.string -> Prims.unit =
  fun msg  ->
    commit_mark_env ();
    varops.commit_mark ();
    FStar_SMTEncoding_Z3.commit_mark msg
let encode_sig:
  FStar_TypeChecker_Env.env -> FStar_Syntax_Syntax.sigelt -> Prims.unit =
  fun tcenv  ->
    fun se  ->
      let caption decls =
        let uu____15254 = FStar_Options.log_queries () in
        match uu____15254 with
        | true  ->
            let uu____15256 =
              let uu____15257 =
                let uu____15258 =
                  let uu____15259 =
                    FStar_All.pipe_right
                      (FStar_Syntax_Util.lids_of_sigelt se)
                      (FStar_List.map FStar_Syntax_Print.lid_to_string) in
                  FStar_All.pipe_right uu____15259 (FStar_String.concat ", ") in
                Prims.strcat "encoding sigelt " uu____15258 in
              FStar_SMTEncoding_Term.Caption uu____15257 in
            uu____15256 :: decls
        | uu____15264 -> decls in
      let env = get_env tcenv in
      let uu____15266 = encode_sigelt env se in
      match uu____15266 with
      | (decls,env) ->
          (set_env env;
           (let uu____15272 = caption decls in
            FStar_SMTEncoding_Z3.giveZ3 uu____15272))
let encode_modul:
  FStar_TypeChecker_Env.env -> FStar_Syntax_Syntax.modul -> Prims.unit =
  fun tcenv  ->
    fun modul  ->
      let name =
        FStar_Util.format2 "%s %s"
          (match modul.FStar_Syntax_Syntax.is_interface with
           | true  -> "interface"
           | uu____15281 -> "module")
          (modul.FStar_Syntax_Syntax.name).FStar_Ident.str in
      (let uu____15283 = FStar_TypeChecker_Env.debug tcenv FStar_Options.Low in
       match uu____15283 with
       | true  ->
           let uu____15284 =
             FStar_All.pipe_right
               (FStar_List.length modul.FStar_Syntax_Syntax.exports)
               Prims.string_of_int in
           FStar_Util.print2
             "+++++++++++Encoding externals for %s ... %s exports\n" name
             uu____15284
       | uu____15287 -> ());
      (let env = get_env tcenv in
       let uu____15289 =
         encode_signature
           (let uu___160_15293 = env in
            {
              bindings = (uu___160_15293.bindings);
              depth = (uu___160_15293.depth);
              tcenv = (uu___160_15293.tcenv);
              warn = false;
              cache = (uu___160_15293.cache);
              nolabels = (uu___160_15293.nolabels);
              use_zfuel_name = (uu___160_15293.use_zfuel_name);
              encode_non_total_function_typ =
                (uu___160_15293.encode_non_total_function_typ)
            }) modul.FStar_Syntax_Syntax.exports in
       match uu____15289 with
       | (decls,env) ->
           let caption decls =
             let uu____15305 = FStar_Options.log_queries () in
             match uu____15305 with
             | true  ->
                 let msg = Prims.strcat "Externals for " name in
                 FStar_List.append ((FStar_SMTEncoding_Term.Caption msg) ::
                   decls)
                   [FStar_SMTEncoding_Term.Caption (Prims.strcat "End " msg)]
             | uu____15308 -> decls in
           (set_env
              (let uu___161_15310 = env in
               {
                 bindings = (uu___161_15310.bindings);
                 depth = (uu___161_15310.depth);
                 tcenv = (uu___161_15310.tcenv);
                 warn = true;
                 cache = (uu___161_15310.cache);
                 nolabels = (uu___161_15310.nolabels);
                 use_zfuel_name = (uu___161_15310.use_zfuel_name);
                 encode_non_total_function_typ =
                   (uu___161_15310.encode_non_total_function_typ)
               });
            (let uu____15312 =
               FStar_TypeChecker_Env.debug tcenv FStar_Options.Low in
             match uu____15312 with
             | true  ->
                 FStar_Util.print1 "Done encoding externals for %s\n" name
             | uu____15313 -> ());
            (let decls = caption decls in FStar_SMTEncoding_Z3.giveZ3 decls)))
let encode_query:
  (Prims.unit -> Prims.string) Prims.option ->
    FStar_TypeChecker_Env.env ->
      FStar_Syntax_Syntax.term ->
        (FStar_SMTEncoding_Term.decl Prims.list*
          FStar_SMTEncoding_ErrorReporting.label Prims.list*
          FStar_SMTEncoding_Term.decl* FStar_SMTEncoding_Term.decl
          Prims.list)
  =
  fun use_env_msg  ->
    fun tcenv  ->
      fun q  ->
        (let uu____15347 =
           let uu____15348 = FStar_TypeChecker_Env.current_module tcenv in
           uu____15348.FStar_Ident.str in
         FStar_SMTEncoding_Z3.query_logging.FStar_SMTEncoding_Z3.set_module_name
           uu____15347);
        (let env = get_env tcenv in
         let bindings =
           FStar_TypeChecker_Env.fold_env tcenv
             (fun bs  -> fun b  -> b :: bs) [] in
         let uu____15356 =
           let rec aux bindings =
             match bindings with
             | (FStar_TypeChecker_Env.Binding_var x)::rest ->
                 let uu____15377 = aux rest in
                 (match uu____15377 with
                  | (out,rest) ->
                      let t =
                        FStar_TypeChecker_Normalize.normalize
                          [FStar_TypeChecker_Normalize.Eager_unfolding;
                          FStar_TypeChecker_Normalize.Beta;
                          FStar_TypeChecker_Normalize.Simplify;
                          FStar_TypeChecker_Normalize.EraseUniverses]
                          env.tcenv x.FStar_Syntax_Syntax.sort in
                      let uu____15393 =
                        let uu____15395 =
                          FStar_Syntax_Syntax.mk_binder
                            (let uu___162_15396 = x in
                             {
                               FStar_Syntax_Syntax.ppname =
                                 (uu___162_15396.FStar_Syntax_Syntax.ppname);
                               FStar_Syntax_Syntax.index =
                                 (uu___162_15396.FStar_Syntax_Syntax.index);
                               FStar_Syntax_Syntax.sort = t
                             }) in
                        uu____15395 :: out in
                      (uu____15393, rest))
             | uu____15399 -> ([], bindings) in
           let uu____15403 = aux bindings in
           match uu____15403 with
           | (closing,bindings) ->
               let uu____15417 =
                 FStar_Syntax_Util.close_forall (FStar_List.rev closing) q in
               (uu____15417, bindings) in
         match uu____15356 with
         | (q,bindings) ->
             let uu____15430 =
               let uu____15433 =
                 FStar_List.filter
                   (fun uu___131_15435  ->
                      match uu___131_15435 with
                      | FStar_TypeChecker_Env.Binding_sig uu____15436 ->
                          false
                      | uu____15440 -> true) bindings in
               encode_env_bindings env uu____15433 in
             (match uu____15430 with
              | (env_decls,env) ->
                  ((let uu____15451 =
                      ((FStar_TypeChecker_Env.debug tcenv FStar_Options.Low)
                         ||
                         (FStar_All.pipe_left
                            (FStar_TypeChecker_Env.debug tcenv)
                            (FStar_Options.Other "SMTEncoding")))
                        ||
                        (FStar_All.pipe_left
                           (FStar_TypeChecker_Env.debug tcenv)
                           (FStar_Options.Other "SMTQuery")) in
                    match uu____15451 with
                    | true  ->
                        let uu____15452 = FStar_Syntax_Print.term_to_string q in
                        FStar_Util.print1 "Encoding query formula: %s\n"
                          uu____15452
                    | uu____15453 -> ());
                   (let uu____15454 = encode_formula q env in
                    match uu____15454 with
                    | (phi,qdecls) ->
                        let uu____15466 =
                          let uu____15469 =
                            FStar_TypeChecker_Env.get_range tcenv in
                          FStar_SMTEncoding_ErrorReporting.label_goals
                            use_env_msg uu____15469 phi in
                        (match uu____15466 with
                         | (labels,phi) ->
                             let uu____15479 = encode_labels labels in
                             (match uu____15479 with
                              | (label_prefix,label_suffix) ->
                                  let query_prelude =
                                    FStar_List.append env_decls
                                      (FStar_List.append label_prefix qdecls) in
                                  let qry =
                                    let uu____15500 =
                                      let uu____15505 =
                                        FStar_SMTEncoding_Util.mkNot phi in
                                      let uu____15506 =
                                        let uu____15508 =
                                          varops.mk_unique "@query" in
                                        Some uu____15508 in
                                      (uu____15505, (Some "query"),
                                        uu____15506) in
                                    FStar_SMTEncoding_Term.Assume uu____15500 in
                                  let suffix =
                                    let uu____15513 =
                                      let uu____15515 =
                                        let uu____15517 =
                                          FStar_Options.print_z3_statistics
                                            () in
                                        match uu____15517 with
                                        | true  ->
                                            [FStar_SMTEncoding_Term.PrintStats]
                                        | uu____15519 -> [] in
                                      FStar_List.append uu____15515
                                        [FStar_SMTEncoding_Term.Echo "Done!"] in
                                    FStar_List.append label_suffix
                                      uu____15513 in
                                  (query_prelude, labels, qry, suffix)))))))
let is_trivial:
  FStar_TypeChecker_Env.env -> FStar_Syntax_Syntax.typ -> Prims.bool =
  fun tcenv  ->
    fun q  ->
      let env = get_env tcenv in
      FStar_SMTEncoding_Z3.push "query";
      (let uu____15530 = encode_formula q env in
       match uu____15530 with
       | (f,uu____15534) ->
           (FStar_SMTEncoding_Z3.pop "query";
            (match f.FStar_SMTEncoding_Term.tm with
             | FStar_SMTEncoding_Term.App
                 (FStar_SMTEncoding_Term.TrueOp ,uu____15536) -> true
             | uu____15539 -> false)))