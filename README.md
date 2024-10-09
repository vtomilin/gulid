# Gleam ULID
[Universally Unique Lexicographically Sortable Identifier](https://github.com/ulid/spec) implementation in
Gleam.

# Caveats
1. Only Erlang build target is supported (at the moment)

[![Package Version](https://img.shields.io/hexpm/v/ulid)](https://hex.pm/packages/ulid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/ulid/)

```sh
gleam add gulid
```

# Basic Use

```gleam
import gulid.{ new_as_string, new, new_monotonic, from_string_function,
                    to_string_function }

pub fn main() {
  // Quick and dirty ULID string - has performance implications
  let ulid_str = new_as_string()
  io.println("ULID is " <> ulid_str)

  // Conver many ULIDs to String with a generator function
  let to_string = to_string_function()
  // `to_string_function` returns a function that then can be used to
  // convert `Ulid` values to `String`. The reason this is done this way is
  // that Gleam doesn't have a way to define module scoped global constants
  // that could use function calls to initialize. Nor does it have module scoped
  // `let`. Therefore, the only way to have a `private` reused value is to
  // have it as a capture. So, there is a `let` in `to_string_function`, which
  // binds an Erlang array with ULID character encodings, captured in returned
  // function.
  let bunch_of_ulids = list.map([new(), new(), new(), new(), new()], to_string)
  io.println("A bunch of ULIDs:")
  io.debug(bunch_of_ulids)

  // Parse ULIDs from string
  let from_string = from_string_function()
  // Quick and dirty
  let assert Ok(ulid) = from_string("01J9HSAQG7YR6Z16SS7ZTH26WQ")
  io.println("Quick and dirty parsed ULID is")
  io.debug(ulid)

  // More proper
  io.println("A more properly parsed ULID is")
  case from_string("01J9HS6WA9ZBA045WTNYWAGPM5") {
    Ok(ulid) -> {
      io.debug(ulid)
      Nil
    }
    Error(InvalidLength(error)) | Error(DecodeError(error)) ->
      io.println("Oh, noes: " <> error)
  }

  // Monotonic ULIDs:
  // 1. Generate initial `Ulid` with `new()`
  // 2. Then use `new_monotonic(Ulid)` with initial and subsequently generated
  list.range(0, 9)
  |> list.scan(new(), fn(ulid, _) { new_monotonic(ulid) })
  |> list.map(to_string_function())
  |> io.debug

}
```
# Advanced Use
In case one needs to create ULIDs out of predefined constituents
(timestamp and random), or extract them:

```gleam
import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/bool
import gulid.{from_parts, from_tuple, to_parts}

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

  io.println("Same ulids? " <> { bool.to_string(same_ulid == ulid) })
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
```

Further documentation can be found at <https://hexdocs.pm/ulid>.

## Development

```sh
gleam run -m examples/example1   # Run the example one
gleam run -m examples/example2   # Run the example two
gleam test  # Run the tests
```
