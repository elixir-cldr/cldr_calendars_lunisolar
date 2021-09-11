defmodule Cldr.Calendar.Korean do
  @moduledoc """
  Implementation of the Korean lunisolar calendar.

  In a ‘regular’ Korean lunisolar calendar, one year
  is divided into 12 months, with one month corresponding
  to the time between two full moons.

  Since the cycle of the moon is not
  an even number of days, a month in the lunar calendar
  can vary between 29 and 30 days and a normal year can
  have 353, 354, or 355 days.

  """
  use Cldr.Calendar.Behaviour,
    epoch: ~D[-2332-02-15],
    cldr_calendar_type: :dangi

  import Astro.Math, only: [
    angle: 3,
    mt: 1,
    # amod: 2
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

      iex> Cldr.Calendar.Korean.leap_year? Cldr.Calendar.Korean.elapsed_years(78, 37)
      true

      iex> Cldr.Calendar.Korean.leap_year? Cldr.Calendar.Korean.elapsed_years(78, 38)
      false

      iex> Cldr.Calendar.Korean.leap_year? Cldr.Calendar.Korean.elapsed_years(78, 39)
      false

      iex> Cldr.Calendar.Korean.leap_year? Cldr.Calendar.Korean.elapsed_years(78, 40)
      true

      iex> Cldr.Calendar.Korean.leap_year? Cldr.Calendar.Korean.elapsed_years(78, 41)
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

      iex> Cldr.Calendar.Korean.leap_year? 78, 37
      true

      iex> Cldr.Calendar.Korean.leap_year? 78, 38
      false

      iex> Cldr.Calendar.Korean.leap_year? 78, 39
      false

      iex> Cldr.Calendar.Korean.leap_year? 78, 40
      true

      iex> Cldr.Calendar.Korean.leap_year? 78, 41
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

  # @years_in_cycle 60
  #
  # def cycle_and_year(elapsed_years) do
  #   cycle = floor((elapsed_years + 364) / @years_in_cycle)
  #   year = amod(elapsed_years + 364, @years_in_cycle)
  #
  #   {cycle, year}
  # end
  #
  # def elapsed_years(cycle, year) do
  #   (@years_in_cycle * cycle) + year - 364
  # end

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

  # Since the Korean (dangi) calendar is a lunisolar
  # calendar, a refernce longitude is required
  # in order to calculate sunset and sunrise.

  @spec korean_location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def korean_location(iso_days) do
    offset = korean_offset(iso_days)
    {angle(37, 34, 0), angle(126, 58, 0), mt(0), Astro.Time.hours_to_days(offset)}
  end

  @korea_1908 Cldr.Calendar.Gregorian.date_to_iso_days(1908, 4, 1)
  @korea_1912 Cldr.Calendar.Gregorian.date_to_iso_days(1912, 1, 1)
  @korea_1954 Cldr.Calendar.Gregorian.date_to_iso_days(1954, 3, 21)
  @korea_1961 Cldr.Calendar.Gregorian.date_to_iso_days(1961, 8, 10)

  def korean_offset(iso_days) do
    cond do
      iso_days < @korea_1908 -> 3809 / 450
      iso_days < @korea_1912 -> 8.5
      iso_days < @korea_1954 -> 9
      iso_days < @korea_1961 -> 8.5
      true -> 9
    end
  end

end
