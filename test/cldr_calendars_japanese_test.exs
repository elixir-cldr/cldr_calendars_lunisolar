# TODO This goes into a new Cldr.Calendar Japanese module
# defmodule Cldr.Calendar.Japanese.Test do
#   use ExUnit.Case, async: true
#
#   alias Cldr.Calendar.Japanese
#
#   test "Year of Japanese Era around transitions" do
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[2019-05-01], Japanese)) == {1, 236}
#
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[2019-04-30], Japanese)) == {31, 235}
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[1989-01-08], Japanese)) == {1, 235}
#
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[1989-01-07], Japanese)) == {63, 234}
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[1926-12-25], Japanese)) == {1, 234}
#
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[1926-12-24], Japanese)) == {15, 233}
#     assert Cldr.Calendar.year_of_era(Date.convert!(~D[1912-07-30], Japanese)) == {1, 233}
#
#     assert Cldr.Calendar.year_of_era(~D[1912-06-16 Cldr.Calendar.Japanese]) == {45, 232}
#     assert Cldr.Calendar.year_of_era(~D[1868-09-08 Cldr.Calendar.Japanese]) == {1, 232}
#
#     assert Cldr.Calendar.year_of_era(~D[1868-09-07 Cldr.Calendar.Japanese]) == {4, 231}
#     assert Cldr.Calendar.year_of_era(~D[1865-04-07 Cldr.Calendar.Japanese]) == {1, 231}
#   end
#
#   test "Era localization" do
#     assert Cldr.Calendar.localize(Date.convert!(~D[2019-05-01], Cldr.Calendar.Japanese), :era) ==
#       "Reiwa"
#     assert Cldr.Calendar.localize(Date.convert!(~D[2019-04-30], Cldr.Calendar.Japanese), :era) ==
#       "Heisei"
#     assert Cldr.Calendar.localize(Date.convert!(~D[1989-01-07], Cldr.Calendar.Japanese), :era) ==
#       "Shōwa"
#     assert Cldr.Calendar.localize(Date.convert!(~D[1926-12-24], Cldr.Calendar.Japanese), :era) ==
#       "Taishō"
#   end
# end