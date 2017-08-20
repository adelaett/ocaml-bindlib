(* lets open the library ! *)
open Bindlib

(* type of pure lambda-terms *)

type term =
  App of term * term
| Abs of (term,term) binder

| FVar of term var (* constructor used for normalisation only *)

let fVar (x:term var) = FVar(x)
let app = box_apply2 (fun x y -> App(x,y))
let vabs name f = box_apply (fun f -> Abs f) (vbind fVar name f)
let abs name f = box_apply (fun f -> Abs f) (bind fVar name f)

(* advanced printing of term *)

let app_lvl = 2
let abs_lvl = 1
let ini_lvl = 0

let print_term t =
  let rec fn nv b = function
      App(t1,t2) ->
      	if b >= app_lvl then print_string "(";
      	fn nv abs_lvl t1;
      	print_string " ";
      	fn nv app_lvl t2;
      	if b >= app_lvl then print_string ")"
    | Abs _ as t ->
    	if b >= abs_lvl then print_string "(";
    	print_string "fun ";
        let rec gn nv = function
	    Abs f ->
	      let v = new_var fVar (binder_name f) in
	      let f' = subst f (FVar v) in
	      print_string (name_of v);
	      print_string " ";
	      gn (nv + 1) f'
	  | t ->
              print_string "-> ";
              fn nv ini_lvl t
    	in gn nv t;
    	if b >= abs_lvl then print_string ")"
    | FVar(v) ->
    	print_string (name_of v)
  in fn 0 ini_lvl t; print_newline ()

(* weak head normal form *)

(* call by name normalisation *)
let norm t =
  let rec fn t stack =
  match t with
  | App(t1,t2) -> fn t1 (t2::stack)
  | Abs f as t0 -> (
    match stack with
    | t::stack -> fn (subst f t) stack
    | [] ->
       if binder_closed f then box t0 else
         vabs (binder_name f) (fun x -> fn (subst f (FVar x)) []))
  | FVar x ->
     List.fold_left (fun t u -> app t (fn u [])) (box_of_var x) stack
in unbox (fn t [])

(* examples of terms *)
let idt = unbox(abs "x" (fun x -> x))

let delta = unbox(abs "x" (fun x -> app x x))

let _ = print_string "delta'"
let _ = print_newline ()

let zero =
  unbox(abs "f" (fun f -> abs "x" (fun x -> x)))

let tfalse = zero

let ttrue =
  unbox(abs "f" (fun f -> abs "x" (fun x -> f)))

let succ =
  unbox(abs "n" (fun n -> abs "f" (fun f ->
              abs "x" (fun x ->
                app f (app(app n f) x)))))
let succ' =
  unbox(abs "n" (fun n -> abs "f" (fun f ->
              abs "x" (fun x ->
                app (app n f) (app f x)))))

let two = App(succ,App(succ,zero))
let four = App(two,two)

let plus = unbox(abs "n" (fun n -> abs "m" (fun m ->
  abs "f" (fun f -> abs "x" (fun x ->
    app (app n f) (app (app m f) x))))))

let mul = unbox(abs "n" (fun n -> abs "m" (fun m ->
               abs "f" (fun f -> app n (app m f)))))

let height = App(App(plus,four) ,four)
let ten = App(App(plus,two) ,height)
let hundred = App(App(mul,ten) ,ten)
let thousand = App(App(mul,hundred) ,ten)


let pred = unbox(abs "n" (fun n ->
  app (app (app (app n (abs "p" (fun p ->
    abs "x" (fun x -> abs "y" (fun y ->
       app (app p (app (box succ) x)) x)))))
	      (abs "x" (fun x -> abs "y" (fun y -> y))))
	 (box zero)) (box zero)))

let bench () =
  let fh = App(App(mul,four),hundred) in
  let ft = App(App(mul,four),thousand) in
  print_term (norm (App(App(ft,pred),ft)));
  print_newline();
  print_term (norm (App(App(mul,fh),thousand)));
  print_newline();
  Printf.eprintf "top heap: %d\n%!" Gc.((stat ()).top_heap_words)

let _ = bench ()
