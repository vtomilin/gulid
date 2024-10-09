import gleam/erlang
import gleam/int
import gleam/list
import gleam/order
import gleam/string
import gleam_ulid.{
  type Ulid, from_parts, from_string_function, new, new_monotonic, to_parts,
  to_string_function,
}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn to_string_success_test() -> #(Ulid, String) {
  let to_string = to_string_function()
  let ulid = new()
  let ulid_str = to_string(ulid)

  ulid_str
  |> string.length
  |> should.equal(26)
  #(ulid, ulid_str)
}

pub fn monotonic_test() {
  list.range(0, 9)
  |> list.scan(new(), fn(ulid, _) { new_monotonic(ulid) })
  |> list.map(to_string_function())
  |> list.window_by_2
  |> list.all(fn(ulid_pair) {
    let #(a, b) = ulid_pair
    string.compare(a, b) == order.Lt
  })
  |> should.be_true
}

pub fn from_string_success_test() {
  let from_string = from_string_function()
  let #(ulid, ulid_str) = to_string_success_test()
  let assert Ok(ulid_from_str) = from_string(ulid_str)

  ulid_from_str
  |> should.equal(ulid)
}

pub fn from_string_bad_input_test() {
  let from_string = from_string_function()

  "ABSOLUTEBS"
  |> from_string
  |> should.be_error
}

pub fn from_string_too_long_test() {
  let from_string = from_string_function()
  "01J9HGG3AXEE36X303YGE20GGP0"
  |> from_string
  |> should.be_error
}

pub fn from_string_too_short_test() {
  let from_string = from_string_function()
  "01J9HGG3AXEE36X303YGE20GG"
  |> from_string
  |> should.be_error
}

pub fn from_parts_test() {
  let date_time = erlang.system_time(erlang.Millisecond)
  let random = int.random(162_554_647_477_263)
  let ulid = from_parts(date_time, random)
  let #(ts, rnd) = to_parts(ulid)

  ts |> should.equal(date_time)
  rnd |> should.equal(random)
}
