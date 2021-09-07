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
  use Cldr.Calendar.Behaviour,
    epoch: ~D[-2636-02-15],
    cldr_calendar_type: :chinese

  # Alternative epoch starting from the reign of Emporer Huangdi
  # @alt_epoch Cldr.Calendar.Gregorian.date_to_iso_days(-2696, 1, 1)

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

  # Winter season in degrees
  @winter 270

  # Number of years in a cycle
  @years_in_cycle 60

  # Calculating solar events in
  # the following year (in days)
  @one_solar_year_later 370

  # This is the nummber of months
  # in the calendar (not the number
  # of new moons)
  @calendar_months_in_year 12

  def cyclic_year(year, _month, _day) do
    {_cycle, year} =  cycle_and_year(year)
    year
  end

  def related_gregorian_year(year, _month, _day) do
    iso_days = date_to_iso_days(year, 1, 1)
    {year, _month, _day} =  Cldr.Calendar.Gregorian.date_from_iso_days(iso_days)
    year
  end

  def month_of_year(year, month, day) do
    iso_days = date_to_iso_days(year, month, day)
    {month, _start_of_month, leap_month?} = month_and_leap(iso_days)
    {month, leap_month?}
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
    start_of_this_year = date_to_iso_days(year, 1, 1)
    start_of_next_year = date_to_iso_days(year + 1, 1, 1)
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

  defp leap_lunisolar_year?({start_of_year, end_of_year}) do
    leap_lunisolar_year?(start_of_year, end_of_year)
  end

  defp leap_lunisolar_year?(iso_days) when is_number(iso_days) do
    iso_days
    |> lunisolar_year()
    |> leap_lunisolar_year?()
  end

  defp leap_lunisolar_year?(start_of_year, end_of_year) do
    # 12 full lunar months means 13 new moons
    round((end_of_year - start_of_year) / Time.mean_synodic_month()) == @calendar_months_in_year
  end

  def leap_lunisolar_year?(year, month, day) do
    iso_days = date_to_iso_days(year, month, day)
    leap_lunisolar_year?(iso_days)
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
  def leap_month?(year, month) do
    {cycle, year} = cycle_and_year(year)
    leap_month?(cycle, year, month)
  end

  def leap_month?(cycle, year, month) do
    start_of_month = chinese_date_to_iso_days(cycle, year, month, 1)
    new_year = new_year_on_or_before(start_of_month)

    leap_lunisolar_year?(start_of_month) &&
      no_major_solar_term?(start_of_month) &&
      !is_prior_leap_month?(start_of_month, new_year)
  end

  # Version which uses ordinal numbers in a monotonic sequence 1..12
  # or 1..13 for month numbers. Leap months are not marked but can
  # be later calculated.

  # This makes clear how simple the calendar is - just a sequence of
  # months aligned to new moons. The complication is only determining
  # the start of the year.

  def date_to_iso_days(year, month, day) do
    {cycle, year} = cycle_and_year(year)
    chinese_date_to_iso_days(cycle, year, month, day)
  end

  def date_to_iso_days({year, month, day}) do
    date_to_iso_days(year, month, day)
  end

  def chinese_date_to_iso_days(cycle, year, month, day) do
    new_year =
      cycle
      |> mid_year(year)
      |> new_year_on_or_before()

    prior_new_moon = new_moon_on_or_after(new_year + (month - 1) * 29)

    prior_new_moon + day - 1
  end

  def chinese_date_to_iso_days({cycle, year, month, day}) do
    chinese_date_to_iso_days(cycle, year, month, day)
  end

  # Original version in which the month number doesnt change for
  # a leap month (but the leap_month? flag is set for the second
  # month with the same number)

  @doc false
  defmacrop leap_month?(d) do
    quote do
      elem(unquote(d), 3)
    end
  end

  @doc false
  defmacrop month(d) do
    quote do
      elem(unquote(d), 2)
    end
  end

  @doc false
  def alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day) do
    mid_year = mid_year(cycle, year)
    new_year = new_year_on_or_before(mid_year)

    p = new_moon_on_or_after(new_year + (month - 1) * 29)
    d = alt_chinese_date_from_iso_days(p)

    prior_new_moon =
      if month == month(d) && leap_month? == leap_month?(d) do
        p
      else
        new_moon_on_or_after(1 + p)
      end

    prior_new_moon + day - 1
  end

  @doc false
  def alt_chinese_date_to_iso_days({cycle, year, month, leap_month?, day}) do
    alt_chinese_date_to_iso_days(cycle, year, month, leap_month?, day)
  end

  # Here we return months that monotonically increase
  # from 1 to 12 (or 13 in a leap year).
  def date_from_iso_days(iso_days) do
    {cycle, year, month, day} = chinese_date_from_iso_days(iso_days)
    elapsed_years = elapsed_years(cycle, year)

    {elapsed_years, month, day}
  end

  def chinese_date_from_iso_days(iso_days) do
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

  @doc false
  def alt_chinese_date_from_iso_days(iso_days) do
    {month, start_of_month, leap_month?} = month_and_leap(iso_days)

    elapsed_years = floor(1.5 - (month / 12) + ((iso_days - epoch()) / Time.mean_tropical_year()))
    {cycle, year} = cycle_and_year(elapsed_years)

    day = (iso_days - start_of_month) + 1

    {cycle, year, month, leap_month?, day}
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
      leap_lunisolar_year?(prior_month_12, next_month_11)

    start_of_month =
      new_moon_before(iso_days + 1)

    month =
      start_of_month
      |> lunar_months_between(prior_month_12)
      |> offset_if_prior_leap_month(leap_sui_year?, prior_month_12, start_of_month)
      |> amod(@calendar_months_in_year)
      |> trunc()

    leap_month? =
      is_leap_month?(leap_sui_year?, start_of_month, prior_month_12)

    {month, start_of_month, leap_month?}
  end

  defp lunisolar_year(iso_days) do
    prior_solstice = december_solstice_on_or_before(iso_days)
    prior_month_12 = new_moon_on_or_after(1 + prior_solstice)

    next_solstice = december_solstice_on_or_before(prior_solstice + @one_solar_year_later)
    next_month_11 = new_moon_before(1 + next_solstice)

    {prior_month_12, next_month_11}
  end

  defp is_leap_month?(leap_sui_year?, iso_days, start_of_sui_year) do
    leap_sui_year? && no_major_solar_term?(iso_days) &&
      !is_prior_leap_month?(start_of_sui_year, new_moon_before(iso_days))
  end

  defp offset_if_prior_leap_month(months, true = _leap_sui_year?, last_month_12, start_of_month) do
    if is_prior_leap_month?(last_month_12, start_of_month), do: months - 1, else: months
  end

  defp offset_if_prior_leap_month(months, _leap_sui_year?, _last_month_12, _start_of_month) do
    months
  end

  defp lunar_months_between(from_iso_days, to_iso_days) do
    round((from_iso_days - to_iso_days) / Time.mean_synodic_month())
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
      leap_lunisolar_year?(prior_month_12, next_month_11)

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

end
