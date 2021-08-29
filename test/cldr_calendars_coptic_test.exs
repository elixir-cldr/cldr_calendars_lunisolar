defmodule Cldr.Calendar.CopticTest do
  use ExUnit.Case

  doctest Cldr.Calendar.Coptic

  test "day of week" do
    {:ok, gregorian_date} = Date.new(2019,12,9, Cldr.Calendar.Gregorian)
    {:ok, coptic_date} = Date.convert(gregorian_date, Cldr.Calendar.Coptic)
    assert Cldr.Calendar.day_of_week(coptic_date) == 1
  end

  test "months in year" do
    assert Cldr.Calendar.Coptic.months_in_year(2000) == 13
  end

  test "~D sigil" do
    assert ~U[1736-13-01T00:00:00.0Z Cldr.Calendar.Coptic]
    assert ~D[1736-13-01 Cldr.Calendar.Coptic]
    assert ~D[1736-13-05 Cldr.Calendar.Coptic]
  end

end
