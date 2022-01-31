defmodule Cldr.Calendar.Chinese.LeapMonth.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 4000

  alias Cldr.Calendar.Chinese

  property "Chinese Leap Month" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      {cycle_a, year_a, _month, leap_month?, day_a} = Chinese.alt_chinese_date_from_iso_days(iso_days)
      {cycle, year, month, day} = Chinese.chinese_date_from_iso_days(iso_days)

      assert cycle_a == cycle
      assert year_a == year
      assert day_a == day

      if leap_month? do
        assert Chinese.leap_month?(cycle, year, month)
      else
        refute Chinese.leap_month?(cycle, year, month)
      end
    end
  end
end
