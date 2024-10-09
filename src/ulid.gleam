import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/erlang
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string

/// Represents an opaque `Ulid` type.
///
/// ## Create
/// - `new()`: Non-monotonic.
/// - `new_monotonic(Ulid)`: Monotonic using previous.
/// - `from_string(String)`: Parse ULID from a string.
/// - `from_parts(Int, Int)`: Create from a timestamp milliseconds from Epoch
///                           and random.
///
/// ## Convert to `String`
/// ```gleam
///    let to_string = to_string_function()
///    let ulid = new()
///    io.println("Ulid: " <> to_string(ulid))
/// ```
pub opaque type Ulid {
  /// Create `Ulid` value from a raw `BitArray`
  Ulid(BitArray)
}

/// Ulid module errors
pub type UlidError {
  /// Returned when failed to decode
  DecodeError(mesage: String)
  /// Returned when input is of incorrect length
  InvalidLength(message: String)
}

/// Returns a function than converts a `Ulid` value to string.
///
/// ## Eamples
///
/// ```gleam
/// let to_string = to_string_function()
/// let ulid = new()
/// io.debug(to_string(ulid))
/// ```
pub fn to_string_function() -> fn(Ulid) -> String {
  let base32_array =
    base32
    |> string.to_graphemes
    |> erl_array_from_list

  fn(ulid: Ulid) -> String {
    // Below let assert is fine, because any `Ulid` value can be converted
    // to string
    let assert Ok(ulid_str) =
      ulid
      |> to_bitarray
      |> encode_to_string_with_accumulator("", base32_array)

    ulid_str
  }
}

/// Returns a new `Ulid` created from current system time and strong random.
pub fn new() -> Ulid {
  let time = erlang.system_time(erlang.Millisecond)
  let randomness = crypto.strong_random_bytes(10)

  Ulid(<<time:big-48, randomness:bits>>)
}

/// Returns new `Ulid` value based on given previous according to behavior,
/// described on ULID spec, basically, if previous has the same timestamp then
/// increment least significant bit of its random by 1 with carry to produce a
/// new `Ulid` (with the same timestamp).
pub fn new_monotonic(prev_ulid: Ulid) -> Ulid {
  let time = erlang.system_time(erlang.Millisecond)
  let assert Ulid(<<prev_time:unsigned-48, random:unsigned-80>>) = prev_ulid
  case int.compare(time, prev_time) {
    order.Eq | order.Lt -> Ulid(<<prev_time:big-48, { random + 1 }:big-80>>)
    _ -> Ulid(<<time:big-48, crypto.strong_random_bytes(10):bits>>)
  }
}

/// Returns a non-monotonic ULID value as string. Note, this is a shortcut, 
/// not very good as far as the performance.
pub fn new_as_string() -> String {
  new() |> to_string_function()
}

/// Builds a `Ulid` value from given `BitArray`. Returns `Ok` with `Ulid` value
/// on success or `UlidError` otherwise.
pub fn from_bitarray(array: BitArray) -> Result(Ulid, UlidError) {
  case array {
    <<ulid:bits-128>> -> Ok(Ulid(ulid))
    _ ->
      "Invalid length of a Ulid bitarray"
      |> InvalidLength
      |> Error
  }
}

