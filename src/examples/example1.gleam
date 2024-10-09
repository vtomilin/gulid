import gleam/io
import gleam/list
import gulid.{
  DecodeError, InvalidLength, from_string_function, new, new_as_string,
  new_monotonic, to_string_function,
}

pub fn main() {
  // Quick and dirty ULID string - performance implications
  let ulid_str = new_as_string()
  io.println("ULID is " <> ulid_str)

  // Convert many ULIDs with a generator function
  let to_string = to_string_function()
  // `to_string_function` returns a function that then can be used to
  // convert `Ulid` values to `String`. The reason this is done this way is
  // that Gleam doesn't have a way to define module scoped global constants
  // that could allow function calls to initialize. Nor does it allow module 
  // scoped `let`. Therefore, the only way to have a `private` reused immutable
  // value is to have it as a capture in a lamdba function. So, there is a 
  // `let` in `to_string_function`, which binds an Erlang array with ULID 
  // character encodings, captured in the returned function. 
  let bunch_of_ulids = list.map([new(), new(), new(), new(), new()], to_string)
  io.println("A bunch of ULIDs:")
  io.debug(bunch_of_ulids)

  // Parse ULIDs from string
  let from_string = from_string_function()
  // Quick and dirty
  let assert Ok(ulid) = from_string("01J9HSAQG7YR6Z16SS7ZTH26WQ")
  io.println("Quick and dirty ULID is")
  io.debug(ulid)

  // More proper
  io.println("A more properly parsed ULID is")
  case from_string("01J9HS6WA9ZBA045WTNYWAGPM5") {
    Ok(ulid) -> {
      io.debug(ulid)
      Nil
    }
    Error(InvalidLength(error)) | Error(DecodeError(error)) ->
      io.println("Oh, noes, the error: " <> error)
  }

  // Monotonic ULIDs:
  io.println("Generating 10 monotonic ULIDs")
  // 1. Generate initial `Ulid` with `new()`
  // 2. Then use `new_monotonic(Ulid)` with initial and subsequently generated
  list.range(0, 9)
  // We want 10 monotonic ULIDs
  |> list.scan(new(), fn(ulid, _) { new_monotonic(ulid) })
  // Convert'em to strings
  |> list.map(to_string_function())
  |> io.debug
}
