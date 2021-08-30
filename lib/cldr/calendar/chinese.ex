defmodule Cldr.Calendar.Chinese do
  @moduledoc """
  Implementation of the Chinese lunisolar calendar.

  """
  import Astro.Math, only: [mod: 2, angle: 3, mt: 1, amod: 2, deg: 1, next: 2]
  import Astro.Time, only: [hours_to_days: 1]

  import Cldr.Macros

  alias Astro.{Solar, Lunar, Time}

  @behaviour Calendar
  @behaviour Cldr.Calendar

  @type year :: -9999..-1 | 1..9999
  @type month :: 1..12
  @type day :: 1..31

  @days_in_week 7

  # Seasons in degrees
  @winter 270

  # Number of years in a cycle
  @years_in_cycle 60

  @doc """
  Defines the CLDR calendar type for this calendar.

  This type is used in support of `Cldr.Calendar.
  localize/3`.

  """
  @impl true
  def cldr_calendar_type do
    :chinese
  end

  @doc """
  Identifies that this calendar is month based.
  """
  @impl true
  def calendar_base do
    :month
  end

  @epoch Cldr.Calendar.Gregorian.date_to_iso_days(-2636, 2, 15)
  def epoch do
    @epoch
  end

  def chinese_location(iso_days) do
    {year, _month, _day} = Cldr.Calendar.Gregorian.date_from_iso_days(trunc(iso_days))

    if year < 1929 do
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), hours_to_days(1397 / 180)}
    else
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), hours_to_days(8)}
    end
  end

  def location(iso_days) do
    {latitude, longitude, altitude, offset} = chinese_location(iso_days)
    properties = %{offset: offset}
    %Geo.PointZ{coordinates: {longitude, latitude, altitude}, properties: properties}
  end

  @doc """
  Determines if the date given is valid according to
  this calendar.

  """
  @impl true
  @months_with_30_days 1..12

  def valid_date?(_year, month, day) when month in @months_with_30_days and day in 1..30 do
    true
  end

  def valid_date?(_year, _month, _day) do
    false
  end

  @doc """
  Calculates the year and era from the given `year`.
  The ISO calendar has two eras: the current era which
  starts in year 1 and is defined as era "1". And a
  second era for those years less than 1 defined as
  era "0".

  """
  @spec year_of_era(year) :: {year, era :: 0..1}
  @impl true
  def year_of_era(year) when year > 0 do
    {year, 1}
  end

  def year_of_era(year) when year < 0 do
    {abs(year), 0}
  end

  @doc """
  Calculates the quarter of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 4.

  """
  @spec quarter_of_year(year, month, day) :: 1..4
  @impl true
  def quarter_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the month of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 12.

  """
  @spec month_of_year(year, month, day) :: month
  @impl true
  def month_of_year(_year, month, _day) do
    month
  end

  @doc """
  Calculates the week of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 53.

  """
  @spec week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true
  def week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the ISO week of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 53.

  """
  @spec iso_week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true
  def iso_week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the week of the year from the given `year`, `month`, and `day`.
  It is an integer from 1 to 53.

  """
  @spec week_of_month(year, month, day) :: {pos_integer(), pos_integer()} | {:error, :not_defined}
  @impl true
  def week_of_month(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the day and era from the given `year`, `month`, and `day`.

  """
  @spec day_of_era(year, month, day) :: {day :: pos_integer(), era :: 0..1}
  @impl true
  def day_of_era(year, month, day) do
    {_, era} = year_of_era(year)
    days = date_to_iso_days(year, month, day)
    {days + epoch(), era}
  end

  @doc """
  Calculates the day of the year from the given `year`, `month`, and `day`.

  """
  @spec day_of_year(year, month, day) :: 1..366
  @impl true
  def day_of_year(year, month, day) do
    first_day = date_to_iso_days(year, 1, 1)
    this_day = date_to_iso_days(year, month, day)
    this_day - first_day + 1
  end

  @epoch_day_of_week 6

  if Code.ensure_loaded?(Date) && function_exported?(Date, :day_of_week, 2) do
    @last_day_of_week 5

    @spec day_of_week(year, month, day, :default | atom()) ::
            {Calendar.day_of_week(), first_day_of_week :: non_neg_integer(),
             last_day_of_week :: non_neg_integer()}

    @impl true
    def day_of_week(year, month, day, :default) do
      days = date_to_iso_days(year, month, day)
      days_after_saturday = rem(days, 7)
      day = Cldr.Math.amod(days_after_saturday + @epoch_day_of_week, @days_in_week)

      {day, @epoch_day_of_week, @last_day_of_week}
    end
  else
    @spec day_of_week(year, month, day) :: 1..7

    @impl true
    def day_of_week(year, month, day) do
      days = date_to_iso_days(year, month, day)
      days_after_saturday = rem(days, 7)
      Cldr.Math.amod(days_after_saturday + @epoch_day_of_week, @days_in_week)
    end
  end

  @doc """
  Returns the number of periods in a given `year`. A period
  corresponds to a month in month-based calendars and
  a week in week-based calendars.

  """
  @impl true
  def periods_in_year(year) do
    months_in_year(year)
  end

  @doc """
  Returns the number of months in a given `year`.

  """
  @impl true
  def months_in_year(_year) do
  end

  @impl true
  def weeks_in_year(_year) do
    {:error, :not_defined}
  end

  @doc """
  Returns the number days in a given year.

  The year is the number of years since the
  Chinese epoch.

  """
  @impl true
  def days_in_year(year) do
    this_year = date_to_iso_days(year, 1, 1)
    next_year = date_to_iso_days(year + 1, 1, 1)
    next_year - this_year + 1
  end

  @doc """
  Returns how many days there are in the given year
  and month.

  Since months are determined by the number of
  days from one new moon to the next, there is
  no fixed number of days for a given month
  number.

  """
  @spec days_in_month(year, month) :: 29..30
  @impl true

  def days_in_month(_year, _month) do
    # Return the number of days in the
    # ordinal month
  end

  @doc """
  Returns the number days in a a week.

  """
  def days_in_week do
    @days_in_week
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given year.

  """
  @impl true
  def year(year) do
    last_month = months_in_year(year)
    days_in_last_month = days_in_month(year, last_month)

    with {:ok, start_date} <- Date.new(year, 1, 1, __MODULE__),
         {:ok, end_date} <- Date.new(year, last_month, days_in_last_month, __MODULE__) do
      Date.range(start_date, end_date)
    end
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given quarter of a year.

  """
  @impl true
  def quarter(_year, _quarter) do
    {:error, :not_defined}
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given month of a year.

  """
  @impl true
  def month(year, month) do
    starting_day = 1
    ending_day = days_in_month(year, month)

    with {:ok, start_date} <- Date.new(year, month, starting_day, __MODULE__),
         {:ok, end_date} <- Date.new(year, month, ending_day, __MODULE__) do
      Date.range(start_date, end_date)
    end
  end

  @doc """
  Returns a `Date.Range.t` representing
  a given week of a year.

  """
  @impl true
  def week(_year, _week) do
    {:error, :not_defined}
  end

  @doc """
  Adds an `increment` number of `date_part`s
  to a `year-month-day`.

  `date_part` can be `:months` only.

  """
  @impl true
  def plus(year, month, day, date_part, increment, options \\ [])

  def plus(year, month, day, :months, months, options) do
    months_in_year = months_in_year(year)
    {year_increment, new_month} = Cldr.Math.div_amod(month + months, months_in_year)
    new_year = year + year_increment

    new_day =
      if Keyword.get(options, :coerce, false) do
        max_new_day = days_in_month(new_year, new_month)
        min(day, max_new_day)
      else
        day
      end

    {new_year, new_month, new_day}
  end

  @doc """
  Returns if the given year is a leap year.

  Since this calendar is observational we
  calculate the start of successive years
  and then calcualate the difference in
  days to determine if its a leap year.

  Note that `year` is not the chinese year-in-cycle,
  this is the year since epoch.

  ## Examples

      iex> Cldr.Calendar.Chinese.leap_year? 4717
      true

      iex> Cldr.Calendar.Chinese.leap_year? 4718
      false

      iex> Cldr.Calendar.Chinese.leap_year? 4719
      false

      iex> Cldr.Calendar.Chinese.leap_year? 4720
      true

      iex> Cldr.Calendar.Chinese.leap_year? 4721
      false

  """
  @spec leap_year?(year) :: boolean()
  @impl true

  def leap_year?(year) do
    approx_years_since_epoch = (year - 1) - @years_in_cycle + 1 / 2
    mid_year = trunc(@epoch + approx_years_since_epoch * Time.mean_tropical_year())

    s1 = winter_solstice_on_or_before(mid_year)
    s2 = winter_solstice_on_or_before(s1 + 370)

    next_m11 = new_moon_before(1 + s2)
    m12 = new_moon_on_or_after(1 + s1)

    round((next_m11 - m12) / Time.mean_synodic_month()) == 12
  end

  @doc """
  Returns if the given cycle and year is a leap
  year.

  Note that `year` is the chinese year-in-cycle,
  not a gregorian year or year since epoch.

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
    epoch_year = cycle * @years_in_cycle + year
    leap_year?(epoch_year)
  end

  @doc """
  Approximately every three years (7 times in 19 years),
  a leap month is added to the Chinese calendar.

  To determine when, find the number of new moons between
  the 11th month in one year and the 11th month in the
  following year.

  A leap month is inserted if there are 13 New Moons
  from the start of the 11th month in the first year
  to the start of the 11th month in the next year.

  The Chinese calendar uses a solar term system
  that has 12 principal terms to indicate when the Sun's
  longitude is a multiple of 30 degrees.

  Unlike all other months, the leap month does not
  contain a principal term (Zhongqi).

  """
  def leap_month?(_year, _month) do

  end

  defp leap_month?({_cycle, _year, _month, leap_month?, _day, _leap_year?}) do
    leap_month?
  end

  defp month({_cycle, _year, month, _leap_month?, _day, _leap_year?}) do
    month
  end

  @doc """
  Returns the number of days since the calendar
  epoch for a given `year-month-day`

  Note that a chinese year is a year within a
  60 year cycle, not a year since the epoch.

  However to support the `Calendar` protocol
  we add `cycle * 60` to `year` so that date
  conversion can occur.  For all formatting
  purposes, the Chinese year is used and the
  cycle can also be formatted.

  """
  def date_to_iso_days(year, month, day) do
    {cycle, year} = Cldr.Math.div_mod(year, @years_in_cycle)
    {month, leap_month?} = decode_month(month)
    chinese_date_to_iso_days(cycle, year, month, leap_month?, day, nil)
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  defp decode_month(month) when month > 100 do
    {month - 100, true}
  end

  defp decode_month(month) do
    {month, false}
  end

  def chinese_date_to_iso_days(cycle, year, month, leap_month?, day, _leap_year?) do
    approx_years_since_epoch = (((cycle - 1) * 60) + (year - 1) + 1/2) * Time.mean_tropical_year()
    mid_year = floor(@epoch + approx_years_since_epoch)
    new_year = new_year_on_or_before(mid_year)

    p = new_moon_on_or_after(new_year + (month - 1) * 29)
    d = chinese_date_from_iso_days(p)

    prior_new_moon =
      if month == month(d) && leap_month? == leap_month?(d) do
        p
      else
        new_moon_on_or_after(1 + p)
      end

    prior_new_moon + day - 1
  end

  def chinese_date_to_iso_days({cycle, year, month, leap_month?, day, leap_year?}) do
    chinese_date_to_iso_days(cycle, year, month, leap_month?, day, leap_year?)
  end

  @doc """
  Returns a `{year, month, day}` calculated from
  the number of `iso_days`.

  """
  def date_from_iso_days(iso_days) do
    {cycle, year, month, leap_month?, day, _leap_year?} = chinese_date_from_iso_days(iso_days)
    {cycle * @years_in_cycle + year, encode_leap_month(month, leap_month?), day}
  end

  def chinese_date_from_iso_days(iso_days) do
    s1 = winter_solstice_on_or_before(iso_days)
    s2 = winter_solstice_on_or_before(s1 + 370)

    next_m11 = new_moon_before(1 + s2)
    m12 = new_moon_on_or_after(1 + s1)

    leap_year? = round((next_m11 - m12) / Time.mean_synodic_month()) == 12

    m = new_moon_before(1 + iso_days)

    d = if leap_year? && is_prior_leap_month?(m12, m), do: 1, else: 0
    month = amod(round((m - m12) / Time.mean_synodic_month()) - d, 12) |> trunc

    leap_month? =
      leap_year? && is_no_major_solar_term?(m) &&
        !is_prior_leap_month?(m12, new_moon_before(m))

    elapsed_years = floor(1.5 - month / 12 + ((iso_days - @epoch) / Time.mean_tropical_year()))

    cycle = 1 + floor((elapsed_years - 1 )/ @years_in_cycle)
    year = amod(elapsed_years, @years_in_cycle)
    day = 1 + (iso_days - m)

    {cycle, year, month, leap_month?, day, leap_year?}
  end

  defp encode_leap_month(month, true) do
    month + 100
  end

  defp encode_leap_month(month, false) do
    month
  end

  @doc """
  Return moment (Beijing time) of the first date on or after
  iso_days, date, (Beijing time) when the solar longitude
  will be 'lam' degrees.
  """
  def solar_longitude_on_or_after(lambda, iso_days) do
    d = Time.universal_from_standard(iso_days, location(iso_days))
    t = Solar.solar_longitude_after(lambda, d)
    Time.standard_from_universal(t, location(t))
  end

  @doc """
  Return last Chinese major solar term (zhongqi) before
  iso_days, date.
  """
  def current_major_solar_term(iso_days) do
    {_lat, _lng, _alt, offset} = chinese_location(iso_days)
    d = Time.universal_from_standard(iso_days, offset)
    s = Solar.solar_longitude(d)
    amod(2 + floor(trunc(s) / deg(30)), 12)
  end

  @doc """
  Return moment (in Beijing) of the first Chinese major
  solar term (zhongqi) on or after `iso_days`.  The
  major terms begin when the sun's longitude is a
  multiple of 30 degrees.
  """
  def major_solar_term_on_or_after(iso_days) do
    s = Solar.solar_longitude(midnight_in_china(iso_days))
    l = mod(30 * ceil(s / 30), 360)
    solar_longitude_on_or_after(l, iso_days)
  end

  @doc """
  Return last Chinese minor solar term (jieqi) before `iso_days`.
  """
  def current_minor_solar_term(iso_days) do
    {_lat, _lng, _alt, offset} = chinese_location(iso_days)
    d = Time.universal_from_standard(iso_days, offset)
    s = Solar.solar_longitude(d)
    amod(3 + floor(s - deg(15) / deg(30)), 12)
  end

  @doc """
  Return moment (in Beijing) of the first Chinese minor solar
  term (jieqi) on or after `iso_days`.  The minor terms
  begin when the sun's longitude is an odd multiple of 15 degrees.

  """
  def minor_solar_term_on_or_after(iso_days) do
    s = Solar.solar_longitude(midnight_in_china(iso_days))
    l = mod(30 * ceil((s - deg(15)) / 30) + deg(15), 360)

    solar_longitude_on_or_after(l, iso_days)
  end

  @doc """
  Return `iso_day` (Beijing) of first new moon before `iso_days`.
  """
  def new_moon_before(iso_days) do
    t = Lunar.date_time_new_moon_before(midnight_in_china(iso_days))
    {_lat, _lng, _alt, offset} = chinese_location(iso_days)

    Time.standard_from_universal(t, offset) |> trunc()
  end

  @doc """
  Return `iso_day` (Beijing) of first new moon on or after
  `iso_days`.
  """
  def new_moon_on_or_after(iso_days) do
    t = Lunar.date_time_new_moon_at_or_after(midnight_in_china(iso_days))
    {_lat, _lng, _alt, offset} = chinese_location(iso_days)

    Time.standard_from_universal(t, offset) |> trunc()
  end

  @doc """
  Return `true` if Chinese lunar month starting on `iso_days`
  has no major solar term. This also indicates it is a leap year.
  """
  def is_no_major_solar_term?(iso_days) do
    new_moon = new_moon_on_or_after(iso_days + 1)
    current_major_solar_term(iso_days) == current_major_solar_term(new_moon)
  end

  @doc """
  Return Universal time of (clock) midnight at start of `iso_days`,
  in China.
  """
  def midnight_in_china(iso_days) do
    {_lat, _lng, _alt, offset} = chinese_location(iso_days)
    Time.universal_from_standard(iso_days, offset)
  end

  @doc """
  Return iso_days, in the Chinese zone, of winter solstice
  on or before iso_days.
  """
  def winter_solstice_on_or_before(iso_days) do
    approx = Solar.estimate_prior_solar_longitude(@winter, midnight_in_china(iso_days + 1))

    next(
      trunc(approx) - 1,
      fn iso_day -> @winter < Solar.solar_longitude(midnight_in_china(1 + iso_day)) end
    )
  end

  @doc """
  Return `iso_day` of Chinese New Year in sui (period from
  solstice to solstice) containing `iso_days`.

  """
  def new_year_in_sui(iso_days) do
    s1 = winter_solstice_on_or_before(iso_days)
    s2 = winter_solstice_on_or_before(s1 + 370)

    next_m11 = new_moon_before(1 + s2)

    m12 = new_moon_on_or_after(1 + s1)
    m13 = new_moon_on_or_after(1 + m12)

    leap_year? = round((next_m11 - m12) / Time.mean_synodic_month()) == 12

    if leap_year? && (is_no_major_solar_term?(m12) || is_no_major_solar_term?(m13)) do
      new_moon_on_or_after(1 + m13)
    else
      m13
    end
  end

  @doc """
  Return `iso_day` of Chinese New Year on or
  before `iso_days`.

  """
  def new_year_on_or_before(iso_days) do
    new_year = new_year_in_sui(iso_days)

    if iso_days >= new_year do
      new_year
    else
      new_year_in_sui(iso_days - 180)
    end
  end

  @doc """
  Return iso_days of Chinese New Year in Gregorian
  year, g_year.

  """
  def new_year(gregorian_year) do
    iso_days = Cldr.Calendar.Gregorian.date_to_iso_days(gregorian_year, 7, 1)
    new_year_on_or_before(iso_days)
  end

  @doc """
  Return True if there is a Chinese leap month on or after lunar
  month starting on fixed day, m_prime and at or before
  lunar month starting at iso_days, m.
  """
  def is_prior_leap_month?(m_prime, m) do
    m >= m_prime &&
      (is_no_major_solar_term?(m) ||
         is_prior_leap_month?(m_prime, new_moon_before(m)))
  end

  defp name(stem, branch) when rem(stem, 2) == rem(branch, 2) do
    {stem, branch}
  end

  defp stem({stem, _branch}) do
    stem
  end

  defp branch({_stem, branch}) do
    branch
  end

  @doc """
  Return the n_th name of the Chinese sexagesimal cycle.
  """
  def sexagesimal_name(n) do
    name(amod(n, 10), amod(n, 12))
  end

  @doc """
  Return the number of names from Chinese name c_name1 to the
  next occurrence of Chinese name c_name2.
  """
  def name_difference(c_name1, c_name2) do
    stem1 = stem(c_name1)
    stem2 = stem(c_name2)

    branch1 = branch(c_name1)
    branch2 = branch(c_name2)

    stem_difference = stem2 - stem1
    branch_difference = branch2 - branch1

    1 + mod(stem_difference - 1 + 25 * (branch_difference - stem_difference), @years_in_cycle)
  end

  # CHECK THIS was rd(45) -> might need to be +/- 365 since our
  # epoch is different
  @month_name_epoch 57

  @doc """
  Return sexagesimal name for month, month, of Chinese year, year.
  """
  def month_name(month, year) do
    elapsed_months = 12 * (year - 1) + (month - 1)
    sexagesimal_name(elapsed_months - @month_name_epoch)
  end

  # CHECK THIS was rd(45) -> might need to be +/- 365 since our
  # epoch is different
  @day_name_epoch 45

  @doc """
  Return Chinese sexagesimal name for date, date.
  """
  def day_name(date) do
    sexagesimal_name(date - @day_name_epoch)
  end

  @doc """
  Return iso_days of latest date on or before iso_days, that
  has Chinese name, name.
  """
  def day_name_on_or_before(name, date) do
    name_difference = name_difference(name, sexagesimal_name(@day_name_epoch))
    date - mod(date + name_difference, @years_in_cycle)
  end

  @doc """
  Returns the `t:Calendar.iso_days/0` format of the specified date.

  """
  @impl true
  @spec naive_datetime_to_iso_days(
          Calendar.year(),
          Calendar.month(),
          Calendar.day(),
          Calendar.hour(),
          Calendar.minute(),
          Calendar.second(),
          Calendar.microsecond()
        ) :: Calendar.iso_days()

  def naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond) do
    {date_to_iso_days(year, month, day), time_to_day_fraction(hour, minute, second, microsecond)}
  end

  @doc """
  Converts the `t:Calendar.iso_days/0` format to the datetime format specified by this calendar.

  """
  @spec naive_datetime_from_iso_days(Calendar.iso_days()) :: {
          Calendar.year(),
          Calendar.month(),
          Calendar.day(),
          Calendar.hour(),
          Calendar.minute(),
          Calendar.second(),
          Calendar.microsecond()
        }
  @impl true
  def naive_datetime_from_iso_days({days, day_fraction}) do
    {year, month, day} = date_from_iso_days(days)
    {hour, minute, second, microsecond} = time_from_day_fraction(day_fraction)
    {year, month, day, hour, minute, second, microsecond}
  end

  @doc false
  calendar_impl()

  def parse_date(string) do
    Cldr.Calendar.Parse.parse_date(string, __MODULE__)
  end

  @doc false
  calendar_impl()

  def parse_utc_datetime(string) do
    Cldr.Calendar.Parse.parse_utc_datetime(string, __MODULE__)
  end

  @doc false
  calendar_impl()

  def parse_naive_datetime(string) do
    Cldr.Calendar.Parse.parse_naive_datetime(string, __MODULE__)
  end

  @doc false
  @impl Calendar
  defdelegate parse_time(string), to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate day_rollover_relative_to_midnight_utc, to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate time_from_day_fraction(day_fraction), to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate time_to_day_fraction(hour, minute, second, microsecond), to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate date_to_string(year, month, day), to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate datetime_to_string(
                year,
                month,
                day,
                hour,
                minute,
                second,
                microsecond,
                time_zone,
                zone_abbr,
                utc_offset,
                std_offset
              ),
              to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate naive_datetime_to_string(
                year,
                month,
                day,
                hour,
                minute,
                second,
                microsecond
              ),
              to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate time_to_string(hour, minute, second, microsecond), to: Calendar.ISO

  @doc false
  @impl Calendar
  defdelegate valid_time?(hour, minute, second, microsecond), to: Calendar.ISO

end