/// Returns a function that decodes a `Ulid` value from a given string. It 
/// returns `Ok` with the `Ulid` value or `UlidError`.
///
/// ## Examples
///
/// ```gleam
/// let from_string = from_string_function()
/// let ulid_str = "01J9P2J2B0S4T4DFJAJ6RTV1DE"
/// let ulid = from_string(ulid_str)
/// io.debug(ulid)
/// ```
pub fn from_string_function() -> fn(String) -> Result(Ulid, UlidError) {
  let base32_decode =
    dict.from_list([
      // 0
      #("0", 0),
      #("o", 0),
      #("O", 0),
      // 1
      #("1", 1),
      #("l", 1),
      #("L", 1),
      #("I", 1),
      #("i", 1),
      // 2-9
      #("2", 2),
      #("3", 3),
      #("4", 4),
      #("5", 5),
      #("6", 6),
      #("7", 7),
      #("8", 8),
      #("9", 9),
      // A-H,a-h,J-N,j-n,P-T,p-t,V-Z,v-z
      #("a", 10),
      #("A", 10),
      #("b", 11),
      #("B", 11),
      #("c", 12),
      #("C", 12),
      #("d", 13),
      #("D", 13),
      #("e", 14),
      #("E", 14),
      #("f", 15),
      #("F", 15),
      #("g", 16),
      #("G", 16),
      #("h", 17),
      #("H", 17),
      #("j", 18),
      #("J", 18),
      #("k", 19),
      #("K", 19),
      #("m", 20),
      #("M", 20),
      #("n", 21),
      #("N", 21),
      #("p", 22),
      #("P", 22),
      #("q", 23),
      #("Q", 23),
      #("r", 24),
      #("R", 24),
      #("s", 25),
      #("S", 25),
      #("t", 26),
      #("T", 26),
      #("v", 27),
      #("V", 27),
      #("w", 28),
      #("W", 28),
      #("x", 29),
      #("X", 29),
      #("y", 30),
      #("Y", 30),
      #("z", 31),
      #("Z", 31),
    ])
  fn(str: String) -> Result(Ulid, UlidError) {
    str
    |> string.to_graphemes
    |> list.fold(
      Ok(<<>>),
      fn(acc: Result(BitArray, UlidError), symb: String) -> Result(
        BitArray,
        UlidError,
      ) {
        case acc {
          Ok(ulid_bits) -> {
            case dict.get(base32_decode, symb) {
              Ok(val) -> Ok(bit_array.append(ulid_bits, <<val:big-5>>))
              Error(_) ->
                { "Symbol " <> symb <> " is invalid in Base32 encoding" }
                |> DecodeError
                |> Error
            }
          }
          _ -> acc
        }
      },
    )
    // |> io.debug
    |> result.map(fn(ulid_bits) {
      case ulid_bits {
        <<_:2, trim:bits-128>> -> trim
        _ -> ulid_bits
      }
    })
    // |> io.debug
    |> result.try(from_bitarray)
  }
}

/// Returns an `Ulid` components `#(timestamp: Int, random: Int)` tuple.
pub fn to_parts(ulid: Ulid) -> #(Int, Int) {
  // let assert <<timestamp:unsigned-48, random:unsigned-80>> =
  // bit_array.append(ulid.timestamp, ulid.random)
  let assert Ulid(<<timestamp:unsigned-48, random:unsigned-80>>) = ulid
  #(timestamp, random)
}

/// Returns `Ulid` value, build from given integer timestamp (millis from Epoch)
/// and random values
pub fn from_parts(timestamp: Int, random: Int) -> Ulid {
  Ulid(<<timestamp:big-48, random:big-80>>)
}

/// Returns `Ulid` value, build from given (timestamp, random) tuple.
pub fn from_tuple(parts: #(Int, Int)) -> Ulid {
  from_parts(parts.0, parts.1)
}

//-- Private stuff

// Crockford base32 encoding characters
const base32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

/// Erlang Array
type Array(a)

/// Create Erlang array from a list
@external(erlang, "array", "from_list")
fn erl_array_from_list(list: List(a)) -> Array(a)

/// Get an element of Erlang array by index
@external(erlang, "array", "get")
fn erl_array_get(index: Int, array: Array(a)) -> a

/// Performs Crockford Base32 encoding on a given array accumulating the result 
/// in an accumulator `acc`. Returns the result if success full (e.g. when the
/// bit array's length is divisible by 5) or error otherwise.
fn encode_to_string_with_accumulator(
  array: BitArray,
  acc: String,
  base32: Array(String),
) -> Result(String, UlidError) {
  case array {
    <<>> -> Ok(acc)
    <<symb:unsigned-5, rest:bits>> ->
      acc
      |> string.append(erl_array_get(symb, base32))
      |> encode_to_string_with_accumulator(rest, _, base32)
    _ ->
      "Given bit array's bit length is not divisible by 5"
      |> InvalidLength
      |> Error
  }
}

/// Returns a binary representation of givem `Ulid` value
fn to_bitarray(ulid: Ulid) -> BitArray {
  let Ulid(result) = ulid
  <<0:2, result:bits>>
}
