defmodule Cldr.Calendar.Chinese.RoundTrip.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 2000

  alias Cldr.Calendar.Chinese

  # property "Chinese Date Round Trip" do
  #   check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
  #     chinese_date = Chinese.chinese_date_from_iso_days(iso_days)
  #     assert Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
  #   end
  # end

  property "Chinese Date Round Trip" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      chinese_date = Chinese.chinese_date_from_iso_days(iso_days)
      assert Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
    end
  end

  property "Chinese Date Cycle, Year and day are the same for alt and non-alt" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      {cycle, year, _, _, day} = Chinese.alt_chinese_date_from_iso_days(iso_days)
      {cycle_a, year_a, _, day_a} = Chinese.chinese_date_from_iso_days(iso_days)

      assert cycle == cycle_a and year == year_a and day == day_a
    end
  end

  property "Alt month is +1 of cardinal month when its a leap month" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      {_cycle, _year, month, leap_month?, _day} = Chinese.alt_chinese_date_from_iso_days(iso_days)
      {_cycle_a, _year_a, month_a, _day_a} = Chinese.chinese_date_from_iso_days(iso_days)

      if leap_month? do
        assert month_a == month + 1
      end
    end
  end

  property "Date Round Trip" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      date = Chinese.date_from_iso_days(iso_days)
      assert Chinese.date_to_iso_days(date) == iso_days
    end
  end

  property "Calendar Conversion Round Trip" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      chinese_date = Cldr.Calendar.date_from_iso_days(iso_days, Cldr.Calendar.Chinese)
      gregorian_date = Date.convert!(chinese_date, Cldr.Calendar.Gregorian)
      gregorian_iso_days = Cldr.Calendar.date_to_iso_days(gregorian_date)
      chinese_iso_days = Cldr.Calendar.date_to_iso_days(chinese_date)

      assert chinese_iso_days == gregorian_iso_days
    end
  end

  test "Cycle and Year" do
    from = 3000
    to = 5000

    for year <- from..to do
      cycle_and_year = Cldr.Calendar.Chinese.cycle_and_year(year)
      assert Cldr.Calendar.Chinese.elapsed_years(cycle_and_year) == year
    end
  end

  @tag timeout: :infinity
  @tag :full

  test "Round trip" do
    from = Cldr.Calendar.date_to_iso_days(~D[1800-01-01])
    to = Cldr.Calendar.date_to_iso_days(~D[2025-12-31])

    for iso_days <- from..to do
      chinese_date = Cldr.Calendar.Chinese.chinese_date_from_iso_days(iso_days)
      assert Cldr.Calendar.Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
    end
  end

  @tag timeout: :infinity
  @tag :full

  test "Calendar Conversion" do
    dates = Date.range(~D[1800-01-01], ~D[2025-12-31])

    for date <- dates do
      iso_days = Cldr.Calendar.date_to_iso_days(date)
      chinese_date = Cldr.Calendar.date_from_iso_days(iso_days, Cldr.Calendar.Chinese)
      chinese_iso_days = Cldr.Calendar.date_to_iso_days(chinese_date)

      assert iso_days == chinese_iso_days
    end
  end
end
