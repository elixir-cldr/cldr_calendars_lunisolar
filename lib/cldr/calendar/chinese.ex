defmodule Cldr.Calendar.Chinese do
  @moduledoc """
  Implementation of the Chinese lunisolar calendar.

  In a ‘regular’ Chinese lunisolar calendar, one year
  is divided into 12 months, one month is corresponding
  to one full moon.

  Since the cycle of the Moon is not
  an even number of days, a month in the lunar calendar
  can vary between 29 and 30 days and a normal year can
  have 353, 354, or 355 days.

  """
  use Cldr.Calendar.Behaviour

  import Astro.Math, only: [
    mod: 2,
    angle: 3,
    mt: 1,
    amod: 2,
    deg: 1,
    next: 2
  ]

  alias Astro.{Solar, Lunar, Time}

  @behaviour Calendar
  @behaviour Cldr.Calendar

  @type year :: -9999..-1 | 1..9999
  @type month :: 1..13
  @type day :: 1..30

  @days_in_week 7

  # Winter season in degrees
  @winter 270

  # Number of years in a cycle
  @years_in_cycle 60

  # Calculating solar events in
  # the following year (in days)
  @one_solar_year_later 370

  # Encode a leap month by adding
  # this amount to it, By keeping
  # the maximum number to 2 digits
  # we can continue to use Sigil_D
  @encode_leap_month_addend 50

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

  # This epoch is the first use of the sexagesimal cycle
  # It is also the epoch used by CLDR

  @epoch Cldr.Calendar.Gregorian.date_to_iso_days(-2636, 2, 15)

  # Alternative epoch starting from the reigh of Emporer Huangdi
  # This epoch seems more common in popular press
  # @alt_epoch Cldr.Calendar.Gregorian.date_to_iso_days(-2696, 1, 1)

  def epoch do
    @epoch
  end

  @doc """
  Since the Chinese calendar is a lunisolar
  calendar, a refernce longitude is required
  in order to calculate sunset and sunrise.

  Prior to 1929, the longitude of Beijing was
  used. Since 1929, the longitude of the
  standard China timezone (GMT+8) is used.

  """
  @beijing_local_offset Astro.Time.hours_to_days(1397 / 180)
  @china_standard_offset Astro.Time.hours_to_days(8)

  @spec chinese_location(Time.time()) :: {Astro.angle(), Astro.angle(), Astro.meters, Time.hours()}
  def chinese_location(iso_days) do
    {year, _month, _day} = Cldr.Calendar.Gregorian.date_from_iso_days(trunc(iso_days))

    if year < 1929 do
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), @beijing_local_offset}
    else
      {angle(39, 55, 0), angle(116, 25, 0), mt(43.5), @china_standard_offset}
    end
  end

  @doc """
  Determines if the date given is valid according to
  this calendar.

  """
  @impl true

  def valid_date?(year, month, day) do
    month <= months_in_year(year) && day <= days_in_month(year, month)
  end

  @doc """
  Calculates the year and era from the given `year`.

  """
  @spec year_of_era(year) :: {year, era :: 0..1}
  @impl true

  def year_of_era(year) when year >= 0 do
    {year, 1}
  end

  def year_of_era(year) when year < 0 do
    {abs(year), 0}
  end

  @doc """
  Calculates the quarter of the year from the given
  `year`, `month`, and `day`.

  Quarters are not implemented for the Chinese
  calendar and this function always returns
  `{:error, :not_defined}`.

  """
  @spec quarter_of_year(year, month, day) :: 1..4
  @impl true

  def quarter_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the month of the year from the given
  `year`, `month`, and `day`.

  It returns integer from 1 to 12 for a
  normal year and 1 to 13 for a leap year.

  """
  @spec month_of_year(year, month, day) :: month
  @impl true

  def month_of_year(_year, month, _day) do
    month
  end

  @doc """
  Calculates the week of the year from the given
  `year`, `month`, and `day`.

  Weeks are not implemented for the Chinese
  calendar and this function always returns
  `{:error, :not_defined}`.

  """
  @spec week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true

  def week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the ISO week of the year from the
  given `year`, `month`, and `day`.

  Weeks are not implemented for the Chinese
  calendar and this function always returns
  `{:error, :not_defined}`.

  """
  @spec iso_week_of_year(year, month, day) :: {:error, :not_defined}
  @impl true

  def iso_week_of_year(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the week of the year from the given
  `year`, `month`, and `day`.

  Weeks are not implemented for the Chinese
  calendar and this function always returns
  `{:error, :not_defined}`.

  """
  @spec week_of_month(year, month, day) :: {pos_integer(), pos_integer()} | {:error, :not_defined}
  @impl true

  def week_of_month(_year, _month, _day) do
    {:error, :not_defined}
  end

  @doc """
  Calculates the day and era from the given
  `year`, `month`, and `day`.

  For the Chinese calendar we consider only
  the epoch as the demarkation between eras
  (in the same way as the Gregorian calendar
  works).

  Historically eras have been marked by the
  reign of an emporer but this has no modern
  relevant or use.

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
      days_after_saturday = rem(days, @days_in_week)
      day = Cldr.Math.amod(days_after_saturday + @epoch_day_of_week, @days_in_week)

      {day, @epoch_day_of_week, @last_day_of_week}
    end
  else
    @spec day_of_week(year, month, day) :: 1..7

    @impl true
    def day_of_week(year, month, day) do
      days = date_to_iso_days(year, month, day)
      days_after_saturday = rem(days, @days_in_week)
      Cldr.Math.amod(days_after_saturday + @epoch_day_of_week, @days_in_week)
    end
  end

  @doc """
  Returns the number of periods in a given
  `year`. A period corresponds to a month
  in month-based calendars and a week in
  week-based calendars.

  """
  @impl true

  def periods_in_year(year) do
    months_in_year(year)
  end

  @doc """
  Returns the number of months in a
  given Chinese `year`.

  """
  @impl true

  def months_in_year(year) do
    if leap_year?(year), do: 13, else: 12
  end

  @doc """
  Returns the number of weeks in a
  given Chinese `year`.

  """
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

  The month number is the ordinal month number
  which means that the numbers do not always
  increase monotoncally.

  """
  @spec days_in_month(year, month) :: 29..30
  @impl true

  def days_in_month(year, month) do
    start_of_this_month = date_to_iso_days(year, month, 1)
    start_of_next_month = new_moon_on_or_after(start_of_this_month + 1)
    start_of_next_month - start_of_this_month
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
  @spec leap_year?(year) :: boolean()
  @impl true

  def leap_year?({cycle, year}) do
    leap_year?(cycle, year)
  end

  def leap_year?(year) do
    start_of_this_year = alt_date_to_iso_days(year, 1, 1)
    start_of_next_year = alt_date_to_iso_days(year + 1, 1, 1)
    floor((start_of_next_year - start_of_this_year) / Time.mean_synodic_month) == 13
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
    |> elapsed_years(year)
    |> leap_year?()
  end

  def leap_solar_year?(iso_days) do
    s1 = december_solstice_on_or_before(iso_days)
    s2 = december_solstice_on_or_before(s1 + @one_solar_year_later)

    next_m11 = new_moon_before(1 + s2)
    m12 = new_moon_on_or_after(1 + s1)

    # 12 full lunar months means 13 new moons
    round((next_m11 - m12) / Time.mean_synodic_month()) == 12
  end

  def alt_leap_solar_year?(year, month, day) do
    iso_days = alt_date_to_iso_days(year, month, day)
    leap_solar_year?(iso_days)
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
  def leap_month?(_year, month) do
    month > @encode_leap_month_addend
  end

  defp leap_month?({_cycle, _year, _month, leap_month?, _day}) do
    leap_month?
  end

  def alt_leap_month?(year, month) do
    {cycle, year} = cycle_and_year(year)
    alt_leap_month?(cycle, year, month)
  end

  def alt_leap_month?(cycle, year, month) do
    start_of_month = alt_chinese_date_to_iso_days(cycle, year, month, 1)
    new_year = new_year_on_or_before(start_of_month)

    leap_solar_year?(start_of_month) &&
      no_major_solar_term?(start_of_month) &&
      !is_prior_leap_month?(start_of_month, new_year)
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
    {cycle, year} = cycle_and_year(year)
    {month, leap_month?} = decode_month(month)
    chinese_date_to_iso_days(cycle, year, month, leap_month?, day)
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  # Original version in which the month number doesnt change for
  # a leap month (but the leap_month? flag is set for the second
  # month with the same number)
  def chinese_date_to_iso_days(cycle, year, month, leap_month?, day) do
    mid_year = mid_year(cycle, year)
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

  def chinese_date_to_iso_days({cycle, year, month, leap_month?, day}) do
    chinese_date_to_iso_days(cycle, year, month, leap_month?, day)
  end

  # Version which uses ordinal numbers in a monotonic sequence 1..12
  # or 1..13 for month numbers. Leap months are not marked but can
  # be later calculated.

  # This makes clear how simple the calendar is - just a sequence of
  # months aligned to new moons. The complication is only determining
  # the start of the year.

  def alt_date_to_iso_days(year, month, day) do
    {cycle, year} = cycle_and_year(year)
    alt_chinese_date_to_iso_days(cycle, year, month, day)
  end

  def alt_date_to_iso_days({year, month, day}) do
    alt_date_to_iso_days(year, month, day)
  end

  def alt_chinese_date_to_iso_days(cycle, year, month, day) do
    new_year =
      cycle
      |> mid_year(year)
      |> new_year_on_or_before()

    prior_new_moon = new_moon_on_or_after(new_year + (month - 1) * 29)

    prior_new_moon + day - 1
  end

  def alt_chinese_date_to_iso_days({cycle, year, month, day}) do
    alt_chinese_date_to_iso_days(cycle, year, month, day)
  end

  @doc """
  Returns a `{year, month, day}` calculated from
  the number of `iso_days`.

  ## Example

      iex> Cldr.Calendar.Chinese.date_from_iso_days 729782
      {4635, 1, 1}

  """
  def date_from_iso_days(iso_days) do
    {cycle, year, month, leap_month?, day} = chinese_date_from_iso_days(iso_days)
    month = encode_month(month, leap_month?)
    elapsed_years = elapsed_years(cycle, year)

    {elapsed_years, month, day}
  end

  @doc """
  Returns a `{cycle, year, month, leap_month?, day}`
  tuple from the number of `iso_days`.

  ## Example

      iex> Cldr.Calendar.Chinese.chinese_date_from_iso_days 729782
      {78, 15, 1, false, 1}

  """

  def chinese_date_from_iso_days(iso_days) do
    {month, start_of_month, leap_month?} = month_and_leap(iso_days)

    elapsed_years = floor(1.5 - (month / 12) + ((iso_days - epoch()) / Time.mean_tropical_year()))
    {cycle, year} = cycle_and_year(elapsed_years)

    day = (iso_days - start_of_month) + 1

    {cycle, year, month, leap_month?, day}
  end

  # Here we return months that monotonically increase
  # from 1 to 12 (or 13 in a leap year).
  def alt_date_from_iso_days(iso_days) do
    {cycle, year, month, day} = alt_chinese_date_from_iso_days(iso_days)
    elapsed_years = elapsed_years(cycle, year)

    {elapsed_years, month, day}
  end

  def alt_chinese_date_from_iso_days(iso_days) do
    new_year = new_year_on_or_before(iso_days)
    start_of_month = new_moon_before(iso_days + 1)

    elapsed_years =
      ((new_year - epoch()) / Time.mean_tropical_year()) + 1
      |> round()

    month =
      ((start_of_month - new_year) / Time.mean_synodic_month()) + 1
      |> round()

    day =
      (iso_days - start_of_month + 1)
      |> round()

    {cycle, year} = cycle_and_year(elapsed_years)
    {cycle, year, month, day}
  end

  @doc """
  Returns `{month, start_of_month, leap_month?}` for a given
  date in `iso_days`.

  """
  @calendar_months_in_year 12

  def month_and_leap(iso_days) do
    {prior_month_12, next_month_11} =
      lunisolar_year(iso_days)

    leap_sui_year? =
      leap_sui_year?(prior_month_12, next_month_11)

    start_of_month =
      new_moon_before(1 + iso_days)

    month =
      start_of_month
      |> lunar_months_between(prior_month_12)
      |> offset_if_prior_leap_month(leap_sui_year?, prior_month_12, start_of_month)
      |> amod(@calendar_months_in_year)
      |> trunc()

    leap_month? =
      leap_month?(leap_sui_year?, start_of_month, prior_month_12)

    {month, start_of_month, leap_month?}
  end

  defp lunisolar_year(iso_days) do
    prior_solstice = december_solstice_on_or_before(iso_days)
    prior_month_12 = new_moon_on_or_after(1 + prior_solstice)

    next_solstice = december_solstice_on_or_before(prior_solstice + @one_solar_year_later)
    next_month_11 = new_moon_before(1 + next_solstice)

    {prior_month_12, next_month_11}
  end

  defp leap_month?(leap_sui_year?, iso_days, start_of_sui_year) do
    leap_sui_year? && no_major_solar_term?(iso_days) &&
      !is_prior_leap_month?(start_of_sui_year, new_moon_before(iso_days))
  end

  defp leap_sui_year?(start_of_year, end_of_year) do
    # 12 full lunar months means 13 new moons
    round((end_of_year - start_of_year) / Time.mean_synodic_month()) == @calendar_months_in_year
  end

  defp offset_if_prior_leap_month(months, true = _leap_sui_year?, last_month_12, start_of_month) do
    if is_prior_leap_month?(last_month_12, start_of_month), do: months - 1, else: months
  end

  defp offset_if_prior_leap_month(months, _leap_sui_year?, _last_month_12, _start_of_month) do
    months
  end

  def lunar_months_between(from_iso_days, to_iso_days) do
    round((from_iso_days - to_iso_days) / Time.mean_synodic_month())
  end

  defp month({_cycle, _year, month, _leap_month?, _day}) do
    month
  end

  defp mid_year(cycle, year) do
    floor(epoch() +
      ((((cycle - 1) * @years_in_cycle) + (year - 1) + 1/2) * Time.mean_tropical_year()))
  end

  @doc false
  def elapsed_years(cycle, year) do
    ((cycle - 1) * @years_in_cycle) + year
  end

  def elapsed_years({cycle, year}) do
    elapsed_years(cycle, year)
  end

  @doc false
  def cycle_and_year(elapsed_years) do
    cycle = 1 + floor((elapsed_years - 1) / @years_in_cycle)
    year = amod(elapsed_years, @years_in_cycle)

    {cycle, year}
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

  ## Example

      iex> Cldr.Calendar.Chinese.new_moon_before(-962734 + 1)
      -962734

  """
  def new_moon_before(iso_days) do
    new_moon =
      iso_days
      |> midnight_in_china()
      |> Lunar.date_time_new_moon_before()

    {_lat, _lng, _alt, offset} = chinese_location(new_moon)

    Time.standard_from_universal(new_moon, offset) |> floor()
  end

  @doc """
  Return `iso_day` (Beijing) of first new moon on or after
  `iso_days`.

  ## Example

      iex> Cldr.Calendar.Chinese.new_moon_on_or_after(-962734)
      -962734

  """
  def new_moon_on_or_after(iso_days) do
    new_moon =
      iso_days
      |> midnight_in_china()
      |> Lunar.date_time_new_moon_at_or_after()

    {_lat, _lng, _alt, offset} = chinese_location(new_moon)

    Time.standard_from_universal(new_moon, offset) |> floor()
  end

  @doc """
  Return `true` if Chinese lunar month starting on `iso_days`
  has no major solar term.

  """
  def no_major_solar_term?(iso_days) do
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
  def december_solstice_on_or_before(iso_days) do
    approx = Solar.estimate_prior_solar_longitude(@winter, midnight_in_china(iso_days + 1))
    next(floor(approx) - 1, &(@winter < Solar.solar_longitude(midnight_in_china(1 + &1))))
  end

  @doc """
  Return `iso_day` of Chinese New Year in sui
  (period from solstice to solstice)
  containing `iso_days`.

  """
  def new_year_in_sui(iso_days) do
    {prior_month_12, next_month_11} = lunisolar_year(iso_days)
    prior_month_13 = new_moon_on_or_after(1 + prior_month_12)

    leap_year? =
      leap_sui_year?(prior_month_12, next_month_11)

    no_prior_major_solar_term? =
      no_major_solar_term?(prior_month_12) || no_major_solar_term?(prior_month_13)

    if leap_year? && no_prior_major_solar_term? do
      new_moon_on_or_after(1 + prior_month_13)
    else
      prior_month_13
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
  year.

  """
  def chinese_new_year_for_gregorian_year(gregorian_year) do
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
      (no_major_solar_term?(m) ||
         is_prior_leap_month?(m_prime, new_moon_before(m)))
  end

  @doc """
  Return the name of the Chinese
  sexagesimal cycle.

  """
  def stem_and_branch({_cycle, year, _month, _leap_month?, _day}) do
    stem_and_branch(year)
  end

  def stem_and_branch({year, _month, _day}) do
    {_cycle, year} = cycle_and_year(year)
    stem_and_branch(year)
  end

  def stem_and_branch(n) do
    name(amod(n, 10), amod(n, 12))
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
    stem_and_branch(elapsed_months - @month_name_epoch)
  end

  # CHECK THIS was rd(45) -> might need to be +/- 365 since our
  # epoch is different
  @day_name_epoch 45

  @doc """
  Return Chinese sexagesimal name for date, date.
  """
  def day_name(date) do
    stem_and_branch(date - @day_name_epoch)
  end

  @doc """
  Return iso_days of latest date on or before iso_days, that
  has Chinese name, name.

  """
  def day_name_on_or_before(name, date) do
    name_difference = name_difference(name, stem_and_branch(@day_name_epoch))
    date - mod(date + name_difference, @years_in_cycle)
  end

  def location(iso_days) do
    {latitude, longitude, altitude, offset} = chinese_location(iso_days)
    properties = %{offset: offset}
    %Geo.PointZ{coordinates: {longitude, latitude, altitude}, properties: properties}
  end

  defp encode_month(month, true = _leap_month?) do
    month + @encode_leap_month_addend
  end

  defp encode_month(month, _leap_month?) do
    month
  end

  defp decode_month(month) when month > @encode_leap_month_addend do
    {month -  @encode_leap_month_addend, true}
  end

  defp decode_month(month) do
    {month, false}
  end

end
