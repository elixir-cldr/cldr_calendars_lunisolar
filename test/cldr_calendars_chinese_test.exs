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
    alias Calendar.ISO

    # Lunar Month 1 begins from January 22, 2023 to February 19, 2023
    assert Date.convert!(~D[4660-01-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-01-22]

    # Lunar Month 2 begins from February 20, 2023 to March 21, 2023
    assert Date.convert!(~D[4660-02-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-02-20]

    # Lunar Leap Month 2 begins from March 22, 2023 to April 19, 2023
    assert Date.convert!(~D[4660-03-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-03-22]

    # Lunar Month 3 begins from April 20, 2023 to May 18, 2023
    assert Date.convert!(~D[4660-04-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-04-20]

    # Lunar Month 4 begins from May 19, 2023 to June 17, 2023
    assert Date.convert!(~D[4660-05-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-05-19]

    # Lunar Month 5 begins from June 18, 2023 to July 17, 2023
    assert Date.convert!(~D[4660-06-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-06-18]

    # Lunar Month 6 begins from July 18, 2023 to August 15, 2023
    assert Date.convert!(~D[4660-07-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-07-18]

    # Lunar Month 7 begins from August 16, 2023 to September 14, 2023
    assert Date.convert!(~D[4660-08-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-08-16]

    # Lunar Month 8 begins from September 15, 2023 to October 14, 2023
    assert Date.convert!(~D[4660-09-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-09-15]

    # Lunar Month 9 begins from October 15, 2023 to November 12, 2023
    assert Date.convert!(~D[4660-10-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-10-15]

    # Lunar Month 10 begins from November 13, 2023 to December 12, 2023
    assert Date.convert!(~D[4660-11-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-11-13]

    # Lunar Month 11 begins from December 13, 2023 to January 10, 2024
    assert Date.convert!(~D[4660-12-01 Cldr.Calendar.Chinese], ISO) == ~D[2023-12-13]

    # Lunar Month 12 begins from January 11, 2024 to February 9, 2024
    assert Date.convert!(~D[4660-13-01 Cldr.Calendar.Chinese], ISO) == ~D[2024-01-11]
  end

  test "Localization of leap month for chinese and korean calendars" do
    assert "윤2월" = Cldr.Calendar.localize(~D[4356-03-01 Cldr.Calendar.Korean], :month, locale: :ko)
    assert "闰二月" = Cldr.Calendar.localize(~D[4660-03-01 Cldr.Calendar.Chinese], :month, locale: :zh)
  end

  test "Localization of leap month for japanese calendars" do
    # Japanese calendar has no month_formats (surprising!)
    # Perhaps in CLDR the :japanese calendar is intended to be gregorian?
    assert "2月" = Cldr.Calendar.localize(~D[2023-03-01 Cldr.Calendar.Japanese], :month, locale: :ja)
  end
end
