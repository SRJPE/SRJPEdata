#' Convert Celsius to Fahrenheit
#'
#' This function converts temperature from Celsius to Fahrenheit.
#'
#' @param celsius A numeric value representing the temperature in Celsius.
#'
#' @return A numeric value representing the temperature in Fahrenheit.
#'
#' @examples
#' celsius_to_fahrenheit(0) # Should return 32
#' celsius_to_fahrenheit(100) # Should return 212
#'
#' @export
celsius_to_fahrenheit <- function(celsius) {
  fahrenheit <- (celsius * 9/5) + 32
  return(fahrenheit)
}


#' Convert Fahrenheit to Celsius
#'
#' This function converts temperature from Fahrenheit to Celsius.
#'
#' @param fahrenheit A numeric value representing the temperature in Fahrenheit.
#'
#' @return A numeric value representing the temperature in Celsius.
#'
#' @examples
#' fahrenheit_to_celsius(32) # Should return 0
#' fahrenheit_to_celsius(212) # Should return 100
#'
#' @export
fahrenheit_to_celsius <- function(fahrenheit) {
  celsius <- (fahrenheit - 32) * 5/9
  return(celsius)
}
