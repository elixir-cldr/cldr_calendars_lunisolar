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

  The default epoch for the Chinese lunisolar calendar
  is `~D[-2636-02-15]` which traditional date of the first
  use of the sexagesimal cycle. It can be changed by setting
  the `:chinese_epoch` configuration key in `config.exs`:

      # Alternative epoch starting from the reign of Emperor
      # Huangdi
      config :ex_cldr_calendars,
        chinese_epoch: ~D[-2696-01-01]

  """

  use Cldr.Calendar.Behaviour,
    epoch:  Application.compile_env(:ex_cldr_calendars, :chinese_epoch, ~D[-2636-02-15]),
    cldr_calendar_type: :chinese,
    months_in_normal_year: 12,
    months_in_leap_year: 13

  import Astro.Math, only: [
    angle: 3,
    mt: 1
  ]

  alias Astro.Time
  alias Cldr.Calendar.Lunisolar

  @doc """
  Returns a `t:Date.t/0` in the `#{__MODULE__}` calendar
  formed by a calendar year, a *cardinal* lunar month number
  and a cardinal day number.

  The lunar month number is that used in traditional lunisolar
  calendar notation. It is either a number between 1 and 12
  (the number of months in an ordinary year) or a leap month
  specified by the 2-tuple `{month, :leap}`.

  This function is therefore most useful for creating tradition
  calendar dates for holidays and other events defined in
  the lunisolar calendar.

  ### Arguments

  * `year` is any year in the `#{inspect __MODULE__} calendar.

  * `lunar_month` is either a cardinal month number between 1 and 12 or
    for a leap month the 2-tuple in the format `{month, :leap}`.

  * `day` is any day number valid for `year` and `month`

  ### Returns

  * `{:ok, date}` or

  * `{:error, reason}`

  ### Examples

      # Lunar new year
      iex> Cldr.Calendar.Chinese.new(4660, 1, 1)
      {:ok, ~D[4660-01-01 Cldr.Calendar.Chinese]}

      # First day of leap month
      iex> Cldr.Calendar.Chinese.new(4660, {3, :leap}, 1)
      {:ok, ~D[4660-04-01 Cldr.Calendar.Chinese]}

  """
  @spec new(year :: Calendar.year, month :: Lunisolar.lunar_month(), day :: Calendar.day) ::
    {:ok, Date.t()} | {:error, atom()}

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

  @doc """
  Returns a boolean indicating if the given year is a leap
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

  ### Arguments

  * `date_or_year` is either an integer year number
    or a `t:Date.t/0` in the `#{inspect __MODULE__}`
    calendar.

  ### Returns

  * A booelan indicating if the given year is a leap
    year.

  ### Examples

      iex> Cldr.Calendar.Chinese.leap_year?(4660)
      true

      iex> Cldr.Calendar.Chinese.leap_year?(4661)
      false

  """
  @spec leap_year?(date_or_year :: Calendar.year() | Date.t()) :: boolean()
  @impl Calendar

  def leap_year?(%{year: year, calendar: __MODULE}) do
    leap_year?(year)
  end

  def leap_year?(year) do
    Lunisolar.leap_year?(year, epoch(), &location/1)
  end

  @doc """
  Returns a boolean indicating if the given year and month
  is a leap month.

  ### Arguements

  * `year` is any year in the `#{inspect __MODULE__}` calendar.

  * `month` is any ordinal month number in the `#{inspect __MODULE__}`
    calendar.

  ### Returns

  * A booelan indicating if the given year and month is a leap
    month.

  ### Examples

      iex> Cldr.Calendar.Chinese.leap_month?(4660, 1)
      false

      iex> Cldr.Calendar.Chinese.leap_month?(4660, 3)
      true

  """
  @spec leap_month?(year :: Calendar.year(), month :: Calendar.month()) :: boolean()
  def leap_month?(year, month) do
    Lunisolar.leap_month?(year, month, epoch(), &location/1)
  end

  @doc false
  # For testing only
  def leap_month?(cycle, cyclic_year, month) do
    cycle
    |> Lunisolar.elapsed_years(cyclic_year)
    |> leap_month?(month)
  end

  @doc """
  Returns a boolean indicating if the given year and month
  is a leap month.

  ### Arguements

  * `date` is any `t:Date.t/0` in the `#{inspect __MODULE__}` calendar.

  ### Returns

  * A booelan indicating if the given year and month is a leap
    month.

  ### Examples

      iex> Cldr.Calendar.Chinese.leap_month?(~D[4660-01-01 Cldr.Calendar.Chinese])
      false

      iex> Cldr.Calendar.Chinese.leap_month?(~D[4660-03-29 Cldr.Calendar.Chinese])
      true

  """
  @spec leap_month?(date :: Date.t()) :: boolean()
  def leap_month?(%Date{calendar: __MODULE__} = date) do
    leap_month?(date.year, date.month)
  end

  @doc """
  Returns the ordinal month number of the leap
  month for a year, or nil if there is no leap
  month.

  ### Arguments

  * `date_or_year` is either an integer year number
    or a `t:Date.t/0` in the `#{inspect __MODULE__}`
    calendar.

  ### Returns

  * either an ordinal month number or

  * `nil` indicating there is no leap month in the
    given year.

  ### Examples

      iex> Cldr.Calendar.Chinese.leap_month(4660)
      3

      iex> Cldr.Calendar.Chinese.leap_month(~D[4660-13-29 Cldr.Calendar.Chinese])
      3

      iex> Cldr.Calendar.Chinese.leap_month(4661)
      nil

  """
  @spec leap_month(date_or_year :: Date.t() | Calendar.year()) :: Calendar.month() | nil
  def leap_month(%Date{year: year, calendar: __MODULE__}) do
    leap_month(year)
  end

  def leap_month(year) do
    Lunisolar.leap_month(year, epoch(), &location/1)
  end

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

  @doc false
  def cycle_and_year(iso_days) do
    Lunisolar.cycle_and_year(iso_days)
  end

  @doc false
  def elapsed_years({cycle, cyclical_year}) do
    Lunisolar.elapsed_years(cycle, cyclical_year)
  end

  @doc false
  def elapsed_years(cycle, cyclical_year) do
    Lunisolar.elapsed_years(cycle, cyclical_year)
  end

  @doc false
  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  @doc false
  def date_to_iso_days(year, month, day) do
    Lunisolar.date_to_iso_days(year, month, day, epoch(), &location/1)
  end

  @doc false
  def date_from_iso_days(iso_days) do
    Lunisolar.date_from_iso_days(iso_days, epoch(), &location/1)
  end

  @doc false
  def cyclic_year(year, month, day) do
    Lunisolar.cyclic_year(year, month, day)
  end

  @doc false
  def month_of_year(year, month, day) do
    Lunisolar.month_of_year(year, month, day, epoch(), &location/1)
  end

  @doc false
  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &location/1)
  end

  @doc false
  def new_moon_before(iso_days) do
    Lunisolar.new_moon_before(iso_days, &location/1)
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
  @spec location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def location(iso_days) do
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
    Lunisolar.cyclical_date_from_iso_days(iso_days, epoch(), &location/1)
  end

  @doc false
  def alt_chinese_date_from_iso_days(iso_days) do
    Lunisolar.alt_cyclical_date_from_iso_days(iso_days, epoch(), &location/1)
  end

  @doc false
  def chinese_date_to_iso_days({cycle, year, month, day}) do
    chinese_date_to_iso_days(cycle, year, month, day)
  end

  def chinese_date_to_iso_days(cycle, year, month, day) do
    Lunisolar.cyclical_date_to_iso_days(cycle, year, month, day, epoch(), &location/1)
  end

  @doc false
  def alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day) do
    Lunisolar.alt_cyclical_date_to_iso_days(cycle, year, month, leap_month?, day, epoch(), &location/1)
  end

end
