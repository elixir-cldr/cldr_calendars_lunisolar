defmodule Cldr.Calendar.Japanese do
  @moduledoc """
  Implementation of the Japanese lunisolar calendar.

  In a ‘regular’ Japanese lunisolar calendar, one year
  is divided into 12 months, with one month corresponding
  to the time between two full moons.

  Since the cycle of the moon is not
  an even number of days, a month in the lunar calendar
  can vary between 29 and 30 days and a normal year can
  have 353, 354, or 355 days.

  We define the epoch to the first new moon in the first
  year of the [Taika era](https://en.wikipedia.org/wiki/Taika_(era))
  which is recorded as the first imperial era.

  """
  use Cldr.Calendar.Behaviour,
    # epoch: ~D[0645-02-05],
    epoch: ~D[0001-01-01],
    cldr_calendar_type: :japanese

  import Astro.Math, only: [
    angle: 3,
    mt: 1,
    deg: 1
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

      iex> Cldr.Calendar.Japanese.leap_year? Cldr.Calendar.Japanese.elapsed_years(78, 37)
      true

      iex> Cldr.Calendar.Japanese.leap_year? Cldr.Calendar.Japanese.elapsed_years(78, 38)
      false

      iex> Cldr.Calendar.Japanese.leap_year? Cldr.Calendar.Japanese.elapsed_years(78, 39)
      false

      iex> Cldr.Calendar.Japanese.leap_year? Cldr.Calendar.Japanese.elapsed_years(78, 40)
      true

      iex> Cldr.Calendar.Japanese.leap_year? Cldr.Calendar.Japanese.elapsed_years(78, 41)
      false

  """
  @spec leap_year?(Calendar.year()) :: boolean()
  @impl true

  def leap_year?(year) do
    Lunisolar.leap_year?(year, epoch(), &japanese_location/1)
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

      iex> Cldr.Calendar.Japanese.leap_year? 78, 37
      true

      iex> Cldr.Calendar.Japanese.leap_year? 78, 38
      false

      iex> Cldr.Calendar.Japanese.leap_year? 78, 39
      false

      iex> Cldr.Calendar.Japanese.leap_year? 78, 40
      true

      iex> Cldr.Calendar.Japanese.leap_year? 78, 41
      false

  """
  def leap_year?(cycle, year) do
    cycle
    |> Lunisolar.elapsed_years(year)
    |> leap_year?()
  end

  def leap_month?(cycle, year, month) do
    Lunisolar.leap_month?(cycle, year, month, epoch(), &japanese_location/1)
  end

  def cycle_and_year(iso_days) do
    Lunisolar.cycle_and_year(iso_days)
  end

  def elapsed_years({cycle, year}) do
    Lunisolar.elapsed_years(cycle, year)
  end

  def elapsed_years(cycle, year) do
    Lunisolar.elapsed_years(cycle, year)
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  def date_to_iso_days(year, month, day) do
    Lunisolar.date_to_iso_days(year, month, day, epoch(), &japanese_location/1)
  end

  def date_from_iso_days(iso_days) do
    Lunisolar.date_from_iso_days(iso_days, epoch(), &japanese_location/1)
  end

  def cyclic_year(year, month, day) do
    Lunisolar.cyclic_year(year, month, day)
  end

  def related_gregorian_year(year, month, day) do
    Lunisolar.related_gregorian_year(year, month, day, epoch(), &japanese_location/1)
  end

  def month_of_year(year, month, day) do
    Lunisolar.month_of_year(year, month, day, epoch(), &japanese_location/1)
  end

  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &japanese_location/1)
  end

  def new_moon_before(iso_days) do
    Lunisolar.new_moon_before(iso_days, &japanese_location/1)
  end

  # Since the Japanese calendar is a lunisolar
  # calendar, a refernce longitude is required
  # in order to calculate sunset and sunrise.
  #
  # Prior to 1888, the longitude of Tokyo was
  # used. Since 1889, the longitude of the
  # standard Japan timezone (GMT+8) is used.

  @tokyo_local_offset Astro.Time.hours_to_days(9 + 143 / 450)
  @japan_standard_offset Astro.Time.hours_to_days(9)

  @spec japanese_location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def japanese_location(iso_days) do
    {year, _month, _day} = Cldr.Calendar.Gregorian.date_from_iso_days(trunc(iso_days))

    if year < 1888 do
      {deg(35.7), angle(139, 46, 0), mt(24), @tokyo_local_offset}
    else
      {deg(35), deg(135), mt(0), @japan_standard_offset}
    end
  end

end
