defmodule Cldr.Calendar.Chinese.Test do
  use ExUnit.Case, async: true

  test "rollover of years" do
    # First day of the 15 year of 78th cycle. Also a leap year.
    t = Cldr.Calendar.Gregorian.date_to_iso_days(1998, 1, 28)
    assert Cldr.Calendar.Chinese.alt_chinese_date_from_iso_days(t) == {78, 15, 1, false, 1}

    # First day of the 20th year of 78th cycle. Not a leap year.
    t = Cldr.Calendar.Gregorian.date_to_iso_days(2003, 2, 1)
    assert Cldr.Calendar.Chinese.alt_chinese_date_from_iso_days(t) == {78, 20, 1, false, 1}

    # First day of the 39th year of 78th cycle. Not a leap year.
    t = Cldr.Calendar.Gregorian.date_to_iso_days(2022, 2, 1)
    assert Cldr.Calendar.Chinese.alt_chinese_date_from_iso_days(t) == {78, 39, 1, false, 1}
  end

  test "months in year" do

  end

  test "~D sigil" do

  end
end
