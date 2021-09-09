defmodule Cldr.Calendar.Korean do
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
    epoch: ~D[-2332-01-01],
    cldr_calendar_type: :dangi

  # Alternative epoch starting from the reign of Emporer Huangdi: ~D[-2696-01-01)

  import Astro.Math, only: [
    angle: 3,
    mt: 1,
    deg: 1,
    amod: 2
  ]

  alias Astro.Time
  alias Cldr.Calendar.Lunisolar

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
    Lunisolar.leap_year?(year, epoch(), &korean_location/1)
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
  def leap_year?(cycle, year) do
    cycle
    |> Lunisolar.elapsed_years(year)
    |> leap_year?()
  end

  def leap_month?(cycle, year, month) do
    Lunisolar.leap_month?(cycle, year, month, epoch(), &korean_location/1)
  end

  @years_in_cycle 60

  def cycle_and_year(elapsed_years) do
    cycle = floor((elapsed_years + 364) / @years_in_cycle)
    year = amod(elapsed_years + 364, @years_in_cycle)

    {cycle, year}
  end

  def elapsed_years(cycle, year) do
    (@years_in_cycle * cycle) + year - 364
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  def date_to_iso_days(year, month, day) do
    Lunisolar.date_to_iso_days(year, month, day, epoch(), &korean_location/1)
  end

  def date_from_iso_days(iso_days) do
    Lunisolar.date_from_iso_days(iso_days, epoch(), &korean_location/1)
  end

  def cyclic_year(year, month, day) do
    Lunisolar.cyclic_year(year, month, day)
  end

  def related_gregorian_year(year, month, day) do
    Lunisolar.related_gregorian_year(year, month, day, epoch(), &korean_location/1)
  end

  def month_of_year(year, month, day) do
    Lunisolar.month_of_year(year, month, day, epoch(), &korean_location/1)
  end

  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &korean_location/1)
  end

  # Since the Chinese calendar is a lunisolar
  # calendar, a refernce longitude is required
  # in order to calculate sunset and sunrise.
  #
  # Prior to 1929, the longitude of Beijing was
  # used. Since 1929, the longitude of the
  # standard China timezone (GMT+8) is used.

  @seoul_local_offset Astro.Time.hours_to_days(9 + 143 / 450)
  @korea_standard_offset Astro.Time.hours_to_days(9)

  @spec korean_location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def korean_location(iso_days) do
    if (tee < fixed_from_gregorian(gregorian_date(1908, APRIL, 1))):
        #local mean time for longitude 126 deg 58 min
        z = 3809/450
    elif (tee < fixed_from_gregorian(gregorian_date(1912, JANUARY, 1))):
        z = 8.5
    elif (tee < fixed_from_gregorian(gregorian_date(1954, MARCH, 21))):
        z = 9
    elif (tee < fixed_from_gregorian(gregorian_date(1961, AUGUST, 10))):
        z = 8.5
    else:
        z = 9
    return location(angle(37, 34, 0), angle(126, 58, 0),
                    mt(0), days_from_hours(z))
  end

  # The following are for testing purposes only

  @doc false
  def chinese_date_from_iso_days(iso_days) do
    Lunisolar.chinese_date_from_iso_days(iso_days, epoch(), &korean_location/1)
  end

  @doc false
  def alt_chinese_date_from_iso_days(iso_days) do
    Lunisolar.alt_chinese_date_from_iso_days(iso_days, epoch(), &korean_location/1)
  end

  @doc false
  def chinese_date_to_iso_days({cycle, year, month, day}) do
    chinese_date_to_iso_days(cycle, year, month, day)
  end

  def chinese_date_to_iso_days(cycle, year, month, day) do
    Lunisolar.chinese_date_to_iso_days(cycle, year, month, day, epoch(), &korean_location/1)
  end

  @doc false
  def alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day) do
    Lunisolar.alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day, epoch(), &korean_location/1)
  end

end