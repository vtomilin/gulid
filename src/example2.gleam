import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import ulid.{from_parts, from_tuple, to_parts}

pub fn main() {
  let ulid =
    from_parts(
      erlang.system_time(erlang.Millisecond),
      int.random(99_999_999_999),
    )
  io.println("My ulid made from spare parts:")
  io.debug(ulid)

  let #(timestamp, random) = to_parts(ulid)
  io.println("Now, extracted its constituent timestamp and random:")
  io.println(
    "\tTime: "
    <> { system_time_to_rfc3339(timestamp / 1000) |> from_codepoints },
  )
  // io.debug(system_time_to_rfc3339(timestamp / 1000))
  io.println("\tRandom: " <> int.to_string(random))

  let same_ulid = from_tuple(#(timestamp, random))

  should.equal(ulid, same_ulid)
}

@external(erlang, "calendar", "system_time_to_rfc3339")
fn system_time_to_rfc3339(timestamp_millis_since_epoch: Int) -> List(Int)

fn from_codepoints(code_points: List(Int)) -> String {
  code_points
  |> list.map(string.utf_codepoint)
  |> list.map(fn(res) {
    let assert Ok(default_codepoint) = string.utf_codepoint(97)
    result.unwrap(res, default_codepoint)
  })
  |> string.from_utf_codepoints
}
