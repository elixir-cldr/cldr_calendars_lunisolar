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

  property "Date Round Trip" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      date = Chinese.date_from_iso_days(iso_days)
      assert Chinese.date_to_iso_days(date) == iso_days
    end
  end

  # @tag timeout: :infinity
  # test "Round trip" do
  #   from = Cldr.Calendar.date_to_iso_days(~D[1800-01-01])
  #   to = Cldr.Calendar.date_to_iso_days(~D[2050-12-31])
  #
  #   for iso_days <- from..to do
  #     chinese_date = Cldr.Calendar.Chinese.chinese_date_from_iso_days(iso_days)
  #     assert Cldr.Calendar.Chinese.chinese_date_to_iso_days(chinese_date) == iso_days
  #   end
  # end
end
