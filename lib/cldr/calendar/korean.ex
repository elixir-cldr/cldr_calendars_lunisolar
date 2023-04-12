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

  * `year` is any year in the `#{inspect __MODULE__}` calendar.

  * `lunar_month` is either a cardinal month number between 1 and 12 or
    for a leap month the 2-tuple in the format `{month, :leap}`.

  * `day` is any day number valid for `year` and `month`

  ### Returns

  * `{:ok, date}` or

  * `{:error, reason}`

  ### Examples

      # Buddha's birthday is the 8th day of
      # lunar month 4. In a leap year that is the
      # fifth ordainal month.
      iex> Cldr.Calendar.Korean.new(4356, 4, 8)
      {:ok, ~D[4356-05-08 Cldr.Calendar.Korean]}

      # In an ordianry year lunar month four is the same
      # as the fourth ordinal month.
      iex(6)> Cldr.Calendar.Korean.new(4355, 4, 8)
      {:ok, ~D[4355-04-08 Cldr.Calendar.Korean]}

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

      iex> Cldr.Calendar.Korean.leap_year?(4356)
      true

      iex> Cldr.Calendar.Korean.leap_year?(4355)
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

      iex> Cldr.Calendar.Korean.leap_month?(4356, 1)
      false

      iex> Cldr.Calendar.Korean.leap_month?(4356, 3)
      true

  """
  @spec leap_month?(year :: Calendar.year(), month :: Calendar.month()) :: boolean()
  def leap_month?(year, month) do
    Lunisolar.leap_month?(year, month, epoch(), &location/1)
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

      iex> Cldr.Calendar.Korean.leap_month?(~D[4356-01-01 Cldr.Calendar.Korean])
      false

      iex> Cldr.Calendar.Korean.leap_month?(~D[4356-03-29 Cldr.Calendar.Korean])
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

      iex> Cldr.Calendar.Korean.leap_month(4356)
      3

      iex> Cldr.Calendar.Korean.leap_month(~D[4356-13-29 Cldr.Calendar.Korean])
      3

      iex> Cldr.Calendar.Korean.leap_month(4357)
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
  Returns the year in the lunisolar sexigesimal 60-year
  cycle.

  Traditionally years are numbered only within the cycle
  however in this implementation the year is an offset from
  the epoch date. It can be converted to the current year in
  the current cycle with this function.

  The cycle year is commonly shown on lunisolar calendars and
  it forms part of the traditional Chinese zodiac.

  ### Arguments

  * `date` which is any `t:Date.t/0` in the `#{inspect __MODULE__}`
    calendar, *or*

  *`year` and `month` representing the calendar year and month.

  ### Returns

  * the integer year within the sexigesimal cycle of 60 years.

  ### Examples

      iex> Cldr.Calendar.Korean.cyclic_year(~D[4356-04-01 Cldr.Calendar.Korean])
      36

      iex> Cldr.Calendar.Korean.cyclic_year(~D[4357-01-01 Cldr.Calendar.Korean])
      37

      iex> Cldr.Calendar.Korean.cyclic_year(~D[4321-01-01 Cldr.Calendar.Korean])
      1

      iex> Cldr.Calendar.Korean.cyclic_year(~D[4320-01-01 Cldr.Calendar.Korean])
      60

  """
  @spec cyclic_year(date :: Date.t()) :: Lunisolar.cycle()
  def cyclic_year(%Date{year: year, month: month, calendar: __MODULE__}) do
    cyclic_year(year, month)
  end

  def cyclic_year(year, month) do
    Lunisolar.cyclic_year(year, month, 1)
  end

  @doc """
  Returns the lunar month of the year for a given date or
  year and month.

  The lunar month number in the traditional lunisolar calendar is
  between 1 and 12 with a leap month added when there are 13 new moons
  between Winter solstices. This intercalary leap month is not
  representable in its traditional form in the `t:Date.t/0` struct.

  This function takes a date, or year and month, and returns either the
  month number between 1 and 12 or a 2-tuple representing the leap month.
  This 2-tuple looks like `{month_number, :leap}`.

  The value returned from this function can be passed to `#{inspect __MODULE__}.new/3` to
  define a date using traditional lunar months.

  ### Arguments

  * `date` which is any `t:Date.t/0` in the `#{inspect __MODULE__}`
    calendar, *or*

  *`year` and `month` representing the calendar year and month.

  ### Returns

  * the lunar month as either an integer between 1 and 12 or a
  tuple of the form `{lunar_month, :leap}`.

  ### Examples

      iex> Cldr.Calendar.Korean.lunar_month_of_year(~D[4356-02-01 Cldr.Calendar.Korean])
      2

      iex> Cldr.Calendar.Korean.lunar_month_of_year(~D[4356-03-01 Cldr.Calendar.Korean])
      {2, :leap}

      iex> Cldr.Calendar.Korean.lunar_month_of_year(~D[4356-04-01 Cldr.Calendar.Korean])
      3

  """
  @spec lunar_month_of_year(date :: Date.t()) :: Lunisolar.lunar_month()
  def lunar_month_of_year(%Date{year: year, month: month, calendar: __MODULE__}) do
    lunar_month_of_year(year, month)
  end

  @spec lunar_month_of_year(year :: Calendar.year(), month :: Calendar.month()) :: Lunisolar.lunar_month()
  def lunar_month_of_year(year, month) do
    Lunisolar.lunar_month_of_year(year, month, 1, epoch(), &location/1)
  end

  # Compatibility with Cldr.Calendar.localize
  @doc false
  def month_of_year(year, month, _day) do
    lunar_month_of_year(year, month)
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
  def new_moon_on_or_after(iso_days) do
    Lunisolar.new_moon_on_or_after(iso_days, &location/1)
  end

  # Since the Korean (dangi) calendar is a lunisolar
  # calendar, a reference longitude is required
  # in order to calculate sunset and sunrise.

  @doc false
  @spec location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def location(iso_days) do
    offset = korean_offset(iso_days)
    {angle(37, 34, 0), angle(126, 58, 0), mt(0), Astro.Time.hours_to_days(offset)}
  end

  @korea_1908 Cldr.Calendar.Gregorian.date_to_iso_days(1908, 4, 1)
  @korea_1912 Cldr.Calendar.Gregorian.date_to_iso_days(1912, 1, 1)
  @korea_1954 Cldr.Calendar.Gregorian.date_to_iso_days(1954, 3, 21)
  @korea_1961 Cldr.Calendar.Gregorian.date_to_iso_days(1961, 8, 10)

  @doc false
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
