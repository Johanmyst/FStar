open Prims
let fail_exp lid t =
  let uu____15 =
    let uu____18 =
      let uu____19 =
        let uu____29 =
          FStar_Syntax_Syntax.fvar FStar_Syntax_Const.failwith_lid
            FStar_Syntax_Syntax.Delta_constant None in
        let uu____30 =
          let uu____32 = FStar_Syntax_Syntax.iarg t in
          let uu____33 =
            let uu____35 =
              let uu____36 =
                let uu____37 =
                  let uu____40 =
                    let uu____41 =
                      let uu____42 =
                        let uu____46 =
                          let uu____47 =
                            let uu____48 =
                              FStar_Syntax_Print.lid_to_string lid in
                            Prims.strcat "Not yet implemented:" uu____48 in
                          FStar_Bytes.string_as_unicode_bytes uu____47 in
                        (uu____46, FStar_Range.dummyRange) in
                      FStar_Const.Const_string uu____42 in
                    FStar_Syntax_Syntax.Tm_constant uu____41 in
                  FStar_Syntax_Syntax.mk uu____40 in
                uu____37 None FStar_Range.dummyRange in
              FStar_All.pipe_left FStar_Syntax_Syntax.as_arg uu____36 in
            [uu____35] in
          uu____32 :: uu____33 in
        (uu____29, uu____30) in
      FStar_Syntax_Syntax.Tm_app uu____19 in
    FStar_Syntax_Syntax.mk uu____18 in
  uu____15 None FStar_Range.dummyRange
let mangle_projector_lid: FStar_Ident.lident -> FStar_Ident.lident =
  fun x  -> x
let lident_as_mlsymbol: FStar_Ident.lident -> Prims.string =
  fun id  -> (id.FStar_Ident.ident).FStar_Ident.idText
let binders_as_mlty_binders env bs =
  FStar_Util.fold_map
    (fun env  ->
       fun uu____100  ->
         match uu____100 with
         | (bv,uu____108) ->
             let uu____109 =
               let uu____110 =
                 let uu____112 =
                   let uu____113 = FStar_Extraction_ML_UEnv.bv_as_ml_tyvar bv in
                   FStar_Extraction_ML_Syntax.MLTY_Var uu____113 in
                 Some uu____112 in
               FStar_Extraction_ML_UEnv.extend_ty env bv uu____110 in
             let uu____114 = FStar_Extraction_ML_UEnv.bv_as_ml_tyvar bv in
             (uu____109, uu____114)) env bs
