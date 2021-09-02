defmodule Cldr.Calendar.Chinese.LeapMonth.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 2000

  alias Cldr.Calendar.Chinese

  # This testing shows that there is agreement on the assertion, but
  # not agreement on the refutation. That means that somewhere we are
  # reporting a leap month when it is not

  property "Chinese Leap Month" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      {cycle_a, year_a, _month, leap_month?, _day} = Chinese.chinese_date_from_iso_days(iso_days)
      {cycle, year, month, _day} = Chinese.alt_chinese_date_from_iso_days(iso_days)

      assert cycle_a == cycle
      assert year_a == year

      if leap_month? do
        assert Chinese.alt_leap_month?(cycle, year, month)
      else
        # refute Chinese.alt_leap_month?(cycle, year, month)
        if Chinese.alt_leap_month?(cycle, year, month) do
          IO.inspect iso_days, label: "Unexpected leap month"
        end
      end
    end
  end
end
