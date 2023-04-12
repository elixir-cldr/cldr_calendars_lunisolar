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

  The default epoch for the Korean lunisolar calendar
  is `~D[-2332-02-15]` which is the traditional year of
  the founding of the first Korean nation. The epoch can
  be changed by setting the `:korean_epoch` configuration
  key in `config.exs`:

      config :ex_cldr_calendars,
        korean_epoch: ~D[-2332-02-15]

  """
  use Cldr.Calendar.Behaviour,
    epoch: Application.compile_env(:ex_cldr_calendars, :korean_epoch, ~D[-2332-02-15]),
    cldr_calendar_type: :dangi,
    months_in_normal_year: 12,
    months_in_leap_year: 13

  import Astro.Math, only: [
    angle: 3,
    mt: 1
  ]

  alias Astro.Time
  alias Cldr.Calendar.Lunisolar

  def new(year, month, day) do
    case Lunisolar.new(year, month, day, epoch(), &location/1) do
      {:error, reason} ->
        {:error, reason}

      iso_days ->
        {year, month, day} = date_from_iso_days(iso_days)
        Date.new(year, month, day, __MODULE__)
    end
  end

  def new!(year, month, day) do
    case new(year, month, day) do
      {:ok, date} -> date
      {:error, reason} -> raise ArgumentError, "cannot build date, reason: #{inspect(reason)}"
    end
  end

  def leap_year?(%Date{calendar: __MODULE__} = date) do
    leap_year?(date.year)
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
  @impl Calendar

  def leap_year?(year) do
    Lunisolar.leap_year?(year, epoch(), &location/1)
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

  def leap_month?(%Date{calendar: __MODULE__} = date) do
    leap_month?(date.year, date.month)
  end

  def leap_month?(year, month) do
    Lunisolar.leap_month?(year, month, epoch(), &location/1)
  end

  @doc false
  def leap_month?(cycle, cyclic_year, month) do
    Lunisolar.leap_month?(cycle, cyclic_year, month, epoch(), &location/1)
  end

  def leap_month(year) do
    Lunisolar.leap_month(year, epoch(), &location/1)
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  def date_to_iso_days(year, month, day) do
    Lunisolar.date_to_iso_days(year, month, day, epoch(), &location/1)
  end

  def date_from_iso_days(iso_days) do
    Lunisolar.date_from_iso_days(iso_days, epoch(), &location/1)
  end

  def cyclic_year(year, month, day) do
    Lunisolar.cyclic_year(year, month, day)
  end

  def month_of_year(year, month, day) do
    Lunisolar.month_of_year(year, month, day, epoch(), &location/1)
  end

  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &location/1)
  end

  # Since the Korean (dangi) calendar is a lunisolar
  # calendar, a reference longitude is required
  # in order to calculate sunset and sunrise.

  @spec location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def location(iso_days) do
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
