﻿
(*
   Copyright 2008-2015 Abhishek Anand, Nikhil Swamy and Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)
module FStar.Extraction.ML.Modul
open FStar.Pervasives
open FStar.Compiler.Effect
open FStar.Syntax.Syntax
open FStar.Extraction.ML.Syntax
open FStar.Extraction.ML.UEnv
type iface
val extract_iface: uenv -> modul -> uenv * iface
val extract : uenv -> modul -> uenv * option mllib

