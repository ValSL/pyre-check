(** Copyright (c) 2016-present, Facebook, Inc.

    This source code is licensed under the MIT license found in the
    LICENSE file in the root directory of this source tree. *)


open Core

open Ast.Expression
open Analysis

open OUnit2

module Handler = Service.Environment.SharedHandler.DependencyHandler


let assert_keys ~add ~get keys expected =
  let handle = File.Handle.create "dummy.py" in
  Handler.clear_keys_batch [handle];
  List.iter keys ~f:(add ~handle);
  assert_equal expected (get ~handle)


let test_dependency_keys _ =
  let assert_dependencies accesses ~expected =
    let accesses = List.map accesses ~f:Access.create in
    let expected = List.map expected ~f:Access.create in
    assert_keys ~add:Handler.add_dependent_key ~get:Handler.get_dependent_keys accesses expected
  in
  assert_dependencies ["a.b.c"; "d"; "e"] ~expected:["e"; "d"; "a.b.c"];
  assert_dependencies ["a.b.c"] ~expected:["a.b.c"]


let test_alias_keys _ =
  let assert_aliases keys ~expected =
    assert_keys ~add:Handler.add_alias_key ~get:Handler.get_alias_keys keys expected
  in
  assert_aliases [Type.Primitive "first_key"] ~expected:[Type.Primitive "first_key"];
  assert_aliases
    [Type.Primitive "first_key"; Type.Primitive "second_key"]
    ~expected:[Type.Primitive "second_key"; Type.Primitive "first_key"]


let test_class_keys _ =
  let assert_classes keys ~expected =
    assert_keys ~add:Handler.add_class_key ~get:Handler.get_class_keys keys expected
  in
  assert_classes [Type.Primitive "C"] ~expected:[Type.Primitive "C"];
  assert_classes
    [Type.Primitive "C"; Type.Primitive "D"]
    ~expected:[Type.Primitive "D"; Type.Primitive "C"]


let test_function_keys _ =
  let assert_function_keys keys ~expected =
    let keys = List.map keys ~f:Access.create in
    let expected = List.map expected ~f:Access.create in
    assert_keys ~add:Handler.add_function_key ~get:Handler.get_function_keys keys expected
  in
  assert_function_keys ["f1"] ~expected:["f1"];
  assert_function_keys ["f"; "g"; "class_method"] ~expected:["class_method"; "g"; "f"]


let test_global_keys _ =
  let assert_global_keys keys ~expected =
    let keys = List.map keys ~f:Access.create in
    let expected = List.map expected ~f:Access.create in
    assert_keys ~add:Handler.add_global_key ~get:Handler.get_global_keys keys expected
  in
  assert_global_keys ["a"] ~expected:["a"];
  assert_global_keys ["a"; "b"; "f"] ~expected:["f"; "b"; "a"]


let () =
  "environment">:::[
    "dependent_keys">::test_dependency_keys;
    "alias_keys">::test_alias_keys;
    "class_keys">::test_class_keys;
    "function_keys">::test_function_keys;
    "global_keys">::test_global_keys;
  ]
  |> Test.run
