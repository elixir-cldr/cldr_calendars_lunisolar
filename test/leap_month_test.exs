defmodule Cldr.Calendar.Chinese.LeapMonth.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 4000

  alias Cldr.Calendar.Chinese

  # This testing shows that there is agreement on the assertion, but
  # not agreement on the refutation. That means that somewhere we are
  # reporting a leap month when it is not

  property "Chinese Leap Month" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      {cycle_a, year_a, _month, leap_month?, day_a} = Chinese.chinese_date_from_iso_days(iso_days)
      date = Chinese.alt_chinese_date_from_iso_days(iso_days)
      {cycle, year, month, day} = date

      assert cycle_a == cycle
      assert year_a == year
      assert day_a == day

      if leap_month? do
        assert Chinese.alt_leap_month?(cycle, year, month)
      else
        refute Chinese.alt_leap_month?(cycle, year, month)
        # if Chinese.alt_leap_month?(cycle, year, month) do
        #   prior? = Chinese.is_prior_leap_month?(iso_days, Chinese.new_year_on_or_before(iso_days))
        #   IO.inspect iso_days,
        #     label: "Unexpected leap month for date #{inspect date} and is_prior? #{inspect prior?}"
        # end
      end
    end
  end
end
