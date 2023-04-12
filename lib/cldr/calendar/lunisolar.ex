defmodule Cldr.Calendar.Lunisolar do
  @moduledoc """
  Template for building lunisolar calendars.  See
  `Cldr.Calendar.Chinese` for an example implementation.

  The functions in this module should only be called
  from lunisolar implementations.

  Some conventions are used for naming in this module:

  * `year` refers to the calendar year with is the number
    of years since the epoch.

  * `cyclical_year` is the year in the sexigesimal cycle.

  * `month` is the ordinal month in the calendar year that
    is between 1 and 12 for an ordinary year and between 1
    and 13 in a leap year.

  * `lunar_month` is a the month numbered similarly to how months
    are traditionally numbered. The month will be a cardinal
    number between 1 and 12 in all years with the addition of
    a leap month in leap years. The leap month is represented
    by `{month, :keap}`.

  """

  import Astro.Math, only: [
    mod: 2,
    amod: 2,
    deg: 1,
    next: 2
  ]

  alias Astro.{Time, Solar, Lunar}

  @typedoc "A lunar month"
  @type lunar_month :: Calendar.month() | {Calendar.month(), :leap}

  @typedoc "A sexigesimal cycle number"
  @type cycle :: pos_integer()

  # Winter season in degrees
  @winter 270

  # Number of years in a cycle
  @years_in_cycle 60

  # Calculating solar events in
  # the following year (in days)
  @one_solar_year_later 370

  # This is the number of months
  # in the calendar (not the number
  # of new moons) for a normal year.
  @lunar_calendar_months_in_year 12

  @doc """
  Create a new date in the lunisolar calendar.

  ### Arguments

  * `year` is a year in the lunisolar calendar.

  * `month` is a month in the lunisolar calendar
  as either a positive integer or a tuple of the
  form `{month, :leap}` representing the leap month.

  * `day` is a day of month.

  * `epoch` is the epoch in iso days for the lunisolar
    calendar.

  * `location_fun` is a 1-arity function that returns
    the tuple of the form `{latitude, longitude, altitude, hour_offset}`
    for  the lunisolar calendar.

  ### Returns

  * `iso_days` begin the iso_days for the given date in
    based upon the given location.

  """

  def new(year, {lunar_month, :leap} = month, day, epoch, location_fun) do
    if valid_date?(year, month, day, epoch, location_fun) do
      {cycle, cyclical_year} = cycle_and_year(year)
      leap_month? = true
      alt_cyclical_date_to_iso_days(cycle, cyclical_year, lunar_month, leap_month?, day, epoch, location_fun)
    else
      {:error, :invalid_date}
    end
  end

  def new(year, month, day, epoch, location_fun) do
    if valid_date?(year, month, day, epoch, location_fun) do
      {cycle, cyclical_year} = cycle_and_year(year)
      leap_month? = false
      alt_cyclical_date_to_iso_days(cycle, cyclical_year, month, leap_month?, day, epoch, location_fun)
    else
      {:error, :invalid_date}
    end
  end

  @doc false
  def cyclic_year(year, _month, _day) do
    {_cycle, year} =  cycle_and_year(year)
    year
  end

  @doc false
  def lunar_month_of_year(year, month, day, epoch, location_fun) do
    iso_days = date_to_iso_days(year, month, day, epoch, location_fun)
    {month, _start_of_month, leap_month?} = month_and_leap(iso_days, location_fun)

    case {month, leap_month?} do
      {month, true} -> {month, :leap}
      {month, false} -> month
    end
  end

  # year, month, day where month is in lunisolar month format of an integer between
  # 1 and 12, with a leap month denoted by `{month, :leap}`.

  defp valid_date?(year, lunar_month, day, epoch, location_fun) when is_integer(lunar_month) do
    lunar_month <= @lunar_calendar_months_in_year &&
      day <= days_in_lunar_month(year, lunar_month, epoch, location_fun)
  end

  defp valid_date?(year, {lunar_month, :leap}, day, epoch, location_fun) when is_integer(lunar_month) do
    leap_year?(year, epoch, location_fun) &&
      leap_month(year, epoch, location_fun) == lunar_month &&
      day <= days_in_lunar_month(year, {lunar_month, :leap}, epoch, location_fun)
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

  """

  def leap_year?(year, epoch, location_fun) do
    start_of_this_year = date_to_iso_days(year, 1, 1, epoch, location_fun)
    start_of_next_year = date_to_iso_days(year + 1, 1, 1, epoch, location_fun)
    floor((start_of_next_year - start_of_this_year) / Time.mean_synodic_month) == 13
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
  def leap_month?(year, month, epoch, location_fun) do
    {cycle, cyclic_year} = cycle_and_year(year)
    leap_month?(cycle, cyclic_year, month, epoch, location_fun)
  end

  @first_day_of_month 1

  def leap_month?(cycle, cyclical_year, month, epoch, location_fun) do
    start_of_month = cyclical_date_to_iso_days(cycle, cyclical_year, month, @first_day_of_month, epoch, location_fun)
    new_year = new_year_on_or_before(start_of_month, location_fun)

    leap_lunisolar_year?(start_of_month, location_fun) &&
      no_major_solar_term?(start_of_month, location_fun) &&
      !is_prior_leap_month?(start_of_month, new_year, location_fun)
  end

  @doc """
  Returns the leap month number for a given year
  or nil if its not a leap year.

  """
  def leap_month(year, epoch, location_fun) do
    if leap_year?(year, epoch, location_fun) do
      Enum.find(1..months_in_year(year, epoch, location_fun), &leap_month?(year, &1, epoch, location_fun))
    else
      nil
    end
  end

  # Version which uses ordinal numbers in a monotonic sequence 1..12
  # or 1..13 for month numbers. Leap months are not marked but can
  # be later calculated.

  # This makes clear how simple the calendar is - just a sequence of
  # months aligned to new moons. The complication is only determining
  # the start of the year and leap months.

  def date_to_iso_days(year, month, day, epoch, location_fun) do
    {cycle, cyclic_year} = cycle_and_year(year)
    cyclical_date_to_iso_days(cycle, cyclic_year, month, day, epoch, location_fun)
  end

  # defp date_to_iso_days({year, month, day}, epoch, location_fun) do
  #   date_to_iso_days(year, month, day, epoch, location_fun)
  # end

  def cyclical_date_to_iso_days(cycle, cyclical_year, month, day, epoch, location_fun) do
    new_year =
      cycle
      |> mid_year(cyclical_year, epoch)
      |> new_year_on_or_before(location_fun)

    prior_new_moon = new_moon_on_or_after(new_year + (month - 1) * 29, location_fun)

    prior_new_moon + day - 1
  end

  # defp cyclical_date_to_iso_days({cycle, cyclical_year, month, day}, epoch, location_fun) do
  #   cyclical_date_to_iso_days(cycle, cyclical_year, month, day, epoch, location_fun)
  # end

  # Here we return months that monotonically increase
  # from 1 to 12 (or 13 in a leap year).
  def date_from_iso_days(iso_days, epoch, location_fun) do
    {cycle, cyclical_year, month, day} = cyclical_date_from_iso_days(iso_days, epoch, location_fun)
    elapsed_years = elapsed_years(cycle, cyclical_year)

    {elapsed_years, month, day}
  end

  # THis version returns the cyclical year and ordinal month
  @doc false
  def cyclical_date_from_iso_days(iso_days, epoch, location_fun) do
    new_year = new_year_on_or_before(iso_days, location_fun)
    start_of_month = new_moon_before(iso_days + 1, location_fun)

    elapsed_years =
      ((new_year - epoch) / Time.mean_tropical_year()) + 1
      |> round()

    month =
      ((start_of_month - new_year) / Time.mean_synodic_month()) + 1
      |> round()

    day =
      (iso_days - start_of_month + 1)
      |> round()

    {cycle, cyclic_year} = cycle_and_year(elapsed_years)
    {cycle, cyclic_year, month, day}
  end

  # This version returns the cyclical year and *lunar* month with leap
  # month indicator.
  @doc false
  def alt_cyclical_date_from_iso_days(iso_days, epoch, location_fun) do
    {lunar_month, start_of_month, leap_month?} = month_and_leap(iso_days, location_fun)

    elapsed_years = floor(1.5 - (lunar_month / 12) + ((iso_days - epoch) / Time.mean_tropical_year()))
    {cycle, cyclic_year} = cycle_and_year(elapsed_years)

    day = (iso_days - start_of_month) + 1

    {cycle, cyclic_year, lunar_month, leap_month?, day}
  end

  @doc false
  def elapsed_years(cycle, cyclic_year) do
    ((cycle - 1) * @years_in_cycle) + cyclic_year
  end

  def elapsed_years({cycle, cyclic_year}) do
    elapsed_years(cycle, cyclic_year)
  end

  @doc false
  def cycle_and_year(elapsed_years) do
    cycle = 1 + floor((elapsed_years - 1) / @years_in_cycle)
    cyclic_year = amod(elapsed_years, @years_in_cycle)

    {cycle, cyclic_year}
  end





  defp months_in_year(year, epoch, location_fun) do
    if leap_year?(year, epoch, location_fun), do: @lunar_calendar_months_in_year, else: @lunar_calendar_months_in_year + 1
  end

  defp days_in_lunar_month(year, lunar_month, epoch, location_fun) do
    case lunar_month_to_calendar_month(year, lunar_month, epoch, location_fun) do
      {:ok, month} ->
        days_in_month(year, month, epoch, location_fun)
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp days_in_month(year, month, epoch, location_fun) do
    first =
      date_to_iso_days(year, month, 1, epoch, location_fun)

    last =
      if month == months_in_year(year, epoch, location_fun) do
        date_to_iso_days(year + 1, 1, 1, epoch, location_fun)
      else
        date_to_iso_days(year, month + 1, 1, epoch, location_fun)
      end

    last - first + 1
  end

  defp lunar_month_to_calendar_month(year, lunar_month, epoch, location_fun)
      when is_integer(lunar_month) and lunar_month in 1..@lunar_calendar_months_in_year do
    if leap_year?(year, epoch, location_fun) && leap_month(year, epoch, location_fun) < lunar_month do
      {:ok, lunar_month + 1}
    else
      {:ok, lunar_month}
    end
  end

  defp lunar_month_to_calendar_month(year, {lunar_month, :leap}, epoch, location_fun)
      when is_integer(lunar_month) and lunar_month in 1..@lunar_calendar_months_in_year do
    if leap_year?(year, epoch, location_fun) && leap_month(year, epoch, location_fun) == lunar_month do
      {:ok, lunar_month}
    else
      {:error, :invalid_leap_month}
    end
  end

  defp leap_lunisolar_year?({start_of_year, end_of_year}) do
    leap_lunisolar_year?(start_of_year, end_of_year)
  end

  defp leap_lunisolar_year?(iso_days, location_fun)
      when is_number(iso_days) and is_function(location_fun) do
    iso_days
    |> lunisolar_year(location_fun)
    |> leap_lunisolar_year?()
  end

  defp leap_lunisolar_year?(start_of_year, end_of_year) do
    # 12 full lunar months means 13 new moons
    round((end_of_year - start_of_year) / Time.mean_synodic_month()) == @lunar_calendar_months_in_year
  end

  @doc false
  def leap_lunisolar_year?(year, month, day, epoch, location_fun) do
    iso_days = date_to_iso_days(year, month, day, epoch, location_fun)
    leap_lunisolar_year?(iso_days, location_fun)
  end

  # Original version in which the month number doesn't change for
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
  def alt_cyclical_date_to_iso_days(cycle, cyclical_year, month, leap_month?, day, epoch, location_fun) do
    mid_year = mid_year(cycle, cyclical_year, epoch)
    new_year = new_year_on_or_before(mid_year, location_fun)

    p = new_moon_on_or_after(new_year + (month - 1) * 29, location_fun)
    d = alt_cyclical_date_from_iso_days(p, epoch, location_fun)

    prior_new_moon =
      if month == month(d) && leap_month? == leap_month?(d) do
        p
      else
        new_moon_on_or_after(1 + p, location_fun)
      end

    prior_new_moon + day - 1
  end

  @doc false
  # defp alt_cyclical_date_to_iso_days({cycle, cyclical_year, month, leap_month?, day}, epoch, location_fun) do
  #   alt_cyclical_date_to_iso_days(cycle, cyclical_year, month, leap_month?, day, epoch, location_fun)
  # end

  defp month_and_leap(iso_days, location_fun) do
    {prior_month_12, next_month_11} =
      lunisolar_year(iso_days, location_fun)

    leap_sui_year? =
      leap_lunisolar_year?(prior_month_12, next_month_11)

    start_of_month_in_iso_days =
      new_moon_before(iso_days + 1, location_fun)

    lunar_month =
      start_of_month_in_iso_days
      |> lunar_months_between(prior_month_12)
      |> offset_if_prior_leap_month(leap_sui_year?, prior_month_12, start_of_month_in_iso_days, location_fun)
      |> amod(@lunar_calendar_months_in_year)
      |> trunc()

    leap_month? =
      is_leap_month?(leap_sui_year?, start_of_month_in_iso_days, prior_month_12, location_fun)

    {lunar_month, start_of_month_in_iso_days, leap_month?}
  end

  defp lunisolar_year(iso_days, location_fun) do
    prior_solstice = december_solstice_on_or_before(iso_days, location_fun)
    prior_month_12 = new_moon_on_or_after(1 + prior_solstice, location_fun)

    next_solstice = december_solstice_on_or_before(prior_solstice + @one_solar_year_later, location_fun)
    next_month_11 = new_moon_before(1 + next_solstice, location_fun)

    {prior_month_12, next_month_11}
  end

  defp is_leap_month?(leap_sui_year?, iso_days, start_of_sui_year, location_fun) do
    leap_sui_year? && no_major_solar_term?(iso_days, location_fun) &&
      !is_prior_leap_month?(start_of_sui_year, new_moon_before(iso_days, location_fun), location_fun)
  end

  defp offset_if_prior_leap_month(months, true = _leap_sui_year?, last_month_12, start_of_month, location_fun) do
    if is_prior_leap_month?(last_month_12, start_of_month, location_fun), do: months - 1, else: months
  end

  defp offset_if_prior_leap_month(months, _leap_sui_year?, _last_month_12, _start_of_month, _location_fun) do
    months
  end

  defp lunar_months_between(from_iso_days, to_iso_days) do
    round((from_iso_days - to_iso_days) / Time.mean_synodic_month())
  end

  defp mid_year(cycle, cyclic_year, epoch) do
    floor(epoch +
      ((((cycle - 1) * @years_in_cycle) + (cyclic_year - 1) + 1/2) * Time.mean_tropical_year()))
  end

  @doc """
  Return moment at `location` of the first date on or after
  `iso_days` when the solar longitude
  will be 'lambda' degrees.

  """
  @spec solar_longitude_on_or_after(Astro.angle(), number(), function()) :: Time.time()

  def solar_longitude_on_or_after(lambda, iso_days, location_fun) do
    {_lat, _lng, _alt, offset} = location_fun.(iso_days)
    d = Time.universal_from_standard(iso_days, offset)
    t = Solar.solar_longitude_after(lambda, d)

    Time.standard_from_universal(t, location_fun.(t))
  end

  @doc """
  Return last Chinese major solar term (zhongqi) before
  `iso_days`.

  """
  def current_major_solar_term(iso_days, location_fun) do
    {_lat, _lng, _alt, offset} = location_fun.(iso_days)
    d = Time.universal_from_standard(iso_days, offset)
    s = Solar.solar_longitude(d)
    amod(2 + floor(trunc(s) / deg(30)), 12)
  end

  @doc """
  Return moment at `location` of the first major
  solar term (zhongqi) on or after `iso_days`.  The
  major terms begin when the sun's longitude is a
  multiple of 30 degrees.

  """
  def major_solar_term_on_or_after(iso_days, location_fun) do
    s = Solar.solar_longitude(midnight_in_location(iso_days, location_fun))
    l = mod(30 * ceil(s / 30), 360)
    solar_longitude_on_or_after(l, iso_days, location_fun)
  end

  @doc """
  Return last minor solar term (jieqi) before `iso_days`.
  """
  def current_minor_solar_term(iso_days, location_fun) do
    {_lat, _lng, _alt, offset} = location_fun.(iso_days)
    d = Time.universal_from_standard(iso_days, offset)
    s = Solar.solar_longitude(d)
    amod(3 + floor(s - deg(15) / deg(30)), 12)
  end

  @doc """
  Return moment at `location` of the first minor solar
  term (jieqi) on or after `iso_days`.  The minor terms
  begin when the sun's longitude is an odd multiple of 15 degrees.

  """
  def minor_solar_term_on_or_after(iso_days, location_fun) do
    s = Solar.solar_longitude(midnight_in_location(iso_days, location_fun))
    l = mod(30 * ceil((s - deg(15)) / 30) + deg(15), 360)

    solar_longitude_on_or_after(l, iso_days, location_fun)
  end

  @doc """
  Return `iso_day` at `location` of first new moon
  before `iso_days`.

  """
  def new_moon_before(iso_days, location_fun) do
    new_moon =
      iso_days
      |> midnight_in_location(location_fun)
      |> Lunar.date_time_new_moon_before()

    {_lat, _lng, _alt, offset} = location_fun.(new_moon)

    Time.standard_from_universal(new_moon, offset) |> floor()
  end

  @doc """
  Return `iso_day` at `location` of first new moon on or after
  `iso_days`.

  """
  def new_moon_on_or_after(iso_days, location_fun) do
    new_moon =
      iso_days
      |> midnight_in_location(location_fun)
      |> Lunar.date_time_new_moon_at_or_after()

    {_lat, _lng, _alt, offset} = location_fun.(new_moon)

    Time.standard_from_universal(new_moon, offset) |> floor()
  end

  @doc """
  Return `true` if lunar month starting on `iso_days`
  at `location` has no major solar term.

  """
  def no_major_solar_term?(iso_days, location_fun) do
    new_moon = new_moon_on_or_after(iso_days + 1, location_fun)
    current_major_solar_term(iso_days, location_fun) == current_major_solar_term(new_moon, location_fun)
  end

  @doc """
  Return Universal time of (clock) midnight at start of `iso_days`,
  at `location`.

  """
  def midnight_in_location(iso_days, location_fun) do
    {_lat, _lng, _alt, offset} = location_fun.(iso_days)
    Time.universal_from_standard(iso_days, offset)
  end

  @doc """
  Return iso_days, in the `location` zone, of winter solstice
  on or before `iso_days`.

  """
  def december_solstice_on_or_before(iso_days, location_fun) do
    approx = Solar.estimate_prior_solar_longitude(@winter, midnight_in_location(iso_days + 1, location_fun))
    next(floor(approx) - 1, &(@winter < Solar.solar_longitude(midnight_in_location(1 + &1, location_fun))))
  end

  @doc """
  Return `iso_day` of Lunar New Year in sui
  (period from solstice to solstice)
  containing `iso_days`.

  """
  def new_year_in_sui(iso_days, location_fun) do
    {prior_month_12, next_month_11} = lunisolar_year(iso_days, location_fun)
    prior_month_13 = new_moon_on_or_after(1 + prior_month_12, location_fun)

    leap_year? =
      leap_lunisolar_year?(prior_month_12, next_month_11)

    no_prior_major_solar_term? =
      no_major_solar_term?(prior_month_12, location_fun) || no_major_solar_term?(prior_month_13, location_fun)

    if leap_year? && no_prior_major_solar_term? do
      new_moon_on_or_after(1 + prior_month_13, location_fun)
    else
      prior_month_13
    end
  end

  @doc """
  Return `iso_day` of Lunar New Year on or
  before `iso_days` at `location`.

  """
  def new_year_on_or_before(iso_days, location_fun) do
    new_year = new_year_in_sui(iso_days, location_fun)

    if iso_days >= new_year do
      new_year
    else
      new_year_in_sui(iso_days - 180, location_fun)
    end
  end

  @doc """
  Return iso_days of Lunar New Year at `location` for a
  Gregorian year.

  """
  def chinese_new_year_for_gregorian_year(gregorian_year, location_fun) do
    iso_days = Cldr.Calendar.Gregorian.date_to_iso_days(gregorian_year, 7, 1)
    new_year_on_or_before(iso_days, location_fun)
  end

  @doc """
  Return `true` if there is a Lunar leap month on or after lunar
  month starting on `m_prime` and at or before
  lunar month starting at `m`.

  """
  def is_prior_leap_month?(m_prime, m, location_fun) when m >= m_prime do
    no_major_solar_term?(m, location_fun) ||
       is_prior_leap_month?(m_prime, new_moon_before(m, location_fun), location_fun)
  end

  def is_prior_leap_month?(_m_prime, _m, _location_fun) do
    false
  end

  @doc """
  Return the name of the Lunar
  sexagesimal cycle.

  """
  def stem_and_branch({_cycle, cyclical_year, _month, _leap_month?, _day}) do
    stem_and_branch(cyclical_year)
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
  Return the number of names from Lunar name c_name1 to the
  next occurrence of Lunar name c_name2.

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

  # CHECK THIS was iso_day(45) -> might need to be +/- 365 since our
  # epoch is different
  @month_name_epoch 57

  @doc """
  Return sexagesimal name for month, month, of Chinese year, year.
  """
  def month_name(month, year) do
    elapsed_months = 12 * (year - 1) + (month - 1)
    stem_and_branch(elapsed_months - @month_name_epoch)
  end

  # CHECK THIS was iso_day(45) -> might need to be +/- 365 since our
  # epoch is different
  @day_name_epoch 45

  @doc """
  Return sexagesimal name for date, date.
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

  def location(iso_days, location_fun) do
    {latitude, longitude, altitude, offset} = location_fun.(iso_days)
    properties = %{offset: offset}
    %Geo.PointZ{coordinates: {longitude, latitude, altitude}, properties: properties}
  end

end