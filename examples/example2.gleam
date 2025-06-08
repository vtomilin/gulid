import gleam/bool
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gulid.{
  from_bitarray, from_parts, from_tuple, to_parts, to_string_function,
}

pub fn main() {
  let to_string = to_string_function()
  let ulid =
    from_parts(
      erlang.system_time(erlang.Millisecond),
      int.random(99_999_999_999),
    )
  io.println("My ulid made from spare parts: " <> to_string(ulid))
  echo ulid

  let #(timestamp, random) = to_parts(ulid)
  io.println("Now, extracted its constituent timestamp and random:")
  io.println(
    "\tTime: "
    <> { system_time_to_rfc3339(timestamp / 1000) |> from_codepoints },
  )
  io.println("\tRandom: " <> int.to_string(random))

  let same_ulid = from_tuple(#(timestamp, random))
  io.println(
    "Now, we reconstruct a new ULID back from the earlier extracted components: "
    <> to_string(same_ulid),
  )

  io.println("Same ulids? " <> { bool.to_string(same_ulid == ulid) })

  // Ulid from a binary
  let assert Ok(bin_ulid) =
    <<
      erlang.system_time(erlang.Millisecond):big-48,
      int.random(9_999_999_999):big-80,
    >>
    |> from_bitarray
  io.println("Ulid from a bitarray: ")
  echo bin_ulid

  // Ulid to a bitarray
  io.println("Ulid to binary: ")
  bin_ulid
  |> gulid.to_bitarray
  |> echo
}

@external(erlang, "calendar", "system_time_to_rfc3339")
fn system_time_to_rfc3339(seconds_since_epoch: Int) -> List(Int)

fn from_codepoints(code_points: List(Int)) -> String {
  code_points
  |> list.map(string.utf_codepoint)
  |> list.map(fn(res) {
    let assert Ok(default_codepoint) = string.utf_codepoint(97)
    result.unwrap(res, default_codepoint)
  })
  |> string.from_utf_codepoints
}