let extract_typ_abbrev:
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.fv ->
      FStar_Syntax_Syntax.qualifier Prims.list ->
        FStar_Syntax_Syntax.term ->
          (FStar_Extraction_ML_UEnv.env* FStar_Extraction_ML_Syntax.mlmodule1
            Prims.list)
  =
  fun env  ->
    fun fv  ->
      fun quals  ->
        fun def  ->
          let lid = (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
          let def =
            let uu____142 =
              let uu____143 = FStar_Syntax_Subst.compress def in
              FStar_All.pipe_right uu____143 FStar_Syntax_Util.unmeta in
            FStar_All.pipe_right uu____142 FStar_Syntax_Util.un_uinst in
          let def =
            match def.FStar_Syntax_Syntax.n with
            | FStar_Syntax_Syntax.Tm_abs uu____145 ->
                FStar_Extraction_ML_Term.normalize_abs def
            | uu____160 -> def in
          let uu____161 =
            match def.FStar_Syntax_Syntax.n with
            | FStar_Syntax_Syntax.Tm_abs (bs,body,uu____168) ->
                FStar_Syntax_Subst.open_term bs body
            | uu____191 -> ([], def) in
          match uu____161 with
          | (bs,body) ->
              let assumed =
                FStar_Util.for_some
                  (fun uu___125_203  ->
                     match uu___125_203 with
                     | FStar_Syntax_Syntax.Assumption  -> true
                     | uu____204 -> false) quals in
              let uu____205 = binders_as_mlty_binders env bs in
              (match uu____205 with
               | (env,ml_bs) ->
                   let body =
                     let uu____223 =
                       FStar_Extraction_ML_Term.term_as_mlty env body in
                     FStar_All.pipe_right uu____223
                       (FStar_Extraction_ML_Util.eraseTypeDeep
                          (FStar_Extraction_ML_Util.udelta_unfold env)) in
                   let mangled_projector =
                     let uu____226 =
                       FStar_All.pipe_right quals
                         (FStar_Util.for_some
                            (fun uu___126_228  ->
                               match uu___126_228 with
                               | FStar_Syntax_Syntax.Projector uu____229 ->
                                   true
                               | uu____232 -> false)) in
                     match uu____226 with
                     | true  ->
                         let mname = mangle_projector_lid lid in
                         Some ((mname.FStar_Ident.ident).FStar_Ident.idText)
                     | uu____235 -> None in
                   let td =
                     let uu____248 =
                       let uu____259 = lident_as_mlsymbol lid in
                       (assumed, uu____259, mangled_projector, ml_bs,
                         (Some (FStar_Extraction_ML_Syntax.MLTD_Abbrev body))) in
                     [uu____248] in
                   let def =
                     let uu____287 =
                       let uu____288 =
                         FStar_Extraction_ML_Util.mlloc_of_range
                           (FStar_Ident.range_of_lid lid) in
                       FStar_Extraction_ML_Syntax.MLM_Loc uu____288 in
                     [uu____287; FStar_Extraction_ML_Syntax.MLM_Ty td] in
                   let env =
                     let uu____290 =
                       FStar_All.pipe_right quals
                         (FStar_Util.for_some
                            (fun uu___127_292  ->
                               match uu___127_292 with
                               | FStar_Syntax_Syntax.Assumption 
                                 |FStar_Syntax_Syntax.New  -> true
                               | uu____293 -> false)) in
                     match uu____290 with
                     | true  -> env
                     | uu____294 ->
                         FStar_Extraction_ML_UEnv.extend_tydef env fv td in
                   (env, def))
type data_constructor =
  {
  dname: FStar_Ident.lident;
  dtyp: FStar_Syntax_Syntax.typ;}
type inductive_family =
  {
  iname: FStar_Ident.lident;
  iparams: FStar_Syntax_Syntax.binders;
  ityp: FStar_Syntax_Syntax.term;
  idatas: data_constructor Prims.list;
  iquals: FStar_Syntax_Syntax.qualifier Prims.list;}
let print_ifamily: inductive_family -> Prims.unit =
  fun i  ->
    let uu____354 = FStar_Syntax_Print.lid_to_string i.iname in
    let uu____355 = FStar_Syntax_Print.binders_to_string " " i.iparams in
    let uu____356 = FStar_Syntax_Print.term_to_string i.ityp in
    let uu____357 =
      let uu____358 =
        FStar_All.pipe_right i.idatas
          (FStar_List.map
             (fun d  ->
                let uu____363 = FStar_Syntax_Print.lid_to_string d.dname in
                let uu____364 =
                  let uu____365 = FStar_Syntax_Print.term_to_string d.dtyp in
                  Prims.strcat " : " uu____365 in
                Prims.strcat uu____363 uu____364)) in
      FStar_All.pipe_right uu____358 (FStar_String.concat "\n\t\t") in
    FStar_Util.print4 "\n\t%s %s : %s { %s }\n" uu____354 uu____355 uu____356
      uu____357
let bundle_as_inductive_families env ses quals =
  FStar_All.pipe_right ses
    (FStar_List.collect
       (fun uu___129_391  ->
          match uu___129_391 with
          | FStar_Syntax_Syntax.Sig_inductive_typ
              (l,_us,bs,t,_mut_i,datas,quals,r) ->
              let uu____407 = FStar_Syntax_Subst.open_term bs t in
              (match uu____407 with
               | (bs,t) ->
                   let datas =
                     FStar_All.pipe_right ses
                       (FStar_List.collect
                          (fun uu___128_417  ->
                             match uu___128_417 with
                             | FStar_Syntax_Syntax.Sig_datacon
                                 (d,uu____420,t,l',nparams,uu____424,uu____425,uu____426)
                                 when FStar_Ident.lid_equals l l' ->
                                 let uu____431 =
                                   FStar_Syntax_Util.arrow_formals t in
                                 (match uu____431 with
                                  | (bs',body) ->
                                      let uu____452 =
                                        FStar_Util.first_N
                                          (FStar_List.length bs) bs' in
                                      (match uu____452 with
                                       | (bs_params,rest) ->
                                           let subst =
                                             FStar_List.map2
                                               (fun uu____488  ->
                                                  fun uu____489  ->
                                                    match (uu____488,
                                                            uu____489)
                                                    with
                                                    | ((b',uu____499),
                                                       (b,uu____501)) ->
                                                        let uu____506 =
                                                          let uu____511 =
                                                            FStar_Syntax_Syntax.bv_to_name
                                                              b in
                                                          (b', uu____511) in
                                                        FStar_Syntax_Syntax.NT
                                                          uu____506)
                                               bs_params bs in
                                           let t =
                                             let uu____513 =
                                               let uu____516 =
                                                 FStar_Syntax_Syntax.mk_Total
                                                   body in
                                               FStar_Syntax_Util.arrow rest
                                                 uu____516 in
                                             FStar_All.pipe_right uu____513
                                               (FStar_Syntax_Subst.subst
                                                  subst) in
                                           [{ dname = d; dtyp = t }]))
                             | uu____521 -> [])) in
                   [{
                      iname = l;
                      iparams = bs;
                      ityp = t;
                      idatas = datas;
                      iquals = quals
                    }])
          | uu____522 -> []))
type env_t = FStar_Extraction_ML_UEnv.env
let extract_bundle:
  env_t ->
    FStar_Syntax_Syntax.sigelt ->
      (env_t* FStar_Extraction_ML_Syntax.mlmodule1 Prims.list)
  =
  fun env  ->
    fun se  ->
      let extract_ctor ml_tyvars env ctor =
        let mlt =
          let uu____559 = FStar_Extraction_ML_Term.term_as_mlty env ctor.dtyp in
          FStar_Extraction_ML_Util.eraseTypeDeep
            (FStar_Extraction_ML_Util.udelta_unfold env) uu____559 in
        let tys = (ml_tyvars, mlt) in
        let fvv = FStar_Extraction_ML_UEnv.mkFvvar ctor.dname ctor.dtyp in
        let uu____570 =
          FStar_Extraction_ML_UEnv.extend_fv env fvv tys false false in
        let uu____571 =
          let uu____575 = lident_as_mlsymbol ctor.dname in
          let uu____576 = FStar_Extraction_ML_Util.argTypes mlt in
          (uu____575, uu____576) in
        (uu____570, uu____571) in
      let extract_one_family env ind =
        let uu____601 = binders_as_mlty_binders env ind.iparams in
        match uu____601 with
        | (env,vars) ->
            let uu____627 =
              FStar_All.pipe_right ind.idatas
                (FStar_Util.fold_map (extract_ctor vars) env) in
            (match uu____627 with
             | (env,ctors) ->
                 let uu____666 = FStar_Syntax_Util.arrow_formals ind.ityp in
                 (match uu____666 with
                  | (indices,uu____687) ->
                      let ml_params =
                        let uu____702 =
                          FStar_All.pipe_right indices
                            (FStar_List.mapi
                               (fun i  ->
                                  fun uu____717  ->
                                    let uu____720 =
                                      let uu____721 =
                                        FStar_Util.string_of_int i in
                                      Prims.strcat "'dummyV" uu____721 in
                                    (uu____720, (Prims.parse_int "0")))) in
                        FStar_List.append vars uu____702 in
                      let tbody =
                        let uu____725 =
                          FStar_Util.find_opt
                            (fun uu___130_727  ->
                               match uu___130_727 with
                               | FStar_Syntax_Syntax.RecordType uu____728 ->
                                   true
                               | uu____733 -> false) ind.iquals in
                        match uu____725 with
                        | Some (FStar_Syntax_Syntax.RecordType (ns,ids)) ->
                            let uu____740 = FStar_List.hd ctors in
                            (match uu____740 with
                             | (uu____747,c_ty) ->
                                 let fields =
                                   FStar_List.map2
                                     (fun id  ->
                                        fun ty  ->
                                          let lid =
                                            FStar_Ident.lid_of_ids
                                              (FStar_List.append ns [id]) in
                                          let uu____761 =
                                            lident_as_mlsymbol lid in
                                          (uu____761, ty)) ids c_ty in
                                 FStar_Extraction_ML_Syntax.MLTD_Record
                                   fields)
                        | uu____762 ->
                            FStar_Extraction_ML_Syntax.MLTD_DType ctors in
                      let uu____764 =
                        let uu____775 = lident_as_mlsymbol ind.iname in
                        (false, uu____775, None, ml_params, (Some tbody)) in
                      (env, uu____764))) in
      match se with
      | FStar_Syntax_Syntax.Sig_bundle
          ((FStar_Syntax_Syntax.Sig_datacon
           (l,uu____795,t,uu____797,uu____798,uu____799,uu____800,uu____801))::[],(FStar_Syntax_Syntax.ExceptionConstructor
           )::[],uu____802,r)
          ->
          let uu____812 = extract_ctor [] env { dname = l; dtyp = t } in
          (match uu____812 with
           | (env,ctor) -> (env, [FStar_Extraction_ML_Syntax.MLM_Exn ctor]))
      | FStar_Syntax_Syntax.Sig_bundle (ses,quals,uu____834,r) ->
          let ifams = bundle_as_inductive_families env ses quals in
          let uu____845 = FStar_Util.fold_map extract_one_family env ifams in
          (match uu____845 with
           | (env,td) -> (env, [FStar_Extraction_ML_Syntax.MLM_Ty td]))
      | uu____897 -> failwith "Unexpected signature element"
let rec extract_sig:
  env_t ->
    FStar_Syntax_Syntax.sigelt ->
      (env_t* FStar_Extraction_ML_Syntax.mlmodule1 Prims.list)
  =
  fun g  ->
    fun se  ->
      FStar_Extraction_ML_UEnv.debug g
        (fun u  ->
           let uu____915 = FStar_Syntax_Print.sigelt_to_string se in
           FStar_Util.print1 ">>>> extract_sig %s \n" uu____915);
      (match se with
       | FStar_Syntax_Syntax.Sig_bundle _
         |FStar_Syntax_Syntax.Sig_inductive_typ _
          |FStar_Syntax_Syntax.Sig_datacon _ -> extract_bundle g se
       | FStar_Syntax_Syntax.Sig_new_effect (ed,uu____923) when
           FStar_All.pipe_right ed.FStar_Syntax_Syntax.qualifiers
             (FStar_List.contains FStar_Syntax_Syntax.Reifiable)
           ->
           let extend_env g lid ml_name tm tysc =
             let mangled_name = Prims.snd ml_name in
             let g =
               let uu____952 =
                 FStar_Syntax_Syntax.lid_as_fv lid
                   FStar_Syntax_Syntax.Delta_equational None in
               FStar_Extraction_ML_UEnv.extend_fv' g uu____952 ml_name tysc
                 false false in
             let lb =
               {
                 FStar_Extraction_ML_Syntax.mllb_name =
                   (mangled_name, (Prims.parse_int "0"));
                 FStar_Extraction_ML_Syntax.mllb_tysc = None;
                 FStar_Extraction_ML_Syntax.mllb_add_unit = false;
                 FStar_Extraction_ML_Syntax.mllb_def = tm;
                 FStar_Extraction_ML_Syntax.print_typ = false
               } in
             (g,
               (FStar_Extraction_ML_Syntax.MLM_Let
                  (FStar_Extraction_ML_Syntax.NonRec, [], [lb]))) in
           let rec extract_fv tm =
             let uu____962 =
               let uu____963 = FStar_Syntax_Subst.compress tm in
               uu____963.FStar_Syntax_Syntax.n in
             match uu____962 with
             | FStar_Syntax_Syntax.Tm_uinst (tm,uu____969) -> extract_fv tm
             | FStar_Syntax_Syntax.Tm_fvar fv ->
                 let mlp =
                   FStar_Extraction_ML_Syntax.mlpath_of_lident
                     (fv.FStar_Syntax_Syntax.fv_name).FStar_Syntax_Syntax.v in
                 let uu____980 =
                   let uu____984 = FStar_Extraction_ML_UEnv.lookup_fv g fv in
                   FStar_All.pipe_left FStar_Util.right uu____984 in
                 (match uu____980 with
                  | (uu____1009,tysc,uu____1011) ->
                      let uu____1012 =
                        FStar_All.pipe_left
                          (FStar_Extraction_ML_Syntax.with_ty
                             FStar_Extraction_ML_Syntax.MLTY_Top)
                          (FStar_Extraction_ML_Syntax.MLE_Name mlp) in
                      (uu____1012, tysc))
             | uu____1013 -> failwith "Not an fv" in
           let extract_action g a =
             let uu____1025 = extract_fv a.FStar_Syntax_Syntax.action_defn in
             match uu____1025 with
             | (a_tm,ty_sc) ->
                 let uu____1032 = FStar_Extraction_ML_UEnv.action_name ed a in
                 (match uu____1032 with
                  | (a_nm,a_lid) -> extend_env g a_lid a_nm a_tm ty_sc) in
           let uu____1039 =
             let uu____1042 =
               extract_fv (Prims.snd ed.FStar_Syntax_Syntax.return_repr) in
             match uu____1042 with
             | (return_tm,ty_sc) ->
                 let uu____1050 =
                   FStar_Extraction_ML_UEnv.monad_op_name ed "return" in
                 (match uu____1050 with
                  | (return_nm,return_lid) ->
                      extend_env g return_lid return_nm return_tm ty_sc) in
           (match uu____1039 with
            | (g,return_decl) ->
                let uu____1062 =
                  let uu____1065 =
                    extract_fv (Prims.snd ed.FStar_Syntax_Syntax.bind_repr) in
                  match uu____1065 with
                  | (bind_tm,ty_sc) ->
                      let uu____1073 =
                        FStar_Extraction_ML_UEnv.monad_op_name ed "bind" in
                      (match uu____1073 with
                       | (bind_nm,bind_lid) ->
                           extend_env g bind_lid bind_nm bind_tm ty_sc) in
                (match uu____1062 with
                 | (g,bind_decl) ->
                     let uu____1085 =
                       FStar_Util.fold_map extract_action g
                         ed.FStar_Syntax_Syntax.actions in
                     (match uu____1085 with
                      | (g,actions) ->
                          (g,
                            (FStar_List.append [return_decl; bind_decl]
                               actions)))))
       | FStar_Syntax_Syntax.Sig_new_effect uu____1097 -> (g, [])
       | FStar_Syntax_Syntax.Sig_declare_typ
           (lid,uu____1102,t,quals,uu____1105) when
           FStar_Extraction_ML_Term.is_arity g t ->
           let uu____1108 =
             let uu____1109 =
               FStar_All.pipe_right quals
                 (FStar_Util.for_some
                    (fun uu___131_1111  ->
                       match uu___131_1111 with
                       | FStar_Syntax_Syntax.Assumption  -> true
                       | uu____1112 -> false)) in
             FStar_All.pipe_right uu____1109 Prims.op_Negation in
           (match uu____1108 with
            | true  -> (g, [])
            | uu____1117 ->
                let uu____1118 = FStar_Syntax_Util.arrow_formals t in
                (match uu____1118 with
                 | (bs,uu____1130) ->
                     let fv =
                       FStar_Syntax_Syntax.lid_as_fv lid
                         FStar_Syntax_Syntax.Delta_constant None in
                     let uu____1142 =
                       FStar_Syntax_Util.abs bs
                         FStar_TypeChecker_Common.t_unit None in
                     extract_typ_abbrev g fv quals uu____1142))
       | FStar_Syntax_Syntax.Sig_let
           ((false ,lb::[]),uu____1149,uu____1150,quals,uu____1152) when
           FStar_Extraction_ML_Term.is_arity g lb.FStar_Syntax_Syntax.lbtyp
           ->
           let uu____1163 = FStar_Util.right lb.FStar_Syntax_Syntax.lbname in
           extract_typ_abbrev g uu____1163 quals lb.FStar_Syntax_Syntax.lbdef
       | FStar_Syntax_Syntax.Sig_let (lbs,r,uu____1166,quals,attrs) ->
           let elet =
             (FStar_Syntax_Syntax.mk
                (FStar_Syntax_Syntax.Tm_let
                   (lbs, FStar_Syntax_Const.exp_false_bool))) None r in
           let uu____1186 = FStar_Extraction_ML_Term.term_as_mlexpr g elet in
           (match uu____1186 with
            | (ml_let,uu____1194,uu____1195) ->
                (match ml_let.FStar_Extraction_ML_Syntax.expr with
                 | FStar_Extraction_ML_Syntax.MLE_Let
                     ((flavor,uu____1200,bindings),uu____1202) ->
                     let uu____1209 =
                       FStar_List.fold_left2
                         (fun uu____1216  ->
                            fun ml_lb  ->
                              fun uu____1218  ->
                                match (uu____1216, uu____1218) with
                                | ((env,ml_lbs),{
                                                  FStar_Syntax_Syntax.lbname
                                                    = lbname;
                                                  FStar_Syntax_Syntax.lbunivs
                                                    = uu____1231;
                                                  FStar_Syntax_Syntax.lbtyp =
                                                    t;
                                                  FStar_Syntax_Syntax.lbeff =
                                                    uu____1233;
                                                  FStar_Syntax_Syntax.lbdef =
                                                    uu____1234;_})
                                    ->
                                    let lb_lid =
                                      let uu____1248 =
                                        let uu____1253 =
                                          FStar_Util.right lbname in
                                        uu____1253.FStar_Syntax_Syntax.fv_name in
                                      uu____1248.FStar_Syntax_Syntax.v in
                                    let uu____1257 =
                                      let uu____1260 =
                                        FStar_All.pipe_right quals
                                          (FStar_Util.for_some
                                             (fun uu___132_1262  ->
                                                match uu___132_1262 with
                                                | FStar_Syntax_Syntax.Projector
                                                    uu____1263 -> true
                                                | uu____1266 -> false)) in
                                      match uu____1260 with
                                      | true  ->
                                          let mname =
                                            let uu____1270 =
                                              mangle_projector_lid lb_lid in
                                            FStar_All.pipe_right uu____1270
                                              FStar_Extraction_ML_Syntax.mlpath_of_lident in
                                          let env =
                                            let uu____1272 =
                                              FStar_Util.right lbname in
                                            let uu____1273 =
                                              FStar_Util.must
                                                ml_lb.FStar_Extraction_ML_Syntax.mllb_tysc in
                                            FStar_Extraction_ML_UEnv.extend_fv'
                                              env uu____1272 mname uu____1273
                                              ml_lb.FStar_Extraction_ML_Syntax.mllb_add_unit
                                              false in
                                          (env,
                                            (let uu___137_1274 = ml_lb in
                                             {
                                               FStar_Extraction_ML_Syntax.mllb_name
                                                 =
                                                 ((Prims.snd mname),
                                                   (Prims.parse_int "0"));
                                               FStar_Extraction_ML_Syntax.mllb_tysc
                                                 =
                                                 (uu___137_1274.FStar_Extraction_ML_Syntax.mllb_tysc);
                                               FStar_Extraction_ML_Syntax.mllb_add_unit
                                                 =
                                                 (uu___137_1274.FStar_Extraction_ML_Syntax.mllb_add_unit);
                                               FStar_Extraction_ML_Syntax.mllb_def
                                                 =
                                                 (uu___137_1274.FStar_Extraction_ML_Syntax.mllb_def);
                                               FStar_Extraction_ML_Syntax.print_typ
                                                 =
                                                 (uu___137_1274.FStar_Extraction_ML_Syntax.print_typ)
                                             }))
                                      | uu____1276 ->
                                          let uu____1277 =
                                            let uu____1278 =
                                              let uu____1281 =
                                                FStar_Util.must
                                                  ml_lb.FStar_Extraction_ML_Syntax.mllb_tysc in
                                              FStar_Extraction_ML_UEnv.extend_lb
                                                env lbname t uu____1281
                                                ml_lb.FStar_Extraction_ML_Syntax.mllb_add_unit
                                                false in
                                            FStar_All.pipe_left Prims.fst
                                              uu____1278 in
                                          (uu____1277, ml_lb) in
                                    (match uu____1257 with
                                     | (g,ml_lb) -> (g, (ml_lb :: ml_lbs))))
                         (g, []) bindings (Prims.snd lbs) in
                     (match uu____1209 with
                      | (g,ml_lbs') ->
                          let flags =
                            FStar_List.choose
                              (fun uu___133_1301  ->
                                 match uu___133_1301 with
                                 | FStar_Syntax_Syntax.Assumption  ->
                                     Some FStar_Extraction_ML_Syntax.Assumed
                                 | FStar_Syntax_Syntax.Private  ->
                                     Some FStar_Extraction_ML_Syntax.Private
                                 | FStar_Syntax_Syntax.NoExtract  ->
                                     Some
                                       FStar_Extraction_ML_Syntax.NoExtract
                                 | uu____1303 -> None) quals in
                          let flags' =
                            FStar_List.choose
                              (fun uu___134_1308  ->
                                 match uu___134_1308 with
                                 | {
                                     FStar_Syntax_Syntax.n =
                                       FStar_Syntax_Syntax.Tm_constant
                                       (FStar_Const.Const_string
                                       (data,uu____1313));
                                     FStar_Syntax_Syntax.tk = uu____1314;
                                     FStar_Syntax_Syntax.pos = uu____1315;
                                     FStar_Syntax_Syntax.vars = uu____1316;_}
                                     ->
                                     Some
                                       (FStar_Extraction_ML_Syntax.Attribute
                                          (FStar_Util.string_of_unicode data))
                                 | uu____1321 ->
                                     (FStar_Util.print_warning
                                        "Warning: unrecognized, non-string attribute, bother protz for a better error message";
                                      None)) attrs in
                          let uu____1325 =
                            let uu____1327 =
                              let uu____1328 =
                                FStar_Extraction_ML_Util.mlloc_of_range r in
                              FStar_Extraction_ML_Syntax.MLM_Loc uu____1328 in
                            [uu____1327;
                            FStar_Extraction_ML_Syntax.MLM_Let
                              (flavor, (FStar_List.append flags flags'),
                                (FStar_List.rev ml_lbs'))] in
                          (g, uu____1325))
                 | uu____1332 ->
                     let uu____1333 =
                       let uu____1334 =
                         FStar_Extraction_ML_Code.string_of_mlexpr
                           g.FStar_Extraction_ML_UEnv.currentModule ml_let in
                       FStar_Util.format1
                         "Impossible: Translated a let to a non-let: %s"
                         uu____1334 in
                     failwith uu____1333))
       | FStar_Syntax_Syntax.Sig_declare_typ (lid,uu____1339,t,quals,r) ->
           let uu____1345 =
             FStar_All.pipe_right quals
               (FStar_List.contains FStar_Syntax_Syntax.Assumption) in
           (match uu____1345 with
            | true  ->
                let always_fail =
                  let imp =
                    let uu____1354 = FStar_Syntax_Util.arrow_formals t in
                    match uu____1354 with
                    | ([],t) -> fail_exp lid t
                    | (bs,t) ->
                        let uu____1386 = fail_exp lid t in
                        FStar_Syntax_Util.abs bs uu____1386 None in
                  let uu____1392 =
                    let uu____1401 =
                      let uu____1405 =
                        let uu____1407 =
                          let uu____1408 =
                            let uu____1411 =
                              FStar_Syntax_Syntax.lid_as_fv lid
                                FStar_Syntax_Syntax.Delta_constant None in
                            FStar_Util.Inr uu____1411 in
                          {
                            FStar_Syntax_Syntax.lbname = uu____1408;
                            FStar_Syntax_Syntax.lbunivs = [];
                            FStar_Syntax_Syntax.lbtyp = t;
                            FStar_Syntax_Syntax.lbeff =
                              FStar_Syntax_Const.effect_ML_lid;
                            FStar_Syntax_Syntax.lbdef = imp
                          } in
                        [uu____1407] in
                      (false, uu____1405) in
                    (uu____1401, r, [], quals, []) in
                  FStar_Syntax_Syntax.Sig_let uu____1392 in
                let uu____1419 = extract_sig g always_fail in
                (match uu____1419 with
                 | (g,mlm) ->
                     let uu____1430 =
                       FStar_Util.find_map quals
                         (fun uu___135_1432  ->
                            match uu___135_1432 with
                            | FStar_Syntax_Syntax.Discriminator l -> Some l
                            | uu____1435 -> None) in
                     (match uu____1430 with
                      | Some l ->
                          let uu____1440 =
                            let uu____1442 =
                              let uu____1443 =
                                FStar_Extraction_ML_Util.mlloc_of_range r in
                              FStar_Extraction_ML_Syntax.MLM_Loc uu____1443 in
                            let uu____1444 =
                              let uu____1446 =
                                FStar_Extraction_ML_Term.ind_discriminator_body
                                  g lid l in
                              [uu____1446] in
                            uu____1442 :: uu____1444 in
                          (g, uu____1440)
                      | uu____1448 ->
                          let uu____1450 =
                            FStar_Util.find_map quals
                              (fun uu___136_1452  ->
                                 match uu___136_1452 with
                                 | FStar_Syntax_Syntax.Projector
                                     (l,uu____1455) -> Some l
                                 | uu____1456 -> None) in
                          (match uu____1450 with
                           | Some uu____1460 -> (g, [])
                           | uu____1462 -> (g, mlm))))
            | uu____1465 -> (g, []))
       | FStar_Syntax_Syntax.Sig_main (e,r) ->
           let uu____1469 = FStar_Extraction_ML_Term.term_as_mlexpr g e in
           (match uu____1469 with
            | (ml_main,uu____1477,uu____1478) ->
                let uu____1479 =
                  let uu____1481 =
                    let uu____1482 =
                      FStar_Extraction_ML_Util.mlloc_of_range r in
                    FStar_Extraction_ML_Syntax.MLM_Loc uu____1482 in
                  [uu____1481; FStar_Extraction_ML_Syntax.MLM_Top ml_main] in
                (g, uu____1479))
       | FStar_Syntax_Syntax.Sig_new_effect_for_free uu____1484 ->
           failwith "impossible -- removed by tc.fs"
       | FStar_Syntax_Syntax.Sig_assume _
         |FStar_Syntax_Syntax.Sig_sub_effect _
          |FStar_Syntax_Syntax.Sig_effect_abbrev _ -> (g, [])
       | FStar_Syntax_Syntax.Sig_pragma (p,uu____1495) ->
           ((match p = FStar_Syntax_Syntax.LightOff with
             | true  -> FStar_Options.set_ml_ish ()
             | uu____1497 -> ());
            (g, [])))
let extract_iface:
  FStar_Extraction_ML_UEnv.env -> FStar_Syntax_Syntax.modul -> env_t =
  fun g  ->
    fun m  ->
      let uu____1505 =
        FStar_Util.fold_map extract_sig g m.FStar_Syntax_Syntax.declarations in
      FStar_All.pipe_right uu____1505 Prims.fst
let rec extract:
  FStar_Extraction_ML_UEnv.env ->
    FStar_Syntax_Syntax.modul ->
      (FStar_Extraction_ML_UEnv.env* FStar_Extraction_ML_Syntax.mllib
        Prims.list)
  =
  fun g  ->
    fun m  ->
      FStar_Syntax_Syntax.reset_gensym ();
      (let uu____1530 = FStar_Options.restore_cmd_line_options true in
       let name =
         FStar_Extraction_ML_Syntax.mlpath_of_lident
           m.FStar_Syntax_Syntax.name in
       let g =
         let uu___138_1533 = g in
         {
           FStar_Extraction_ML_UEnv.tcenv =
             (uu___138_1533.FStar_Extraction_ML_UEnv.tcenv);
           FStar_Extraction_ML_UEnv.gamma =
             (uu___138_1533.FStar_Extraction_ML_UEnv.gamma);
           FStar_Extraction_ML_UEnv.tydefs =
             (uu___138_1533.FStar_Extraction_ML_UEnv.tydefs);
           FStar_Extraction_ML_UEnv.currentModule = name
         } in
       let uu____1534 =
         FStar_Util.fold_map extract_sig g m.FStar_Syntax_Syntax.declarations in
       match uu____1534 with
       | (g,sigs) ->
           let mlm = FStar_List.flatten sigs in
           let uu____1550 =
             (((m.FStar_Syntax_Syntax.name).FStar_Ident.str <> "Prims") &&
                (Prims.op_Negation m.FStar_Syntax_Syntax.is_interface))
               &&
               (FStar_Options.should_extract
                  (m.FStar_Syntax_Syntax.name).FStar_Ident.str) in
           (match uu____1550 with
            | true  ->
                ((let uu____1555 =
                    FStar_Syntax_Print.lid_to_string
                      m.FStar_Syntax_Syntax.name in
                  FStar_Util.print1 "Extracted module %s\n" uu____1555);
                 (g,
                   [FStar_Extraction_ML_Syntax.MLLib
                      [(name, (Some ([], mlm)),
                         (FStar_Extraction_ML_Syntax.MLLib []))]]))
            | uu____1585 -> (g, [])))