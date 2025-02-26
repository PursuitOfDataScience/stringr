#' Control matching behaviour with modifier functions
#'
#' @description
#' Modifier functions control the meaning of the `pattern` argument to
#' stringr functions. The default uses the ICU regular expression engine,
#' but you can choose other options:
#'
#' * `boundary()`: Match boundaries between things.
#' * `coll()`: Compare strings using standard Unicode collation rules.
#' * `fixed()`: Compare literal bytes.
#' * `regex()`: the default. Uses ICU regular expressions.
#'
#' @param pattern Pattern to modify behaviour.
#' @param ignore_case Should case differences be ignored in the match?
#'   For `fixed()`, this uses a simple algorithm which assumes a
#'   one-to-one mapping between upper and lower case letters.
#' @name modifiers
#' @examples
#' pattern <- "a.b"
#' strings <- c("abb", "a.b")
#' str_detect(strings, pattern)
#' str_detect(strings, fixed(pattern))
#' str_detect(strings, coll(pattern))
#'
#' # coll() is useful for locale-aware case-insensitive matching
#' i <- c("I", "\u0130", "i")
#' i
#' str_detect(i, fixed("i", TRUE))
#' str_detect(i, coll("i", TRUE))
#' str_detect(i, coll("i", TRUE, locale = "tr"))
#'
#' # Word boundaries
#' words <- c("These are   some words.")
#' str_count(words, boundary("word"))
#' str_split(words, " ")[[1]]
#' str_split(words, boundary("word"))[[1]]
#'
#' # Regular expression variations
#' str_extract_all("The Cat in the Hat", "[a-z]+")
#' str_extract_all("The Cat in the Hat", regex("[a-z]+", TRUE))
#'
#' str_extract_all("a\nb\nc", "^.")
#' str_extract_all("a\nb\nc", regex("^.", multiline = TRUE))
#'
#' str_extract_all("a\nb\nc", "a.")
#' str_extract_all("a\nb\nc", regex("a.", dotall = TRUE))
NULL

#' @export
#' @rdname modifiers
fixed <- function(pattern, ignore_case = FALSE) {
  pattern <- as_bare_character(pattern)
  options <- stri_opts_fixed(case_insensitive = ignore_case)

  structure(
    pattern,
    options = options,
    class = c("fixed", "pattern", "character")
  )
}

#' @export
#' @rdname modifiers
#' @param locale Locale to use for comparisons. See
#'   [stringi::stri_locale_list()] for all possible options.
#'   Defaults to "en" (English) to ensure that default behaviour is
#'   consistent across platforms.
#' @param ... Other less frequently used arguments passed on to
#'   [stringi::stri_opts_collator()],
#'   [stringi::stri_opts_regex()], or
#'   [stringi::stri_opts_brkiter()]
coll <- function(pattern, ignore_case = FALSE, locale = "en", ...) {
  pattern <- as_bare_character(pattern)
  options <- str_opts_collator(
    ignore_case = ignore_case,
    locale = locale,
    ...
  )

  structure(
    pattern,
    options = options,
    class = c("coll", "pattern", "character")
  )
}


str_opts_collator <- function(locale = "en", ignore_case = FALSE, strength = NULL, ...) {
  strength <- strength %||% if (ignore_case) 2L else 3L
  stri_opts_collator(
    strength = strength,
    locale = locale,
    ...
  )
}

#' @export
#' @rdname modifiers
#' @param multiline If `TRUE`, `$` and `^` match
#'   the beginning and end of each line. If `FALSE`, the
#'   default, only match the start and end of the input.
#' @param comments If `TRUE`, white space and comments beginning with
#'   `#` are ignored. Escape literal spaces with `\\ `.
#' @param dotall If `TRUE`, `.` will also match line terminators.
regex <- function(pattern, ignore_case = FALSE, multiline = FALSE,
                   comments = FALSE, dotall = FALSE, ...) {
  pattern <- as_bare_character(pattern)
  options <- stri_opts_regex(
    case_insensitive = ignore_case,
    multiline = multiline,
    comments = comments,
    dotall = dotall,
    ...
  )

  structure(
    pattern,
    options = options,
    class = c("regex", "pattern", "character")
  )
}

#' @param type Boundary type to detect.
#' \describe{
#'  \item{`character`}{Every character is a boundary.}
#'  \item{`line_break`}{Boundaries are places where it is acceptable to have
#'    a line break in the current locale.}
#'  \item{`sentence`}{The beginnings and ends of sentences are boundaries,
#'    using intelligent rules to avoid counting abbreviations
#'    ([details](https://www.unicode.org/reports/tr29/#Sentence_Boundaries)).}
#'  \item{`word`}{The beginnings and ends of words are boundaries.}
#' }
#' @param skip_word_none Ignore "words" that don't contain any characters
#'   or numbers - i.e. punctuation. Default `NA` will skip such "words"
#'   only when splitting on `word` boundaries.
#' @export
#' @rdname modifiers
boundary <- function(type = c("character", "line_break", "sentence", "word"),
                    skip_word_none = NA, ...) {
  type <- arg_match(type)

  if (identical(skip_word_none, NA)) {
    skip_word_none <- type == "word"
  }

  options <- stri_opts_brkiter(
    type = type,
    skip_word_none = skip_word_none,
    ...
  )

  structure(
    character(),
    options = options,
    class = c("boundary", "pattern", "character")
  )
}

opts <- function(x) {
  if (identical(x, "")) {
    stri_opts_brkiter(type = "character")
  } else {
    attr(x, "options")
  }
}

type <- function(x) UseMethod("type")
#' @export
type.boundary <- function(x) "bound"
#' @export
type.regex <- function(x) "regex"
#' @export
type.coll <- function(x) "coll"
#' @export
type.fixed <- function(x) "fixed"
#' @export
type.character <- function(x) if (identical(x, "")) "empty" else "regex"
#' @export
type.default <- function(x) {
  abort("`pattern` must be a string")
}


as_bare_character <- function(x) {
  if (is.character(x) && !is.object(x)) {
    # All OK!
    return(x)
  }

  warning("Coercing `pattern` to a plain character vector.", call. = FALSE)
  as.character(x)
}
