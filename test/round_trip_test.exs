defmodule Cldr.Calendar.Chinese.RoundTrip.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 2000

  alias Cldr.Calendar.Chinese

  property "Chinese Date Round Trip" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      chinese_date = Chinese.chinese_date_from_iso_days(iso_days)
      assert Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
    end
  end

  # property "Date Round Trip" do
  #   check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
  #     date = Chinese.date_from_iso_days(iso_days)
  #     assert Chinese.date_to_iso_days(date) == iso_days
  #   end
  # end

  @tag timeout: :infinity
  @tag :full
  test "Round trip" do
    from = Cldr.Calendar.date_to_iso_days(~D[1800-01-01])
    to = Cldr.Calendar.date_to_iso_days(~D[2025-12-31])

    for iso_days <- from..to do
      chinese_date = Cldr.Calendar.Chinese.chinese_date_from_iso_days(iso_days)
      assert Cldr.Calendar.Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
      # date = Cldr.Calendar.Chinese.date_from_iso_days(iso_days)
      # if  Cldr.Calendar.Chinese.date_to_iso_days(date) != iso_days do
      #   IO.puts "Did not match: #{inspect iso_days}"
      # end
    end
  end

  # @tag timeout: :infinity
  # test "Leap years" do
  #   from = Cldr.Calendar.date_to_iso_days(~D[2020-01-01])
  #   to = Cldr.Calendar.date_to_iso_days(~D[2025-12-31])
  #
  #   for iso_days <- from..to do
  #     chinese_date = Cldr.Calendar.Chinese.chinese_date_from_iso_days(iso_days)
  #     {cycle, year, _month, _leap_month?, _day, leap_year?} = chinese_date
  #
  #     # if Cldr.Calendar.Chinese.leap_year?(cycle, year) != leap_year? do
  #     #   IO.puts "Didn't match for #{inspect iso_days}"
  #     # end
  #     IO.inspect iso_days
  #     assert Cldr.Calendar.Chinese.leap_year?(cycle, year) == leap_year?
  #   end
  # end

  @tag timeout: :infinity
  test "Cycle and Year" do
    from = 3000
    to = 5000

    for year <- from..to do
      cycle_and_year = Cldr.Calendar.Chinese.cycle_and_year(year)
      assert Cldr.Calendar.Chinese.elapsed_years(cycle_and_year) == year
    end
  end
end
