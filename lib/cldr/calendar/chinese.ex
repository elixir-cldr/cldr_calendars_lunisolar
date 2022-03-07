defmodule Cldr.Calendar.Chinese do
  @moduledoc """
  Implementation of the Chinese lunisolar calendar.

  In a ‘regular’ Chinese lunisolar calendar, one year
  is divided into 12 months, with one month corresponding
  to the time between two full moons.

  Since the cycle of the moon is not
  an even number of days, a month in the lunar calendar
  can vary between 29 and 30 days and a normal year can
  have 353, 354, or 355 days.


  """
  use Cldr.Calendar.Behaviour,
    epoch: ~D[-2636-02-15],
    cldr_calendar_type: :chinese

  # Alternative epoch starting from the reign of Emperor Huangdi: ~D[-2696-01-01)

  import Astro.Math, only: [
    angle: 3,
    mt: 1
  ]

  alias Astro.Time
  alias Cldr.Calendar.Lunisolar

  @doc """
  Returns the gregorian date of the
  Chinese New Year for a given gregorian year.

  ## Example

      iex> Cldr.Calendar.Chinese.new_year_for_gregorian_year(2021)
      ~D[2021-02-12]

      iex> Cldr.Calendar.Chinese.new_year_for_gregorian_year(2022)
      ~D[2022-02-01]

      iex> Cldr.Calendar.Chinese.new_year_for_gregorian_year(2023)
      ~D[2023-01-22]

  """
  @spec new_year_for_gregorian_year(Calendar.year()) :: Date.t()
  def new_year_for_gregorian_year(gregorian_year) do
    gregorian_date_for_chinese(gregorian_year, 1, 1)
  end

  @doc """
  Returns the gregorian date of the
  dragon festival (5th day of 5th lunar month)
  for a given gregorian year.

  ## Example

      iex> Cldr.Calendar.Chinese.dragon_festival_for_gregorian_year(2021)
      ~D[2021-06-14]

      iex> Cldr.Calendar.Chinese.dragon_festival_for_gregorian_year(2022)
      ~D[2022-06-03]

      iex> Cldr.Calendar.Chinese.dragon_festival_for_gregorian_year(2023)
      ~D[2023-06-22]

  """
  @dragon_month 5
  @dragon_day 5

  @spec dragon_festival_for_gregorian_year(Calendar.year()) :: Date.t()
  def dragon_festival_for_gregorian_year(gregorian_year) when is_integer(gregorian_year) do
    gregorian_date_for_chinese(gregorian_year, @dragon_month, @dragon_day)
  end

  defp gregorian_date_for_chinese(gregorian_year, chinese_month, chinese_day, leap_month? \\ false) do
    mid_year = Calendar.ISO.date_to_iso_days(gregorian_year, 7, 1)
    {cycle, chinese_year, _month, _day} = chinese_date_from_iso_days(mid_year)
    iso_days = alt_chinese_date_to_iso_days(cycle, chinese_year, chinese_month, leap_month?, chinese_day)
    {year, month, day} = Calendar.ISO.date_from_iso_days(iso_days)
    Date.new!(year, month, day)
  end

  @doc """
  Returns if the given year is a leap
  year.

  Leap years have 13 months. To determine if a year
  is a leap year, calculate the number of new moons
  between the 11th month in one year (i.e., the month
  containing the Winter Solstice) and the 11th month
  in the following year.

  If there are 13 new moons from the start of the 11th
  month in the first year to the start of the 11th
  month in the second year, a leap month must be inserted.

  In leap years, at least one month does not contain a
  Principal Term. The first such month is the leap month.

  The additional complexity is that a leap year is
  calculated for the solar year, but the calendar
  is managed in lunar years and months. Therefore when
  a leap year is detected, the leap month could be in
  the current lunar year or the next lunar year.

  ## Examples

      iex> Cldr.Calendar.Chinese.leap_year? Cldr.Calendar.Chinese.elapsed_years(78, 37)
      true

      iex> Cldr.Calendar.Chinese.leap_year? Cldr.Calendar.Chinese.elapsed_years(78, 38)
      false

      iex> Cldr.Calendar.Chinese.leap_year? Cldr.Calendar.Chinese.elapsed_years(78, 39)
      false

      iex> Cldr.Calendar.Chinese.leap_year? Cldr.Calendar.Chinese.elapsed_years(78, 40)
      true

      iex> Cldr.Calendar.Chinese.leap_year? Cldr.Calendar.Chinese.elapsed_years(78, 41)
      false

  """
  @spec leap_year?(Calendar.year()) :: boolean()
  @impl true

  def leap_year?(year) do
    Lunisolar.leap_year?(year, epoch(), &chinese_location/1)
  end

  @doc """
  Returns if the given cycle and year is a leap
  year.

  Leap years have 13 months. To determine if a year
  is a leap year, calculate the number of new moons
  between the 11th month in one year (i.e., the month
  containing the Winter Solstice) and the 11th month
  in the following year.

  If there are 13 new moons from the start of the 11th
  month in the first year to the start of the 11th
  month in the second year, a leap month must be inserted.

  In leap years, at least one month does not contain a
  Principal Term. The first such month is the leap month.

  The additional complexity is that a leap year is
  calculated for the solar year, but the calendar
  is managed in lunar years and months. Therefore when
  a leap year is detected, the leap month could be in
  the current lunar year or the next lunar year.

  ## Examples

      iex> Cldr.Calendar.Chinese.leap_year? 78, 37
      true

      iex> Cldr.Calendar.Chinese.leap_year? 78, 38
      false

      iex> Cldr.Calendar.Chinese.leap_year? 78, 39
      false

      iex> Cldr.Calendar.Chinese.leap_year? 78, 40
      true

      iex> Cldr.Calendar.Chinese.leap_year? 78, 41
      false

  """
  @spec leap_year?(Lunisolar.cycle(), Calendar.year()) :: boolean()

  def leap_year?(cycle, year) do
    cycle
    |> Lunisolar.elapsed_years(year)
    |> leap_year?()
  end

  @doc """
  Returns if the given cycle, year and
  months is a leap month.

  """
  @spec leap_month?(Lunisolar.cycle(), Calendar.year(), Calendar.month()) :: boolean()
  def leap_month?(cycle, year, month) do
    Lunisolar.leap_month?(cycle, year, month, epoch(), &chinese_location/1)
  end

  @doc false
  def cycle_and_year(iso_days) do
    Lunisolar.cycle_and_year(iso_days)
  end

  @doc false
  def elapsed_years({cycle, year}) do
    Lunisolar.elapsed_years(cycle, year)
  end

  @doc false
  def elapsed_years(cycle, year) do
    Lunisolar.elapsed_years(cycle, year)
  end

  @doc false
  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  @doc false
  def date_to_iso_days(year, month, day) do
    Lunisolar.date_to_iso_days(year, month, day, epoch(), &chinese_location/1)
  end

  @doc false
  def date_from_iso_days(iso_days) do
    Lunisolar.date_from_iso_days(iso_days, epoch(), &chinese_location/1)
  end

  @doc false
  def cyclic_year(year, month, day) do
    Lunisolar.cyclic_year(year, month, day)
  end

  @doc false
  def related_gregorian_year(year, month, day) do
    Lunisolar.related_gregorian_year(year, month, day, epoch(), &chinese_location/1)
  end

  @doc false
  def month_of_year(year, month, day) do
    Lunisolar.month_of_year(year, month, day, epoch(), &chinese_location/1)
  end

  @doc false
  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &chinese_location/1)
  end

  @doc false
  def new_moon_before(iso_days) do
    Lunisolar.new_moon_before(iso_days, &chinese_location/1)
  end

  # Since the Chinese calendar is a lunisolar
  # calendar, a reference longitude is required
  # in order to calculate sunset and sunrise.
  #
  # Prior to 1929, the longitude of Beijing was
  # used. Since 1929, the longitude of the
  # standard China timezone (GMT+8) is used.

  @beijing_local_offset Astro.Time.hours_to_days(1397 / 180)
  @china_standard_offset Astro.Time.hours_to_days(8)

  @doc false
  @spec chinese_location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def chinese_location(iso_days) do
    {year, _month, _day} = Cldr.Calendar.Gregorian.date_from_iso_days(trunc(iso_days))

    if year < 1929 do
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), @beijing_local_offset}
    else
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), @china_standard_offset}
    end
  end

  # The following are for testing purposes only

  @doc false
  def chinese_date_from_iso_days(iso_days) do
    Lunisolar.cyclical_date_from_iso_days(iso_days, epoch(), &chinese_location/1)
  end

  @doc false
  def alt_chinese_date_from_iso_days(iso_days) do
    Lunisolar.alt_cyclical_date_from_iso_days(iso_days, epoch(), &chinese_location/1)
  end

  @doc false
  def chinese_date_to_iso_days({cycle, year, month, day}) do
    chinese_date_to_iso_days(cycle, year, month, day)
  end

  def chinese_date_to_iso_days(cycle, year, month, day) do
    Lunisolar.cyclical_date_to_iso_days(cycle, year, month, day, epoch(), &chinese_location/1)
  end

  @doc false
  def alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day) do
    Lunisolar.alt_cyclical_date_to_iso_days(cycle, year, month, leap_month?, day, epoch(), &chinese_location/1)
  end

end
