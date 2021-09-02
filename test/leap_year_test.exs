defmodule Cldr.Calendar.Chinese.LeapYear.Test do
  use ExUnit.Case
  use ExUnitProperties

  @max_runs 2000

  alias Cldr.Calendar.Chinese

  property "Chinese Leap Year" do
    check all(iso_days <- Chinese.DateGenerator.generate_iso_days(), max_runs: @max_runs) do
      iso_days
    end
  end
end
